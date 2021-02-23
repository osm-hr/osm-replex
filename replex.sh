#!/bin/bash
#

#time setup
today=$(date +"%Y%m%d")
yesterday=$(date +"%Y%m%d" --date='yesterday')
daysago=$(date +"%Y%m%d" --date='2 day ago')
olddate=$(date +"%Y%m%d" --date='30 days ago')
#hour in day, needed for daiyl export vs regular export
hour=$(date +%H)
#simulates midnight for testing
#hour=00
#first day of month, needed for monthly export
dayom01=$(date +%d)
#simulates firsf of month for testing
#dayom01=01

#replex folders
REPLEX=/osm/osm-replex
EUROPE=$REPLEX/europe
DATA=$REPLEX/data
CACHE=$REPLEX/cache
POLY=$REPLEX/poly
STATS=$REPLEX/stats
#www-data folders
WEB=/osm/www-data
PBF=$WEB/osm
FLOODS=$WEB/floods
GIS=$WEB/gis_exports
#www-tms folders
TMS=/osm/www-tms
#aplikacije
osmosis=$REPLEX/bin/osmosis/bin/osmosis
osmconvert=$REPLEX/bin/osmconvert
osmfilter=$REPLEX/bin/osmfilter
MKGMAP=$REPLEX/bin/mkgmap/mkgmap.jar
SPLITTER=$REPLEX/bin/splitter/splitter.jar
OSMANDMC=$REPLEX/bin/osmandmc
OGR2OGR=/usr/bin/ogr2ogr
#Ram za java aplikacije
RAM=5G
#fajlovi
LOG=$REPLEX/replex.log
CHANGESET=changeset-hour.osc.gz
CHANGESETSIMPLE=changeset-hour-simple.osc.gz
#statistike
korisnici=$STATS/korisnici.txt
korisnici_n=$STATS/korisnici_n.txt
korisnici_wr=$STATS/korisnici_wr.txt
svikorisnici=$STATS/korisnici_svi.txt
korpod=$STATS/korisnici_podatci.txt
korstat1=$STATS/korisnici_statistike_1.txt
korstat2=$STATS/korisnici_statistike_2.txt
statistike=$STATS/statistike.htm

#OLDSTATE=state.txt
OLDTIMESTAMP=$(cat state.txt | grep timestamp | awk -F "=" '{print $2}')
OLDYEAR=${OLDTIMESTAMP:0:4}
OLDMONTH=${OLDTIMESTAMP:5:2}
OLDDAY=${OLDTIMESTAMP:8:2}
OLDHOUR=${OLDTIMESTAMP:11:2}
OLDMINUTE=${OLDTIMESTAMP:15:2}
OLDSECOND=${OLDTIMESTAMP:19:2}

echo "===== Replication S T A R T ====="  >> $LOG
echo `date +%Y-%m-%d\ %H:%M:%S`" - Starting script" >> $LOG
start_time0=`date +%s`

############################################
## Downloading changeset from laste state.txt ##
############################################

#Downloading changeset and sorting
echo `date +%Y-%m-%d\ %H:%M:%S`" - Downloading changeset" >> $LOG
$osmosis --rri workingDirectory=$REPLEX --sort-change --wxc $REPLEX/$CHANGESET
EXITSTATUS=$?
echo `date +%Y-%m-%d\ %H:%M:%S`" - Exit state:" $EXITSTATUS >> $LOG
if [[ $EXITSTATUS -ne 0 ]] ; then
    echo `date +%Y-%m-%d\ %H:%M:%S`" - Prekidam procesiranje" >> $LOG
    exit 1
fi

end_time=`date +%s`
lasted="$(( $end_time - $start_time0 ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Changeset finished in" $lasted "seconds." >> $LOG

#print date from state.txt to log
awk '{if (NR!=1) {print}}' $REPLEX/state.txt >> $LOG

#########################
## Simplyfy changeset ##
#########################

#Simplify changeset
echo `date +%Y-%m-%d\ %H:%M:%S`" - Simplyfy changeset" >> $LOG
start_time=`date +%s`
$osmosis --read-xml-change file="$REPLEX/$CHANGESET" --simplify-change --write-xml-change file="$REPLEX/$CHANGESETSIMPLE"
end_time=`date +%s`
lasted="$(( $end_time - $start_time ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Changeset simplified in" $lasted "seconds." >> $LOG


