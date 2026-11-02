# Python 离线调制识别

本目录提供 18 类调制信号的离线识别程序和配套 PyTorch 权重。程序读取 IQ 文件，按帧输出类别与概率。

## 环境

使用 Python 3.10 或更高版本，并安装运行依赖：

```powershell
python -m pip install "numpy>=1.26" "torch>=2.4"
```

## 运行

在本目录执行：

```powershell
python -B fullscale_18class_recognize.py input.iq --checkpoint model/best.pt --output predictions.npz
```

输入支持两种格式：

- `.iq`：小端 `int16`，I/Q 交错排列，每帧 1024 组 IQ 点。
- `.npy`：形状为 `(N,2,1024)`、`(N,1024,2)`，或复数数组 `(N,1024)`。

输入采样率为 1 MSPS。输出文件须使用尚不存在的 `.npz` 路径；其中包含 `prediction`、`labels`、`probabilities` 和 `classes`。可用 `--batch-size` 调整每批帧数，用 `--device cpu` 或 `--device cuda` 选择计算设备。

模块职责与依赖关系见 [src.md](src.md)。
