# 代码结构

```text
py/
├─ fullscale_18class_recognize.py   命令行识别入口
├─ fullscale_18class_config.py      类别顺序与权重校验
├─ signal_preprocess.py             IQ 输入形状转换与检查
├─ correlation_modulation_model.py  识别网络
├─ multiscale_modulation_model.py   多尺度网络模块
├─ modulation_model.py              基础网络模块
├─ fullscale_training.py            批量概率计算
├─ fullscale_dataset.py             概率计算模块的导入依赖
├─ targeted_augmentation.py         概率计算模块的导入依赖
├─ model/
│  └─ best.pt                        PyTorch 权重
├─ README.md                        使用说明
└─ src.md                           本文件
```

## 识别流程

`fullscale_18class_recognize.py` 解析输入文件和参数，通过 `signal_preprocess.py` 将 IQ 转成双通道数组；随后用 `fullscale_18class_config.py` 校验类别顺序，结合三个网络模块加载 `model/best.pt`。`fullscale_training.py` 提供分批归一化和概率计算，结果保存为 `.npz`。

`fullscale_dataset.py` 与 `targeted_augmentation.py` 是 `fullscale_training.py` 导入时需要的模块，因此随识别程序一同提供。
