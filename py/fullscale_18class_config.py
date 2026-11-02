"""当前 fullscale 任务的类别定义；历史 20 类实验使用自己的快照。"""
from pathlib import Path

EXCLUDED_CLASSES = ('16PSK', '256QAM')
CLASSES = (
    '16ASK', '16FSK', '16QAM', '2ASK', '2FSK', '2PSK', '4ASK', '4FSK',
    '4PSK', '64QAM', '8ASK', '8FSK', '8PSK', 'AM-DSB-SC', 'AM-DSB-WC',
    'AM-SSB-SC', 'AM-SSB-WC', 'FM',
)
DEFAULT_OUTPUT = Path('outputs/fullscale_v2_18class_20261031')


def filter_records(records):
    """保留已有整段分割，移除两类，不修改原记录或原始 IQ 文件。"""
    kept, excluded = [], []
    for record in records:
        label = record['label']
        if label in EXCLUDED_CLASSES:
            excluded.append({'metadata': record['metadata'], 'label': label,
                             'reason': 'excluded_modulation_class'})
        elif label in CLASSES:
            kept.append(dict(record))
        else:
            raise ValueError(f'Unexpected modulation class: {label}')
    if sorted({r['label'] for r in kept}) != list(CLASSES):
        raise ValueError('Dataset does not contain the complete requested 18 classes')
    return kept, excluded


def validate_checkpoint_classes(metadata):
    if metadata.get('classes') != list(CLASSES):
        raise ValueError('Expected the 18-class checkpoint excluding 16PSK and 256QAM; retrain with fullscale_18class_training.py')
