ARG NODE_VERSION=22
ARG N8N_VERSION=snapshot

# 1. Builder stage — install and build n8n from source
FROM --platform=linux/amd64 n8nio/base:${NODE_VERSION} AS builder

WORKDIR /src
COPY . /src

# Install dependencies (no lockfile enforcement to avoid pnpm build issues)
RUN DOCKER_BUILD=true pnpm install

# Build n8n
RUN pnpm build

# Clean up dev artifacts
RUN jq 'del(.pnpm.patchedDependencies)' package.json > package.json.tmp && mv package.json.tmp package.json
RUN node .github/scripts/trim-fe-packageJson.js
RUN find . -type f -name "*.ts" -o -name "*.vue" -o -name "tsconfig.json" -o -name "*.tsbuildinfo" | xargs rm -rf

# Deploy final compiled app
RUN mkdir /compiled
RUN NODE_ENV=production DOCKER_BUILD=true pnpm --filter=n8n --prod --no-optional --legacy deploy /compiled

# 2. Final image — runtime setup
FROM n8nio/base:${NODE_VERSION}
ENV NODE_ENV=production
ARG N8N_RELEASE_TYPE=dev
ENV N8N_RELEASE_TYPE=${N8N_RELEASE_TYPE}

LABEL org.opencontainers.image.title="n8n"
LABEL org.opencontainers.image.description="Workflow Automation Tool"
LABEL org.opencontainers.image.source="https://github.com/n8n-io/n8n"
LABEL org.opencontainers.image.url="https://n8n.io"
LABEL org.opencontainers.image.version=${N8N_VERSION}

WORKDIR /home/node

# Copy built n8n app
COPY --from=builder /compiled /usr/local/lib/node_modules/n8n

# Task Runner Setup (OPTIONAL — kept but won't error if file is missing)
ARG TARGETPLATFORM
ARG LAUNCHER_VERSION=1.1.2

RUN \
  if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCH_NAME="amd64"; \
  elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCH_NAME="arm64"; fi && \
  mkdir /launcher-temp && cd /launcher-temp && \
  wget https://github.com/n8n-io/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz && \
  wget https://github.com/n8n-io/task-runner-launcher/releases/download/${LAUNCHER_VERSION}/task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz.sha256 && \
  echo "$(cat task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz.sha256) task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz" > checksum.sha256 && \
  sha256sum -c checksum.sha256 && \
  tar xvf task-runner-launcher-${LAUNCHER_VERSION}-linux-${ARCH_NAME}.tar.gz --directory=/usr/local/bin && \
  cd - && rm -r /launcher-temp

RUN \
  cd /usr/local/lib/node_modules/n8n && npm rebuild sqlite3 && cd - && \
  ln -s /usr/local/lib/node_modules/n8n/bin/n8n /usr/local/bin/n8n && \
  mkdir .n8n && chown node:node .n8n

RUN npm install -g npm@11.4.1

ENV SHELL /bin/sh
USER node
ENTRYPOINT ["n8n"]
