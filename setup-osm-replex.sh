#!/bin/bash
#

##ubuntu 14.04.1 clean install
#sudo apt-get install zip unzip openjdk-7-jre

##ubuntu 18.04.1 clean install
#sudo apt-get install zip unzip openjdk-8-jre zlib1g-dev gdal-bin gcc

REPLEX=/osm/osm-replex

mkdir $REPLEX/bin
mkdir $REPLEX/cache
mkdir $REPLEX/data
mkdir $REPLEX/europe
mkdir $REPLEX/stats

wget http://data.osm-hr.org/osm/europe-east.osm.pbf -O $REPLEX/europe/europe-east.osm.pbf
wget http://data.osm-hr.org/osm/state.txt -O $REPLEX/state.txt

#after initial setup run update to get binaries