############################################
## Primjena changeseta uz rezanje granice ##
############################################

#Primjena changeseta uz rezanje granice
echo `date +%Y-%m-%d\ %H:%M:%S`" - Apply changeset to europe file" >> $LOG
start_time=`date +%s`
$osmosis --read-xml-change file="$REPLEX/$CHANGESETSIMPLE" --read-pbf file="$EUROPE/europe-east.osm.pbf" --apply-change --bounding-polygon clipIncompleteEntities="true" file="$POLY/europe-east.poly" --write-pbf file="$REPLEX/europe-east.osm.pbf"
end_time=`date +%s`
lasted="$(( $end_time - $start_time ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Changeset applied and cropped in" $lasted "seconds." >> $LOG


############################################
## backup europe-east.osm.pbf i state.txt ##
############################################
start_time=`date +%s`
#remove changesets
rm $REPLEX/$CHANGESET
rm $REPLEX/$CHANGESETSIMPLE
echo `date +%Y-%m-%d\ %H:%M:%S`" - Changesets removed." >> $LOG

#move new europe file over old one and copy it to web
mv $REPLEX/europe-east.osm.pbf $EUROPE/europe-east.osm.pbf; cp -p $EUROPE/europe-east.osm.pbf $PBF/europe-east.osm.pbf
#copy state file to web
cp -p $REPLEX/state.txt $PBF/state.txt
echo `date +%Y-%m-%d\ %H:%M:%S`" - Europe and state.txt copied to web." >> $LOG

###################################################
## dnevni backup europe-east.osm.pbf i state.txt ##
###################################################

#only once a day at midnight instance
if [ $hour -eq 00 ]
  then
  #create state.txt dated backup
  cp -p $REPLEX/state.txt $EUROPE/$yesterday-state.txt
  #create europe file dated backup and copy europe file to data for daily garmin generation
  cp -p $EUROPE/europe-east.osm.pbf $EUROPE/$yesterday-europe-east.osm.pbf; cp -p $EUROPE/europe-east.osm.pbf $DATA/europe-east.osm.pbf
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Europe and state.txt backup created. Europe copied." >> $LOG

  if [ $dayom01 -eq 01 ]
   then
   #copy europe dated backup to web monthly folder
   cp -p $EUROPE/$yesterday-europe-east.osm.pbf $WEB/monthly/$yesterday-europe-east.osm.pbf
   echo `date +%Y-%m-%d\ %H:%M:%S`" - Europe monthly archive copied to web." >> $LOG
  fi
  
  #remove old dated europe backups
  rm $EUROPE/$olddate-europe-east.osm.pbf
fi

chmod -R 755 $EUROPE

end_time=`date +%s`
lasted="$(( $end_time - $start_time ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Backup finished in" $lasted "seconds." >> $LOG

#####################
## osm.pbf exporti ##
#####################

echo `date +%Y-%m-%d\ %H:%M:%S`" - PBF export starting." >> $LOG

#izvlaci drzavu iz europe ########################
for drzava in croatia 
do
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" export started" >> $LOG
  start_time=`date +%s`
  $osmosis --read-pbf file="$EUROPE/europe-east.osm.pbf" --bounding-polygon clipIncompleteEntities="true" file="$POLY/$drzava.poly" --write-pbf   file="$DATA/$drzava.osm.pbf"; cp -p $DATA/$drzava.osm.pbf $PBF/$drzava.osm.pbf
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" PBF export finished in" $lasted "seconds." >> $LOG
done

if [ $hour -eq 00 ]; then
for drzava in albania bosnia-herzegovina bulgaria hungary kosovo macedonia montenegro romania serbia slovenia 
do
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" export started" >> $LOG
  start_time=`date +%s`
  $osmosis --read-pbf file="$EUROPE/europe-east.osm.pbf" --bounding-polygon clipIncompleteEntities="true" file="$POLY/$drzava.poly" --write-pbf   file="$DATA/$drzava.osm.pbf"; cp -p $DATA/$drzava.osm.pbf $PBF/$drzava.osm.pbf
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" PBF export finished in" $lasted "seconds." >> $LOG
done
fi

echo `date +%Y-%m-%d\ %H:%M:%S`" - PBF export finished." >> $LOG

