# FPAI_30T

射频信号智能分析仪正式运行工程，包含当前 FPGA 设计、PS 端服务、ZG330 推理模型和运行所需资源。

## 入口

- Vivado 工程：`FPAI_30T.xpr`
- FPGA 位流：`program/system.bit`
- BOOT 配置：`program/system.bif`
- 设备配置：`config/system_v6_hw23.json`
- 当前模型：`npu/v6/model.json`、`npu/v6/model.raw`
- 运行启动器：`tools/run_system.py`
- PS 工作程序源码：`ps/src/rf_worker.cpp`

## 运行链路

FPGA 顶层 `rf_system_top` 完成 IQ 接收、1024 点 FFT 功率谱、自定义运算和 720p HDMI 显示。PS 端 `ps/system/service.py` 负责 RFCT 控制、UDP IQ 接收、窗口调度、结果发布和显示提交；`ps/src/rf_worker.cpp` 连接 iCraft Host/ZG330 后端执行推理及 FPGA 寄存器交互。模型输入为 FP32、形状 `(1, 2, 1024)`，标签顺序见 `npu/v6/labels.json`。

目标板安装随附的 iCraft 运行库和 ARM64 依赖后，在 `ps/` 使用 CMake 构建 `rf_worker`，再用 `tools/run_system.py --config config/system_v6_hw23.json --worker <rf_worker>` 启动服务。
