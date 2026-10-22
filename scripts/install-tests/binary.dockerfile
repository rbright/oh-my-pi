# Test binary build from local source
FROM debian:bookworm-slim

# eMudhra CA compromise (https://emudhra.we-have-a-problem.com/): require the
# bookworm-security ca-certificates fix (bug 1151413). CI does not build this
# image, so it also keeps the advisory's blocklist.
RUN apt-get update && apt-get install -y curl ca-certificates unzip build-essential \
    && dpkg --compare-versions "$(dpkg-query -W -f='${Version}' ca-certificates)" ge 20250419~deb12u2 \
    && sed -i -e 's|^mozilla/emSign_ECC_Root_CA_-_G3.crt|!&|' -e 's|^mozilla/Comodo_AAA_Services_root.crt|!&|' /etc/ca-certificates.conf \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

# Install Rust — the host native addon builds through the default
# cargo/napi-rs backend, so no bazelisk is needed.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly
ENV PATH="/root/.cargo/bin:$PATH"

# Copy local repo
WORKDIR /repo
COPY . .

# Build native addon and binary
RUN bun install --frozen-lockfile
RUN bun --cwd=packages/natives run build
RUN cd packages/coding-agent && bun run build

# Install binary to PATH
RUN mkdir -p /root/.local/bin && \
    cp packages/coding-agent/dist/omp /root/.local/bin/
ENV PATH="/root/.local/bin:$PATH"

# Verify
RUN HOME=/tmp/omp-home XDG_DATA_HOME=/tmp/omp-xdg omp --version
