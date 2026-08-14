#!/usr/bin/env bash

# Build a shared Conda environment for inference and evaluation with
# QD-DETR, TR-DETR, and VideoLights.
#
# Usage:
#   bash build_env.sh [ENV_NAME] [cuda|cpu]
#
# Examples:
#   bash build_env.sh                  # esport_eval, PyTorch cu117 runtime
#   bash build_env.sh esport_eval cpu  # CPU-only environment
#
# Re-running the same command is safe. Completed steps are reused and
# interrupted PyTorch wheel downloads continue from the cached files.

set -euo pipefail

ENV_NAME="${1:-esport_eval}"
BACKEND="${2:-cuda}"

# Network settings apply to this script only.
export CONDA_REMOTE_CONNECT_TIMEOUT_SECS="${CONDA_REMOTE_CONNECT_TIMEOUT_SECS:-60}"
export CONDA_REMOTE_READ_TIMEOUT_SECS="${CONDA_REMOTE_READ_TIMEOUT_SECS:-300}"
export CONDA_REMOTE_MAX_RETRIES="${CONDA_REMOTE_MAX_RETRIES:-10}"
export PIP_ROOT_USER_ACTION="${PIP_ROOT_USER_ACTION:-ignore}"

CACHE_BASE="${XDG_CACHE_HOME:-${HOME:-/tmp}/.cache}"
WHEEL_CACHE="${ESPORT_WHEEL_CACHE:-${CACHE_BASE}/esport-datasets/pytorch}"
OFFICIAL_PYPI="https://pypi.org/simple"
TUNA_PYPI="https://pypi.tuna.tsinghua.edu.cn/simple"

run_with_retry() {
    local max_attempts=4
    local attempt=1
    local status=0

    while true; do
        if "$@"; then
            return 0
        else
            status=$?
        fi

        if (( attempt >= max_attempts )); then
            echo "Command failed after ${max_attempts} attempts." >&2
            return "${status}"
        fi

        echo "Command failed; retrying in $((attempt * 10)) seconds (${attempt}/${max_attempts})..." >&2
        sleep $((attempt * 10))
        ((attempt += 1))
    done
}

check_cuda_driver() {
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        echo "Error: nvidia-smi was not found." >&2
        echo "The NVIDIA driver must be installed and the GPU must be exposed before building the CUDA environment." >&2
        return 1
    fi

    if ! nvidia-smi -L >/dev/null 2>&1; then
        echo "Error: the NVIDIA driver cannot communicate with a GPU." >&2
        echo "This is a host/container driver problem and cannot be repaired by reinstalling Python packages." >&2
        echo "Check 'nvidia-smi' in the same terminal; for a container, also check that it was started with GPU access." >&2
        return 1
    fi
}

check_cuda_runtime() {
    local smoke_test
    smoke_test="import torch; assert torch.cuda.is_available(), 'torch.cuda.is_available() is False'; x = torch.ones((32, 32), device='cuda'); y = torch.mm(x, x); torch.cuda.synchronize(); assert y[0, 0].item() == 32.0; print('CUDA device:', torch.cuda.get_device_name(0)); print('CUDA/cuBLAS smoke test: OK')"

    if ! conda run --no-capture-output --name "${ENV_NAME}" python -c "${smoke_test}"; then
        echo >&2
        echo "Error: CUDA/cuBLAS initialization failed." >&2
        echo "The packages were installed, but the GPU runtime is not usable." >&2
        echo "Run 'nvidia-smi' and check available GPU memory before retrying inference." >&2
        echo "CUBLAS_STATUS_NOT_INITIALIZED commonly occurs when the driver/GPU is unavailable or insufficient free GPU memory remains." >&2
        return 1
    fi
}

