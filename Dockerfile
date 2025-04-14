# FROM pytorch/pytorch:2.5.1-cuda12.1-cudnn9-devel as compile_server
FROM pytorch/pytorch:2.6.0-cuda12.6-cudnn9-devel as compile_server

ARG CPU_INSTRUCT=NATIVE

# 设置工作目录和 CUDA 路径
WORKDIR /workspace
ENV CUDA_HOME=/usr/local/cuda

# 安装依赖
RUN apt update -y && apt install -y apt-utils && apt upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt update -y && apt install -y --no-install-recommends \
    libtbb-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libaio1 \
    libaio-dev \
    libfmt-dev \
    libgflags-dev \
    zlib1g-dev \
    patchelf \
    git \
    wget \
    vim \
    gcc \
    g++  && apt-get clean && rm -rf /var/lib/apt/lists/*

# 安装CMake
RUN wget https://github.com/Kitware/CMake/releases/download/v4.0.1/cmake-4.0.1-linux-x86_64.sh && echo y | bash cmake-4.0.1-linux-x86_64.sh && rm -rf cmake-4.0.1-linux-x86_64.sh

# 克隆代码
RUN git clone https://github.com/kvcache-ai/ktransformers.git 

# 进入项目目录
WORKDIR /workspace/ktransformers
# 初始化子模块
RUN git submodule update --init --recursive

# 升级 pip
RUN pip install --upgrade pip && pip install -U wheel setuptools ninja pyproject numpy cpufeature aiohttp zmq openai flash-attn && pip cache purge

# 安装 ktransformers 本体（含编译）
RUN CPU_INSTRUCT=${CPU_INSTRUCT} \
    USE_BALANCE_SERVE=1 \
    KTRANSFORMERS_FORCE_BUILD=TRUE \
    TORCH_CUDA_ARCH_LIST="8.0;8.6;8.7;8.9;9.0+PTX" \
    pip install . --no-build-isolation --verbose && pip cache purge

RUN pip install third_party/custom_flashinfer/ && pip cache purge

# 拷贝 C++ 运行时库
RUN cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/conda/lib/

# 预下载的配置文件
# RUN pip install huggingface_hub modelscope
# RUN huggingface-cli download deepseek-ai/DeepSeek-R1 --exclude *.safetensors --local-dir /app/model/DeepSeek-R1
# RUN huggingface-cli download deepseek-ai/DeepSeek-V3-0324 --exclude *.safetensors --local-dir /app/model/DeepSeek-V3-0324
# RUN huggingface-cli download deepseek-ai/DeepSeek-V2-Lite-Chat --exclude *.safetensors --local-dir /app/model/DeepSeek-V2-Lite-Chat

# 保持容器运行（调试用）
ENTRYPOINT ["tail", "-f", "/dev/null"]
