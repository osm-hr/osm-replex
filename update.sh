#!/bin/bash
#

rm -rf bin/osmosis
mkdir bin/osmosis
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.zip -O bin/osmosis.zip
unzip bin/osmosis.zip -d bin/osmosis/
rm bin/osmosis.zip

rm -rf bin/osmandmc
mkdir bin/osmandmc
wget http://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip -O bin/osmandmc.zip
unzip bin/osmandmc.zip -d bin/osmandmc/
rm bin/osmandmc.zip

rm -rf bin/mkgmap
mkdir bin/mkgmap
wget -v -O - http://www.mkgmap.org.uk/snapshots/mkgmap-latest.tar.gz | tar -xz --strip=1 -C bin/mkgmap

rm -rf bin/splitter
mkdir bin/splitter
wget -v -O - http://www.mkgmap.org.uk/download/splitter-latest.tar.gz | tar -xz --strip=1 -C bin/splitter


#for later use
rm bin/osmfilter
#wget http://m.m.i24.cc/osmfilter32 -O bin/osmfilter32
#source&compile
wget -O - http://m.m.i24.cc/osmfilter.c |cc -x c - -O3 -o bin/osmfilter

#for later use
rm bin/osmconvert
#wget http://m.m.i24.cc/osmconvert32 -O bin/osmconvert32
#source&compile
wget -O - http://m.m.i24.cc/osmconvert.c | cc -x c - -lz -O3 -o bin/osmconvert
#In case of error with "zlib.h" not found : install zlib1g-dev 
