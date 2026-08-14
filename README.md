# 电竞视频高光数据集（Esport Datasets）

本仓库公开了电竞视频高光数据集及论文配套的基准测试资源，包括时序标注、固定的数据集划分、预提取的多模态特征，以及三个基准模型的实现与模型权重。

> 本仓库不提供原始比赛视频。原始视频的获取方式及版权说明请参见[视频来源与版权说明](#视频来源与版权说明)。

## 快速开始

### 1. 克隆代码仓库

```bash
git clone https://github.com/Ella-zsy/Esport_Datasets.git
cd Esport_Datasets
```

### 2. 从魔搭社区下载数据与模型文件

请先安装并配置能够使用 `ms-hub` 命令的魔搭社区下载工具，然后在仓库根目录执行：

```bash
ms-hub download Huiang03/Esport_Datasets \
  --repo-type dataset \
  --local-dir "$(pwd)"
```

该命令会将预提取特征、标注文件以及三个基准模型的 checkpoint 下载到当前仓库的对应目录中。下载完成后，仓库结构如下：

```text
Esport_Datasets/
├── QD-DETR/                 # QD-DETR 代码及模型 checkpoint
├── TR-DETR/                 # TR-DETR 代码及模型 checkpoint
├── VideoLights/             # VideoLights 代码及模型 checkpoint
├── features/                # 预提取的多模态特征
├── labels/                  # 数据集标注及固定划分
└── build_env.sh             # 环境安装脚本
```

其中，代码和 `build_env.sh` 来自 GitHub，特征、标注及 checkpoint 由魔搭社区数据集仓库提供。

### 3. 搭建运行环境

请确保系统已安装 Conda，然后在仓库根目录直接运行：

```bash
bash build_env.sh
```

脚本默认在 Linux x86_64 系统上创建名为 `esport_eval` 的 Conda 环境，并安装 CUDA 版本的依赖。安装完成后激活环境：

```bash
conda activate esport_eval
```

## 数据集概览

本数据集包含来自三个电竞项目的 150 个比赛片段。

| 子数据集 | 目录 | 训练集 | 验证集 | 测试集 | 总计 |
| --- | --- | ---: | ---: | ---: | ---: |
| 王者荣耀（Honor of Kings） | `labels/honor/` | 63 | 14 | 13 | 90 |
| 英雄联盟（League of Legends） | `labels/ying/` | 28 | 6 | 6 | 40 |
| Dota 2 | `labels/dota2/` | 14 | 3 | 3 | 20 |
| 全部数据 | `labels/total/` | 105 | 23 | 22 | 150 |

`labels/total/` 中的数据是三个游戏子数据集的并集。本仓库提供的训练集、验证集和测试集划分均已固定，不同划分之间不存在重复的 `vid`。

## 标注格式

标注以 JSON Lines 格式发布，每一行表示一个比赛片段，例如：

```json
{
  "qid": 1,
  "query": "Highlight moments in the honor of kings",
  "duration": 1054,
  "vid": "1KZ6PPYqcVs_486_1540",
  "relevant_clip_ids": [120, 121, 122],
  "saliency_scores": [[4, 4, 4], [4, 4, 4], [4, 4, 4]],
  "relevant_windows": [[240, 258]]
}
```

各字段含义如下：

- `qid`：查询文本的唯一编号。
- `query`：基准模型使用的文本查询。
- `duration`：比赛片段的时长，单位为秒，等于 `vid` 中的 `end_time - start_time`。
- `vid`：原始 YouTube 视频 ID，以及该片段在原视频中的起止时间。
- `relevant_windows`：高光片段的标注区间，单位为秒；时间相对于当前截取的比赛片段起点计算。
- `relevant_clip_ids`：相关 2 秒片段的索引。
- `saliency_scores`：每个 `relevant_clip_ids` 对应的三个显著性分数。

## 预提取特征

`features/` 目录包含基准模型使用的多模态特征：

| 目录 | 模态 | 索引方式 | 格式 |
| --- | --- | --- | --- |
| `features/slowfast_features/` | 视觉（SlowFast） | 每个 `vid` 一个文件 | `.npz` |
| `features/clip_features/` | 视觉（CLIP） | 每个 `vid` 一个文件 | `.npz` |
| `features/pann_features/` | 音频（PANN） | 每个 `vid` 一个文件 | `.npy` |
| `features/clip_text_features/` | 文本（CLIP） | 每个查询一个 `qid<qid>.npz` 文件 | `.npz` |

每种视频或音频特征均包含 150 个文件，文本查询特征也包含 150 个文件。这些特征文件通过上述魔搭社区下载命令获取。

## 基准模型

本仓库提供以下三个经过适配的基准模型实现：

- `QD-DETR/`
- `TR-DETR/`
- `VideoLights/`

对应的模型 checkpoint 由魔搭社区下载到各模型目录中。有关各项目的代码来源、依赖和许可证，请参阅相应子目录中的 README 与 LICENSE 文件。

## 复现模型结果

完成数据和 checkpoint 下载并激活环境后，可以运行各模型提供的推理脚本，在测试集上复现本项目的实验结果：

```bash
conda activate esport_eval
```

推理脚本的调用格式统一为：

```text
bash <inference.sh> <checkpoint 路径> test
```

### Checkpoint 说明

本仓库包含两类 checkpoint：

- QD-DETR 的 `results/video_checkpoint/`、`results/audio_checkpoint/`，TR-DETR 的 `checkpoint/checkpoint/`，以及 VideoLights 的 `res/checkpoint/` 保存的是原论文模型，主要用于直接测试原始模型。
- `honor`、`ying`、`dota2` 和 `total` 对应本项目在四个数据集划分上重新训练得到的模型。复现本项目的实验结果时，应使用这些目录中的 `model_best.ckpt`。

QD-DETR 还根据输入模态进一步区分模型目录：

- `*_v`：只使用视觉特征训练的模型。
- `*_v+a`：同时使用视觉和音频特征训练的模型。

### QD-DETR

QD-DETR 的视觉模型使用 `inference.sh`，视觉与音频模型使用 `inference_audio.sh`。以王者荣耀数据集为例：

```bash
cd QD-DETR

# 仅使用视觉特征
bash qd_detr/scripts/inference.sh \
  results/honor_v/model_best.ckpt \
  test

# 使用视觉和音频特征
bash qd_detr/scripts/inference_audio.sh \
  results/honor_v+a/model_best.ckpt \
  test

cd ..
```

各数据集对应的 QD-DETR checkpoint 如下：

| 数据集 | 仅视觉 | 视觉 + 音频 |
| --- | --- | --- |
| 王者荣耀 | `results/honor_v/model_best.ckpt` | `results/honor_v+a/model_best.ckpt` |
| 英雄联盟 | `results/ying_v/model_best.ckpt` | `results/ying_v+a/model_best.ckpt` |
| Dota 2 | `results/dota2_v/model_best.ckpt` | `results/dota2_v+a/model_best.ckpt` |
| 全部数据 | `results/total_v/model_best.ckpt` | `results/total_v+a/model_best.ckpt` |

### TR-DETR

以王者荣耀数据集为例：

```bash
cd TR-DETR
bash tr_detr/scripts/inference.sh \
  checkpoint/honor/model_best.ckpt \
  test
cd ..
```

其他数据集对应的 checkpoint 路径为：

```text
checkpoint/honor/model_best.ckpt
checkpoint/ying/model_best.ckpt
checkpoint/dota2/model_best.ckpt
checkpoint/total/model_best.ckpt
```

### VideoLights

以王者荣耀数据集为例：

```bash
cd VideoLights
bash video_lights/scripts/qvhl/inference.sh \
  res/honor/model_best.ckpt \
  test
cd ..
```

其他数据集对应的 checkpoint 路径为：

```text
res/honor/model_best.ckpt
res/ying/model_best.ckpt
res/dota2/model_best.ckpt
res/total/model_best.ckpt
```

> 上述脚本需要从对应模型的根目录运行，例如 QD-DETR 脚本需要在 `QD-DETR/` 下运行。直接在仓库根目录调用脚本可能导致 Python 模块或相对路径无法正确解析。

### 选择评测数据集

如需复现某个数据集的结果，请打开对应的 `inference.sh`，将 `eval_path` 切换为所需目录：

| 数据集 | 标注目录 |
| --- | --- |
| 王者荣耀 | `labels/honor/` |
| 英雄联盟 | `labels/ying/` |
| Dota 2 | `labels/dota2/` |
| 全部数据 | `labels/total/` |

checkpoint 和标注必须选择同一个数据集。例如，使用 `results/ying_v/model_best.ckpt` 时，应将脚本中的 `eval_path` 切换到 `labels/ying/`。

脚本中已经预留了这四种 `eval_path`。保留目标数据集对应的一行，并注释掉其他行即可。checkpoint 目录下的 `opt.json` 保存了训练和推理配置；如果仓库移动到了不同位置，请同时确认其中的 `v_feat_dirs`、`t_feat_dir`（VideoLights 中为 `t_feat_dirs`）、`a_feat_dir` 和 `results_dir` 指向当前仓库中的实际目录。

### 软链接与旧绝对路径

部分 checkpoint 附带的 `opt.json` 保存了训练环境中的绝对路径，例如 `/root/New/features/slowfast_features`。当仓库位于其他目录时，推理程序可能找不到特征文件，并报出 `FileNotFoundError`。可以先检查配置和旧路径：

```bash
grep -E 'v_feat_dirs|t_feat_dir|t_feat_dirs|a_feat_dir|results_dir|/root/' \
  <checkpoint 目录>/opt.json
ls -ld /root/New
```

推荐直接修改对应 checkpoint 目录下的 `opt.json`，将上述路径改为当前仓库中的实际绝对路径。如果不方便逐个修改配置，也可以建立兼容软链接。进入当前 `Esport_Datasets` 仓库根目录后执行：

```bash
ln -s "$(pwd)" /root/New
```

例如，仓库位于 `/root/autodl-tmp/Esport_Datasets/` 时，该命令会让旧路径 `/root/New/features/...` 指向当前仓库的 `features/...`。创建后可验证：

```bash
readlink -f /root/New
ls /root/New/features
```

如果 `/root/New` 已经存在，请不要直接覆盖；先使用 `readlink -f /root/New` 检查它是否指向当前仓库。如果它是普通目录或指向其他项目，应优先修改 `opt.json`。在没有 `/root` 写权限的环境中，也应采用修改 `opt.json` 的方式。

推理完成后，预测结果和评测指标将写入 checkpoint 所在的结果目录，主要包括：

```text
hl_test_submission.jsonl
hl_test_submission_metrics.json
```

将命令中的 `test` 替换为 `val` 时，会生成对应的 `hl_val_submission.jsonl` 和指标文件。

## 视频来源与版权说明

原始比赛视频来自 YouTube 上的官方赛事频道，并继续由原始发布者托管。由于平台运营或版权政策变化，部分视频未来可能无法访问。

本仓库不重新分发原始视频文件。每条标注通过 `vid` 字段记录其来源视频及时间边界，格式为：

```text
{youtube_id}_{start_time}_{end_time}
```

例如，`1KZ6PPYqcVs_486_1540` 表示 YouTube 视频 `1KZ6PPYqcVs` 中从第 486 秒到第 1540 秒的片段，其来源页面为：

```text
https://www.youtube.com/watch?v=1KZ6PPYqcVs
```

由于 YouTube ID 本身可能包含下划线，解析 `vid` 时应从右侧的最后两个下划线分隔项读取 `start_time` 和 `end_time`。

如需获取原始视频，请前往对应的官方来源，并遵守 YouTube 服务条款及相关发布者的版权政策。本仓库不保证原始视频始终可用。

## 发布范围与许可证

本数据集用于支持科研复现。本仓库的发布不代表授予用户对原始视频、赛事转播、商标或其他由原始发布者所有的内容的任何权利。

各基准模型代码分别遵循其子目录中的许可证。如在研究中使用本仓库提供的标注或特征，请引用对应论文。
