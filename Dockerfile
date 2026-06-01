# =============================================================================
# SuGaR – Docker image
# Base: Ubuntu 22.04 + CUDA 12.1 (matches the 'sugar' conda environment)
#
# Layer order is optimised for build-cache efficiency:
#   1. OS packages          (changes almost never)
#   2. PyTorch              (changes almost never)
#   3. pip requirements     (changes when requirements.txt changes)
#   4. pytorch3d from git   (changes when the pinned commit changes)
#   5. CUDA submodules      (changes when submodule source changes)
#   6. Application code     (changes on every code edit  ← stays last)
# =============================================================================
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# ---------------------------------------------------------------------------
# System environment
# ---------------------------------------------------------------------------
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    CUDA_HOME=/usr/local/cuda \
    PATH="/usr/local/cuda/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}" \
    # Explicitly list target CUDA architectures so PyTorch's cpp_extension
    # never has to probe attached GPUs (build daemon has no GPU access).
    # Covers Volta (7.0), Turing (7.5), Ampere (8.0/8.6), Ada (8.9), Hopper (9.0).
    TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0+PTX"

# ---------------------------------------------------------------------------
# Stage 1 – OS-level dependencies  (invalidated only by apt changes)
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    build-essential \
    cmake \
    ninja-build \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxrender1 \
    libxext6 \
    libgomp1 \
    python3.10 \
    python3.10-dev \
    python3-pip \
    python3.10-distutils \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 \
 && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
 && python -m pip install --upgrade pip setuptools wheel

WORKDIR /app

# ---------------------------------------------------------------------------
# Stage 2 – PyTorch with CUDA 12.1  (invalidated only when torch version changes)
# ---------------------------------------------------------------------------
RUN pip install --no-cache-dir \
    torch==2.5.1+cu121 \
    torchaudio==2.5.1+cu121 \
    torchvision==0.20.1+cu121 \
    --extra-index-url https://download.pytorch.org/whl/cu121

# ---------------------------------------------------------------------------
# Stage 3 – pip requirements  (invalidated only when requirements.txt changes)
# Copy just the requirements file – no code yet.
# ---------------------------------------------------------------------------
COPY requirements.txt /app/requirements.txt

RUN grep -v -E "^(torch|torchaudio|torchvision|nvdiffrast|simple_knn|diff_gaussian_rasterization|pytorch3d)" \
        requirements.txt > /tmp/requirements_filtered.txt \
 && pip install --no-cache-dir -r /tmp/requirements_filtered.txt

# ---------------------------------------------------------------------------
# Stage 4 – pytorch3d from source  (invalidated only when the commit hash changes)
# --no-build-isolation lets setup.py import the torch already in the image.
# ---------------------------------------------------------------------------
RUN pip install --no-cache-dir --no-build-isolation \
    "git+https://github.com/facebookresearch/pytorch3d.git@c307c64c7000cd370ff379be421bd92f6dec577b"

# ---------------------------------------------------------------------------
# Stage 5 – CUDA submodules  (invalidated only when submodule source changes)
# Copy only the two submodule trees needed for compilation.
# ---------------------------------------------------------------------------
COPY nvdiffrast/ /app/nvdiffrast/
COPY gaussian_splatting/submodules/ /app/gaussian_splatting/submodules/

RUN pip install --no-cache-dir --no-build-isolation -e /app/nvdiffrast
RUN pip install --no-cache-dir --no-build-isolation -e /app/gaussian_splatting/submodules/diff-gaussian-rasterization
RUN pip install --no-cache-dir --no-build-isolation -e /app/gaussian_splatting/submodules/simple-knn

# ---------------------------------------------------------------------------
# Stage 6 – Application code  (invalidated on every code edit – cheap step)
# Copy everything else: Python packages, configs, scripts, etc.
# ---------------------------------------------------------------------------
COPY . /app

# ---------------------------------------------------------------------------
# Default values for every train_full_pipeline.py argument.
# All can be overridden at 'docker run' time with -e VAR=value.
# ---------------------------------------------------------------------------

# --- Required ---
ENV SCENE_PATH=""
ENV REGULARIZATION_TYPE="dn_consistency"

# --- Vanilla 3DGS checkpoint (optional) ---
ENV GS_OUTPUT_DIR=""

# --- Mesh extraction ---
ENV SURFACE_LEVEL="0.3"
ENV N_VERTICES_IN_MESH="1000000"
ENV PROJECT_MESH_ON_SURFACE_POINTS="True"
ENV BBOXMIN=""
ENV BBOXMAX=""
ENV CENTER_BBOX="True"

# --- Refined SuGaR ---
ENV GAUSSIANS_PER_TRIANGLE="1"
ENV REFINEMENT_ITERATIONS="15000"

# --- Textured mesh export ---
ENV EXPORT_OBJ="True"
ENV SQUARE_SIZE="8"
ENV POSTPROCESS_MESH="False"
ENV POSTPROCESS_DENSITY_THRESHOLD="0.1"
ENV POSTPROCESS_ITERATIONS="5"

# --- PLY export ---
ENV EXPORT_PLY="True"

# --- Preset configs ---
ENV LOW_POLY="False"
ENV HIGH_POLY="False"
ENV REFINEMENT_TIME=""

# --- Training iterations ---
ENV ITERATIONS="7000"

# --- Misc ---
ENV EVAL="True"
ENV GPU="0"
ENV WHITE_BACKGROUND="False"

# ---------------------------------------------------------------------------
# Entrypoint
# ---------------------------------------------------------------------------
RUN chmod +x /app/docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]
