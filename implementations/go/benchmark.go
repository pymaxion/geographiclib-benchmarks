package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/pymaxion/geographiclib-go/v2/geodesic"
	"gonum.org/v1/gonum/stat"
)

type TestCase struct {
	Lat1, Lon1, Azi1 float64
	Lat2, Lon2, Azi2 float64
	S12, A12, M12    float64
	S12Area          float64
}

type Result struct {
	Language       string  `json:"language"`
	Version        string  `json:"version"`
	Library        string  `json:"library"`
	LibraryVersion string  `json:"library_version"`
	TestCases      int     `json:"test_cases"`
	Runs           int     `json:"runs"`
	DirectMedian   float64 `json:"direct_us"`
	DirectStdDev   float64 `json:"direct_stddev_us"`
	InverseMedian  float64 `json:"inverse_us"`
	InverseStdDev  float64 `json:"inverse_stddev_us"`
}

func loadTestCases(filepath string) ([]TestCase, error) {
	file, err := os.Open(filepath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var cases []TestCase
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		parts := strings.Fields(scanner.Text())
		if len(parts) != 10 {
			continue
		}
		tc := TestCase{}
		tc.Lat1, _ = strconv.ParseFloat(parts[0], 64)
		tc.Lon1, _ = strconv.ParseFloat(parts[1], 64)
		tc.Azi1, _ = strconv.ParseFloat(parts[2], 64)
		tc.Lat2, _ = strconv.ParseFloat(parts[3], 64)
		tc.Lon2, _ = strconv.ParseFloat(parts[4], 64)
		tc.Azi2, _ = strconv.ParseFloat(parts[5], 64)
		tc.S12, _ = strconv.ParseFloat(parts[6], 64)
		tc.A12, _ = strconv.ParseFloat(parts[7], 64)
		tc.M12, _ = strconv.ParseFloat(parts[8], 64)
		tc.S12Area, _ = strconv.ParseFloat(parts[9], 64)
		cases = append(cases, tc)
	}
	return cases, scanner.Err()
}

// Returns time per function call in microseconds
func benchmarkDirect(cases []TestCase) float64 {
	start := time.Now()
	var checksum float64
	for i := range cases {
		r := geodesic.WGS84.Direct(cases[i].Lat1, cases[i].Lon1, cases[i].Azi1, cases[i].S12)
		checksum += r.Lat2
	}
	elapsed := time.Since(start)
	_ = checksum // Prevent optimization
	return float64(elapsed.Nanoseconds()) / float64(len(cases)) / 1000.0 // microseconds per call
}

// Returns time per function call in microseconds
func benchmarkInverse(cases []TestCase) float64 {
	start := time.Now()
	var checksum float64
	for i := range cases {
		r := geodesic.WGS84.Inverse(cases[i].Lat1, cases[i].Lon1, cases[i].Lat2, cases[i].Lon2)
		checksum += r.S12
	}
	elapsed := time.Since(start)
	_ = checksum
	return float64(elapsed.Nanoseconds()) / float64(len(cases)) / 1000.0 // microseconds per call
}

func median(data []float64) float64 {
	sorted := make([]float64, len(data))
	copy(sorted, data)
	sort.Float64s(sorted)
	return stat.Quantile(0.5, stat.Empirical, sorted, nil)
}

func stddev(data []float64) float64 {
	return stat.StdDev(data, nil)
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: benchmark <GeodTest.dat path>")
		os.Exit(1)
	}

	const RUNS = 50
	cases, err := loadTestCases(os.Args[1])
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error loading test cases:", err)
		os.Exit(1)
	}

	// Warm-up
	benchmarkDirect(cases)
	benchmarkInverse(cases)

	directTimes := make([]float64, RUNS)
	inverseTimes := make([]float64, RUNS)

	for i := 0; i < RUNS; i++ {
		directTimes[i] = benchmarkDirect(cases)
		inverseTimes[i] = benchmarkInverse(cases)
	}

	result := Result{
		Language:       "go",
		Version:        runtime.Version(),
		Library:        "geographiclib-go",
		LibraryVersion: "2.1.1",
		TestCases:      len(cases),
		Runs:           RUNS,
		DirectMedian:   math.Round(median(directTimes)*1000) / 1000,
		DirectStdDev:   math.Round(stddev(directTimes)*1000) / 1000,
		InverseMedian:  math.Round(median(inverseTimes)*1000) / 1000,
		InverseStdDev:  math.Round(stddev(inverseTimes)*1000) / 1000,
	}

	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	enc.Encode(result)
}
