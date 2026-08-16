# Esports Video Highlight Dataset

This repository contains the public release of an esports video highlight dataset and the benchmark resources associated with the accompanying paper. It includes temporal annotations, fixed dataset splits, pre-extracted multimodal features, adapted implementations of three benchmark models, and model checkpoints.

> Raw match videos are not included. See [Video Sources and Copyright](#video-sources-and-copyright) for information about accessing the source videos and the applicable copyright terms.

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/Ella-zsy/Esport_Datasets.git
cd Esport_Datasets
```

### 2. Download the Data and Trained Checkpoints from ModelScope

First, install and configure the ModelScope command-line tool so that the `ms-hub` command is available. Then run the following command from the repository root:

```bash
ms-hub download Huiang03/Esport_Datasets \
  --repo-type dataset \
  --local-dir "$(pwd)"
```

This command downloads the pre-extracted features, annotations, and checkpoints retrained for this project into their corresponding directories. After the download is complete, the repository will have the following structure:

```text
Esport_Datasets/
├── QD-DETR/                 # QD-DETR code and model checkpoints
├── TR-DETR/                 # TR-DETR code and model checkpoints
├── VideoLights/             # VideoLights code and model checkpoints
├── features/                # Pre-extracted multimodal features
├── labels/                  # Annotations and fixed dataset splits
└── build_env.sh             # Environment setup script
```

The source code and `build_env.sh` are provided through GitHub. The features, annotations, and checkpoints retrained for this project are distributed through the ModelScope dataset repository. To obtain the original-paper checkpoints, follow the instructions in [Downloading the Original-Paper Checkpoints](#downloading-the-original-paper-checkpoints).

### 3. Set Up the Environment

Make sure Conda is installed, then run the following command from the repository root:

```bash
bash build_env.sh
```

By default, the script creates a Conda environment named `esport_eval` on Linux x86_64 and installs the CUDA dependencies. Activate the environment after installation:

```bash
conda activate esport_eval
```

## Dataset Overview

The dataset contains 150 match clips from three esports titles.

| Subset | Directory | Train | Validation | Test | Total |
| --- | --- | ---: | ---: | ---: | ---: |
| Honor of Kings | `labels/honor/` | 63 | 14 | 13 | 90 |
| League of Legends | `labels/ying/` | 28 | 6 | 6 | 40 |
| Dota 2 | `labels/dota2/` | 14 | 3 | 3 | 20 |
| Combined | `labels/total/` | 105 | 23 | 22 | 150 |

The files in `labels/total/` are the union of the three game-specific subsets. The released train, validation, and test splits are fixed, and no `vid` appears in more than one split.

## Annotation Format

Annotations are provided in JSON Lines format. Each line contains one match-clip record:

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

The fields are defined as follows:

- `qid`: Unique identifier for the text query.
- `query`: Text query used by the benchmark models.
- `duration`: Duration of the match clip in seconds. It equals `end_time - start_time` in `vid`.
- `vid`: Source YouTube video ID and the start and end times of the clip within that video.
- `relevant_windows`: Annotated highlight intervals in seconds, relative to the beginning of the extracted match clip.
- `relevant_clip_ids`: Indices of the relevant 2-second clips.
- `saliency_scores`: Three saliency scores for each entry in `relevant_clip_ids`.

## Pre-extracted Features

The `features/` directory contains the multimodal features used by the benchmark models:

| Directory | Modality | Indexing | Format |
| --- | --- | --- | --- |
| `features/slowfast_features/` | Visual (SlowFast) | One file per `vid` | `.npz` |
| `features/clip_features/` | Visual (CLIP) | One file per `vid` | `.npz` |
| `features/pann_features/` | Audio (PANN) | One file per `vid` | `.npy` |
| `features/clip_text_features/` | Text (CLIP) | One `qid<qid>.npz` file per query | `.npz` |

Each video or audio feature type contains 150 files, and the text-query features also contain 150 files. Use the ModelScope command above to download these files.

## Benchmark Models

This repository includes adapted implementations of the following three benchmark models:

- `QD-DETR/`
- `TR-DETR/`
- `VideoLights/`

The checkpoints retrained for this project are downloaded from ModelScope, while the original-paper checkpoints must be downloaded separately from the model authors. See the README and license files in each model directory for the corresponding source project, dependencies, and licensing information.

## Reproducing Model Results

After downloading the required data and checkpoints, activate the environment before running inference:

```bash
conda activate esport_eval
```

All inference scripts follow this general command format:

```text
bash <inference.sh> <checkpoint_path> test
```

### Checkpoint Types

This release uses two types of checkpoints:

- `QD-DETR/results/video_checkpoint/`, `QD-DETR/results/audio_checkpoint/`, `TR-DETR/checkpoint/checkpoint/`, and `VideoLights/res/checkpoint/` are reserved for the original-paper models. These weights are used to evaluate the original models on this dataset and must be downloaded separately from the model authors.
- The `honor`, `ying`, `dota2`, and `total` directories contain models retrained on the four dataset variants in this project. Use the `model_best.ckpt` files in these directories to reproduce this project's experimental results.

QD-DETR further distinguishes checkpoints by input modality:

- `*_v`: Models trained with visual features only.
- `*_v+a`: Models trained with both visual and audio features.

### Downloading the Original-Paper Checkpoints

The original-paper checkpoints are large binary files and are not stored directly in this project's GitHub repository. Download them from the locations provided by the respective model authors and save them as shown below:

| Model | Download | Save as |
| --- | --- | --- |
| QD-DETR (video + audio) | [Video+Audio Checkpoint](https://www.dropbox.com/s/hsc7jk21ppqasjt/videoaudio.ckpt?dl=0) | `QD-DETR/results/audio_checkpoint/videoaudio.ckpt` |
| QD-DETR (video only) | [Video-only Checkpoint](https://www.dropbox.com/s/yygwyljw8514d9r/videoonly.ckpt?dl=0) | `QD-DETR/results/video_checkpoint/videoonly.ckpt` |
| TR-DETR | [TR-DETR Checkpoint](https://raw.githubusercontent.com/mingyao1120/TR-DETR/master/checkpoint/%5BV_SOTA%5Dhl-video_tef-exp-2023_07_24_20_09_00/model_best.ckpt) | `TR-DETR/checkpoint/checkpoint/model_best.ckpt` |
| VideoLights | [VideoLights Checkpoint](https://drive.google.com/file/d/1psyVph1kNKSKFOxwXjzkeYuO_mbBsLkH/view?usp=drive_link) | `VideoLights/res/checkpoint/model_best.ckpt` |

The TR-DETR checkpoint can be downloaded directly with the following command, run from the repository root:

```bash
wget -O TR-DETR/checkpoint/checkpoint/model_best.ckpt \
  'https://raw.githubusercontent.com/mingyao1120/TR-DETR/master/checkpoint/%5BV_SOTA%5Dhl-video_tef-exp-2023_07_24_20_09_00/model_best.ckpt'
```

Download the QD-DETR and VideoLights checkpoints through the links in the table and place them at the specified paths. Inference also requires the corresponding `opt.json` file in each checkpoint directory; retain the configuration files included with this repository.

After downloading the checkpoints, use the following commands to evaluate the original-paper models:

```bash
# QD-DETR (video only)
cd QD-DETR
bash qd_detr/scripts/inference.sh \
  results/video_checkpoint/videoonly.ckpt \
  test

# QD-DETR (video + audio)
bash qd_detr/scripts/inference_audio.sh \
  results/audio_checkpoint/videoaudio.ckpt \
  test
cd ..

# TR-DETR
cd TR-DETR
bash tr_detr/scripts/inference.sh \
  checkpoint/checkpoint/model_best.ckpt \
  test
cd ..

# VideoLights
cd VideoLights
bash video_lights/scripts/qvhl/inference.sh \
  res/checkpoint/model_best.ckpt \
  test
cd ..
```

### Reproducing Results with the Retrained Checkpoints

#### QD-DETR

Use `inference.sh` for the visual-only models and `inference_audio.sh` for the models that use both visual and audio features. The following example evaluates the Honor of Kings checkpoints:

```bash
cd QD-DETR

# Visual features only
bash qd_detr/scripts/inference.sh \
  results/honor_v/model_best.ckpt \
  test

# Visual and audio features
bash qd_detr/scripts/inference_audio.sh \
  results/honor_v+a/model_best.ckpt \
  test

cd ..
```

The QD-DETR checkpoint paths for each dataset are listed below:

| Dataset | Video only | Video + audio |
| --- | --- | --- |
| Honor of Kings | `results/honor_v/model_best.ckpt` | `results/honor_v+a/model_best.ckpt` |
| League of Legends | `results/ying_v/model_best.ckpt` | `results/ying_v+a/model_best.ckpt` |
| Dota 2 | `results/dota2_v/model_best.ckpt` | `results/dota2_v+a/model_best.ckpt` |
| Combined | `results/total_v/model_best.ckpt` | `results/total_v+a/model_best.ckpt` |

#### TR-DETR

The following example evaluates the Honor of Kings checkpoint:

```bash
cd TR-DETR
bash tr_detr/scripts/inference.sh \
  checkpoint/honor/model_best.ckpt \
  test
cd ..
```

Use the corresponding checkpoint path for each dataset:

```text
checkpoint/honor/model_best.ckpt
checkpoint/ying/model_best.ckpt
checkpoint/dota2/model_best.ckpt
checkpoint/total/model_best.ckpt
```

#### VideoLights

The following example evaluates the Honor of Kings checkpoint:

```bash
cd VideoLights
bash video_lights/scripts/qvhl/inference.sh \
  res/honor/model_best.ckpt \
  test
cd ..
```

Use the corresponding checkpoint path for each dataset:

```text
res/honor/model_best.ckpt
res/ying/model_best.ckpt
res/dota2/model_best.ckpt
res/total/model_best.ckpt
```

> Run each inference script from the root directory of its model. For example, run the QD-DETR scripts from `QD-DETR/`. Calling a script directly from the repository root may prevent Python modules or relative paths from being resolved correctly.

### Selecting the Evaluation Dataset

To reproduce results for a particular dataset, open the relevant `inference.sh` file and set `eval_path` to the corresponding annotation directory:

| Dataset | Annotation directory |
| --- | --- |
| Honor of Kings | `labels/honor/` |
| League of Legends | `labels/ying/` |
| Dota 2 | `labels/dota2/` |
| Combined | `labels/total/` |

The checkpoint and annotations must correspond to the same dataset. For example, when evaluating `results/ying_v/model_best.ckpt`, set `eval_path` to the test or validation file under `labels/ying/`.

All four `eval_path` options are already included in the inference scripts. Uncomment the line for the target dataset and comment out the other lines. Each checkpoint directory also contains an `opt.json` file with the training and inference configuration. If the repository has been moved, make sure that `v_feat_dirs`, `t_feat_dir` (`t_feat_dirs` for VideoLights), `a_feat_dir`, and `results_dir` point to the correct locations in the current repository.

Inference writes the predictions and evaluation metrics to the checkpoint's result directory. The main output files are:

```text
hl_test_submission.jsonl
hl_test_submission_metrics.json
```

Replace `test` with `val` in an inference command to evaluate the validation split and generate the corresponding `hl_val_submission.jsonl` and metrics file.

## Video Sources and Copyright

The source match videos were collected from official tournament channels on YouTube and remain hosted by their original publishers. Some videos may become unavailable because of platform operations or changes in copyright policy.

This repository does not redistribute the raw video files. Each annotation identifies its source video and temporal boundaries through the `vid` field:

```text
{youtube_id}_{start_time}_{end_time}
```

For example, `1KZ6PPYqcVs_486_1540` refers to the segment from 486 to 1540 seconds in the YouTube video with ID `1KZ6PPYqcVs`. The source page is:

```text
https://www.youtube.com/watch?v=1KZ6PPYqcVs
```

Because a YouTube ID may itself contain underscores, parse `start_time` and `end_time` from the two rightmost underscore-separated components of `vid`.

Users who need the original videos must obtain them from the corresponding official sources and comply with YouTube's terms of service and the copyright policies of the original publishers. This repository does not guarantee the continued availability of any source video.

## Release Scope and Licenses

This dataset is released to support research reproducibility. The release does not grant any rights to the source videos, tournament broadcasts, trademarks, or other content owned by the original publishers.

The benchmark implementations are governed by the license files in their respective subdirectories. Please cite the accompanying paper when using the annotations or features provided in this repository.
