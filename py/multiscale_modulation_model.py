"""实数 IQ 多尺度残差 CNN：3/15/31 点卷积，第一次池化延后。"""
import torch
from torch import nn


class ParallelScaleResidual(nn.Module):
    """先压缩通道，再并行观察三个时间范围，融合后加回输入。"""
    kernels = (3, 15, 31)

    def __init__(self, channels):
        super().__init__()
        hidden = channels // 2
        self.reduce = nn.Sequential(nn.Conv2d(channels, hidden, 1, bias=False),
                                    nn.BatchNorm2d(hidden), nn.ReLU(inplace=True))
        self.branches = nn.ModuleList([
            nn.Sequential(nn.Conv2d(hidden, hidden, (1, k), padding=(0, k//2), bias=False),
                          nn.BatchNorm2d(hidden), nn.ReLU(inplace=True)) for k in self.kernels])
        # 不同分支的时间长度相同；通道拼接后由 1×1 卷积学习融合比例。
        self.fuse = nn.Sequential(nn.Conv2d(3*hidden, channels, 1, bias=False), nn.BatchNorm2d(channels))
        self.activation = nn.ReLU(inplace=True)

    def forward(self, inputs):
        reduced = self.reduce(inputs)
        mixed = self.fuse(torch.cat([branch(reduced) for branch in self.branches], dim=1))
        return self.activation(inputs + mixed)


class MultiScaleIQCNN(nn.Module):
    """输入仍为 (N,2,1024)，全部为实数卷积；从随机权重开始训练。"""
    def __init__(self, num_classes, dropout=.2):
        super().__init__()
        if num_classes <= 0: raise ValueError('num_classes must be positive')
        self.features = nn.Sequential(
            nn.Conv2d(2, 32, (1, 7), padding=(0, 3), bias=False), nn.BatchNorm2d(32), nn.ReLU(inplace=True),
            # 原模型在首层后立即池化；这里先在完整时间分辨率上提取多尺度特征。
            ParallelScaleResidual(32), nn.MaxPool2d((1, 2)),
            nn.Conv2d(32, 64, (1, 5), padding=(0, 2), bias=False), nn.BatchNorm2d(64), nn.ReLU(inplace=True),
            nn.MaxPool2d((1, 2)), ParallelScaleResidual(64),
            nn.Conv2d(64, 128, (1, 5), padding=(0, 2), bias=False), nn.BatchNorm2d(128), nn.ReLU(inplace=True),
            nn.AdaptiveAvgPool2d((1, 1)))
        self.classifier = nn.Sequential(nn.Flatten(), nn.Dropout(dropout), nn.Linear(128, num_classes))

    def forward(self, inputs):
        if inputs.ndim != 3 or inputs.shape[1] != 2 or inputs.shape[2] < 4:
            raise ValueError('model input must have shape (N,2,L), L>=4')
        return self.classifier(self.features(inputs.unsqueeze(2)))


def load_multiscale_checkpoint(path, device='cpu'):
    cp = torch.load(path, map_location='cpu', weights_only=True)
    if cp['metadata']['architecture'] != 'multiscale_3_15_31':
        raise ValueError('expected multiscale_3_15_31 checkpoint')
    model = MultiScaleIQCNN(len(cp['metadata']['classes'])).to(device)
    model.load_state_dict(cp['model_state'], strict=True)
    return model.eval(), cp['metadata']
