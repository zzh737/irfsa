#pragma once
#include <array>
#include <algorithm>
#include <cstdint>
#include "fft_coefficients.hpp"

inline int16_t rf_sat(int64_t n) {return int16_t(std::clamp<int64_t>(n,-32768,32767));}
inline int64_t rf_round(int64_t n,int64_t d) {return n<0?-((-n+d/2)/d):(n+d/2)/d;}
inline std::array<uint32_t,1024> rf_cpu_power(const std::array<int16_t,2048>& iq,bool hann) {
 std::array<int16_t,1024> re{},im{};
 for(unsigned n=0;n<1024;++n) {
   unsigned r=0;for(unsigned b=0;b<10;++b)r=(r<<1)|((n>>b)&1);
   re[r]=hann?rf_sat(rf_round(int64_t(iq[2*n])*rf_hann[n],32767)):iq[2*n];
   im[r]=hann?rf_sat(rf_round(int64_t(iq[2*n+1])*rf_hann[n],32767)):iq[2*n+1];
 }
 for(unsigned span=2;span<=1024;span*=2)for(unsigned base=0;base<1024;base+=span)
  for(unsigned j=0;j<span/2;++j) {
   unsigned a=base+j,b=a+span/2,k=j*1024/span;
   int32_t tr=rf_sat(rf_round(int64_t(re[b])*rf_wr[k]-int64_t(im[b])*rf_wi[k],32767));
   int32_t ti=rf_sat(rf_round(int64_t(re[b])*rf_wi[k]+int64_t(im[b])*rf_wr[k],32767));
   int32_t ar=re[a],ai=im[a];
   re[a]=rf_sat(rf_round(ar+tr,2));im[a]=rf_sat(rf_round(ai+ti,2));
   re[b]=rf_sat(rf_round(ar-tr,2));im[b]=rf_sat(rf_round(ai-ti,2));
  }
 std::array<uint32_t,1024> out{};
 for(unsigned n=0;n<1024;++n)out[n]=uint32_t(int64_t(re[n])*re[n]+int64_t(im[n])*im[n]);
 return out;
}
