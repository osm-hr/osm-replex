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
#www-tms folders
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



echo "===== Replication S T A R T ====="  >> $LOG
echo `date +%Y-%m-%d\ %H:%M:%S`" - Starting script" >> $LOG
start_time0=`date +%s`

############################################
## Downloading changeset from laste state.txt ##
############################################

#Downloading changeset and sorting
echo `date +%Y-%m-%d\ %H:%M:%S`" - Downloading changeset" >> $LOG
$osmosis --rri workingDirectory=$REPLEX --sort-change --wxc $REPLEX/$CHANGESET
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
for drzava in albania bosnia-herzegovina bulgaria croatia hungary kosovo macedonia montenegro romania serbia slovenia 
do
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" export started" >> $LOG
  start_time=`date +%s`
  $osmosis --read-pbf file="$EUROPE/europe-east.osm.pbf" --bounding-polygon clipIncompleteEntities="true" file="$POLY/$drzava.poly" --write-pbf   file="$DATA/$drzava.osm.pbf"; cp -p $DATA/$drzava.osm.pbf $PBF/$drzava.osm.pbf
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" PBF export finished in" $lasted "seconds." >> $LOG
done

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
  java -Xmx$RAM -cp "$OSMANDMC/OsmAndMapCreator.jar:$OSMANDMC/lib/OsmAnd-core.jar:$OSMANDMC/lib/*.jar" net.osmand.data.index.IndexBatchCreator $REPLEX/osmandmc.xml
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
  $osmosis --read-pbf file="$PBF/croatia.osm.pbf" --write-xml file="$STATS/croatia.osm"
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - croatia.osm exported in" $lasted "seconds." >> $LOG

  #pretrazuje osm i izvlaci korisnike van
  start_time=`date +%s`
  grep -e "node \|way \|relation" $STATS/croatia.osm | grep "user=" | awk '{print $6,$7,$8,$9,$10,$11,$12;}' | cut -d \" -f 2 | sort -f | uniq > $svikorisnici
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - Sorted out all croatia users in" $lasted "seconds." >> $LOG

  start_time=`date +%s`
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
  end_time=`date +%s`
  lasted="$(( $end_time - $start_time ))"
  echo `date +%Y-%m-%d\ %H:%M:%S`" - All croatia users and their ownership found in" $lasted "seconds." >> $LOG

  #country total stats
  echo $yesterday,`cat $svikorisnici | wc -l`','$TOTAL_NODE','$TOTAL_WAY','$TOTAL_RELATION >> $WEB/croatia/stats/croatia-total.csv
  #next 2lines to be replaced with symlink on server
  cp -p $WEB/croatia/stats/croatia-total.csv $WEB/croatia/croatia-total.csv
  cp -p $WEB/croatia/stats/croatia-total.csv $WEB/statistics/croatia-total.csv

  #sort by 2nd, then 3rd, then 4th column, node, way, relation
  sort -f -t "." -k2,2nr -k3,3nr -k4,4nr  $korstat1 >$korstat2

  #country user stats.csv to web folder
  echo 'user,nodes,ways,relations,lastedit' >$WEB/croatia/croatia-users.csv
  cat $korstat2 | tr "." "," >>$WEB/croatia/croatia-users.csv
  cp -p $WEB/croatia/croatia-users.csv $WEB/croatia/stats/$yesterday-croatia-users.csv
  #next line to be replaced with symlink on server
  cp -p $WEB/croatia/croatia-users.csv $WEB/statistics/croatia-users.csv
  echo `date +%Y-%m-%d\ %H:%M:%S`" - croatia csv files created and copied to web." >> $LOG

  echo '<html><head><title> OSM Statistike</title>' >$statistike
  echo '<script src="http://data.osm-hr.org/statistics/sorttable.js"></script><meta http-equiv="content-type" content="text/html; charset=utf-8"/></head><body>' >>$statistike
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
  
  #country user stats.htm to web folder
  cp -p $statistike $WEB/statistics/croatia-stats.htm
  mv $statistike $WEB/croatia/croatia-stats.htm
  echo `date +%Y-%m-%d\ %H:%M:%S`" - croatia htm files created and copied to web." >> $LOG

  rm $STATS/croatia.osm

  ##statistike i za ostale drzave
  ##############################################################
  if [ $dayom01 -eq 01 ]
  then
    for drzava in albania bosnia-herzegovina bulgaria hungary kosovo macedonia montenegro romania serbia slovenia
    do
      echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" statistics starting." >> $LOG
      start_time=`date +%s`
      TOTAL_NODE=0
      TOTAL_WAY=0
      TOTAL_RELATION=0
      $osmosis --read-pbf file="$PBF/$drzava.osm.pbf" --write-xml file="$STATS/$drzava.osm"
      end_time=`date +%s`
      lasted="$(( $end_time - $start_time ))"
      echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava".osm exported in" $lasted "seconds." >> $LOG

      #pretrazuje osm i izvlaci korisnike van
      start_time=`date +%s`
      grep -e "node \|way \|relation" $STATS/$drzava.osm | grep "user=" | awk '{print $6,$7,$8,$9,$10,$11,$12;}' | cut -d \" -f 2 | sort -f | uniq  > $svikorisnici
      end_time=`date +%s`
      lasted="$(( $end_time - $start_time ))"
      echo `date +%Y-%m-%d\ %H:%M:%S`" - Sorted out all "$drzava" users in" $lasted "seconds." >> $LOG    

      start_time=`date +%s`
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
      end_time=`date +%s`
      lasted="$(( $end_time - $start_time ))"
      echo `date +%Y-%m-%d\ %H:%M:%S`" - All "$drzava" users and their ownership found in" $lasted "seconds." >> $LOG

      #country total stats
      echo $yesterday,`cat $svikorisnici | wc -l`','$TOTAL_NODE','$TOTAL_WAY','$TOTAL_RELATION >> $WEB/$drzava/stats/$drzava-total.csv
      #next 2 lines to be replaced with symlink on server
      cp -p $WEB/$drzava/stats/$drzava-total.csv $WEB/$drzava/$drzava-total.csv
      cp -p $WEB/$drzava/stats/$drzava-total.csv $WEB/statistics/$drzava-total.csv

      #sort by 2nd, then 3rd, then 4th column, node, way, relation
      sort -f -t "." -k2,2nr -k3,3nr -k4,4nr  $korstat1 >$korstat2
   
      #country user stats.csv to web folder
      echo 'user,nodes,ways,relations,lastedit' >$WEB/$drzava/$drzava-users.csv
      cat $korstat2 | tr "." "," >>$WEB/$drzava/$drzava-users.csv
      cp -p $WEB/$drzava/$drzava-users.csv $WEB/$drzava/stats/$yesterday-$drzava-users.csv
      #next line to be replaced with symlink on server
      cp -p $WEB/$drzava/$drzava-users.csv $WEB/statistics/$drzava-users.csv
      echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" csv files created and copied to web." >> $LOG

      #html export 
      echo '<html><head><title> OSM Stats</title>' >$statistike
      echo '<script src="http://data.osm-hr.org/statistics/sorttable.js"></script><meta http-equiv="content-type" content="text/html; charset=utf-  8"/></head><body>' >>$statistike
      echo '<center><h1>Stats for '$drzava.osm.pbf'</h1></center>'>>$statistike 
      echo 'Date of file:'$yesterday >>$statistike
      echo '<br>Number of users:'`cat $svikorisnici | wc -l` >>$statistike
      echo '<br>Number of nodes:'$TOTAL_NODE >>$statistike
      echo '<br>Number of ways:'$TOTAL_WAY >>$statistike
      echo '<br>Number of relations:'$TOTAL_RELATION >>$statistike
      echo '<table class="sortable" style="width: 100%; border: 1px solid gray" border=1 width=100%>' >>$statistike
      echo '<tr><td>User</td><td>Nodes</td><td>%</td><td>Ways</td><td>%</td><td>Relations</td><td>%</td><td>Last edit</td></tr>' >>  $statistike
      exec 3<"$korstat2"
      
      while read <&3 -r LINE
      do
        echo "$LINE" | awk -v Node=$TOTAL_NODE -v Way=$TOTAL_WAY -v Relation=$TOTAL_RELATION -F "." '{printf "<tr><td><a href=\"http://osm.org/user/%s\">%s</a>: <a href=\"http://hdyc.neis-one.org/?%s\">h</a>, <a href=\"http://yosmhm.neis-one.org/?%s\">y</a></td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td><td align=\"right\">%3.2f</td><td>%s</td></tr> \n",$1,$1,$1,$1,$2,100*($2)/Node,$3,100*($3)/Way,$4,100*($4)/Relation,$5;}' >>$statistike
      done
      exec 3>&-
      echo '</table></body></html>' >> $statistike
      
      #country user stats.htm to web folder
      cp -p $statistike $WEB/statistics/$drzava-stats.htm
      mv $statistike $WEB/$drzava/$drzava-stats.htm
      echo `date +%Y-%m-%d\ %H:%M:%S`" - "$drzava" htm files created and copied to web." >> $LOG

      rm $STATS/$drzava.osm
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
