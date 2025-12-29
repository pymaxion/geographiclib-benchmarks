# GeographicLib Benchmarks

Benchmark comparison of geodesic calculation performance across different language implementations of [GeographicLib](https://geographiclib.sourceforge.io/).

## Languages & Libraries

| Language | Library | Version |
|----------|---------|---------|
| C++ | [GeographicLib](https://geographiclib.sourceforge.io/) | 2.3 |
| Java | [GeographicLib-Java](https://github.com/geographiclib/geographiclib-java) | 2.0 |
| Go | [geographiclib-go](https://github.com/pymaxion/geographiclib-go) | 2.1.1 |
| Rust | [geographiclib-rs](https://github.com/georust/geographiclib-rs) | 0.2.5 |

## Benchmarks

Two geodesic problems are benchmarked:

- **Direct**: Given a starting point, azimuth, and distance, find the destination point
- **Inverse**: Given two points, find the distance and azimuths between them

Each benchmark runs 500,000 test cases from the official [GeodTest.dat](https://geographiclib.sourceforge.io/C++/doc/geodesic.html#testgeod) dataset, repeated 50 times.

## Running Benchmarks

### Prerequisites

- C++: CMake, GeographicLib development headers
- Java: JDK 21+, Maven
- Go: Go 1.21+
- Rust: Rust 1.70+
- Python 3 (for analysis script)

### Local Execution

```bash
# Download test data
./data/download-geodtest.sh

# Build and run all benchmarks
make run

# Analyze results
make analyze
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
Language   Median (ms)  Relative   Library
------------------------------------------------------------
rust       92.0         1.00x      geographiclib-rs 0.2.5
cpp        98.0         1.07x      GeographicLib 2.3
go         103.0        1.12x      geographiclib-go 2.1.1
java       121.0        1.32x      GeographicLib-Java 2.0

----------------------------------------
Inverse (geodesic inverse problem)
----------------------------------------
Language   Median (ms)  Relative   Library
------------------------------------------------------------
rust       173.0        1.00x      geographiclib-rs 0.2.5
cpp        195.0        1.13x      GeographicLib 2.3
go         280.0        1.62x      geographiclib-go 2.1.1
java       292.0        1.69x      GeographicLib-Java 2.0
```

## CI/CD

GitHub Actions runs benchmarks automatically on push/PR. Results are uploaded as artifacts.

## License

MIT