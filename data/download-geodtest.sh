#!/bin/bash
set -e
cd "$(dirname "$0")"
if [ ! -f GeodTest.dat ]; then
    echo "Downloading GeodTest.dat..."
    curl -L -o GeodTest.dat.gz \
        https://sourceforge.net/projects/geographiclib/files/testdata/GeodTest.dat.gz/download
    gunzip GeodTest.dat.gz
    echo "Downloaded $(wc -l < GeodTest.dat) test cases"
fi
