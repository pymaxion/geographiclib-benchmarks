# GeographicLib Multi-Language Benchmarks
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# =============================================================================
# ALL APT DEPENDENCIES (single layer for efficiency)
# =============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    ca-certificates \
    python3 \
    libboost-dev \
    openjdk-21-jdk-headless \
    maven \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# C++ TOOLCHAIN + GEOGRAPHICLIB
# =============================================================================
ARG GEOGRAPHICLIB_VERSION=2.5
RUN git clone --depth 1 --branch v${GEOGRAPHICLIB_VERSION} \
        https://github.com/geographiclib/geographiclib.git /tmp/geographiclib && \
    cd /tmp/geographiclib && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rm -rf /tmp/geographiclib

# =============================================================================
# GO TOOLCHAIN
# =============================================================================
ARG GO_VERSION=1.25.4
RUN ARCH=$(dpkg --print-architecture) && \
    curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" | tar -C /usr/local -xz
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"

# =============================================================================
# RUST TOOLCHAIN
# =============================================================================
ARG RUST_VERSION=stable
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --profile minimal --default-toolchain ${RUST_VERSION}
ENV PATH="/root/.cargo/bin:${PATH}"

# =============================================================================
# COPY SOURCE AND BUILD ALL IMPLEMENTATIONS
# =============================================================================
WORKDIR /benchmark

# Copy only what's needed for each build (ordered for cache efficiency)
# Java: pom.xml first for dependency caching
COPY implementations/java/pom.xml implementations/java/
RUN cd implementations/java && mvn dependency:go-offline -q

# Go: go.mod/go.sum first for dependency caching
COPY implementations/go/go.mod implementations/go/go.sum implementations/go/
RUN cd implementations/go && go mod download

# Rust: Cargo requires a valid src/main.rs to parse the manifest, so we create
# a dummy one to compile dependencies, then delete it before copying real source
COPY implementations/rust/Cargo.toml implementations/rust/Cargo.lock* implementations/rust/
RUN mkdir -p implementations/rust/src && \
    echo "fn main() {}" > implementations/rust/src/main.rs && \
    cd implementations/rust && cargo build --release && \
    rm -rf src target/release/geographiclib-benchmark target/release/deps/geographiclib*

# Copy all source files
COPY implementations/ implementations/
COPY scripts/ scripts/
COPY data/download-geodtest.sh data/
COPY Makefile .

# Download test data and build all implementations
RUN ./data/download-geodtest.sh && make build

# =============================================================================
# RUN BENCHMARKS
# =============================================================================
CMD ["make", "run-only", "analyze"]
