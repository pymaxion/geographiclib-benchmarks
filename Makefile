.PHONY: all build clean run run-only cpp java go rust data analyze

DATA_FILE := data/GeodTest.dat
RESULTS_DIR := results

all: build

# Download test data if not present
data: $(DATA_FILE)

$(DATA_FILE):
	./data/download-geodtest.sh

# Build all implementations
build: build-cpp build-java build-go build-rust

build-cpp:
	cd implementations/cpp && mkdir -p build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build . --config Release

build-java:
	cd implementations/java && mvn package -q -DskipTests

build-go:
	cd implementations/go && go build -o benchmark

build-rust:
	cd implementations/rust && cargo build --release

# Clean all builds
clean:
	rm -rf implementations/cpp/build
	cd implementations/java && mvn clean -q || true
	rm -f implementations/go/benchmark
	cd implementations/rust && cargo clean || true
	rm -f $(RESULTS_DIR)/*.json

# Run all benchmarks
run: data run-cpp run-java run-go run-rust

run-cpp: build-cpp
	@mkdir -p $(RESULTS_DIR)
	./implementations/cpp/build/benchmark $(DATA_FILE) > $(RESULTS_DIR)/cpp.json
	@echo "C++ benchmark complete"

run-java: build-java
	@mkdir -p $(RESULTS_DIR)
	java -jar implementations/java/target/benchmark-1.0-SNAPSHOT.jar $(DATA_FILE) > $(RESULTS_DIR)/java.json
	@echo "Java benchmark complete"

run-go: build-go
	@mkdir -p $(RESULTS_DIR)
	./implementations/go/benchmark $(DATA_FILE) > $(RESULTS_DIR)/go.json
	@echo "Go benchmark complete"

run-rust: build-rust
	@mkdir -p $(RESULTS_DIR)
	./implementations/rust/target/release/geographiclib-benchmark $(DATA_FILE) > $(RESULTS_DIR)/rust.json
	@echo "Rust benchmark complete"

# Run analysis script
analyze:
	python3 scripts/analyze.py $(RESULTS_DIR)

# Run targets without build dependencies (for Docker where build is done separately)
run-only:
	@mkdir -p $(RESULTS_DIR)
	./implementations/cpp/build/benchmark $(DATA_FILE) > $(RESULTS_DIR)/cpp.json
	@echo "C++ benchmark complete"
	java -jar implementations/java/target/benchmark-1.0-SNAPSHOT.jar $(DATA_FILE) > $(RESULTS_DIR)/java.json
	@echo "Java benchmark complete"
	./implementations/go/benchmark $(DATA_FILE) > $(RESULTS_DIR)/go.json
	@echo "Go benchmark complete"
	./implementations/rust/target/release/geographiclib-benchmark $(DATA_FILE) > $(RESULTS_DIR)/rust.json
	@echo "Rust benchmark complete"
