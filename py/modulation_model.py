"""Residual CNNs for two-channel IQ modulation recognition."""

from __future__ import annotations

import math

try:
    import torch
    from torch import nn
except ImportError:  # Keep data-only workflows usable without PyTorch.
    torch = None
    nn = None


def _require_torch() -> None:
    if torch is None or nn is None:
        raise ImportError("model training requires PyTorch; install the training extra")


if nn is not None:

    class ResidualBlock(nn.Module):
        # 残差分支学习 F(x)，直连分支保留 x；两者形状一致才能逐元素相加。
        def __init__(self, channels: int) -> None:
            super().__init__()
            self.layers = nn.Sequential(
                nn.Conv2d(channels, channels, kernel_size=(1, 5), padding=(0, 2), bias=False),
                nn.BatchNorm2d(channels),
                nn.ReLU(inplace=True),
                nn.Conv2d(channels, channels, kernel_size=(1, 5), padding=(0, 2), bias=False),
                nn.BatchNorm2d(channels),
            )
            self.activation = nn.ReLU(inplace=True)

        def forward(self, inputs):
            # y=ReLU(x+F(x))，让网络可在保留已有特征的基础上学习修正。
            return self.activation(inputs + self.layers(inputs))


    class MultiScaleResidualBlock(nn.Module):
        """Additive short/long temporal branches without concatenation."""

        def __init__(self, channels: int) -> None:
            super().__init__()
            self.short_path = nn.Sequential(
                nn.Conv2d(channels, channels, kernel_size=(1, 3), padding=(0, 1), bias=False),
                nn.BatchNorm2d(channels),
                nn.ReLU(inplace=True),
                nn.Conv2d(channels, channels, kernel_size=(1, 3), padding=(0, 1), bias=False),
                nn.BatchNorm2d(channels),
            )
            self.long_path = nn.Sequential(
                nn.Conv2d(channels, channels, kernel_size=(1, 9), padding=(0, 4), bias=False),
                nn.BatchNorm2d(channels),
            )
            self.activation = nn.ReLU(inplace=True)

        def forward(self, inputs):
            return self.activation(inputs + self.short_path(inputs) + self.long_path(inputs))


    class LegacyIQResidualCNN(nn.Module):
        """Original baseline kept for controlled ablation experiments."""

        # 历史对照：I/Q 放在空间高度上，高度为 1 的卷积核不能直接联合两者。

        def __init__(self, num_classes: int, dropout: float = 0.2) -> None:
            super().__init__()
            if num_classes <= 0:
                raise ValueError("num_classes must be positive")
            self.features = nn.Sequential(
                nn.Conv2d(1, 32, kernel_size=(1, 7), padding=(0, 3), bias=False),
                nn.BatchNorm2d(32),
                nn.ReLU(inplace=True),
                nn.MaxPool2d(kernel_size=(1, 2)),
                ResidualBlock(32),
                nn.Conv2d(32, 64, kernel_size=(1, 5), padding=(0, 2), bias=False),
                nn.BatchNorm2d(64),
                nn.ReLU(inplace=True),
                nn.MaxPool2d(kernel_size=(1, 2)),
                ResidualBlock(64),
                nn.Conv2d(64, 128, kernel_size=(1, 5), padding=(0, 2), bias=False),
                nn.BatchNorm2d(128),
                nn.ReLU(inplace=True),
                nn.AdaptiveAvgPool2d((1, 1)),
            )
            self.classifier = nn.Sequential(
                nn.Flatten(),
                nn.Dropout(dropout),
                nn.Linear(128, num_classes),
            )

        def forward(self, inputs):
            if inputs.ndim == 3:
                inputs = inputs.unsqueeze(1)
            if inputs.ndim != 4 or inputs.shape[1] != 1 or inputs.shape[2] != 2:
                raise ValueError("model input must have shape (N, 2, L)")
            return self.classifier(self.features(inputs))


    class ChannelIQBaselineCNN(nn.Module):
        """Original network depth with corrected I/Q channel placement."""

        # 当前推荐的 channel 架构：I/Q 是输入通道，首层卷积直接联合两路信息。
        # 后续卷积沿时间提取局部波形特征，池化压缩时间长度，残差块继续加工特征。

        def __init__(self, num_classes: int, dropout: float = 0.2) -> None:
            super().__init__()
            if num_classes <= 0:
                raise ValueError("num_classes must be positive")
            self.features = nn.Sequential(
                nn.Conv2d(2, 32, kernel_size=(1, 7), padding=(0, 3), bias=False),
                nn.BatchNorm2d(32),
                nn.ReLU(inplace=True),
                nn.MaxPool2d(kernel_size=(1, 2)),
                ResidualBlock(32),
                nn.Conv2d(32, 64, kernel_size=(1, 5), padding=(0, 2), bias=False),
                nn.BatchNorm2d(64),
                nn.ReLU(inplace=True),
                nn.MaxPool2d(kernel_size=(1, 2)),
                ResidualBlock(64),
                nn.Conv2d(64, 128, kernel_size=(1, 5), padding=(0, 2), bias=False),
                nn.BatchNorm2d(128),
                nn.ReLU(inplace=True),
                nn.AdaptiveAvgPool2d((1, 1)),
            )
            self.classifier = nn.Sequential(
                nn.Flatten(),
                nn.Dropout(dropout),
                nn.Linear(128, num_classes),
            )

        def forward(self, inputs):
            if inputs.ndim != 3 or inputs.shape[1] != 2:
                raise ValueError("model input must have shape (N, 2, L)")
            # (N,2,L) -> (N,2,1,L)，满足 Conv2d 的 NCHW 输入约定。
            # L=1024 时，两次池化后长度为 256；全局平均池化得到 128 个特征。
            # 输出 (N,num_classes) 的原始分数 logits；交叉熵内部会处理 softmax。
            return self.classifier(self.features(inputs.unsqueeze(2)))


    class IQResidualCNN(nn.Module):
        """NPU-friendly CNN that treats I and Q as convolution channels."""

        # 更深的 v2 实验架构；当前推荐权重对应上面的 ChannelIQBaselineCNN。

        DOWNSAMPLE_FACTOR = 32

        def __init__(
            self,
            num_classes: int,
            dropout: float = 0.2,
            sample_length: int = 1024,
            num_families: int = 0,
        ) -> None:
            super().__init__()
            if num_classes <= 0:
                raise ValueError("num_classes must be positive")
            if sample_length <= 0 or sample_length % self.DOWNSAMPLE_FACTOR != 0:
                raise ValueError(
                    f"sample_length must be a positive multiple of {self.DOWNSAMPLE_FACTOR}"
                )
            self.sample_length = sample_length
            pooled_length = sample_length // self.DOWNSAMPLE_FACTOR
            self.features = nn.Sequential(
                nn.Conv2d(2, 32, kernel_size=(1, 7), padding=(0, 3), bias=False),
                nn.BatchNorm2d(32),
                nn.ReLU(inplace=True),
                ResidualBlock(32),
                ResidualBlock(32),
                nn.MaxPool2d(kernel_size=(1, 2)),
                nn.Conv2d(32, 64, kernel_size=(1, 5), padding=(0, 2), bias=False),
                nn.BatchNorm2d(64),
                nn.ReLU(inplace=True),
                ResidualBlock(64),
                ResidualBlock(64),
                nn.MaxPool2d(kernel_size=(1, 2)),
                nn.Conv2d(64, 128, kernel_size=(1, 5), padding=(0, 2), bias=False),
                nn.BatchNorm2d(128),
                nn.ReLU(inplace=True),
                ResidualBlock(128),
                nn.MaxPool2d(kernel_size=(1, 2)),
                nn.MaxPool2d(kernel_size=(1, 2)),
                nn.MaxPool2d(kernel_size=(1, 2)),
                nn.AvgPool2d(kernel_size=(1, pooled_length)),
            )
            self.classifier = nn.Sequential(
                nn.Flatten(),
                nn.Dropout(dropout),
                nn.Linear(128, num_classes),
            )
            self.family_classifier = None
            if num_families > 0:
                self.family_classifier = nn.Sequential(
                    nn.Flatten(),
                    nn.Dropout(dropout),
                    nn.Linear(128, num_families),
                )

        def forward_features(self, inputs):
            if inputs.ndim != 3 or inputs.shape[1] != 2:
                raise ValueError("model input must have shape (N, 2, L)")
            if inputs.shape[2] != self.sample_length:
                raise ValueError(
                    f"model input length must be {self.sample_length}, got {inputs.shape[2]}"
                )
            # Conv2d expects NCHW. I and Q are channels, while the spatial
            # height stays at one so every convolution mixes both components.
            return self.features(inputs.unsqueeze(2))

        def forward(self, inputs, return_auxiliary: bool = False):
            features = self.forward_features(inputs)
            logits = self.classifier(features)
            if return_auxiliary:
                if self.family_classifier is None:
                    raise RuntimeError("this model was built without an auxiliary family head")
                return logits, self.family_classifier(features)
            return logits


    class RobustIQNet(nn.Module):
        """Multi-scale residual CNN for low-SNR and impaired IQ signals."""

        DOWNSAMPLE_FACTOR = 16

        def __init__(
            self,
            num_classes: int,
            dropout: float = 0.2,
            sample_length: int = 1024,
            num_impairment_targets: int = 0,
        ) -> None:
            super().__init__()
            if num_classes <= 0:
                raise ValueError("num_classes must be positive")
            if sample_length <= 0 or sample_length % self.DOWNSAMPLE_FACTOR != 0:
                raise ValueError(
                    f"sample_length must be a positive multiple of {self.DOWNSAMPLE_FACTOR}"
                )
            self.sample_length = sample_length
            pooled_length = sample_length // self.DOWNSAMPLE_FACTOR
            self.stem = nn.Sequential(
                nn.Conv2d(2, 32, kernel_size=(1, 7), padding=(0, 3), bias=False),
                nn.BatchNorm2d(32),
                nn.ReLU(inplace=True),
            )
            self.stage1 = nn.Sequential(
                MultiScaleResidualBlock(32),
                MultiScaleResidualBlock(32),
                nn.MaxPool2d(kernel_size=(1, 2)),
            )
            self.transition1 = nn.Sequential(
                nn.Conv2d(32, 64, kernel_size=(1, 1), bias=False),
                nn.BatchNorm2d(64),
                nn.ReLU(inplace=True),
            )
            self.stage2 = nn.Sequential(
                MultiScaleResidualBlock(64),
                MultiScaleResidualBlock(64),
                nn.MaxPool2d(kernel_size=(1, 2)),
            )
            self.transition2 = nn.Sequential(
                nn.Conv2d(64, 128, kernel_size=(1, 1), bias=False),
                nn.BatchNorm2d(128),
                nn.ReLU(inplace=True),
            )
            self.stage3 = nn.Sequential(
                MultiScaleResidualBlock(128),
                nn.MaxPool2d(kernel_size=(1, 2)),
                nn.MaxPool2d(kernel_size=(1, 2)),
                nn.AvgPool2d(kernel_size=(1, pooled_length)),
            )
            self.classifier = nn.Sequential(
                nn.Flatten(),
                nn.Dropout(dropout),
                nn.Linear(128, num_classes),
            )
            self.impairment_head = None
            if num_impairment_targets > 0:
                self.impairment_head = nn.Sequential(
                    nn.Flatten(),
                    nn.Linear(128, num_impairment_targets),
                )

        def forward_features(self, inputs):
            if inputs.ndim != 3 or inputs.shape[1] != 2:
                raise ValueError("model input must have shape (N, 2, L)")
            if inputs.shape[2] != self.sample_length:
                raise ValueError(
                    f"model input length must be {self.sample_length}, got {inputs.shape[2]}"
                )
            features = self.stem(inputs.unsqueeze(2))
            features = self.stage1(features)
            features = self.transition1(features)
            features = self.stage2(features)
            features = self.transition2(features)
            return self.stage3(features)

        def forward(self, inputs, return_auxiliary: bool = False):
            features = self.forward_features(inputs)
            logits = self.classifier(features)
            if return_auxiliary:
                if self.impairment_head is None:
                    raise RuntimeError("this model was built without an impairment head")
                return logits, self.impairment_head(features)
            return logits


    class SpectralFilterBank(nn.Module):
        """Fixed complex matched filters followed by a small classifier.

        Each frequency has real and imaginary filters, plus their negatives.
        ReLU on the four responses preserves both signs without square, sqrt,
        FFT, or other operators outside the known image-model operator set.
        """

        def __init__(
            self,
            num_classes: int,
            dropout: float = 0.2,
            sample_length: int = 1024,
            num_frequencies: int = 16,
            filter_length: int = 33,
            output_bins: int = 8,
            trainable_filters: bool = False,
        ) -> None:
            super().__init__()
            if num_classes <= 0:
                raise ValueError("num_classes must be positive")
            if num_frequencies <= 0 or filter_length <= 1 or filter_length % 2 == 0:
                raise ValueError("frequency count must be positive and filter length odd")
            if sample_length <= 0 or output_bins <= 0 or sample_length % output_bins:
                raise ValueError("sample_length must be divisible by output_bins")
            self.sample_length = sample_length
            self.analysis = nn.Conv2d(
                2, 4 * num_frequencies, kernel_size=(1, filter_length),
                padding=(0, filter_length // 2), bias=False,
            )
            self._initialize_filters(num_frequencies, filter_length)
            self.analysis.weight.requires_grad_(trainable_filters)
            self.rectifier = nn.ReLU()
            self.temporal_pool = nn.AvgPool2d(kernel_size=(1, sample_length // output_bins))
            self.classifier = nn.Sequential(
                nn.Flatten(),
                nn.Linear(4 * num_frequencies * output_bins, 128),
                nn.ReLU(),
                nn.Dropout(dropout),
                nn.Linear(128, num_classes),
            )

        def _initialize_filters(self, count: int, length: int) -> None:
            tap = torch.arange(length, dtype=torch.float32) - (length - 1) / 2
            window = torch.hann_window(length, periodic=False)
            frequencies = torch.linspace(-0.45, 0.45, count)
            with torch.no_grad():
                for index, frequency in enumerate(frequencies):
                    cosine = window * torch.cos(2 * math.pi * frequency * tap)
                    sine = window * torch.sin(2 * math.pi * frequency * tap)
                    scale = torch.sqrt(2 * (cosine.square() + sine.square()).sum())
                    cosine, sine = cosine / scale, sine / scale
                    # Real and imaginary parts of IQ * exp(-j omega t).
                    self.analysis.weight[4 * index, 0, 0] = cosine
                    self.analysis.weight[4 * index, 1, 0] = sine
                    self.analysis.weight[4 * index + 1, 0, 0] = -cosine
                    self.analysis.weight[4 * index + 1, 1, 0] = -sine
                    self.analysis.weight[4 * index + 2, 0, 0] = -sine
                    self.analysis.weight[4 * index + 2, 1, 0] = cosine
                    self.analysis.weight[4 * index + 3, 0, 0] = sine
                    self.analysis.weight[4 * index + 3, 1, 0] = -cosine

        def forward(self, inputs):
            if inputs.ndim != 3 or inputs.shape[1] != 2:
                raise ValueError("model input must have shape (N, 2, L)")
            if inputs.shape[2] != self.sample_length:
                raise ValueError(
                    f"model input length must be {self.sample_length}, got {inputs.shape[2]}"
                )
            responses = self.rectifier(self.analysis(inputs.unsqueeze(2)))
            return self.classifier(self.temporal_pool(responses))


    class IQMLP(nn.Module):
        """Pure Matmul/ReLU baseline on a fixed-length IQ frame."""

        def __init__(self, num_classes: int, dropout: float = 0.2, sample_length: int = 1024) -> None:
            super().__init__()
            if num_classes <= 0 or sample_length <= 0:
                raise ValueError("num_classes and sample_length must be positive")
            self.sample_length = sample_length
            self.classifier = nn.Sequential(
                nn.Flatten(),
                nn.Linear(2 * sample_length, 128),
                nn.ReLU(),
                nn.Dropout(dropout),
                nn.Linear(128, num_classes),
            )

        def forward(self, inputs):
            if inputs.ndim != 3 or inputs.shape[1:] != (2, self.sample_length):
                raise ValueError(f"model input must have shape (N, 2, {self.sample_length})")
            return self.classifier(inputs)

else:

    class LegacyIQResidualCNN:  # pragma: no cover - clear optional-dependency error.
        def __init__(self, *args, **kwargs) -> None:
            _require_torch()


    class ChannelIQBaselineCNN:  # pragma: no cover - clear optional-dependency error.
        def __init__(self, *args, **kwargs) -> None:
            _require_torch()


    class IQResidualCNN:  # pragma: no cover - only used for a clear error message.
        def __init__(self, *args, **kwargs) -> None:
            _require_torch()


    class RobustIQNet:  # pragma: no cover - clear optional-dependency error.
        def __init__(self, *args, **kwargs) -> None:
            _require_torch()


    class SpectralFilterBank:  # pragma: no cover - clear optional-dependency error.
        def __init__(self, *args, **kwargs) -> None:
            _require_torch()


    class IQMLP:  # pragma: no cover - clear optional-dependency error.
        def __init__(self, *args, **kwargs) -> None:
            _require_torch()


def build_model(
    num_classes: int,
    dropout: float = 0.2,
    sample_length: int = 1024,
    architecture: str = "channel",
    num_families: int = 0,
    num_impairment_targets: int = 0,
):
    """Build a model after checking the optional dependency."""

    _require_torch()
    if architecture == "legacy":
        return LegacyIQResidualCNN(num_classes=num_classes, dropout=dropout)
    if architecture == "channel":
        return ChannelIQBaselineCNN(num_classes=num_classes, dropout=dropout)
    if architecture == "v2":
        return IQResidualCNN(
            num_classes=num_classes,
            dropout=dropout,
            sample_length=sample_length,
            num_families=num_families,
        )
    if architecture == "robust":
        return RobustIQNet(
            num_classes=num_classes,
            dropout=dropout,
            sample_length=sample_length,
            num_impairment_targets=num_impairment_targets,
        )
    if architecture in {"filterbank", "learned_filterbank"}:
        return SpectralFilterBank(
            num_classes=num_classes,
            dropout=dropout,
            sample_length=sample_length,
            trainable_filters=architecture == "learned_filterbank",
        )
    if architecture == "mlp":
        return IQMLP(num_classes=num_classes, dropout=dropout, sample_length=sample_length)
    raise ValueError("architecture must be legacy, channel, v2, robust, filterbank, learned_filterbank, or mlp")
