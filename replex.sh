#!/bin/bash
#

#time setup
today=$(date +"%Y%m%d")
yesterday=$(date +"%Y%m%d" --date='yesterday')
daysago=$(date +"%Y%m%d" --date='2 day ago')
olddate=$(date +"%Y%m%d" --date='10 days ago')
#hour in day, needed for daiyl export vs regular export
hour=$(date +%H)
#simulates midnight for testing
#hour=00
#first day of month, needed for monthly export
dayom01=$(date +%d)
#simulates firsf of month for testing
#dayom01=01

#geofabrik link for .bz2
GEOFABRIK=http://download.geofabrik.de/europe
#replex folders
REPLEX=/osm/osm-replex
EUROPE=$REPLEX/europe
DATA=$REPLEX/data
CACHE=$REPLEX/cache
POLY=$REPLEX/poly
STATS=$REPLEX/stats
#www-data folderi
WEB=/osm/www-data
PBF=$WEB/osm
FLOODS=$WEB/floods
#www-tms folderi
TMS=/osm/www-tms
#aplikacije
osmosis=$REPLEX/bin/osmosis/bin/osmosis
osmconvert=$REPLEX/bin/osmconvert32
osmfilter=$REPLEX/bin/osmfilter32
MKGMAP=$REPLEX/bin/mkgmap/mkgmap.jar
SPLITTER=$REPLEX/bin/splitter/splitter.jar
OSMANDMC=$REPLEX/bin/osmandmc
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



echo "===== S T A R T replikacije====="  >> $LOG
echo "Početak u: "`date +%Y%m%d-%H%M%S` >> $LOG
pocetak=`date +%s`

############################################
## Skidanje promjena od zadnjeg state.txt ##
############################################

#Skidanje changeseta uz sortiranje
$osmosis --rri workingDirectory=$REPLEX --sort-change --wxc $REPLEX/$CHANGESET
kraj=`date +%s`
vrijeme="$(( $kraj - $pocetak ))"
echo "Changeset gotov za" $vrijeme "sekundi." >> $LOG
echo "Kraj changeseta u: "`date +%Y%m%d-%H%M%S` >> $LOG 

#ispiši datum u log
awk '{if (NR!=1) {print}}' $REPLEX/state.txt >> $LOG

#########################
## Simplyfy changeseta ##
#########################

#Simplify changeseta
pocetak2=`date +%s`
$osmosis --read-xml-change file="$REPLEX/$CHANGESET" --simplify-change --write-xml-change file="$REPLEX/$CHANGESETSIMPLE"
kraj=`date +%s`
vrijeme="$(( $kraj - $pocetak2 ))"
echo "Changeset pojednostavljen za" $vrijeme "sekundi." >> $LOG
echo "Kraj pojednostavljenja changeseta u: "`date +%Y%m%d-%H%M%S` >> $LOG 

############################################
## Primjena changeseta uz rezanje granice ##
############################################

#Primjena changeseta uz rezanje granice
pocetak3=`date +%s`
$osmosis --read-xml-change file="$REPLEX/$CHANGESETSIMPLE" --read-pbf file="$EUROPE/europe-east.osm.pbf" --apply-change --bounding-polygon clipIncompleteEntities="true" file="$POLY/europe-east.poly" --write-pbf file="$REPLEX/europe-east.osm.pbf"

############################################
## backup europe-east.osm.pbf i state.txt ##
############################################

#micanje starih fajlova
rm $REPLEX/$CHANGESET
rm $REPLEX/$CHANGESETSIMPLE
mv $REPLEX/europe-east.osm.pbf $EUROPE/europe-east.osm.pbf; cp -p $EUROPE/europe-east.osm.pbf $PBF/europe-east.osm.pbf 

#kopira europu u web direktorij
#cp -p $EUROPE/europe-east.osm.pbf $PBF/europe-east.osm.pbf
cp -p $REPLEX/state.txt $EUROPE/state.txt; cp -p $REPLEX/state.txt $PBF/state.txt

###################################################
## dnevni backup europe-east.osm.pbf i state.txt ##
###################################################

