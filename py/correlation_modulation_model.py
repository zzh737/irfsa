"""多尺度 IQ + 延迟复相关分支，避免 atan2 相位包裹，保留幅度关联。"""
import torch
from torch import nn
from modulation_model import ResidualBlock
from multiscale_modulation_model import MultiScaleIQCNN


def lag_correlations(inputs,lags=(1,2,4)):
    """x[n] conj(x[n-lag])，按 2 缩放适配逐帧 RMS 输入；边界补零。"""
    if inputs.ndim!=3 or inputs.shape[1]!=2 or inputs.shape[-1]<=max(lags):raise ValueError('invalid IQ shape/length')
    i,q=inputs[:,0],inputs[:,1];features=[]
    for lag in lags:
        real=(i[:,lag:]*i[:,:-lag]+q[:,lag:]*q[:,:-lag])*.5
        imag=(q[:,lag:]*i[:,:-lag]-i[:,lag:]*q[:,:-lag])*.5
        features.extend([torch.nn.functional.pad(real,(lag,0)),torch.nn.functional.pad(imag,(lag,0))])
    return torch.stack(features,1)


class CorrelationIQCNN(nn.Module):
    def __init__(self,num_classes,dropout=.2):
        super().__init__()
        self.raw=MultiScaleIQCNN(num_classes,dropout)
        self.correlations=nn.Sequential(
            nn.Conv2d(6,24,(1,7),padding=(0,3),bias=False),nn.BatchNorm2d(24),nn.ReLU(inplace=True),
            ResidualBlock(24),nn.AvgPool2d((1,4)),
            nn.Conv2d(24,48,(1,5),padding=(0,2),bias=False),nn.BatchNorm2d(48),nn.ReLU(inplace=True),
            ResidualBlock(48),nn.AvgPool2d((1,4)),nn.AdaptiveAvgPool2d((1,1)))
        # 原 raw.classifier 权重仍保留；新增支路通过零初始化输出作增量修正。
        self.correlation_classifier=nn.Sequential(nn.Flatten(),nn.Dropout(dropout),nn.Linear(48,num_classes,bias=False))
        nn.init.zeros_(self.correlation_classifier[2].weight)

    def initialize_from_multiscale(self,state):self.raw.load_state_dict(state,strict=True)

    def forward(self,inputs):
        raw=self.raw(inputs)
        correlated=self.correlations(lag_correlations(inputs).unsqueeze(2))
        return raw+self.correlation_classifier(correlated)


def snr_training_weights(snrs):
    """只用于训练，不进入推理路径；整体均值归一，避免单纯改变损失尺度。"""
    weights=torch.where(snrs<=-12,.4,torch.where(snrs<=4,1.8,.8))
    return weights/weights.mean()
