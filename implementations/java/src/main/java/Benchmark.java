import net.sf.geographiclib.Geodesic;
import net.sf.geographiclib.GeodesicData;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class Benchmark {

    static class TestCase {
        double lat1, lon1, azi1, lat2, lon2, azi2, s12, a12, m12, S12;
    }

    public static void main(String[] args) throws IOException {
        if (args.length < 1) {
            System.err.println("Usage: java Benchmark <GeodTest.dat path>");
            System.exit(1);
        }

        final int RUNS = 50;
        List<TestCase> cases = loadTestCases(args[0]);
        Geodesic geod = Geodesic.WGS84;

        // Warm-up
        benchmarkDirect(geod, cases);
        benchmarkInverse(geod, cases);

        double[] directTimes = new double[RUNS];
        double[] inverseTimes = new double[RUNS];

        for (int i = 0; i < RUNS; i++) {
            directTimes[i] = benchmarkDirect(geod, cases);
            inverseTimes[i] = benchmarkInverse(geod, cases);
        }

        // Output JSON
        System.out.println("{");
        System.out.println("  \"language\": \"java\",");
        System.out.println("  \"version\": \"" + System.getProperty("java.version") + "\",");
        System.out.println("  \"library\": \"GeographicLib-Java\",");
        System.out.println("  \"library_version\": \"2.1\",");
        System.out.println("  \"test_cases\": " + cases.size() + ",");
        System.out.println("  \"runs\": " + RUNS + ",");
        System.out.print("  \"direct_ms\": [");
        for (int i = 0; i < directTimes.length; i++) {
            System.out.printf("%.1f%s", directTimes[i], i < directTimes.length - 1 ? ", " : "");
        }
        System.out.println("],");
        System.out.print("  \"inverse_ms\": [");
        for (int i = 0; i < inverseTimes.length; i++) {
            System.out.printf("%.1f%s", inverseTimes[i], i < inverseTimes.length - 1 ? ", " : "");
        }
        System.out.println("]");
        System.out.println("}");
    }

    static List<TestCase> loadTestCases(String filepath) throws IOException {
        List<TestCase> cases = new ArrayList<>();
        try (BufferedReader reader = new BufferedReader(new FileReader(filepath))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String[] parts = line.split("\\s+");
                if (parts.length != 10) continue;
                TestCase tc = new TestCase();
                tc.lat1 = Double.parseDouble(parts[0]);
                tc.lon1 = Double.parseDouble(parts[1]);
                tc.azi1 = Double.parseDouble(parts[2]);
                tc.lat2 = Double.parseDouble(parts[3]);
                tc.lon2 = Double.parseDouble(parts[4]);
                tc.azi2 = Double.parseDouble(parts[5]);
                tc.s12 = Double.parseDouble(parts[6]);
                tc.a12 = Double.parseDouble(parts[7]);
                tc.m12 = Double.parseDouble(parts[8]);
                tc.S12 = Double.parseDouble(parts[9]);
                cases.add(tc);
            }
        }
        return cases;
    }

    static double benchmarkDirect(Geodesic geod, List<TestCase> cases) {
        long start = System.nanoTime();
        double checksum = 0;
        for (int i = 0; i < cases.size(); i++) {
            TestCase tc = cases.get(i);
            GeodesicData g = geod.Direct(tc.lat1, tc.lon1, tc.azi1, tc.s12);
            checksum += g.lat2;
        }
        long end = System.nanoTime();
        if (checksum == Double.NaN) System.err.print(""); // Prevent optimization
        return (end - start) / 1_000_000.0;
    }

    static double benchmarkInverse(Geodesic geod, List<TestCase> cases) {
        long start = System.nanoTime();
        double checksum = 0;
        for (int i = 0; i < cases.size(); i++) {
            TestCase tc = cases.get(i);
            GeodesicData g = geod.Inverse(tc.lat1, tc.lon1, tc.lat2, tc.lon2);
            checksum += g.s12;
        }
        long end = System.nanoTime();
        if (checksum == Double.NaN) System.err.print("");
        return (end - start) / 1_000_000.0;
    }
}