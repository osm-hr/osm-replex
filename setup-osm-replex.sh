#!/bin/bash
#

##ubuntu 14.04.1 clean install
#sudo apt-get install zip unzip openjdk-7-jre

REPLEX=/osm/osm-replex

mkdir $REPLEX/bin
mkdir $REPLEX/cache
mkdir $REPLEX/data
mkdir $REPLEX/europe

wget http://data.osm-hr.org/osm/europe-east.osm.pbf -O $REPLEX/europe/europe-east.osm.pbf
wget http://data.osm-hr.org/osm/state.txt -O -O $REPLEX/state.txt

#after initial setup run update to get binaries