select_pypi() {
    if [[ -n "${ESPORT_PYPI_INDEX:-}" ]]; then
        PYPI_INDEX="${ESPORT_PYPI_INDEX}"
        return
    fi

    # Prefer TUNA when it is quickly reachable; otherwise use official PyPI.
    if command -v curl >/dev/null 2>&1 && \
       curl --fail --silent --show-error --location \
            --connect-timeout 3 --max-time 5 \
            "${TUNA_PYPI}/pip/" >/dev/null 2>&1; then
        PYPI_INDEX="${TUNA_PYPI}"
    else
        PYPI_INDEX="${OFFICIAL_PYPI}"
    fi
}

wheel_is_valid() {
    local wheel_path="$1"
    [[ -f "${wheel_path}" ]] && \
        conda run --name "${ENV_NAME}" python -c \
            'import sys, zipfile; sys.exit(0 if zipfile.is_zipfile(sys.argv[1]) else 1)' \
            "${wheel_path}" >/dev/null 2>&1
}

download_wheel() {
    local url="$1"
    local output="$2"
    local output_dir
    local output_name

    if wheel_is_valid "${output}"; then
        echo "Using cached wheel: ${output}"
        return 0
    fi

    output_dir="$(dirname "${output}")"
    output_name="$(basename "${output}")"
    mkdir -p "${output_dir}"

    echo
    echo "Downloading ${output_name}"
    echo "Cache: ${output}"

    if command -v aria2c >/dev/null 2>&1; then
        aria2c \
            --continue=true \
            --max-connection-per-server=8 \
            --split=8 \
            --min-split-size=10M \
            --file-allocation=none \
            --max-tries=0 \
            --retry-wait=5 \
            --dir="${output_dir}" \
            --out="${output_name}" \
            "${url}"
    elif command -v curl >/dev/null 2>&1; then
        local curl_args=(
            --fail
            --location
            --continue-at -
            --retry 20
            --retry-delay 5
            --connect-timeout 60
            --output "${output}"
        )
        if curl --help all 2>/dev/null | grep -q -- '--retry-all-errors'; then
            curl_args+=(--retry-all-errors)
        fi
        curl "${curl_args[@]}" "${url}"
    elif command -v wget >/dev/null 2>&1; then
        wget \
            --continue \
            --timeout=300 \
            --tries=0 \
            --output-document="${output}" \
            "${url}"
    else
        echo "Error: curl, wget, or aria2c is required to download PyTorch wheels." >&2
        return 1
    fi

    if ! wheel_is_valid "${output}"; then
        echo "Downloaded wheel is incomplete; re-run this script to continue it." >&2
        return 1
    fi
}

if ! command -v conda >/dev/null 2>&1; then
    echo "Error: conda was not found in PATH. Install Miniconda or Anaconda first." >&2
    exit 1
fi

if [[ "${BACKEND}" != "cuda" && "${BACKEND}" != "cpu" ]]; then
    echo "Error: backend must be either 'cuda' or 'cpu'." >&2
    echo "Usage: bash build_env.sh [ENV_NAME] [cuda|cpu]" >&2
    exit 2
fi

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
    echo "Error: this reproducibility environment currently supports Linux x86_64 only." >&2
    exit 3
fi

if [[ "${BACKEND}" == "cuda" ]]; then
    echo "Checking NVIDIA driver access..."
    check_cuda_driver
fi

if conda env list | awk 'NF && $1 !~ /^#/ {print $1}' | grep -Fxq "${ENV_NAME}"; then
    echo "Conda environment '${ENV_NAME}' already exists; continuing the installation."
else
    echo "Creating Conda environment '${ENV_NAME}' with Python 3.10..."
    run_with_retry conda create --yes --name "${ENV_NAME}" python=3.10 pip
fi

select_pypi
echo "Using Python package index: ${PYPI_INDEX}"

PIP_COMMON=(
    conda run --no-capture-output --name "${ENV_NAME}"
    python -m pip install
    --timeout 300
    --retries 10
    --index-url "${PYPI_INDEX}"
)

if [[ "${PYPI_INDEX}" != "${OFFICIAL_PYPI}" ]]; then
    PIP_COMMON+=(--extra-index-url "${OFFICIAL_PYPI}")
fi

