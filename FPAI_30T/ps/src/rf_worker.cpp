// Persistent SDK worker. Loopback RPC separates all SDK stdout from data.
// --host performs real CPU FFT + iCraft Host inference; --board uses PL + ZG330.
#ifdef _WIN32
#define NOMINMAX
#include <winsock2.h>
#include <ws2tcpip.h>
#ifdef IN
#undef IN
#endif
#ifdef OUT
#undef OUT
#endif
#ifdef small
#undef small
#endif
using rf_socket=SOCKET;
inline void close_socket(rf_socket s){closesocket(s);}
#else
#include <arpa/inet.h>
#include <sys/socket.h>
#include <unistd.h>
using rf_socket=int;
inline void close_socket(rf_socket s){close(s);}
#endif
#include <icraft-xrt/core/session.h>
#include <icraft-xrt/dev/host_device.h>
#include <icraft-xrt/dev/zg330_device.h>
#include <icraft-backends/hostbackend/backend.h>
#include <icraft-backends/zg330backend/zg330backend.h>
#include <icraft-xir/base/version.h>
#include "rf_regs.h"
#include "iq_preprocess.hpp"
#include "fft_cpu.hpp"
#include <array>
#include <chrono>
#include <csignal>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <thread>
#include <vector>
using namespace icraft::xrt;
using Clock=std::chrono::steady_clock;
static uint64_t us(Clock::time_point t){return std::chrono::duration_cast<std::chrono::microseconds>(Clock::now()-t).count();}
static uint32_t get32(const char* p){uint32_t n=0;for(int b=0;b<4;++b)n|=uint32_t(uint8_t(p[b]))<<(8*b);return n;}
static void put32(std::vector<char>& out,uint32_t n){for(int b=0;b<4;++b)out.push_back(char(n>>(8*b)));}
static void put64(std::vector<char>& out,uint64_t n){for(int b=0;b<8;++b)out.push_back(char(n>>(8*b)));}
static bool read_all(rf_socket s,char* p,size_t n){
 while(n){int got=recv(s,p,int(n),0);if(got==0)return false;if(got<0)throw std::runtime_error("socket read");p+=got;n-=got;}return true;
}
static void send_all(rf_socket s,const std::vector<char>& bytes){
 size_t off=0;while(off<bytes.size()){int n=send(s,bytes.data()+off,int(bytes.size()-off),0);if(n<=0)throw std::runtime_error("socket write");off+=n;}
}