#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  then
  cp -p $REPLEX/state.txt $EUROPE/$yesterday-state.txt
  cp -p $EUROPE/europe-east.osm.pbf $EUROPE/$yesterday-europe-east.osm.pbf; cp -p $EUROPE/europe-east.osm.pbf $DATA/europe-east.osm.pbf

  if [ $dayom01 -eq 01 ]
   then
   cp -p $EUROPE/$yesterday-europe-east.osm.pbf $WEB/monthly/$yesterday-europe-east.osm.pbf
  fi
  
  #micanje starih europa fajlova
  rm $EUROPE/$olddate-europe-east.osm.pbf
fi

chmod -R 755 $EUROPE

kraj=`date +%s`
vrijeme="$(( $kraj - $pocetak3 ))"
echo "Changeset primjenjen i odrezan za" $vrijeme "sekundi." >> $LOG
echo "Kraj primjene changeseta u: "`date +%Y%m%d-%H%M%S` >> $LOG 


#####################
## osm.pbf exporti ##
#####################

#Extract drzava ##################################
pocetak4=`date +%s`

#izvlaci drzavu iz europe ########################
for drzava in albania bosnia-herzegovina bulgaria croatia hungary kosovo macedonia montenegro romania serbia slovenia 
do
  echo "Pocetak $drzava extracta u: "`date +%Y%m%d-%H%M%S` >> $LOG 
  $osmosis --read-pbf file="$EUROPE/europe-east.osm.pbf" --bounding-polygon clipIncompleteEntities="true" file="$POLY/$drzava.poly" --write-pbf   file="$DATA/$drzava.osm.pbf"; cp -p $DATA/$drzava.osm.pbf $PBF/$drzava.osm.pbf
  echo "Kraj $drzava extracta u: "`date +%Y%m%d-%H%M%S` >> $LOG 
done

#izvlaci drzave iz europe #########################
#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  then
  ##kopira croatia sa datumom ######################
  cp -p $PBF/croatia.osm.pbf $WEB/croatia/arhiva/$yesterday-croatia.osm.pbf
  ## izvlaci dnevni changeset ######################
  $osmosis --read-pbf file="$WEB/croatia/arhiva/$daysago-croatia.osm.pbf" --read-pbf file="$WEB/croatia/arhiva/$yesterday-croatia.osm.pbf" --derive-change --write-xml-change compressionMethod=gzip file="$WEB/croatia/arhiva/$2daysago-$yesterday-croatia.osc.gz"
fi

############################################
## preuzima croatia.osm.bz2 sa geofabrika ##
############################################

#uvjet da se izvršava samo u 6 ujutro ############
if [ $hour -eq 06 ]
  then
  wget -q --tries=2 --timeout=5 $GEOFABRIK/croatia-latest.osm.bz2 -O $WEB/croatia/croatia.osm.bz2
fi

kraj=`date +%s`
vrijeme="$(( $kraj - $pocetak4 ))"
echo "Ekstrakti gotovi za" $vrijeme "sekundi." >> $LOG
echo "Kraj ekstrakta u: "`date +%Y%m%d-%H%M%S` >> $LOG


####################
## Garmin exporti ##
####################
  ##Garmin karte 