echo "Updating pip tooling..."
run_with_retry "${PIP_COMMON[@]}" --upgrade \
    "pip<25" \
    "setuptools<70" \
    wheel

if [[ "${BACKEND}" == "cuda" ]]; then
    BUILD_TAG="cu117"
    TORCH_CHECK="import torch, torchvision, torchaudio; assert torch.__version__ == '1.13.1+cu117'; assert torchvision.__version__ == '0.14.1+cu117'; assert torchaudio.__version__ == '0.13.1+cu117'"
else
    BUILD_TAG="cpu"
    TORCH_CHECK="import torch, torchvision, torchaudio; assert torch.__version__ == '1.13.1+cpu'; assert torchvision.__version__ == '0.14.1+cpu'; assert torchaudio.__version__ == '0.13.1+cpu'"
fi

if conda run --name "${ENV_NAME}" python -c "${TORCH_CHECK}" >/dev/null 2>&1; then
    echo "The requested PyTorch stack is already installed."
else
    TORCH_FILE="torch-1.13.1+${BUILD_TAG}-cp310-cp310-linux_x86_64.whl"
    VISION_FILE="torchvision-0.14.1+${BUILD_TAG}-cp310-cp310-linux_x86_64.whl"
    AUDIO_FILE="torchaudio-0.13.1+${BUILD_TAG}-cp310-cp310-linux_x86_64.whl"

    TORCH_PATH="${WHEEL_CACHE}/${TORCH_FILE}"
    VISION_PATH="${WHEEL_CACHE}/${VISION_FILE}"
    AUDIO_PATH="${WHEEL_CACHE}/${AUDIO_FILE}"

    BASE_URL="https://download-r2.pytorch.org/whl/${BUILD_TAG}"
    run_with_retry download_wheel \
        "${BASE_URL}/torch-1.13.1%2B${BUILD_TAG}-cp310-cp310-linux_x86_64.whl" \
        "${TORCH_PATH}"
    run_with_retry download_wheel \
        "${BASE_URL}/torchvision-0.14.1%2B${BUILD_TAG}-cp310-cp310-linux_x86_64.whl" \
        "${VISION_PATH}"
    run_with_retry download_wheel \
        "${BASE_URL}/torchaudio-0.13.1%2B${BUILD_TAG}-cp310-cp310-linux_x86_64.whl" \
        "${AUDIO_PATH}"

    echo "Installing cached PyTorch wheels..."
    run_with_retry "${PIP_COMMON[@]}" \
        "${TORCH_PATH}" \
        "${VISION_PATH}" \
        "${AUDIO_PATH}"
fi

echo "Installing inference and evaluation dependencies..."
run_with_retry "${PIP_COMMON[@]}" \
    torchtext==0.14.1 \
    numpy==1.23.5 \
    scipy==1.10.1 \
    scikit-learn==1.2.2 \
    pandas==1.5.3 \
    tqdm==4.65.0 \
    tensorboard==2.12.3 \
    tabulate==0.9.0 \
    easydict==1.10 \
    einops==0.6.1 \
    fvcore==0.1.5.post20221221 \
    PyYAML==6.0.1

echo "Checking core imports..."
conda run --no-capture-output --name "${ENV_NAME}" python -c \
    "import torch, torchvision, torchtext, numpy, scipy, sklearn, pandas, tqdm, tensorboard, tabulate, easydict, einops, fvcore; print('PyTorch:', torch.__version__); print('CUDA runtime:', torch.version.cuda); print('CUDA available:', torch.cuda.is_available()); print('Core imports: OK')"

if [[ "${BACKEND}" == "cuda" ]]; then
    echo "Checking CUDA and cuBLAS execution..."
    check_cuda_runtime
fi

echo
echo "Environment '${ENV_NAME}' is ready."
echo "Activate it with: conda activate ${ENV_NAME}"
if [[ "${BACKEND}" == "cuda" ]]; then
    echo "CUDA and cuBLAS were verified with a GPU matrix multiplication."
fi