class Engine {
 bool board_mode;
 icraft::xir::Network network;
 Session session;
 Tensor input;
 Device device;
 MemChunk memory;
 bool quarantined=false;
 uint32_t address=0;
 uint32_t read(uint32_t off){return uint32_t(device.cast<ZG330Device>().defaultRegRegion().read(RF_REG_BASE+off,false));}
 void write(uint32_t off,uint32_t value){device.cast<ZG330Device>().defaultRegRegion().write(RF_REG_BASE+off,value,false);}
 public:
 ~Engine() {
   if(board_mode&&quarantined){
     std::cerr<<"QUARANTINED SDK operation: retaining worker; recover board before termination.\n";
     for(;;)std::this_thread::sleep_for(std::chrono::seconds(1));
   }
 }
 Engine(bool board,const std::string& json,const std::string& raw):board_mode(board) {
   if(icraft::xir::MajorVersionNum()!=3 || icraft::xir::MinorVersionNum()!=36 ||
      (icraft::xir::PatchVersionNum()!=0 && icraft::xir::PatchVersionNum()!=1))
     throw std::runtime_error("Validated runtime family is iCraft 3.36.0/3.36.1; installed XIR is "+
                              std::string(icraft::xir::MainVersion()));
   network=icraft::xir::Network::CreateFromJsonFile(json);
   network.loadParamsFromFile(raw);
   if(network.inputs().size()!=1||network.outputs().size()!=1)throw std::runtime_error("Expected one model input/output");
   auto dtype=network.inputs()[0].tensorType();
   if(dtype->shape.size()!=3||dtype->shape[0]!=1||dtype->shape[1]!=2||dtype->shape[2]!=1024||
      dtype->element_dtype!=icraft::xir::FloatType::FP32())
     throw std::runtime_error("Expected model FP32 FD (1,2,1024); retain model boundary Cast/Reshape ops");
   if(board_mode) {
     device=Device::Open("axi://zg330aiu?npu=0x40000000&dma=0x80000000");
     if(read(RF_VERSION)!=RF_VERSION_VALUE||(read(RF_CAPABILITIES)&7)!=7)
       throw std::runtime_error("Wrong system bitstream or missing FFT/display capability");
     if(read(RF_STATUS)&RF_BUSY)throw std::runtime_error("Custom Op busy on entry; recover board");
     session=Session::Create<icraft::xrt::zg330::ZG330Backend,HostBackend>(network,{device,HostDevice::Default()});
     // Required conservative configuration: 312 frozen frames matched on 3.36.0.
     // Default optimization combination produced repeated-session mismatches.
     for(auto binding:session.backendBindings()) {
       if(binding.second.is<icraft::xrt::zg330::ZG330Backend>()) {
         auto backend=binding.second.cast<icraft::xrt::zg330::ZG330Backend>();
         backend.disableMergeHardOp();
         backend.disableEtmOptimize();
         backend.ocmOptimize(icraft::xrt::zg330::OcmOpt::None);
       }
     }
     session.apply();
     memory=device.cast<ZG330Device>().defaultMemRegion().malloc(8192,false,64);
     uint64_t base=memory->begin.addr();
     if((base&63)||base>std::numeric_limits<uint32_t>::max()-8191)throw std::runtime_error("Device address out of range");
     address=uint32_t(base);
   } else {
     HostBackend::setThreadsNum(2);
     session=Session::Create<HostBackend>(network,{HostDevice::Default()});
   }
   input=Tensor(network.inputs()[0]);input.mallocOn(HostDevice::MemRegion());
 }
 std::vector<char> process(uint32_t capture,uint32_t seq,uint32_t window,const std::vector<char>& payload) {
   if(quarantined)throw std::runtime_error("Worker quarantined: recover board before restart");
   if(!capture||window>1||payload.size()!=4096)throw std::runtime_error("Invalid process request");
   auto started=Clock::now();
   std::array<int16_t,2048> iq{};
   for(unsigned i=0;i<2048;++i){uint16_t bits=uint8_t(payload[2*i])|(uint16_t(uint8_t(payload[2*i+1]))<<8);std::memcpy(&iq[i],&bits,2);}
   std::array<uint32_t,1024> power{};
   if(board_mode) {
     if(read(RF_STATUS)&RF_BUSY)throw std::runtime_error("PL already active");
     memory.write(0,const_cast<char*>(payload.data()),payload.size());
     write(RF_INPUT_ADDR,address);write(RF_OUTPUT_ADDR,address+4096);
     write(RF_INPUT_BYTES,4096);write(RF_OUTPUT_BYTES,4096);
     write(RF_FRAME_SEQ,seq);write(RF_MODE,RF_MODE_FFT);write(RF_WINDOW,window);
     quarantined=true; // Any uncertain SDK exception preserves the persistent allocation.
     write(RF_CONTROL,RF_START);
     bool warned=false;
     for(;;){
       auto status=read(RF_STATUS);
       if(!(status&RF_BUSY)&&(status&RF_DONE)){
         quarantined=false;
         if(status&RF_ERROR)throw std::runtime_error("PL error "+std::to_string(read(RF_ERROR_CODE)));
         break;
       }
       if(!warned&&us(started)>10000000){std::cerr<<"PL timeout: retain allocation, keep waiting; recover board if stuck\n";warned=true;}
       std::this_thread::sleep_for(std::chrono::microseconds(50));
     }
     std::array<char,4096> raw{};memory.read(raw.data(),4096,raw.size());
     for(unsigned k=0;k<1024;++k)power[k]=get32(raw.data()+4*k);
     if(read(RF_FRAME_SEQ)!=seq)throw std::runtime_error("PL frame identity mismatch");
   } else power=rf_cpu_power(iq,window!=0);
   uint64_t fft_us=us(started);
   auto values=normalize_iq(iq);
   input.write(0,reinterpret_cast<char*>(values.data()),sizeof(values));
   auto inference=Clock::now();
   quarantined=true;
   auto outputs=session.forward({input});
   if(outputs.size()!=1)throw std::runtime_error("Expected one output tensor");
   if(!outputs[0].waitForReady(std::chrono::milliseconds(10000)))throw std::runtime_error("Inference readiness timeout");
   quarantined=false;
   std::ostringstream logits(std::ios::out|std::ios::binary);
   outputs[0].dump(logits,"SFB");
   auto bytes=logits.str();
   if(bytes.size()!=72)throw std::runtime_error("Model output must be 18 FP32 logits");
   for(unsigned k=0;k<18;++k){float v;std::memcpy(&v,bytes.data()+4*k,4);if(!std::isfinite(v))throw std::runtime_error("Nonfinite logits");}
   uint64_t inference_us=us(inference);
   std::vector<char> result;result.reserve(4192);
   for(auto p:power)put32(result,p);
   result.insert(result.end(),bytes.begin(),bytes.end());
   put64(result,fft_us);put64(result,inference_us);put64(result,us(started));
   return result;
 }
 bool close_safely() {
   if(board_mode&&quarantined)return false;
   if(board_mode){memory.free();Device::Close(device);}
   return true;
 }
 bool display(uint32_t capture,uint32_t seq,uint32_t class_id,const std::vector<char>& payload) {
   if(payload.size()!=2064||(class_id>17&&class_id!=255))throw std::runtime_error("Invalid display request");
   if(!board_mode)return false;
   // Skip a display update if the previous bank is awaiting the next video
   // frame. Classification/FFT are not throttled to the monitor refresh rate.
   if(read(RF_DISPLAY_STATUS)&1)return false;
   for(unsigned k=0;k<1024;++k){uint32_t h=uint8_t(payload[2*k])|(uint32_t(uint8_t(payload[2*k+1]))<<8);if(h>400)throw std::runtime_error("Height out of range");write(RF_DISPLAY_HEIGHTS+4*k,h);}
   write(RF_DISPLAY_CAPTURE,capture);write(RF_DISPLAY_SEQ,seq);write(RF_DISPLAY_CLASS,class_id);
   write(RF_DISPLAY_CONF,get32(payload.data()+2048));write(RF_DISPLAY_FLAGS,get32(payload.data()+2052));
   write(RF_DISPLAY_PEAK,get32(payload.data()+2056));write(RF_DISPLAY_COMMIT,1);
   return true; // submitted, not necessarily visible yet
 }
};

