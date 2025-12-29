# Multi-stage build for GeographicLib benchmarks
FROM ubuntu:24.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

# Install common dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    curl \
    git \
    wget \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install GeographicLib (C++)
RUN apt-get update && apt-get install -y libgeographic-dev && rm -rf /var/lib/apt/lists/*

# Install Java (OpenJDK 21)
RUN apt-get update && apt-get install -y openjdk-21-jdk maven && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget -q https://go.dev/dl/go1.23.4.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz && \
    rm go1.23.4.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:${PATH}"

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
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