#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  then
  pocetak5=`date +%s`
  ##normalne drzave exporti
  mapid=90000001
  for drzava in europe-east albania bosnia-herzegovina bulgaria croatia hungary kosovo macedonia montenegro romania serbia slovenia
  do
    echo "Početak $drzava garmina u: "`date +%Y%m%d-%H%M%S` >> $LOG
    rm $CACHE/*
    java -Xmx$RAM -jar $SPLITTER --output-dir=$CACHE --mapid=$mapid --cache=$CACHE $DATA/$drzava.osm.pbf 
    java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --index --gmapsupp --series-name="OSM $drzava - d1" --family-name="OSM $drzava" --country-name="$drzava" --remove-short-arcs --net --route --generate-sea:no-sea-sectors,extend-sea-sectors $CACHE/90*.osm.pbf
    mv $CACHE/gmapsupp.img $WEB/garmin/$drzava-gmapsupp.img
    zip -j $DATA/$drzava-garmin.zip $CACHE/*90*.img $CACHE/osmmap.*
    mapid=$(($mapid + 10000))
    echo "Kraj $drzava garmina u: "`date +%Y%m%d-%H%M%S` >> $LOG
  done
  mv $DATA/*-garmin.zip $WEB/garmin/

  ##spajanje topo i gmapsupp
  for drzava in croatia #hrsibame
  do
    rm $CACHE/*
    java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --gmapsupp $WEB/garmin/$drzava-gmapsupp.img $WEB/garmin/$drzava-topo25m.img
    mv $CACHE/gmapsupp.img $WEB/garmin/$drzava-topo25m-gmapsupp.img
    rm $CACHE/*
    java -Xmx$RAM -jar $MKGMAP --output-dir=$CACHE --gmapsupp $WEB/garmin/$drzava-gmapsupp.img $WEB/garmin/$drzava-topo10m.img
    mv $CACHE/gmapsupp.img $WEB/garmin/$drzava-topo10m-gmapsupp.img
  done
  rm $CACHE/*

  #deleting europe because we don't want it in osmand generation
  rm $DATA/europe-east.osm.pbf
  
  kraj=`date +%s`
  vrijeme="$(( $kraj - $pocetak5 ))"
  echo "Garmin gotov za" $vrijeme "sekundi." >> $LOG
  echo "Kraj garmina u: "`date +%Y%m%d-%H%M%S` >> $LOG
fi

####################
## OsmAnd exporti ##
####################

#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  then
  #osmand karte 
  pocetak7=`date +%s`

  echo "Početak OsmAnd-a u: "`date +%Y%m%d-%H%M%S` >> $LOG
 
  #cd $OSMANDMCMC
  #java -Djava.util.logging.config.file=$REPLEX/logging.properties -Xms64M -Xmx$RAM -cp "$OSMANDMC/OsmAndMapCreator.jar:$OSMANDMC/lib/OsmAnd-core.jar:$OSMANDMC/lib/*.jar" net.osmand.data.index.IndexBatchCreator $REPLEX/batch.xml
  java -Xmx$RAM -cp "$OSMANDMC/OsmAndMapCreator.jar:$OSMANDMC/lib/OsmAnd-core.jar:$OSMANDMC/lib/*.jar" net.osmand.data.index.IndexBatchCreator $REPLEX/osmandmc.xml
  mv $DATA/*.obf* $WEB/osmand

  kraj=`date +%s`
  vrijeme="$(( $kraj - $pocetak7 ))"
  echo "OsmAnd gotov za" $vrijeme "sekundi." >> $LOG
  echo "Kraj OsmAnd-a u: "`date +%Y%m%d-%H%M%S` >> $LOG
fi


############################
## Statistike za hrvatsku ##
############################

#uvjet da se izvršava samo u ponoć
if [ $hour -eq 00 ]
  then
  echo "Početak statistika u: "`date +%Y%m%d-%H%M%S` >> $LOG

  pocetak6=`date +%s`
  
  $osmosis --read-pbf file="$PBF/croatia.osm.pbf" --write-xml file="$STATS/croatia.osm"
  
  #pretrazuje osm i izvlaci korisnike van
  grep -e "node \|way \|relation" $STATS/croatia.osm | grep "user=" | awk '{print $6,$7,$8,$9,$10,$11,$12;}' | cut -d \" -f 2 | sort -f | uniq > $svikorisnici
  
  rm -f $korstat1
  USER_No=1
  exec 3<"$svikorisnici"
  while read <&3 -r LINE
  do 
     NICK="user="\"$LINE\"
     grep -F "$NICK" $STATS/croatia.osm > $korpod
        DATE_LIST=`awk '{print $4;}' $korpod | cut -d \" -f 2 | sort`
        DATE_LAST=`echo "$DATE_LIST" | tail -n1`
        DATE_LIST=""
     NODES=`grep -e "node " $korpod | wc -l`
     WAYS=`grep -e "way " $korpod | wc -l`
     RELATIONS=`grep -e "relation " $korpod | wc -l`
     echo $LINE'.'$NODES'.'$WAYS'.'$RELATIONS'.'$DATE_LAST >> $korstat1
  done
  exec 3>&-
  rm $korpod
  exec 3<"$korstat1"
  while read <&3 -r LINE   
  do
    USER_NODE=`echo "$LINE" | awk -F "." '{print $2;}'`
    USER_WAY=`echo "$LINE" | awk -F "." '{print $3;}'`
    USER_RELATION=`echo "$LINE" | awk -F "." '{print $4;}'`
  TOTAL_NODE=$(( $TOTAL_NODE + $USER_NODE ))
  TOTAL_WAY=$(( $TOTAL_WAY + $USER_WAY ))
  TOTAL_RELATION=$(( $TOTAL_RELATION + $USER_RELATION ))
  done
  exec 3>&-

  #sortiranje sa zarezom
  #sort -t, -k2,2nr $korstat1 >$korstat2
  #sortiranje sa tockom i zamjenom u zarez
  #  sort -t "." -k 2nr $korstat1 | tr "." "," >$korstat2 
  sort -f -t "." -k 2nr $korstat1 >$korstat2
  
  #zapisuje statitiske za drzavu
  echo $yesterday,`cat $svikorisnici | wc -l`','$TOTAL_NODE','$TOTAL_WAY','$TOTAL_RELATION >> $REPLEX/croatia-stats.csv
  
  echo '<html><head><title> OSM Statistike</title>' >$statistike
  echo '<script src="http://data.osm-hr.org/statistike/sorttable.js"></script><meta http-equiv="content-type" content="text/html; charset=utf-8"/></head><body>' >>$statistike
  echo '<center><h1>Statistike za croatia.osm.pbf</h1></center>'>>$statistike 
  echo 'Datum podataka:'$yesterday >>$statistike
  echo '<br>Broj korisnika:'`cat $svikorisnici | wc -l` >>$statistike
  echo '<br>Broj točaka:'$TOTAL_NODE >>$statistike
  echo '<br>Broj puteva:'$TOTAL_WAY >>$statistike
  echo '<br>Broj relacija:'$TOTAL_RELATION >>$statistike
  echo '<table class="sortable" style="width: 100%; border: 1px solid gray" border=1 width=100%>' >>$statistike
  echo '<tr><td>Korisnik</td><td>Točke</td><td>%</td><td>Putevi</td><td>%</td><td>Relacije</td><td>%</td><td>Zadnji put uređivao</td></tr>' >>$statistike
  exec 3<"$korstat2"
  
  while read <&3 -r LINE
  do
    echo "$LINE" | awk -v Node=$TOTAL_NODE -v Way=$TOTAL_WAY -v Relation=$TOTAL_RELATION -F "." '{printf "<tr><td><a href=\"http://osm.org/user/%s\">%s</a>: <a href=\"http://hdyc.neis-one.org/?%s\">h</a>, <a href=\"http://yosmhm.neis-one.org/?%s\">y</a></td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td></tr>\n",$1,$1,$1,$1,$2,100*($2)/Node,$3,100*($3)/Way,$4,100*($4)/Relation,$5;}' >>$statistike

  done
  exec 3>&-
  echo '</table></body></html>' >> $statistike
  
  #salje csv i htm u web folder
  cp -p $statistike $WEB/statistike/croatia-stats.htm
  mv $statistike $WEB/croatia/statistike/$yesterday-croatia-stats.htm
  cat $korstat2 | tr "." "," >$WEB/statistike/croatia-users.csv
  cp -p $WEB/statistike/croatia-users.csv $WEB/croatia/statistike/$yesterday-croatia-users.csv

  rm $STATS/croatia.osm

  ##statistike i za ostale drzave
  ##############################################################
  if [ $dayom01 -eq 01 ]
  then
    for drzava in albania bosnia-herzegovina bulgaria hungary kosovo macedonia montenegro romania serbia slovenia
    do
    
      $osmosis --read-pbf file="$PBF/$drzava.osm.pbf" --write-xml file="$STATS/$drzava.osm"
    
      #pretrazuje osm i izvlaci korisnike van
      grep -e "node \|way \|relation" $STATS/$drzava.osm | grep "user=" | awk '{print $6,$7,$8,$9,$10,$11,$12;}' | cut -d \" -f 2 | sort -f | uniq  > $svikorisnici
      
      rm -f $korstat1
      USER_No=1
      exec 3<"$svikorisnici"
      while read <&3 -r LINE
      do 
         NICK="user="\"$LINE\"
         grep -F "$NICK" $STATS/$drzava.osm > $korpod
            DATE_LIST=`awk '{print $4;}' $korpod | cut -d \" -f 2 | sort`
            DATE_LAST=`echo "$DATE_LIST" | tail -n1`
            DATE_LIST=""
         NODES=`grep -e "node " $korpod | wc -l`
         WAYS=`grep -e "way " $korpod | wc -l`
         RELATIONS=`grep -e "relation " $korpod | wc -l`
         echo $LINE'.'$NODES'.'$WAYS'.'$RELATIONS'.'$DATE_LAST >> $korstat1
      done
      exec 3>&-
      rm $korpod
      exec 3<"$korstat1"
      while read <&3 -r LINE   
      do
        USER_NODE=`echo "$LINE" | awk -F "." '{print $2;}'`
        USER_WAY=`echo "$LINE" | awk -F "." '{print $3;}'`
        USER_RELATION=`echo "$LINE" | awk -F "." '{print $4;}'`
      TOTAL_NODE=$(( $TOTAL_NODE + $USER_NODE ))
      TOTAL_WAY=$(( $TOTAL_WAY + $USER_WAY ))
      TOTAL_RELATION=$(( $TOTAL_RELATION + $USER_RELATION ))
      done
      exec 3>&-
    
      #sortiranje sa zarezom
      #sort -t, -k2,2nr $korstat1 >$korstat2
      #sortiranje sa tockom i zamjenom u zarez
      #  sort -t "." -k 2nr $korstat1 | tr "." "," >$korstat2 
      sort -f -t "." -k 2nr $korstat1 >$korstat2
      
      #zapisuje statitiske za drzavu
      echo $yesterday,`cat $svikorisnici | wc -l`','$TOTAL_NODE','$TOTAL_WAY','$TOTAL_RELATION >> $REPLEX/$drzava-stats.csv
      
      echo '<html><head><title> OSM Statistike</title>' >$statistike
      echo '<script src="http://data.osm-hr.org/statistike/sorttable.js"></script><meta http-equiv="content-type" content="text/html; charset=utf-  8"/></head><body>' >>$statistike
      echo '<center><h1>Statistike za '$drzava.osm.pbf'</h1></center>'>>$statistike 
      echo 'Datum podataka:'$yesterday >>$statistike
      echo '<br>Broj korisnika:'`cat $svikorisnici | wc -l` >>$statistike
      echo '<br>Broj točaka:'$TOTAL_NODE >>$statistike
      echo '<br>Broj puteva:'$TOTAL_WAY >>$statistike
      echo '<br>Broj relacija:'$TOTAL_RELATION >>$statistike
      echo '<table class="sortable" style="width: 100%; border: 1px solid gray" border=1 width=100%>' >>$statistike
      echo '<tr><td>Korisnik</td><td>Točke</td><td>%</td><td>Putevi</td><td>%</td><td>Relacije</td><td>%</td><td>Zadnji put uređivao</td></tr>' >>  $statistike
      exec 3<"$korstat2"
      
      while read <&3 -r LINE
      do
        echo "$LINE" | awk -v Node=$TOTAL_NODE -v Way=$TOTAL_WAY -v Relation=$TOTAL_RELATION -F "." '{printf "<tr><td><a href=\"http://osm.org/user/%s\">%s</a>: <a href=\"http://hdyc.neis-one.org/?%s\">h</a>, <a href=\"http://yosmhm.neis-one.org/?%s\">y</a></td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td></tr> \n",$1,$1,$1,$1,$2,100*($2)/Node,$3,100*($3)/Way,$4,100*($4)/Relation,$5;}' >>$statistike
    
      done
      exec 3>&-
      echo '</table></body></html>' >> $statistike
      
      #salje csv i htm u web folder
      cp -p $statistike $WEB/statistike/$drzava-stats.htm
      mv $statistike $WEB/statistike/$yesterday-$drzava-stats.htm
      cat $korstat2 | tr "." "," >$WEB/statistike/$drzava-users.csv
      cp -p $WEB/statistike/$drzava-users.csv $WEB/statistike/$yesterday-$drzava-users.csv
    
      rm $STATS/$drzava.osm
    done
  fi

  kraj=`date +%s`
  vrijeme="$(( $kraj - $pocetak6 ))"
  echo "Statistike gotove za" $vrijeme "sekundi." >> $LOG
  echo "Kraj statistika u: "`date +%Y%m%d-%H%M%S` >> $LOG

fi


#kompletno trajanje
kraj=`date +%s`
vrijeme="$(( $kraj - $pocetak ))"
echo "Kompeletna promjena gotova za" $vrijeme "sekundi." >> $LOG
echo "Kompeletna promjena gotova u: "`date +%Y%m%d-%H%M%S` >> $LOG


rm $CACHE/*

chmod -R 755 $WEB
echo "Kraj u: "`date +%Y%m%d-%H%M%S` >> $LOG
echo "===== K R A J replikacije====="  >> $LOG