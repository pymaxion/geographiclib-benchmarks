#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <chrono>
#include <cmath>
#include <iomanip>

#include <GeographicLib/Geodesic.hpp>

using namespace std;
using namespace GeographicLib;
using namespace std::chrono;

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
    return duration<double, milli>(end - start).count();
}

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
    return duration<double, milli>(end - start).count();
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        cerr << "Usage: " << argv[0] << " <GeodTest.dat path>" << endl;
        return 1;
    }

    const int RUNS = 5;
    auto cases = loadTestCases(argv[1]);
    const Geodesic& geod = Geodesic::WGS84();

    // Warm-up
    benchmarkDirect(geod, cases);
    benchmarkInverse(geod, cases);

    vector<double> directTimes, inverseTimes;
    for (int i = 0; i < RUNS; i++) {
        directTimes.push_back(benchmarkDirect(geod, cases));
        inverseTimes.push_back(benchmarkInverse(geod, cases));
    }

    // Output JSON
    cout << "{" << endl;
    cout << "  \"language\": \"cpp\"," << endl;
    cout << "  \"version\": \"" << __cplusplus << "\"," << endl;
    cout << "  \"library\": \"GeographicLib\"," << endl;
    cout << "  \"library_version\": \"" << GEOGRAPHICLIB_VERSION_STRING << "\"," << endl;
    cout << "  \"test_cases\": " << cases.size() << "," << endl;
    cout << "  \"runs\": " << RUNS << "," << endl;
    cout << "  \"direct_ms\": [";
    for (size_t i = 0; i < directTimes.size(); i++) {
        cout << fixed << setprecision(1) << directTimes[i];
        if (i < directTimes.size() - 1) cout << ", ";
    }
    cout << "]," << endl;
    cout << "  \"inverse_ms\": [";
    for (size_t i = 0; i < inverseTimes.size(); i++) {
        cout << fixed << setprecision(1) << inverseTimes[i];
        if (i < inverseTimes.size() - 1) cout << ", ";
    }
    cout << "]" << endl;
    cout << "}" << endl;

    return 0;
}
