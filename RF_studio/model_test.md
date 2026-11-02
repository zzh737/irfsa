# 模型接入与测试

模型测试支持 RX1 实时识别和录制目录离线评估。模型页本身不发送硬件控制命令。

## 随附模型

模型文件为 `model/fullscale_v6_18class.onnx`，配套文件为 `model/fullscale_v6_18class.model.json`。

| 项目 | 要求 |
|---|---|
| 采样率 | 1,000,000 Hz |
| 单窗长度 | 1024 个复数 IQ 点 |
| 输入 | `iq`，float32，形状 `(N, 2, 1024)` |
| 输出 | `logits`，float32，形状 `(N, 18)` |
| 归一化 | 每窗 RMS 归一化，不去均值 |
| 多帧融合 | 连续窗口的 logits 取平均 |

支持类别：

```text
16ASK, 16FSK, 16QAM, 2ASK, 2FSK, 2PSK,
4ASK, 4FSK, 4PSK, 64QAM, 8ASK, 8FSK, 8PSK,
AM-DSB-SC, AM-DSB-WC, AM-SSB-SC, AM-SSB-WC, FM
```

模型不包含 16PSK 和 256QAM。该模型为闭集分类器，输入其他调制时仍可能给出上述类别中的结果。显示概率不能作为信号类别存在的独立证明。

## 接入模型文件

将 `<name>.onnx` 和同名 `<name>.model.json` 放入程序旁的 `model` 目录，在模型测试页点击“刷新”并选择模型。也可以使用“其他位置…”选择其他目录的模型。

模型说明采用 `KU5P_IQ_MODEL_1` 契约，主要字段如下：

| 字段 | 说明 |
|---|---|
| `schema` | `KU5P_IQ_MODEL_1` |
| `onnx_file` | 相对模型说明文件目录的 ONNX 文件名 |
| `classes` | 输出列对应的类别名称，顺序必须一致 |
| `fs_hz` | 输入采样率，Hz |
| `window_points` | 每窗复数 IQ 点数 |
| `normalization` | `per_window_rms_no_dc` |
| `output_kind` | `logits`；也支持 `probabilities`，融合前转换为对数值 |
| `input_name` / `output_name` | ONNX 输入 / 输出名称 |
| `onnx_sha256` | 用于核对模型文件完整性的 SHA-256 |
| `fixture_only` | 是否仅用于接口演示 |

输入形状为 `(N, 2, L)`，其中 `L` 与 `window_points` 相同，第 0 通道为 I，第 1 通道为 Q。输出列数与 `classes` 长度相同。推理使用 ONNX Runtime 的 CPU 执行器。

预处理将小端 int16 交错 IQ 转为 float32，按下式逐窗归一化：

```text
rms = sqrt(mean(I² 和 Q² 的全部 2L 个实数))
I_normalized = I / rms
Q_normalized = Q / rms
```

不减均值，不执行额外的频偏校正；全零窗口跳过。推理输入采样率必须与模型说明一致。

## 实时识别

1. 在模型测试页选择并加载模型。
2. 连接 RX，输出采样率选择 1 MSPS，开启 RX1 同窗观测。
3. 勾选“开启实时识别”，选择融合帧数。
4. 查看融合判决、Top-5 概率与连续窗口结果。

实时任务约每 0.25 秒提交一次。融合使用最新的连续窗口；实际可用窗口不足时，融合帧数按现有窗口数缩减。

板端 TX1 开启且标签在模型类别内时，界面可将识别结果与 TX1 配置读回对比。标签描述发射配置，不是对接收信号的独立认证。TX1 关闭时只显示识别结果。

## 离线评估

在模型测试页选择训练采集目录，点击“开始评估”。目录中每份录制需包含同名 `.json`、`.iq` 和 `.index.bin`。

评估使用元数据中的标签和采样率，核对索引与 IQ 的 CRC，并排除以下窗口：

- `flags` 低三位中有置位的窗口。
- 全零窗口。
- ADC 轨值比例超过 1% 的窗口，轨值条件为 `≤−2048` 或 `≥2047`。

采样率不匹配、标签不在类别中、文件缺失或 CRC 错误的录制会跳过并记录原因。长窗模型只能使用采样位置与窗口编号连续的数据拼接，遇到缺口丢弃尚未拼满的窗口。

按连续 1、2、4、8 帧分别统计准确率与混淆矩阵；融合不跨录制文件，不跨窗口缺口。没有足够有效窗口时，对应准确率为 `null`。

GUI 报告保存在 `reports/model_tests`，包含模型信息、类别顺序、有效分组数、各帧数准确率、混淆矩阵、逐文件结果和跳过原因。混淆矩阵行表示真实标签，列表示预测类别。

演示录制会在结果中标明 `simulated`。离线评估不会自动把所有演示数据移出目录，实采评估时应选择只包含目标实采数据的目录。

## Python 接口

在程序目录中执行，加载模型并评估指定目录：

```python
import json
from pathlib import Path
from model_eval import IQModel, evaluate_directory

model_path = Path("model/fullscale_v6_18class.onnx")
model = IQModel(model_path)
print(model.describe())

report = evaluate_directory(model_path, Path("captures/training"))
output = Path("reports/model_tests/manual.json")
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
```

对内存中的 IQ 块推理：

```python
from model_eval import IQModel, classify_block

model = IQModel("model/fullscale_v6_18class.onnx")
# raw_iq 为小端 int16 的 I、Q 交错字节，至少包含一个完整模型窗口。
result = classify_block(model, raw_iq, fs=1_000_000, frames=4)
print(result)
```

`IQModel.windows()` 返回归一化窗口及有效窗口掩码；`IQModel.logits()` 返回每窗输出。`classify_block()` 的 `frames` 控制最新窗口融合数量，`label` 可选，用于已知配置标签的比较。

## 常见问题

| 提示或现象 | 处理方式 |
|---|---|
| 找不到模型 | 确认 `.onnx` 与同名 `.model.json` 配套，点击“刷新” |
| ONNX 加载失败 | 核对 `onnx_file`、文件完整性及 ONNX Runtime 环境 |
| 输入形状不符 | 核对 ONNX 形状 `(N,2,L)` 与说明中的窗长 |
| 采样率不符 | 将 RX 或待评估数据采样率与模型要求保持一致 |
| 没有有效窗口 | 查看 IQ 是否全零、长度是否足够、接收是否连续 |
| 标签不在类别中 | 使用覆盖该标签的模型，或选择对应类别的数据 |
| CRC 错误 | 确认录制三件套完整且属于同一次录制 |
| 高融合帧数无结果 | 增加连续数据长度，减少窗口丢失，或降低融合帧数 |

TX1 内部 SNR 是发射参数，不等于接收端 SNR / SINR。评估结果应结合采集配置、数据来源及类别覆盖范围理解。
