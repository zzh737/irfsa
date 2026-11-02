# 代码结构

## 目录

```text
RF_studio/
├─ KU5P_Radio_Studio.exe     Windows 图形程序
├─ Start_KU5P.bat            启动入口
├─ app.py                    GUI 主入口与界面状态管理
├─ backend.py                硬件工作线程、观测与录制
├─ radio_links.py            UART / RX 通道与串口枚举
├─ command_interface.py      控制台命令与本机 TCP 服务
├─ ku5p_cmd.py               TCP 命令客户端
├─ console.py                日志显示、命令输入与提示
├─ controls.py               开关与上传按钮
├─ ui_parameters.py          参数定义、类型转换与校验
├─ band_check.py             发射频带与接收频带检查
├─ training_capture.py       训练标签、配置快照与采集约束
├─ training_campaign.py      批量任务、参数组合与任务检查
├─ campaign_view.py          批量采集编辑与执行
├─ analysis_view.py          IQ、星座、频谱与瀑布图界面
├─ analysis_workers.py       分析子进程与任务调度
├─ dsp_analysis.py           频谱、PSD 与星座同步计算
├─ rx_filter.py              PC 端复基带 FIR 滤波器
├─ signal_view.py            波形与频谱绘制组件
├─ demo_signal.py            离线演示信号源
├─ model_view.py             模型选择、识别与评估界面
├─ model_eval.py             ONNX 推理、预处理与文件评估
├─ theme.py                  界面配色与样式
├─ exe_selftest.py           命令行演示自检入口
├─ build_exe.py              PyInstaller 构建入口
├─ core/
│  ├─ ku5p.py                协议客户端、编号与录制器
│  ├─ rf_protocol.py         RFCT / RFIQ 编解码及数据结构
│  └─ waveform_config.py     调制参数规划与配置字生成
├─ vendor/                  随附串口依赖
├─ assets/                  界面图标
├─ model/                   ONNX 模型与配套说明
├─ README.md                软件使用说明
├─ src.md                   代码结构说明
├─ api_skill.md             Agent 控制台接口说明
└─ model_test.md            模型接入与测试说明
```

## 控制路径

鼠标操作和控制台命令共用 `Application` 的参数、校验、锁定及异步动作处理。`CommandInterface.execute()` 在 Tk 主线程中分发命令，硬件工作通过 `RadioWorker` 执行，结果以事件返回界面。

`radio_links.py` 将发射与接收控制拆分为独立通道：

| 通道 | 实现 | 用途 |
|---|---|---|
| UART | `UARTClient` | TX 参数、发射开关与 TX 状态读回 |
| UDP 控制 | `RXClient` | RX 配置、启停及状态 |
| 通道组合 | `SplitClient` | 向上提供统一访问入口 |
| IQ 接收 | `backend.py`、`core/ku5p.py` | 报文校验、窗口重组与录制 |

`core/waveform_config.py` 使用 Hz、dB 等物理量生成配置字；界面的 MHz 参数在进入底层前转换。修改草稿与上传硬件参数是独立动作。

## 数据路径

IQ 报文经过来源、会话、元数据与 CRC 校验后重组成窗口，再供观测、录制和模型分析使用。PC 滤波器开启时参与观测及录制数据处理。

图形分析通过 `AnalysisPool` 将频谱和星座任务分配给后台进程。模型界面通过独立工作进程执行 ONNX 推理，避免在 Tk 主线程中执行耗时计算。

普通录制保存 IQ、索引及元数据；训练录制增加板端 TX1 配置标签和配置一致性信息。批量采集由 `campaign_view.py` 调度，每一点使用已有的参数上传与训练采集路径。

## 常用接口定位

| 接口 | 用途 |
|---|---|
| `Application` | 图形界面与操作状态管理 |
| `CommandInterface.execute(line)` | 在 GUI 主线程中执行控制台命令 |
| `ku5p_cmd.send(commands, port, timeout)` | 通过本机 TCP 控制已运行界面 |
| `RadioWorker.submit()` / `events` | 异步提交硬件工作与接收事件 |
| `backend.waveform(values)` | 将界面参数转换为经过规划校验的波形配置 |
| `backend.recording_options(...)` | 校验录制路径、文件名、时长与采样率 |
| `model_eval.IQModel` | 加载模型及执行预处理与推理 |
| `model_eval.classify_block(...)` | 对连续 IQ 块执行识别与融合 |
| `model_eval.evaluate_directory(...)` | 对录制目录生成评估结果 |

GUI 正在使用设备时，外部程序通过 TCP 命令口接入，避免另外打开同一串口或占用相同 UDP 端口。

## 运行文件位置

源码运行时，数据根目录为 `app.py` 所在目录；EXE 运行时为可执行文件所在目录。

| 路径 | 用途 |
|---|---|
| `settings.json` | 界面参数与目录设置 |
| `state/request_ids.sqlite` | 请求、配置及采集编号 |
| `captures/` | 默认普通录制目录 |
| `captures/training/` | 默认训练采集目录 |
| `logs/YYYYMMDD.log` | 操作日志 |
| `reports/model_tests/` | 模型评估报告 |

## 构建

在具备 Python、Tkinter、NumPy 和 ONNX Runtime 的 Windows 环境中执行：

```powershell
Set-Location 'D:\e-project\IRFSA_release\RF_studio'
python -m pip install numpy onnxruntime
python -m pip install --target .build_deps pyinstaller
python -B build_exe.py --dist-dir .\dist
```

构建输出为 `dist/KU5P_Radio_Studio.exe`。部署时将 `model` 目录放在 EXE 旁，模型的 `.onnx` 和 `.model.json` 保持配套。