int main(int argc,char** argv) {
 if(argc!=5){std::cerr<<"Usage: rf_worker --host|--board model.json model.raw port\n";return 2;}
 try {
   const std::string mode=argv[1];
   if(mode!="--host"&&mode!="--board")throw std::runtime_error("Choose explicit worker mode");
   const int port=std::stoi(argv[4]);if(port<1||port>65535)throw std::runtime_error("Invalid port");
#ifdef _WIN32
   WSADATA state;if(WSAStartup(MAKEWORD(2,2),&state))throw std::runtime_error("WSAStartup");
#else
   // A timed-out PS client must not terminate an uncertain SDK operation.
   std::signal(SIGPIPE,SIG_IGN);
#endif
   rf_socket listener=socket(AF_INET,SOCK_STREAM,0);
   sockaddr_in address{};address.sin_family=AF_INET;address.sin_port=htons(uint16_t(port));address.sin_addr.s_addr=htonl(INADDR_LOOPBACK);
   if(bind(listener,reinterpret_cast<sockaddr*>(&address),sizeof(address))||listen(listener,1))throw std::runtime_error("Loopback worker bind/listen");
   Engine engine(mode=="--board",argv[2],argv[3]);
   std::cout<<"RF_WORKER_READY "<<(mode=="--host"?"host-cpu":"zg330-pl")<<" "<<port<<std::endl;
   rf_socket client=accept(listener,nullptr,nullptr);
   if(client==rf_socket(-1))throw std::runtime_error("Worker accept");
   std::array<char,32> header{};
   while(read_all(client,header.data(),header.size())) {
     if(std::memcmp(header.data(),"RFWK",4)||get32(header.data()+4)!=1)throw std::runtime_error("Bad RPC header");
     uint32_t op=get32(header.data()+8),capture=get32(header.data()+12),seq=get32(header.data()+16),arg=get32(header.data()+20),length=get32(header.data()+28);
     if(length>8192||get32(header.data()+24)!=0)throw std::runtime_error("Bad RPC size/status");
     std::vector<char> payload(length),body;uint32_t status=0;
     if(!read_all(client,payload.data(),payload.size()))throw std::runtime_error("Truncated RPC body");
     try {
       if(op==0&&payload.empty()){
         std::string label=mode=="--host"?"host-cpu":"zg330-pl";body.assign(label.begin(),label.end());
       } else if(op==1)body=engine.process(capture,seq,arg,payload);
       else if(op==2)put32(body,engine.display(capture,seq,arg,payload)?1u:0u);
       else if(op==3&&payload.size()==4096&&arg<=1){
         std::array<int16_t,2048> iq{};
         for(unsigned i=0;i<2048;++i){uint16_t bits=uint8_t(payload[2*i])|(uint16_t(uint8_t(payload[2*i+1]))<<8);std::memcpy(&iq[i],&bits,2);}
         auto tick=Clock::now();auto power=rf_cpu_power(iq,arg!=0);auto elapsed=us(tick);
         for(auto p:power)put32(body,p);put64(body,elapsed);
       }
       else throw std::runtime_error("Unsupported worker operation");
     } catch(const std::exception& e){status=1;std::string message=e.what();body.assign(message.begin(),message.end());}
     std::vector<char> response={'R','F','R','S'};
     for(auto n:{1u,op,capture,seq,arg,status,uint32_t(body.size())})put32(response,n);
     response.insert(response.end(),body.begin(),body.end());send_all(client,response);
   }
   close_socket(client);close_socket(listener);
   if(!engine.close_safely()){
     std::cerr<<"QUARANTINED: retaining uncertain active SDK buffers. Recover board before terminating worker.\n";
     for(;;)std::this_thread::sleep_for(std::chrono::seconds(1));
   }
   return 0;
 }catch(const std::exception& e){std::cerr<<e.what()<<'\n';return 1;}
}
