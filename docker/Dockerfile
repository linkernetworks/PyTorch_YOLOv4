FROM docker.io/pytorch/pytorch:1.5.1-cuda10.1-cudnn7-devel
RUN apt-get update && apt-get install -y --no-install-recommends \
         build-essential \
         cmake \
         git \
         curl \
         ca-certificates \
         libjpeg-dev \
         libpng-dev && \
     rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/NVIDIA/apex && cd apex && pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" . --user

COPY . /workspace
RUN conda install -c conda-forge --file requirements.txt && \
     /opt/conda/bin/conda clean -ya
# RUN pip -v install git+https://github.com/thomasbrandon/mish-cuda@nasty-hack
