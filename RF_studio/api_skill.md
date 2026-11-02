# Agent 控制台操作

Agent 通过本机 TCP 命令口操作运行中的 RF Studio。命令与鼠标操作使用相同的参数校验、界面锁定及设备会话，不需要额外连接板卡。

## 接入

软件运行后，在 GUI 控制台输入 `serve`，默认监听 `127.0.0.1:47100`。使用 `serve 端口` 指定端口，`serve off` 停止监听。也可以在启动时启用：

```powershell
Set-Location 'D:\e-project\IRFSA_release\RF_studio'
.\KU5P_Radio_Studio.exe --serve 47100
```

复用已经运行的界面。已有实例未启用端口时，在该实例内输入 `serve`。

```powershell
python -B ku5p_cmd.py help
python -B ku5p_cmd.py status
python -B ku5p_cmd.py "get mod center bw offset"
```

每个位置参数是一条完整命令，多词命令整体加引号。自定义端口使用 `--port`：

```powershell
python -B ku5p_cmd.py --port 47100 "get mod" status
```

## 通信与返回值

接口为 UTF-8 文本 TCP：每条请求以换行结束，回复由多行 `<level> <text>` 构成，以单独一行 `.` 结束。级别为 `info`、`ok`、`warning`、`error`。

```text
请求：get offset
回复：info offset = 0.15
      .
```

CLI 退出码：0 表示回复中没有 `error`，1 表示至少一个业务错误，2 表示连接或套接字错误。`warning` 不导致退出码 1。

Python 客户端：

```python
from ku5p_cmd import send

replies = send(["get mod center", "status"], port=47100, timeout=600)
for command, messages in replies:
    for level, text in messages:
        print(command, level, text)
```

同一次 `send()` 在遇到业务错误后仍会发送列表内后续命令。有依赖的操作应逐条调用并判断结果。

## 操作顺序与结果判断

1. 用 `help`、`get`、`status` 了解可用命令、当前草稿和板端缓存状态。
2. 在 GUI 设置 COM 口与本机 / 板端 IP，按需要执行 `connect uart`、`connect rx`。
3. 使用 `set` 修改草稿，执行 `check`，再执行 `upload`。
4. `upload` 后执行 `wait 90`，随后执行 `status refresh` → `wait 15` → `status`。
5. 核对实际参数、开关、上传提示及本次日志，再进入下一步。

`set` 成功表示草稿已改变。连接、上传、开关等返回“已提交”表示动作已入队。`wait` 返回 `ok idle` 仅表示界面已空闲，不保存上一次动作的成败。硬件操作结果以状态读回和日志为准。

`status` 返回缓存；`status refresh` 异步查询硬件。日志同时显示于界面和 `logs/YYYYMMDD.log`。

`wait` 不用于等待已开始的普通录制结束，普通录制应使用 `record wait`。单条 TCP 请求的等待上限为 600 秒，长批量任务通过 `train status` 分次查看。

## 命令

| 命令 | 用途 |
|---|---|
| `help` | 显示命令和参数名 |
| `get [名称…]` | 读取草稿，省略名称时读取全部公开参数 |
| `set 名称 值 [名称 值…]` | 修改草稿参数 |
| `check` | 检查 TX1 频带相对 RX 的位置 |
| `upload` | 上传已连接通道的参数 |
| `tx1 on\|off`、`tx2 on\|off` | 控制对应发射开关 |
| `monitor on\|off` | 开关 RX 观测 |
| `status [refresh]` | 查看状态，或提交状态刷新 |
| `wait [秒]` | TCP 等待界面空闲，默认 60 秒 |
| `connect uart\|rx\|demo` | 连接真实 UART、RX 或模拟 UART |
| `disconnect uart\|rx` | 断开对应通道 |
| `record start [秒] [文件名]` | 使用录制页目录及采样率开始普通录制 |
| `record stop` | 停止普通录制并收尾 |
| `record status` | 查看录制状态和最近结果 |
| `record wait [秒]` | 等待普通录制收尾，默认录制时长加 60 秒 |
| `train check` | 检查训练页当前批量任务 |
| `train start [-y]` | 开始或继续批量任务；`-y` 跳过总览确认，参数错误仍会拒绝 |
| `train pause` | 当前点结束后暂停 |
| `train stop` | 中止当前点并停止批量调度 |
| `train status` | 查询批量进度和任务文件 |
| `train load 文件`、`train save 文件` | 导入 / 导出批量任务 |
| `stop` | 请求关闭 TX1、TX2，并停止本软件 RX 会话 |
| `serve [端口]`、`serve off` | 开关本机命令服务 |

