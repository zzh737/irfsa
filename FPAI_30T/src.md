# 源代码结构

- `FPAI_30T.xpr`：Vivado 工程入口，产品顶层为 `rf_system_top`。
- `FPAI_30T.srcs/`：当前 PS AI Block Design、IP 配置、硬件交接文件及 HDL 源。
- `rtl/`：产品 RTL；`custom_op` 为 FFT 与自定义运算，`video` 为频谱界面与 HDMI，`platform` 和 `top` 为平台连接。
- `constraints/`：引脚、时序、CDC 约束。
- `vendor/fpai_demo/`：当前设计引用的 AI Mate、DDR/时钟/FIFO IP 以及 PS AI IP 仓库。
- `ps/src/`：PS 端 C++ 推理工作程序。
- `ps/include/`：寄存器、FFT、IQ 预处理头文件。
- `ps/system/`：采集服务、控制、处理、显示和会话管理。
- `ps/udp/`：RFCT/RFIQ 协议和 IQ 接收器。
- `ps/CMakeLists.txt`、`ps/toolchains/`：工作程序构建配置。
- `npu/v6/`：当前 JSON/RAW 模型、标签、预处理和加载契约。
- `config/`：设备运行配置；`protocol/`：通信协议定义；`reference/`：CPU FFT 参考实现。
- `program/`：FPGA 位流和 BOOT 配置。
