# 工程结构说明

本文件按发布目录中的工程说明汇总组件关系。四个主工程分别承担硬件收发、桌面控制分析、离线识别和正式运行推理职责；其中 `AD9361_Packer` 的硬件接口是其他软件工程使用 RFCT/RFIQ 和 IQ 文件的基础。

## 顶层目录

```text
IRFSA_release/
├─ AD9361_Packer/        KU5P + FMC AD9361 纯 PL 射频收发工程
├─ RF_studio/            Windows GUI 控制、观测、录制和 ONNX 分析
├─ py/                   Python/PyTorch 离线 18 类识别
├─ FPAI_30T/             正式运行 FPGA、PS 服务和 ZG330 推理
├─ README.md             工程总体说明
└─ src.md                本结构说明
```

## AD9361_Packer

```text
AD9361_Packer/
├─ README.md、src.md
└─ AD9361_Packer/
   ├─ AD9361_Packer.xpr             Vivado 工程入口
   ├─ rtl/                          自研射频、协议、网络和数据通路 RTL
   ├─ constraints/                  引脚、时钟、接口时序和 CDC 约束
   ├─ scripts/                      源文件清单、构建、ROM 生成、仿真和下载脚本
   ├─ host/                         Python 协议客户端、参数规划和 IQ 录制
   ├─ protocol/                     UART/RX 协议测试向量
   ├─ sim/                          独立仿真顶层和输入数据
   ├─ vendor/                       Ethernet RTL 与 ADI no-OS 参考代码
   ├─ archive/softcore_prototype/   参考算法输入及历史软核原型资料
   ├─ reports/radio_oracle/         射频 ROM 生成的参考轨迹和 C 输入
   └─ reports/system_build/         位流、Flash 镜像和实现检查报告
```

FPGA 顶层为 `rtl/ku5p_top.sv`，目标器件为 `xcku5p-ffvb676-2-i`。AD9361 相关模块完成 SPI、初始化、频率规划、调谐、校准、LVDS 帧同步和 IQ 装配；`waveform_core.sv`、`rrc_resampler.sv` 和 `gaussian_prng.sv` 负责调制、成形和噪声；`fir_decimate5.sv` 提供接收抽取。`rfct_controller.sv`、UART/UDP 接收模块处理控制帧，`rfiq_packetizer.sv` 完成 IQ 窗口和网络分片封装，`network_core.sv` 与 PHY 初始化模块连接以太网。

`rtl/rom` 保存射频配置、校准、频率、正弦、滤波器和噪声数据。`host/ku5p.py` 提供握手、状态、会话编号、RX 停止、IQ 重组和录制；`host/rf_protocol.py` 定义控制帧、IQ 帧、配置/状态结构及 CRC；`host/waveform_config.py` 将物理参数转换为射频占用和硬件寄存器规划。

## RF_studio

```text
RF_studio/
├─ app.py                         GUI 入口和界面状态管理
├─ backend.py                     硬件工作线程、观测和录制
├─ radio_links.py                 UART、RX 和通道组合
├─ command_interface.py           控制台命令和本机 TCP 服务
├─ ku5p_cmd.py                    TCP 命令客户端
├─ controls.py、ui_parameters.py  控件、参数类型转换和校验
├─ band_check.py                  发射/接收频带检查
├─ training_capture.py            训练标签、配置快照和采集约束
├─ training_campaign.py           批量任务、参数组合和检查
├─ campaign_view.py               批量采集编辑和执行
├─ analysis_view.py               IQ、星座、频谱和瀑布图
├─ analysis_workers.py            分析子进程和任务调度
├─ dsp_analysis.py、rx_filter.py  PSD、星座同步计算和 PC 端 FIR
├─ signal_view.py、demo_signal.py 绘图组件和离线演示信号
├─ model_view.py、model_eval.py   模型选择、推理和目录评估
├─ core/                          KU5P 协议、RFCT/RFIQ 和波形配置
├─ model/                         ONNX 模型及 `.model.json`
├─ vendor/、assets/               串口依赖和界面资源
└─ build_exe.py、exe_selftest.py  构建和命令行自检入口
```

GUI 操作和 TCP 命令共用 `Application` 的参数、校验、锁定及异步动作路径。UART 固定承担 TX 控制，UDP 控制 RX 配置，UDP IQ 通道承担数据接收。IQ 报文先做来源、会话、元数据和 CRC 校验，再重组成窗口供观测、录制和模型分析；分析任务与 ONNX 推理放在后台进程，避免阻塞 Tk 主线程。普通录制和训练录制都以 `.iq`、`.index.bin`、`.json` 为核心数据文件，训练录制额外保存 TX1 配置标签及一致性信息。