## 参数

界面与命令中的频率通常为 MHz；滤波频率参数为 kHz。增益、衰减及 SNR 为 dB。

| 参数 | 说明 |
|---|---|
| `mod` | AM-DSB-WC、AM-DSB-SC、AM-SSB-WC、AM-SSB-SC、FM、2/4/8/16ASK、2/4/8/16FSK、2/4/8/16PSK、16/64/256QAM |
| `center` | TX 本振，300～6000 MHz |
| `bw` | TX1 单边基带带宽 B，0.005～10 MHz |
| `offset` | 载波相对 TX 本振的频偏，−10～10 MHz；完整占用频带需落在可用范围内 |
| `snr`、`noise` | TX1 内部数字 SNR（−10～20 dB）及噪声开关 |
| `att1`、`att2` | 发射衰减，0～89.75 dB，步进 0.25 dB |
| `noise_low`、`noise_high` | TX2 相对本振的噪声频段边界，MHz |
| `seed` | 非零 u32 随机种子，支持十六进制 |
| `sideband` | `usb` / `lsb` |
| `carrier_ratio` | AM-SSB-WC 载波与所选边带功率比，−30～40 dB |
| `am_depth` | AM-DSB-WC 调制度，0＜μ≤1 |
| `follow` | RX 本振跟随 TX 本振，`on` / `off` |
| `rx_center` | 独立 RX 本振，300～6000 MHz；关闭跟随后生效 |
| `rx_bw` | RX 模拟带宽：0.2、0.5、1、2、5、10、15、20 MHz |
| `gain_mode` | `manual` / `slow` / `fast` |
| `gain` | 手动 RX 增益，整数 dB，允许范围随 RX 本振变化 |
| `rate` | `1` / `25`，单位 MSPS |
| `filter` | PC 端 RX 滤波开关，`on` / `off`，仅支持 1 MSPS |
| `filter_type` | `lpf` / `hpf` / `bpf` / `bsf` |
| `f1` | LPF/HPF 的有符号截止频率，或 BPF/BSF 下边沿，kHz |
| `f2` | BPF/BSF 上边沿，kHz，必须大于 `f1` |
| `ap`、`as`、`tw` | 通带纹波（dB）、阻带衰减（dB）、过渡带宽（kHz） |

布尔值还支持 `1/0`、`true/false`、`yes/no`。LPF 保留 `f≤f1`，HPF 保留 `f≥f1`，滤波频率相对 RX 本振。

`set` 的类型转换成功不代表参数组合可用，完整频带及范围校验还会在上传和采集时执行。修改滤波参数会立即校验；观测中修改可能重启观测。录制或训练期间参数锁定。

串口、IP、录制目录及训练段在 GUI 设置。当前 TCP 接口没有模型加载、模型推理、`capture start` 或 `train set` 命令。

## 示例

修改并上传参数，随后查询读回：

```powershell
python -B ku5p_cmd.py "set mod 4PSK bw 0.1 offset 0.15" check
python -B ku5p_cmd.py upload
python -B ku5p_cmd.py "wait 90"
python -B ku5p_cmd.py "status refresh" "wait 15" status
```

普通录制，需先在 GUI 设置目录并连接 RX：

```powershell
python -B ku5p_cmd.py "record start 3 sample_001"
python -B ku5p_cmd.py "record wait 90" "record status"
```

录制完成后核对元数据中的 `stop_confirmed`、窗口统计及错误信息。`ok record idle` 只表示当前已不处于录制流程。

导入并检查批量任务，路径使用带引号的正斜杠写法：

```powershell
python -B ku5p_cmd.py 'train load "D:/data/campaign.json"'
python -B ku5p_cmd.py "train check"
python -B ku5p_cmd.py "train start"
python -B ku5p_cmd.py "train status"
```

`train start` 会在 GUI 显示总览；自动开始已设置任务时使用 `train start -y`。

## 会话与停止

TX 控制固定使用 UART；RX 配置及 IQ 使用网口。GUI 运行时不要额外占用相同串口、UDP 40001 或 UDP 40000。

普通 `upload` 保留现有 TX 开关；RX 未观测时保存下一次启动参数，观测中上传会重启观测。只操作本软件拥有的 RX 会话。

停止发射使用 `stop`，等待后检查实际 TX 状态。`train stop`、断开 UART、关闭软件均不能作为 TX 已关闭的证明。
