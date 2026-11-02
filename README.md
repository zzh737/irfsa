# IRFSA 工程总述

IRFSA（射频信号智能分析仪）发布目录由射频硬件、桌面控制分析、离线识别和正式运行推理四部分组成。各部分围绕同一条数据链路协作：FPGA/AD9361 产生或采集 IQ 数据，控制与分析软件通过 UART、UDP 及 RFCT/RFIQ 协议管理设备并保存数据，识别模型对 1 MSPS、1024 点复数 IQ 窗口进行调制分类，正式运行工程再将采集、推理和显示整合到 FPGA、PS 与 ZG330 平台。

## 工程组成

| 工程 | 定位 | 主要内容 |
|---|---|---|
| `AD9361_Packer/` | KU5P + FMC AD9361 射频收发 FPGA 工程 | 纯 PL 射频收发、双路发射、接收采样、UART/UDP 控制、IQ 网络封装、Vivado 构建与下载文件 |
| `RF_studio/` | Windows 图形控制与分析软件 | TX/RX 参数控制、实时 IQ 观测、录制、训练批量采集、ONNX 实时识别和离线评估 |
| `py/` | Python 离线调制识别 | 使用 PyTorch 权重从 `.iq` 或 `.npy` 输入生成逐帧类别、概率和 `.npz` 结果 |
| `FPAI_30T/` | 正式运行与边缘推理工程 | FPGA 频谱处理与 HDMI 显示、PS 端采集服务、C++ 推理工作程序、ZG330 模型及运行配置 |

## 端到端数据链路

1. `AD9361_Packer` 在 KU5P FPGA 内完成 AD9361 初始化、频率规划、调制波形生成、接收 LVDS 数据装配及可选 FIR 抽取。
2. TX 参数通过 UART 的 RFCT 控制帧下发；RX 配置通过 UDP 控制端口下发；IQ 数据以 RFIQ 数据帧经 UDP 发送到主机。默认控制端口为 `40001`，IQ 接收端口为 `40000`，主机和板端默认地址分别为 `192.168.10.1` 与 `192.168.10.2`。
3. `RF_studio` 复用上述控制和数据协议，提供设备连接、参数检查、发射控制、RX 观测、普通录制和训练采集。录制由 `.iq`、`.index.bin`、`.json` 三件套组成，并保存采样配置、标签、窗口索引、CRC 和结束状态。
4. 识别可在 `RF_studio` 中通过 ONNX Runtime 实时执行或对训练目录离线评估，也可在 `py` 中使用 PyTorch 权重独立离线识别。两类识别均以 1 MSPS、每窗 1024 个复数 IQ 点为主要约定，按每窗 RMS 归一化且不去均值。
5. `FPAI_30T` 面向正式运行板卡：FPGA 侧完成 IQ 接收、1024 点 FFT、功率谱和 720p HDMI 显示；PS 服务负责 RFCT/RFIQ、窗口调度、结果发布和显示提交；`rf_worker` 连接 iCraft Host/ZG330 后端完成推理及寄存器交互。

## 射频与识别能力

桌面软件和 FPGA 工程支持 AM、FM、ASK、FSK、PSK 及 QAM 等调制控制。TX1 支持 AM 双边带/单边带、带载波/抑制载波，以及 2/4/8/16 阶 ASK、FSK、PSK 和 16/64/256QAM；TX2 提供带限噪声。TX 本振范围为 300 MHz～6 GHz，TX1 基带带宽为 0.005～10 MHz，发射衰减为 0～89.75 dB、步进 0.25 dB。RX 支持多档模拟带宽、手动或自动增益，以及 1 MSPS 和 25 MSPS 输出；PC 端滤波器仅适用于 1 MSPS。

随附桌面 ONNX 模型和 Python 模型均覆盖 18 类：`16ASK`、`16FSK`、`16QAM`、`2ASK`、`2FSK`、`2PSK`、`4ASK`、`4FSK`、`4PSK`、`64QAM`、`8ASK`、`8FSK`、`8PSK`、`AM-DSB-SC`、`AM-DSB-WC`、`AM-SSB-SC`、`AM-SSB-WC`、`FM`。桌面随附模型不包含 16PSK 和 256QAM；它是闭集分类器，输出概率需要结合采集条件、标签和有效窗口质量理解。

## 常用工作方式

### 设备控制、观测和录制

可直接运行 `RF_studio/KU5P_Radio_Studio.exe` 或 `Start_KU5P.bat`。源码运行需要 Python 3.10+、Tkinter、NumPy 和 ONNX Runtime。连接 UART 后配置 TX，连接网口 RX 后配置接收、观测或录制。需要脚本控制时，在 GUI 控制台输入 `serve`，默认开启 `127.0.0.1:47100` 的本机 TCP 命令服务，再用 `RF_studio/ku5p_cmd.py` 执行 `get`、`set`、`check`、`upload`、`status`、`record` 和 `train` 等命令。

### 离线识别

`py` 目录可执行：

```powershell
python -B fullscale_18class_recognize.py input.iq --checkpoint model/best.pt --output predictions.npz
```

输入支持小端 `int16` I/Q 交错 `.iq`，以及形状为 `(N,2,1024)`、`(N,1024,2)` 或 `(N,1024)` 复数数组的 `.npy`。输出 `.npz` 含 `prediction`、`labels`、`probabilities` 和 `classes`。

### 正式运行

`FPAI_30T` 的入口包括 Vivado 工程 `FPAI_30T.xpr`、FPGA 位流 `program/system.bit`、启动配置 `config/system_v6_hw23.json`、ZG330 模型 `npu/v6/model.json` 与 `model.raw`，以及 `tools/run_system.py`。目标板准备好 iCraft 运行库和 ARM64 依赖后，在 `ps/` 构建 `rf_worker`，再由启动器加载配置运行服务。

## 资料与文档入口

| 文档 | 内容 |
|---|---|
| [src.md](src.md) | 根目录工程结构、模块职责、数据流和文档关系 |
| [AD9361_Packer/README.md](AD9361_Packer/README.md) | FPGA 下载、硬件连接、发射接收和协议客户端 |
| [AD9361_Packer/src.md](AD9361_Packer/src.md) | RTL、构建脚本、协议和参考代码结构 |
| [RF_studio/README.md](RF_studio/README.md) | 图形软件启动、连接、录制和模型测试 |
| [RF_studio/src.md](RF_studio/src.md) | GUI、后台工作线程、分析和构建结构 |
| [RF_studio/api_skill.md](RF_studio/api_skill.md) | 本机 TCP 控制命令及结果判断 |
| [RF_studio/model_test.md](RF_studio/model_test.md) | ONNX 模型契约、实时识别和离线评估 |
| [py/README.md](py/README.md) | Python 离线识别用法 |
| [py/src.md](py/src.md) | Python 识别模块关系 |
| [FPAI_30T/README.md](FPAI_30T/README.md) | 正式运行工程入口和运行链路 |
| [FPAI_30T/src.md](FPAI_30T/src.md) | FPGA、PS、协议、模型和配置目录 |

`AD9361_Packer/AD9361_Packer/vendor/` 中还随附 `verilog-ethernet` 和 Analog Devices `no-OS` 参考代码。前者提供 Ethernet、ARP、IPv4、UDP、MAC/PHY、AXI Stream 和 PTP 组件；后者提供面向无操作系统环境的 ADI 驱动、硬件抽象层和参考项目框架。

