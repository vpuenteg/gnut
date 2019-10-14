rm out *pcv1 *pcv2

#Input files: corresponding SINEX and list of stations to be processed
snx=$1;
list=$2;

  grep -v COMMENT igs08.atx > atx

#Extract dome block
firstmatch="\+SITE\/ID"
secondmatch="\-SITE\/ID"
sed "/$firstmatch/,/$secondmatch/!d;//d" $snx > dome

#Extract receiver block
firstmatch="\+SITE\/RECEIVER"
secondmatch="\-SITE\/RECEIVER"
sed "/$firstmatch/,/$secondmatch/!d;//d" $snx > receiver

#Extract antenna block
firstmatch="\+SITE\/ANTENNA"
secondmatch="\-SITE\/ANTENNA"
sed "/$firstmatch/,/$secondmatch/!d;//d" $snx > antenna

#Extract eccentricity block
firstmatch="\+SITE\/ECCENTRICITY"
secondmatch="\-SITE\/ECCENTRICITY"
sed "/$firstmatch/,/$secondmatch/!d;//d" $snx > eccentricity

#Extract coordinates block
firstmatch="\+SOLUTION\/ESTIMATE"
secondmatch="\-SOLUTION\/ESTIMATE"
sed "/$firstmatch/,/$secondmatch/!d;//d" $snx > coord

#Loop over stations
for stat in `cat $list`; do

  #Convert station code to upper case
  STAT=`echo $stat | awk '{print toupper($0) }'`
  #Get dome, receiver model, antenna, NEU eccentricities and coordinates
  dome=`grep "^ $STAT" dome | awk '{print $3}'`
  rec=`grep "^ $STAT" receiver | tail -1 | awk '{print $7}'`
  ant=`grep "^ $STAT" antenna | tail -1 | awk '{ printf "%-15s %4s", $7, $8 }'`
  #ant=`grep "^ $STAT" antenna | tail -1 | cut -c 43-62`
  IFS='%'
  #unset IFS
  echo $ant
  ecc=`grep "^ $STAT" eccentricity | tail -1 | awk '{print $8,$9,$10}'`
  X=`grep "STAX   $STAT" coord | awk '{print $9}'`
  Y=`grep "STAY   $STAT" coord | awk '{print $9}'`
  Z=`grep "STAZ   $STAT" coord | awk '{print $9}'`


  


  #All fields must exist to store the station and check antenna calibration
  if [ ! -z "$X" ] && [ ! -z "$Y" ] && [ ! -z "$Z" ] && [ ! -z "$ecc" ] && [ ! -z "$rec" ] && [ ! -z "$ant" ]; then
  
  #Get antenna block
  grep -A165 $ant atx > $STAT.atx2
  
#Extract frequency 1 block
 firstmatch="G01\                                                      START OF FREQUENCY"
 secondmatch="G01\                                                      END OF FREQUENCY"
 sed "/$firstmatch/,/$secondmatch/!d;//d" $STAT.atx2 > L1


 #Extract frequency 2 block
 firstmatch="G02\                                                      START OF FREQUENCY"
 secondmatch="G02\                                                      END OF FREQUENCY"
 sed "/$firstmatch/,/$secondmatch/!d;//d" $STAT.atx2 > L2

 #Get Phase Center Offset PCO=PCV-ARP for each frequency
PCO1=`awk '(NR==1) {print $1,$2,$3}' L1`
 PCO2=`awk '(NR==1) {print $1,$2,$3}' L2`
 
 #Get Phase Center Variations (PCV) for each frequency
 awk '(NR>2){print $0}' L1 > $STAT.pcv1
 awk '(NR>2){print $0}' L2 > $STAT.pcv2
  
  #echo $STAT $dome $X $Y $Z $ecc $rec $ant >> out
  
  if [ ! -z "$PCO1" ] && [ ! -z "$PCO2" ]; then
  echo $STAT $X $Y $Z $ecc $PCO1 $PCO2 >> out
    else
    echo "Missing antenna calibration for station $STAT. It will not be processed"
  fi
    
  #Missing data  
  else
    echo "Missing data for station $STAT. It will not be processed"
  fi
done

#Remove auxiliary files
rm dome receiver antenna eccentricity coord L1 L2 *atx2 atx
