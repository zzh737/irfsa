# AD9361 Packer

面向 KU5P FPGA 与 FMC AD9361 的纯 PL 射频收发工程，提供双路发射、接收采样、射频配置和 IQ 网络传输。工程包含 RTL、引脚及时序约束、ROM 数据、构建脚本、协议客户端和硬件下载文件。

## 硬件连接

使用 KU5P 开发板、FMC AD9361 模块、UART 和以太网连接。FPGA 型号为 `xcku5p-ffvb676-2-i`，引脚分配见 `AD9361_Packer/constraints/ku5p_pins.xdc`，开发板与模块资料位于 FPGA 工程根目录。

| 通道 | 参数 | 用途 |
| --- | --- | --- |
| UART | 115200，8 数据位，无校验，1 停止位，无流控 | TX 参数配置、状态读取及双路发射开关 |
| 以太网 | 本机默认 `192.168.10.1`，板端默认 `192.168.10.2`，控制端口 UDP `40001` | RX 参数配置、接收启停和 IQ 数据传输 |

将电脑网卡配置到板端所在网段。控制程序分别通过 UART 和 UDP 与 FPGA 握手，以协议应答和状态读回确认连接。IQ 数据接收使用本机 UDP `40000` 端口；使用接收功能时，需要允许控制与接收程序通过防火墙访问对应网卡。

## FPGA 下载与固化

下载文件位于 `AD9361_Packer/reports/system_build`。

| 文件 | 用途 |
| --- | --- |
| `ku5p_HW23.bit` | 通过 JTAG 配置 FPGA |
| `hw23.mcs` | 写入配置 Flash，用于上电启动 |
| `hw23.prm` | Flash 镜像的地址、接口及校验信息 |

在 Vivado Hardware Manager 中连接目标 KU5P，使用 **Program Device** 选择 `.bit` 文件进行配置。固化时，按开发板实际 Flash 型号添加 Configuration Memory Device，选择 `.mcs` 文件，执行擦除、编程及校验。镜像接口为 SPI x4，容量 32 MB，装载起始地址为 `0x00000000`。固化后重新上电加载。

## 发射

1. 连接 UART，通过 RFCT 发射控制协议完成握手。
2. 下发调制方式、本振、基带带宽、频偏、衰减和噪声参数，等待配置完成并读取状态。
3. 按需开启 TX1、TX2；停止发射时关闭对应通道。

TX1 支持 AM、FM、2/4/8/16 阶 ASK、FSK、PSK，以及 16/64/256QAM。AM 包括双边带和单边带、带载波和抑制载波形式。TX2 提供带限噪声，两路可独立开关。

本振范围为 300 MHz～6 GHz。基带带宽 `B` 为单边基带带宽，范围 0.005～10 MHz；频偏 `f` 为 TX1 载波相对 TX 本振的位置。物理参数到硬件寄存器的换算见 `AD9361_Packer/host/waveform_config.py`，命令处理见 `AD9361_Packer/rtl/rfct_controller.sv`。

| 调制形式 | 相对 TX 本振的占用范围 | 射频带宽 |
| --- | --- | --- |
| 双边带 AM、FM、ASK、FSK、PSK、QAM | `f − B` 至 `f + B` | `2B` |
| 单边带 USB | `f` 至 `f + B` | `B` |
| 单边带 LSB | `f − B` 至 `f` | `B` |

TX1 与 TX2 的频带均需落在本振 ±10 MHz 范围内。发射衰减范围为 0～89.75 dB，步进 0.25 dB。

## 接收与协议客户端

通过 UDP 配置接收本振、模拟带宽、增益方式和 IQ 输出采样率，再启动接收。支持 25 MSPS 原始采样和 FIR 抽取后的 1 MSPS 输出；持续接收速率应与网络吞吐能力匹配。

`AD9361_Packer/host/ku5p.py` 提供状态查询、停止接收和 IQ 录制命令，使用 Python 3.10 或更高版本，无需安装第三方 Python 库。

```powershell
cd D:\e-project\IRFSA_release\AD9361_Packer\AD9361_Packer\host
python ku5p.py --bind 192.168.10.1 --peer 192.168.10.2 status
python ku5p.py --bind 192.168.10.1 --peer 192.168.10.2 capture --rate 1m --seconds 10 --center 2380000000 --output capture.iq
python ku5p.py --bind 192.168.10.1 --peer 192.168.10.2 stop
```

`--center` 单位为 Hz，`--seconds` 单位为秒；`--rate` 可选 `1m` 或 `25m`。该录制命令将接收模拟带宽设为 20 MHz、手动增益设为 10 dB，并在录制结束时停止本次接收。TX 配置和发射开关通过 UART 控制，不能使用该客户端经 UDP 下发。

录制输出包含以下文件：

| 文件类型 | 内容 |
| --- | --- |
| `.iq` | 小端有符号 16 位 I、Q 交错样本 |
| `.json` | 采样率、频率、接收配置和接收统计 |
| `.index.bin` | 窗口、采样位置、文件偏移和完整性索引 |

协议数据结构、帧编解码及 CRC 处理见 `AD9361_Packer/host/rf_protocol.py`。客户端会在脚本所在目录保存请求编号数据库，可用 `--state` 指定其路径。

## FPGA 构建

使用 Vivado 2025.2 打开 `AD9361_Packer/AD9361_Packer.xpr`，顶层为 `ku5p_top`。需要重新构建时，重置综合与实现运行，再依次执行 **Run Synthesis**、**Run Implementation** 和 **Generate Bitstream**。

工程中的 Tcl 钩子会设置器件与 I/O 约束，检查时序、DRC 和 CDC，并将生成的位流输出到 `AD9361_Packer/reports/system_build/ku5p_system_candidate.bit`。构建工具需要对工程目录具有写入权限。

如需运行 Python 构建或仿真脚本，脚本使用的 Vivado 路径为 `D:\Xilinx\2025.2\Vivado\bin`；ADI 参考算法生成脚本使用 `D:\Xilinx\2025.2\win64\tools\vcxx\libexec\clang.exe`。使用这些脚本时，需要在对应路径安装工具。部分联调测试还需要配套的 FPAI 工程或硬件连接。

代码目录和模块职责见 [src.md](src.md)。
