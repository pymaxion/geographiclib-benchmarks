# GeographicLib benchmarks
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install all dependencies (apt-get update is required once to populate package lists)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    pkg-config \
    curl \
    ca-certificates \
    wget \
    python3 \
    libgeographiclib-dev \
    libboost-dev \
    openjdk-17-jdk-headless \
    maven \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.25
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then GOARCH="arm64"; else GOARCH="amd64"; fi && \
    wget -q https://go.dev/dl/go1.25.4.linux-${GOARCH}.tar.gz && \
    tar -C /usr/local -xzf go1.25.4.linux-${GOARCH}.tar.gz && \
    rm go1.25.4.linux-${GOARCH}.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /benchmark

# Copy source code
COPY . .

# Download test data
RUN ./data/download-geodtest.sh

# Build all implementations
RUN make build

# Default command runs all benchmarks
CMD ["make", "run", "analyze"]
