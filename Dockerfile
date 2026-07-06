FROM node:24-bookworm-slim

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    jq \
    tesseract-ocr \
    git \
    gh \
    ripgrep \
    fd-find \
    poppler-utils \
    ghostscript \
    imagemagick \
    ffmpeg \
    python3 \
    python3-pip \
    pandoc \
    zip \
    unzip \
    tree \
    procps \
    file \
    xxd
RUN rm -rf /var/lib/apt/lists/*
RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

WORKDIR /workspace
ENTRYPOINT ["pi"]
