# User image customisations
FROM pi-box:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        jq \
        git \
        gh \
        ripgrep \
        fd-find \
        python3 \
        python3-pip \
        zip \
        unzip \
        tree \
        procps \
        file \
        xxd
RUN rm -rf /var/lib/apt/lists/*

RUN npm install -g --ignore-scripts \
    fallow
