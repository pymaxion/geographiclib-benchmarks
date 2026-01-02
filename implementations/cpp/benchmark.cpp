#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <chrono>
#include <iomanip>

#include <GeographicLib/Geodesic.hpp>
#include <boost/accumulators/accumulators.hpp>
#include <boost/accumulators/statistics/stats.hpp>
#include <boost/accumulators/statistics/median.hpp>
#include <boost/accumulators/statistics/variance.hpp>

using namespace std;
using namespace GeographicLib;
using namespace std::chrono;
namespace ba = boost::accumulators;

struct TestCase {
    double lat1, lon1, azi1, lat2, lon2, azi2, s12, a12, m12, S12;
};

vector<TestCase> loadTestCases(const string& filepath) {
    vector<TestCase> cases;
    ifstream file(filepath);
    string line;
    while (getline(file, line)) {
        istringstream iss(line);
        TestCase tc;
        iss >> tc.lat1 >> tc.lon1 >> tc.azi1 >> tc.lat2 >> tc.lon2
            >> tc.azi2 >> tc.s12 >> tc.a12 >> tc.m12 >> tc.S12;
        cases.push_back(tc);
    }
    return cases;
}

// Returns time per function call in microseconds
double benchmarkDirect(const Geodesic& geod, const vector<TestCase>& cases) {
    auto start = high_resolution_clock::now();
    double checksum = 0;
    for (const auto& tc : cases) {
        double lat2, lon2, azi2;
        geod.Direct(tc.lat1, tc.lon1, tc.azi1, tc.s12, lat2, lon2, azi2);
        checksum += lat2;
    }
    auto end = high_resolution_clock::now();
    volatile double v = checksum;
    (void)v;
    return duration<double, micro>(end - start).count() / cases.size();
}

// Returns time per function call in microseconds
double benchmarkInverse(const Geodesic& geod, const vector<TestCase>& cases) {
    auto start = high_resolution_clock::now();
    double checksum = 0;
    for (const auto& tc : cases) {
        double s12;
        geod.Inverse(tc.lat1, tc.lon1, tc.lat2, tc.lon2, s12);
        checksum += s12;
    }
    auto end = high_resolution_clock::now();
    volatile double v = checksum;
    (void)v;
    return duration<double, micro>(end - start).count() / cases.size();
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <GeodTest.dat path>" << endl;
        return 1;
    }

    const int RUNS = 50;
    auto cases = loadTestCases(argv[1]);
    const Geodesic& geod = Geodesic::WGS84();

    // Warm-up
    benchmarkDirect(geod, cases);
    benchmarkInverse(geod, cases);

    ba::accumulator_set<double, ba::stats<ba::tag::median, ba::tag::variance>> directAcc;
    ba::accumulator_set<double, ba::stats<ba::tag::median, ba::tag::variance>> inverseAcc;

    for (int i = 0; i < RUNS; i++) {
        directAcc(benchmarkDirect(geod, cases));
        inverseAcc(benchmarkInverse(geod, cases));
    }

    // Output JSON
    cout << "{" << endl;
    cout << "  \"language\": \"cpp\"," << endl;
    cout << "  \"version\": \"" << __cplusplus << "\"," << endl;
    cout << "  \"library\": \"GeographicLib\"," << endl;
    cout << "  \"library_version\": \"" << GEOGRAPHICLIB_VERSION_STRING << "\"," << endl;
    cout << "  \"test_cases\": " << cases.size() << "," << endl;
    cout << "  \"runs\": " << RUNS << "," << endl;
    cout << fixed << setprecision(3);
    cout << "  \"direct_us\": " << ba::median(directAcc) << "," << endl;
    cout << "  \"direct_stddev_us\": " << sqrt(ba::variance(directAcc)) << "," << endl;
    cout << "  \"inverse_us\": " << ba::median(inverseAcc) << "," << endl;
    cout << "  \"inverse_stddev_us\": " << sqrt(ba::variance(inverseAcc)) << endl;
    cout << "}" << endl;

    return 0;
}