#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  start_time=`date +%s`
  then
  ##kopira croatia sa datumom ######################
  cp -p $PBF/croatia.osm.pbf $WEB/croatia/archive/$yesterday-croatia.osm.pbf
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia daily archive created." >> $LOG
  ## izvlaci dnevni changeset ######################
  $osmosis --read-pbf file="$WEB/croatia/archive/$daysago-croatia.osm.pbf" --read-pbf file="$WEB/croatia/archive/$yesterday-croatia.osm.pbf" --derive-change --write-xml-change compressionMethod=gzip file="$WEB/croatia/archive/$daysago-$yesterday-croatia.osc.gz"
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia diff finished in" $lasted "seconds." >> $LOG
  if [ $dayom01 -eq 01 ]
   then
   for drzava in albania bosnia-herzegovina bulgaria hungary kosovo macedonia montenegro romania serbia slovenia
    do
      #copy drzava monthly backup
      cp -p $PBF/$drzava.osm.pbf $WEB/$drzava/archive/$yesterday-$drzava.osm.pbf
      echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" monthly archive created." >> $LOG
    done
  fi
fi

#####################
## gpkg exporti ##
#####################

echo `date +%Y-%m-%d\ %H:%M:%S`" - GPKG export starting." >> $LOG

for drzava in croatia 
do
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" GPKG export started" >> $LOG
  start_time=`date +%s`
  $OGR2OGR -f GPKG $CACHE/$drzava.gpkg $DATA/$drzava.osm.pbf
  zip -m -j $CACHE/$drzava.gpkg.zip $CACHE/$drzava.gpkg
  mv $CACHE/$drzava.gpkg.zip $GIS/
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" GPKG export finished in" $lasted "seconds." >> $LOG
done

if [ $hour -eq 00 ]; then
for drzava in albania bosnia-herzegovina bulgaria hungary kosovo macedonia montenegro romania serbia slovenia 
do
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" GPKG export started" >> $LOG
  start_time=`date +%s`
  $OGR2OGR -f GPKG $CACHE/$drzava.gpkg $DATA/$drzava.osm.pbf
  zip -m -j $CACHE/$drzava.gpkg.zip $CACHE/$drzava.gpkg
  mv $CACHE/$drzava.gpkg.zip $GIS/
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" GPKG export finished in" $lasted "seconds." >> $LOG
done
fi

echo `date +%Y-%m-%d\ %H:%M:%S`" - GPKG export finished." >> $LOG



####################
## Garmin exporti ##
####################

