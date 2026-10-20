# Test --source install from local repo
FROM debian:bookworm-slim

# The sed distrusts the roots above the compromised eMudhra intermediates
# (https://emudhra.we-have-a-problem.com/) until Debian ships a fix (bug 1151413).
RUN apt-get update && apt-get install -y curl ca-certificates unzip build-essential \
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

# Install dependencies, build native addon, and link globally
RUN bun install --frozen-lockfile
RUN bun --cwd=packages/natives run build
RUN cd packages/coding-agent && bun link

# Verify
RUN omp --version
