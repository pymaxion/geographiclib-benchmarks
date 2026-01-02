# GeographicLib Benchmarks

[![Run Benchmarks](https://github.com/pymaxion/geographiclib-benchmarks/actions/workflows/benchmark.yml/badge.svg)](https://github.com/pymaxion/geographiclib-benchmarks/actions/workflows/benchmark.yml)

**Direct problem (500k cases):**
![Rust](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/pymaxion/84e9bf15fe8b3994c6608d5c5d5344e7/raw/rust-direct.json)
![C++](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/pymaxion/84e9bf15fe8b3994c6608d5c5d5344e7/raw/cpp-direct.json)
![Java](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/pymaxion/84e9bf15fe8b3994c6608d5c5d5344e7/raw/java-direct.json)
![Go](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/pymaxion/84e9bf15fe8b3994c6608d5c5d5344e7/raw/go-direct.json)

**Inverse problem (500k cases):**
![Rust](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/pymaxion/84e9bf15fe8b3994c6608d5c5d5344e7/raw/rust-inverse.json)
![C++](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/pymaxion/84e9bf15fe8b3994c6608d5c5d5344e7/raw/cpp-inverse.json)
![Java](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/pymaxion/84e9bf15fe8b3994c6608d5c5d5344e7/raw/java-inverse.json)
![Go](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/pymaxion/84e9bf15fe8b3994c6608d5c5d5344e7/raw/go-inverse.json)

Benchmark comparison of geodesic calculation performance across different language implementations of [GeographicLib](https://geographiclib.sourceforge.io/).

## Languages & Libraries

| Language | Library | Version |
|----------|---------|---------|
| C++ | [GeographicLib](https://geographiclib.sourceforge.io/) | 2.5 |
| Java | [GeographicLib-Java](https://github.com/geographiclib/geographiclib-java) | 2.1 |
| Go | [geographiclib-go](https://github.com/pymaxion/geographiclib-go) | 2.1.1 |
| Rust | [geographiclib-rs](https://github.com/georust/geographiclib-rs) | 0.2.5 |

## Benchmarks

Two geodesic problems are benchmarked:

- **Direct**: Given a starting point, azimuth, and distance, find the destination point
- **Inverse**: Given two points, find the distance and azimuths between them

Each benchmark runs 500,000 test cases from the official [GeodTest.dat](https://geographiclib.sourceforge.io/C++/doc/geodesic.html#testgeod) dataset, repeated 50 times.

## Running Benchmarks

### Prerequisites

- C++: CMake, GeographicLib development headers, Boost
- Java: JDK 11+, Maven
- Go: Go 1.25+
- Rust: Rust 1.70+
- Python 3 (for analysis script)

### Local Execution

```bash
# Build, run, and analyze all benchmarks
make run analyze
```

### Docker

```bash
docker build -t geographiclib-benchmarks .
docker run --rm geographiclib-benchmarks
```

### Individual Benchmarks

```bash
# Build specific implementation
make build-cpp
make build-java
make build-go
make build-rust

# Run specific benchmark
make run-cpp
make run-java
make run-go
make run-rust
```

## Results

Results are stored as JSON in the `results/` directory. The analysis script produces a summary like:

```
================================================================================
GeographicLib Benchmark Results
================================================================================

Test cases: 500,000
Runs per benchmark: 50

----------------------------------------
Direct (geodesic forward problem)
----------------------------------------
Language   Median (ms)    StdDev     Relative   Library
--------------------------------------------------------------------------------
rust       86.66          ±0.72      1.00x      geographiclib-rs 0.2.5
cpp        98.46          ±0.62      1.14x      GeographicLib 2.5
java       144.17         ±6.73      1.66x      GeographicLib-Java 2.1
go         158.12         ±2.10      1.82x      geographiclib-go 2.1.1

----------------------------------------
Inverse (geodesic inverse problem)
----------------------------------------
Language   Median (ms)    StdDev     Relative   Library
--------------------------------------------------------------------------------
rust       175.40         ±1.83      1.00x      geographiclib-rs 0.2.5
cpp        185.21         ±1.65      1.06x      GeographicLib 2.5
go         304.85         ±1.89      1.74x      geographiclib-go 2.1.1
java       326.59         ±6.10      1.86x      GeographicLib-Java 2.1
```

## CI/CD

GitHub Actions runs benchmarks automatically on push/PR. Results are uploaded as artifacts.

## License

MIT
