# 代码结构

## 目录

```text
AD9361_Packer/
├─ README.md                         使用说明
├─ src.md                            代码结构
└─ AD9361_Packer/                     FPGA 工程
   ├─ AD9361_Packer.xpr               Vivado 工程入口
   ├─ AD9361_Packer.srcs/utils_1/     工程引用的综合检查点
   ├─ rtl/                           自研 RTL 与 ROM 数据
   ├─ constraints/                   引脚及时序约束
   ├─ scripts/                       构建、ROM 生成和仿真脚本
   ├─ host/                          Python 协议客户端与参数规划
   ├─ protocol/                      协议测试向量
   ├─ sim/                           独立仿真顶层与输入数据
   ├─ vendor/                        以太网 RTL 与 ADI 参考代码
   ├─ archive/softcore_prototype/
   │  └─ firmware/ad9361_defaults.c  ADI 参考算法的初始化参数输入
   ├─ reports/radio_oracle/           ROM 生成所需的参考轨迹与 C 输入
   ├─ reports/system_build/           下载文件与实现检查报告
   └─ *.pdf、*.xlsx                   器件手册、板卡资料和引脚表
```

FPGA 的 RTL、构建脚本、ROM 和第三方代码按工程内相对路径组织。打开 `AD9361_Packer/AD9361_Packer.xpr` 使用 Vivado 工程；通信和参数规划代码位于工程内的 `host` 目录。

## FPGA 模块

顶层文件为 `AD9361_Packer/rtl/ku5p_top.sv`，目标器件为 `xcku5p-ffvb676-2-i`。

| 模块 | 职责 |
| --- | --- |
| `ad9361_spi.v` | AD9361 SPI 寄存器访问 |
| `ad9361_radio.sv` | 射频初始化、收发配置及运行状态管理 |
| `ad9361_frequency_plan.sv`、`ad9361_tune.sv`、`ad9361_adc_cal.sv` | 频率规划、调谐与校准 |
| `ad9361_lvds.sv`、`ad9361_frame_core.sv` | AD9361 LVDS 数据接口、帧同步和 IQ 装配 |
| `ad9361_rx_observer.sv` | 接收输入与帧活动观测 |
| `waveform_core.sv` | 调制波形生成、载波频移和双路发射数据组织 |
| `rrc_resampler.sv`、`gaussian_prng.sv` | 成形重采样与噪声生成 |
| `fir_decimate5.sv` | 接收 FIR 滤波与抽取 |
| `rfct_controller.sv` | 控制命令处理及寄存器接口 |
| `uart_phy.sv`、`uart_command_rx.sv` | UART 物理层和命令帧接收 |
| `control_transport.sv`、`udp_command_rx.sv` | 控制传输与 UDP 命令接收 |
| `rfiq_packetizer.sv` | IQ 数据窗口与网络分片封装 |
| `network_core.sv`、`rtl8211f_init.sv` | 以太网数据通路及 PHY 初始化 |
| `eeprom_i2c.sv`、`boot_journal.sv` | EEPROM 访问和启动编号管理 |
| `us_ddr.v`、`us_ssio.sv` | UltraScale+ DDR 与源同步 I/O 适配 |

`rtl/rom` 提供射频配置、校准、频率表、正弦表、滤波系数和噪声表。`constraints/ku5p_pins.xdc` 定义板级引脚，`constraints/ku5p_timing.xdc` 定义时钟及外部接口时序。

接收数据从 AD9361 LVDS 接口进入，经帧装配、可选 FIR 抽取和 IQ 封装后通过以太网送到电脑。TX 参数经 UART 下发，波形模块产生 IQ 并经 LVDS 接口送至 AD9361。运行时由 RTL 状态机完成控制，无需软核 CPU。

## 构建与参考代码

| 路径或脚本 | 用途 |
| --- | --- |
| `scripts/source_manifest.py` | 从顶层实例关系选择 RTL 源文件 |
| `scripts/system_sources.json`、`scripts/system_sources.tcl` | 构建源文件列表 |
| `scripts/build_system.py`、`scripts/build_system.tcl` | 自动化综合、布局布线和位流生成入口 |
| `scripts/ku5p_post_synth.tcl`、`scripts/ku5p_post_opt.tcl` | 综合后和优化后的约束设置 |
| `scripts/ku5p_io_config.tcl` | I/O 及配置接口设置 |
| `scripts/ku5p_pre_bitstream.tcl`、`scripts/ku5p_post_bitstream.tcl` | 位流生成前检查与输出处理 |
| `scripts/generate_*.py` | ROM、滤波系数及射频参考数据生成 |
| `scripts/sim_utils.py`、`scripts/test_*.py` | XSIM 驱动、协议和硬件模块测试 |
| `scripts/release_manifest.py`、`scripts/verify_candidate.py` | 自动构建的输入与验收条件检查 |
| `scripts/program_candidate.py`、`scripts/program_candidate.tcl` | 对完成发布检查的构建执行 JTAG 下载 |
| `vendor/verilog-ethernet` | MAC、ARP、IP、UDP、AXI Stream 和相关约束 |
| `vendor/no-os` | AD9361 初始化与校准算法的 C 参考实现 |

自动化发布检查依赖各测试生成的结果文件；执行自动化下载前，需要先完成相应构建和测试。直接下载随附文件的操作见 README。

`generate_radio_rom.py` 从 `reports/radio_oracle` 读取参考轨迹。重新生成参考轨迹时，`generate_radio_trace.py` 使用 ADI C 代码和 `archive/softcore_prototype/firmware/ad9361_defaults.c`；该 C 文件用于主机侧参考计算，不参与 FPGA 运行。

## 协议客户端

| 文件 | 职责 |
| --- | --- |
| `host/ku5p.py` | 协议握手、状态查询、会话编号、接收重组、IQ 录制及命令行入口 |
| `host/rf_protocol.py` | 控制帧、IQ 帧、配置及状态结构，编解码和 CRC 校验 |
| `host/waveform_config.py` | 调制参数、射频占用范围和硬件寄存器规划 |

UART 使用 RFCT 发射控制帧，UDP 使用 RFCT 接收控制帧和 RFIQ 数据帧。`host/ku5p.py` 的命令行提供 RX 状态查询、停止接收及录制功能；发射控制由 UART 接入。

`protocol/vectors_uart_rx` 保存协议测试向量。`scripts/test_command_rx.py`、`scripts/test_controller.py`、`scripts/test_split_control.py` 等脚本用于验证命令接收、控制状态机和 UART/UDP 分工。
