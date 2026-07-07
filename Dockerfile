FROM node:24-bookworm-slim

RUN npm install -g --ignore-scripts @earendil-works/pi-coding-agent

COPY entrypoint.sh /usr/local/bin/pi-box-entrypoint
RUN chmod +x /usr/local/bin/pi-box-entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/pi-box-entrypoint"]