#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  then
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Garmin export starting." >> $LOG
  mapid=90000001
  for drzava in europe-east albania bosnia-herzegovina bulgaria croatia hungary kosovo macedonia montenegro romania serbia slovenia
  do
    echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" garmin export started" >> $LOG
    start_time=`date +%s`
    rm $CACHE/*
    java -Xmx$RAM -jar $SPLITTER --output-dir=$CACHE --mapid=$mapid --cache=$CACHE $DATA/$drzava.osm.pbf 
    java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --index --gmapsupp --series-name="OSM $drzava - d1" --family-name="OSM $drzava" --country-name="$drzava" --remove-short-arcs --net --route --generate-sea:no-sea-sectors,extend-sea-sectors $CACHE/90*.osm.pbf
    mv $CACHE/gmapsupp.img $WEB/garmin/$drzava-gmapsupp.img
    zip -j $DATA/$drzava-garmin.zip $CACHE/*90*.img $CACHE/osmmap.*
    mv $DATA/$drzava-garmin.zip $WEB/garmin/$drzava-garmin.zip
    mapid=$(($mapid + 10000))
    end_time=`date +%s`
    lasted="$(( $end_time - $start_time ))"
    echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" Garmin export finished in" $lasted "seconds." >> $LOG
  done

  ##spajanje topo i gmapsupp
  rm $CACHE/*
  java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --gmapsupp $WEB/garmin/$drzava-gmapsupp.img $WEB/garmin/croatia-topo25m.img
  mv $CACHE/gmapsupp.img $WEB/garmin/croatia-topo25m-gmapsupp.img
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia topo25 finished." >> $LOG
  rm $CACHE/*
  java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --gmapsupp $WEB/garmin/$drzava-gmapsupp.img $WEB/garmin/croatia-topo10m.img
  mv $CACHE/gmapsupp.img $WEB/garmin/croatia-topo10m-gmapsupp.img
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia topo10 finished." >> $LOG

  #deleting europe because we don't want it in osmand generation
  rm $DATA/europe-east.osm.pbf
  
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Garmin export finished." >> $LOG
fi

####################
## OsmAnd exporti ##
####################

#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  then
  #osmand karte 
  start_time=`date +%s`

  echo `date +%Y-%m-%d\ %H:%M:%S`" - OsmAnd export starting." >> $LOG
 
  #cd $OSMANDMCMC
  #java -Djava.util.logging.config.file=$REPLEX/logging.properties -Xms64M -Xmx$RAM -cp "$OSMANDMC/OsmAndMapCreator.jar:$OSMANDMC/lib/OsmAnd-core.jar:$OSMANDMC/lib/*.jar" net.osmand.data.index.IndexBatchCreator $REPLEX/batch.xml
  java -Xmx$RAM -cp "$OSMANDMC/OsmAndMapCreator.jar:$OSMANDMC/lib/OsmAnd-core.jar:$OSMANDMC/lib/*.jar" net.osmand.util.IndexBatchCreator $REPLEX/osmandmc.xml
  mv $DATA/*.obf* $WEB/osmand

  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - OsmAnd export finished in" $lasted "seconds." >> $LOG
fi

rm $CACHE/*

############################
## Statistike za hrvatsku ##
############################

#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  then
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Croatia statistics starting." >> $LOG

  start_time=`date +%s`
  for drzava in croatia
  do
    $osmconvert --out-statistics $PBF/$drzava.osm.pbf > $STATS/$drzava-stats.txt
    TOTAL_NODE=`cat $STATS/$drzava-stats.txt | grep nodes | awk -F ' ' '{print $2}'`
    TOTAL_WAY=`cat $STATS/$drzava-stats.txt | grep ways | awk -F ' ' '{print $2}'`
    TOTAL_RELATION=`cat $STATS/$drzava-stats.txt | grep relations | awk -F ' ' '{print $2}'`
    #country total stats
    echo $yesterday,'empty,'$TOTAL_NODE','$TOTAL_WAY','$TOTAL_RELATION >> $WEB/$drzava/stats/$drzava-total.csv
    #next 2lines to be replaced with symlink on server
    cp -p $WEB/$drzava/stats/$drzava-total.csv $WEB/$drzava/$drzava-total.csv
    cp -p $WEB/$drzava/stats/$drzava-total.csv $WEB/statistics/$drzava-total.csv
    echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" csv files created and copied to web." >> $LOG
  done

  ##statistike i za ostale drzave
  ##############################################################
  if [ $dayom01 -eq 01 ]
  then
    for drzava in albania bosnia-herzegovina bulgaria hungary kosovo macedonia montenegro romania serbia slovenia
    do
      $osmconvert --out-statistics $PBF/$drzava.osm.pbf > $STATS/$drzava-stats.txt
      TOTAL_NODE=`cat $STATS/$drzava-stats.txt | grep nodes | awk -F ' ' '{print $2}'`
      TOTAL_WAY=`cat $STATS/$drzava-stats.txt | grep ways | awk -F ' ' '{print $2}'`
      TOTAL_RELATION=`cat $STATS/$drzava-stats.txt | grep relations | awk -F ' ' '{print $2}'`
      #country total stats
      echo $yesterday,'empty,'$TOTAL_NODE','$TOTAL_WAY','$TOTAL_RELATION >> $WEB/$drzava/stats/$drzava-total.csv
      #next 2lines to be replaced with symlink on server
      cp -p $WEB/$drzava/stats/$drzava-total.csv $WEB/$drzava/$drzava-total.csv
      cp -p $WEB/$drzava/stats/$drzava-total.csv $WEB/statistics/$drzava-total.csv
    echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" csv files created and copied to web." >> $LOG
    done

  fi
  echo `date +%Y-%m-%d\ %H:%M:%S`" - All statistics finished." >> $LOG
fi

chmod -R 755 $WEB

#complete duration of the script
end_time=`date +%s`
lasted="$(( $end_time - $start_time0 ))"
echo `date +%Y-%m-%d\ %H:%M:%S`" - Complete script finished in" $lasted "seconds." >> $LOG    
echo "===== Replication E N D====="  >> $LOG
