# ───────────────────────────────────────────────────────────────
# CUDA-runtime base image (Ubuntu 22.04, CUDA 12.2, requires NVIDIA Container Toolkit on host)
# ───────────────────────────────────────────────────────────────
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04

# ---------- system packages ----------
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip python3-venv python3-dev \
        git curl wget ffmpeg libgl1 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ---------- isolate deps in a venv ----------
ENV VENV_PATH=/opt/venv
RUN python3 -m venv ${VENV_PATH}
ENV PATH=${VENV_PATH}/bin:$PATH

# ---------- python deps ----------
WORKDIR /workspace
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

RUN pip install gdown


# ---------- project source ----------
COPY . /workspace

# ---------- download model & avatar assets ----------
# (gdown is in requirements.txt)
RUN gdown --id 1Z8J3CglXPy3bih8vTFhL7jR0tGcsK7mF -O models/wav2lip.pth && \
    mkdir -p data/avatars && \
    gdown --id 1w7dHHpTJ-1Ikg5m7FoZkqZqQCXdHmqbW -O /tmp/avatar.tar.gz && \
    tar -xzf /tmp/avatar.tar.gz -C data/avatars && \
    rm /tmp/avatar.tar.gz

# ---------- runtime configuration ----------
EXPOSE 8010
EXPOSE 1935 8080
ENV TRANSPORT=webrtc
ENV MODEL=wav2lip
ENV AVATAR_ID=wav2lip256_avatar1

# ---------- entrypoint ----------
# Use exec-form so the Python process receives signals directly
ENTRYPOINT ["bash", "-c", "python app.py --transport ${TRANSPORT} --model ${MODEL} --avatar_id ${AVATAR_ID}"]