## py

```text
py/
├─ fullscale_18class_recognize.py   命令行识别入口
├─ fullscale_18class_config.py      类别顺序和权重校验
├─ signal_preprocess.py              IQ 形状转换与输入检查
├─ correlation_modulation_model.py  识别网络
├─ multiscale_modulation_model.py   多尺度网络模块
├─ modulation_model.py               基础网络模块
├─ fullscale_training.py             分批归一化和概率计算
├─ fullscale_dataset.py              训练模块导入依赖
├─ targeted_augmentation.py          训练模块导入依赖
└─ model/best.pt                     PyTorch 权重
```

命令行入口读取 `.iq` 或 `.npy`，将输入整理为双通道 `(N,2,1024)`，校验类别顺序并加载 `model/best.pt`。推理结果保存到新建 `.npz`，字段包括 `prediction`、`labels`、`probabilities` 和 `classes`；可用 `--batch-size` 和 `--device cpu|cuda` 调整运行方式。

## FPAI_30T

```text
FPAI_30T/
├─ FPAI_30T.xpr                  Vivado 工程入口，顶层 rf_system_top
├─ FPAI_30T.srcs/                PS AI Block Design、IP 和 HDL 源
├─ rtl/                          产品 RTL
│  ├─ custom_op/                 FFT 与自定义运算
│  ├─ video/                     频谱界面与 HDMI
│  └─ platform/、top/             平台连接
├─ constraints/                  引脚、时序和 CDC
├─ vendor/fpai_demo/              AI Mate、DDR/时钟/FIFO 和 PS AI IP
├─ ps/
│  ├─ src/                        C++ 推理工作程序 `rf_worker`
│  ├─ include/                    寄存器、FFT、IQ 预处理头文件
│  ├─ system/                     采集、控制、处理、显示和会话服务
│  ├─ udp/                        RFCT/RFIQ 协议和 IQ 接收器
│  └─ CMakeLists.txt、toolchains/ 构建配置
├─ npu/v6/                        JSON/RAW 模型、标签和加载契约
├─ config/、protocol/、reference/ 运行配置、协议和 CPU FFT 参考
├─ program/                       FPGA 位流和 BOOT 配置
└─ tools/run_system.py            运行启动器
```

`rf_system_top` 在 FPGA 侧完成 IQ 接收、1024 点 FFT、功率谱、自定义运算和 720p HDMI。PS 端 `system/service.py` 负责 RFCT 控制、UDP IQ 接收、窗口调度、结果发布和显示提交；`src/rf_worker.cpp` 连接 iCraft Host/ZG330 后端进行推理及 FPGA 寄存器交互。模型输入约定为 FP32 `(1,2,1024)`，标签顺序由 `npu/v6/labels.json` 定义。

## 共享接口和数据关系

| 层次 | 主要接口或数据 | 使用工程 |
|---|---|---|
| 发射控制 | UART、RFCT 控制帧 | AD9361_Packer、RF_studio、FPAI_30T PS |
| 接收控制 | UDP 控制端口 `40001` | AD9361_Packer、RF_studio、FPAI_30T PS |
| IQ 传输 | UDP RFIQ，默认主机接收端口 `40000` | AD9361_Packer、RF_studio、FPAI_30T PS |
| 录制格式 | 小端 `int16` I/Q 交错 `.iq`、窗口索引 `.index.bin`、元数据 `.json` | AD9361_Packer host、RF_studio、py |
| 模型窗口 | 1 MSPS、1024 个复数点、双通道 FP32 | RF_studio、py、FPAI_30T |
| 网络基础组件 | Ethernet、ARP、IPv4、UDP、MAC/PHY、AXI Stream、PTP | AD9361_Packer/vendor/verilog-ethernet |
| ADI 参考代码 | 无操作系统驱动、硬件抽象和 AD9361 参考算法 | AD9361_Packer/vendor/no-os |

## 文档关系

根目录 `README.md` 用于快速了解整体定位和使用路径；本文件说明目录和模块关系。各子工程的 README 负责各自启动、硬件连接、运行命令和操作约束，各子工程的 `src.md` 负责模块级结构。`RF_studio/api_skill.md` 进一步定义本机 TCP 命令及返回判断，`RF_studio/model_test.md` 定义 ONNX 模型契约、实时识别和离线评估规则。

