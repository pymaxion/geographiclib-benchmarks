use geographiclib_rs::{DirectGeodesic, Geodesic, InverseGeodesic};
use serde::Serialize;
use statrs::statistics::{Data, Distribution, Median};
use std::env;
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::process::Command;
use std::time::Instant;

fn rustc_version() -> String {
    Command::new("rustc")
        .arg("--version")
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "unknown".to_string())
}

const RUNS: usize = 50;

#[derive(Debug)]
struct TestCase {
    lat1: f64,
    lon1: f64,
    azi1: f64,
    lat2: f64,
    lon2: f64,
    s12: f64,
}

#[derive(Serialize)]
struct Result {
    language: String,
    version: String,
    library: String,
    library_version: String,
    test_cases: usize,
    runs: usize,
    direct_us: f64,
    direct_stddev_us: f64,
    inverse_us: f64,
    inverse_stddev_us: f64,
}

fn load_test_cases(filepath: &str) -> Vec<TestCase> {
    let file = File::open(filepath).expect("Failed to open file");
    let reader = BufReader::new(file);
    let mut cases = Vec::new();

    for line in reader.lines() {
        let line = line.expect("Failed to read line");
        let parts: Vec<&str> = line.split_whitespace().collect();
        if parts.len() != 10 {
            continue;
        }
        cases.push(TestCase {
            lat1: parts[0].parse().unwrap(),
            lon1: parts[1].parse().unwrap(),
            azi1: parts[2].parse().unwrap(),
            lat2: parts[3].parse().unwrap(),
            lon2: parts[4].parse().unwrap(),
            s12: parts[6].parse().unwrap(),
        });
    }
    cases
}

// Returns time per function call in microseconds
fn benchmark_direct(geod: &Geodesic, cases: &[TestCase]) -> f64 {
    let start = Instant::now();
    let mut checksum = 0.0_f64;
    for tc in cases {
        let (lat2, _, _) = geod.direct(tc.lat1, tc.lon1, tc.azi1, tc.s12);
        checksum += lat2;
    }
    let elapsed = start.elapsed();
    let _ = checksum; // Prevent optimization
    elapsed.as_secs_f64() * 1_000_000.0 / cases.len() as f64
}

// Returns time per function call in microseconds
fn benchmark_inverse(geod: &Geodesic, cases: &[TestCase]) -> f64 {
    let start = Instant::now();
    let mut checksum = 0.0_f64;
    for tc in cases {
        let s12: f64 = geod.inverse(tc.lat1, tc.lon1, tc.lat2, tc.lon2);
        checksum += s12;
    }
    let elapsed = start.elapsed();
    let _ = checksum;
    elapsed.as_secs_f64() * 1_000_000.0 / cases.len() as f64
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: benchmark <GeodTest.dat path>");
        std::process::exit(1);
    }

    let cases = load_test_cases(&args[1]);
    let geod = Geodesic::wgs84();

    // Warm-up
    benchmark_direct(&geod, &cases);
    benchmark_inverse(&geod, &cases);

    let mut direct_times = Vec::with_capacity(RUNS);
    let mut inverse_times = Vec::with_capacity(RUNS);

    for _ in 0..RUNS {
        direct_times.push(benchmark_direct(&geod, &cases));
        inverse_times.push(benchmark_inverse(&geod, &cases));
    }

    let direct_data = Data::new(direct_times.clone());
    let inverse_data = Data::new(inverse_times.clone());

    let result = Result {
        language: "rust".to_string(),
        version: rustc_version(),
        library: "geographiclib-rs".to_string(),
        library_version: "0.2.5".to_string(),
        test_cases: cases.len(),
        runs: RUNS,
        direct_us: (direct_data.median() * 1000.0).round() / 1000.0,
        direct_stddev_us: (direct_data.std_dev().unwrap_or(0.0) * 1000.0).round() / 1000.0,
        inverse_us: (inverse_data.median() * 1000.0).round() / 1000.0,
        inverse_stddev_us: (inverse_data.std_dev().unwrap_or(0.0) * 1000.0).round() / 1000.0,
    };

    println!("{}", serde_json::to_string_pretty(&result).unwrap());
}
