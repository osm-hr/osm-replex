#!/bin/bash
#

#rm -rf bin/osmosis
#mkdir bin/osmosis
wget http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.zip -O bin/osmosis.zip
##unzip to bin/osmosis

#rm -rf bin/osmandmc
#mkdir bin/osmandmc
wget http://download.osmand.net/latest-night-build/OsmAndMapCreator-main.zip -O bin/osmandmc.zip
##unzip to bin/osmandmc

rm -rf bin/mkgmap
mkdir bin/mkgmap
wget -v -O - http://www.mkgmap.org.uk/snapshots/mkgmap-latest.tar.gz | tar -xz --strip=1 -C bin/mkgmap

rm -rf bin/splitter
mkdir bin/splitter
wget -v -O - http://www.mkgmap.org.uk/download/splitter-latest.tar.gz | tar -xz --strip=1 -C bin/splitter


#for later use
rm bin/osmfilter
wget http://m.m.i24.cc/osmfilter32 -O bin/osmfilter32

#for later use
rm bin/osmconvert
wget http://m.m.i24.cc/osmconvert32 -O bin/osmconvert32
