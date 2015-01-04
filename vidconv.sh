#!/bin/bash
# Script für rekursive Suche nach Videofiles und Konversion
# Originalfiles werden in das Unterverzeichnis Backup verschoben

# globale Konstante
LOGFILE="/etc/iwops/logvidconv.txt"
# STARTDIR="/media/Recs/Aufnahmen/Videos/Test"
# STARTDIR="/media/Recs/Aufnahmen/Videos"
# STARTDIR="/media/Share/Medien/Videos/Panasonic/20141104_Videos"
STARTDIR="/media/Recs/Aufnahmen/Conversion"

# testparameter: falls 1 wird keine konversion durchgefuehrt
NOCONV=0

# groessenlimit fuer das ignorieren von kleinen files (bytes)
LIMIT=32000

# LOGFILE="/cygdrive/c/Users/wilhelmi/Skripts/log.txt"
# STARTDIR="/cygdrive/c/Users/wilhelmi/Skripts"

# ===================== function recursiveconversion ======================================
# Parameter: Startverzeichnis
# Functions

recursiveconversion () {
  for d in *; do
    if [ -d "$d" ]; then
      cd "$d"
      recursiveconversion
      cd ..
    fi
# wenn d kein directory ist: 
# aktion für das file "d" durchführen:
# pruef ob d ein video-sourcefile ist:
   case ${d/*./} in
		[tT][sS])
			fileaction "$d";;
		[aAmM][vVtTpP][iIsSgG])
			fileaction "$d";;
		MPG)
			fileaction "$d";;
		*)
			logtext "$d not processed";;
	esac
  done
}

# ===================== function fileaction ======================================
# Parameter: name des video-files das zu verarbeiten ist
# aktion die für jedes file auszuführen ist
fileaction () {
# schreibe parameter 1 in sprechende variable
   INFILE="$1"

# pruefe groesse des files:
   FILESIZE=$(stat -c %s "$INFILE")
   if [ $FILESIZE -lt $LIMIT ] 
     then
        logtext "$INFILE size: $FILESIZE bytes - below limit of $LIMIT (probably semaphor)"
        return 2
     else
        logtext "$INFILE size: $FILESIZE bytes - processing"
   fi

# File groesse ist ueber limit: verarbeiten
# Zielfilenamen erzeugen
   TARGET="${INFILE%\.*}.mp4"
   logtext "Infile is: $INFILE"
   logtext "Writing to target, removing it: $TARGET"
   rm $TARGET
   
# video-konvertierung durchführen   
   if [ $NOCONV -eq 1 ]
     then
       logtext "using command: ffmpeg -i $INFILE -vpre default -vres 1280x720 $TARGET"
       return 0
     else
# fuehre conversion durch
       logtext "=== starting conversion ==="
# verwendete streams haengen vom filetyp ab:
       case ${INFILE/*./} in
		[tT][sS]) { # sat-stream 
 			logtext "===  Trying sat-stream $INFILE using stream mapping"
       			nice -19 ffmpeg -async 25 -i "$INFILE" \
            			-vcodec libx264  \
            			-threads 0 -sn -y "$TARGET" -map 0:1 -map 0:2
# if stream mapping fails try without
  			if [ $? != 0 ]; then
 			    logtext "=== Stream mapping for $INFILE failed, converting without mapping"
       			    nice -19 ffmpeg -async 25 -i "$INFILE" \
            			-vcodec libx264  \
            			-threads 0 -sn -y "$TARGET"
 			fi };;
		[aAmM][vVtTpP][iIsSgG]) # camcorder or avi
       			nice -19 ffmpeg -async 25 -i "$INFILE" \
            			-vcodec libx264 \
            			-threads 0 -sn "$TARGET" ;;
		MPG)
       			nice -19 ffmpeg -async 25 -i "$INFILE" \
            			-vcodec libx264 \
            			-threads 0 -sn "$TARGET" ;;
		*)
       			nice -19 ffmpeg -async 25 -i "$INFILE" \
            			-vcodec libx264 \
            			-threads 0 -sn "$TARGET" ;;
	esac
   fi
   
# check for success of ffmpeg: when $? = 0 then success or $? = 1 failure
   if [ $? = 0 ] 
   then
# erfolg: achtung! der returnwert von ffmpeg ist nicht zuverlaessig bzw.
# ich kenn mich damit nciht aus :-)
	logtext "$INFILE sucessfull converted" 
 	chmod 777 "$TARGET"
# erzeugt backupfile 
	mv "$INFILE" "./Backup/$INFILE.bak"

# semaphor ab Version 7 nicht mehr erzeugen! (zeilen entfernt - siehe Version 6)
# verlasse _fileaction_ und retourniere success (fuer conversion)
	return 0
   else
# conversion hat nicht funktioniert!
	logtext "conversion of $INFILE failed"
	return 1
   fi


} # end _fileaction
   

# ===================== function logtext ======================================
# Parameter: Text der ins Logfile geschrieben werden soll
# function for writing text to logfile
logtext () {
   echo "`date`: " $1 2>&1 | tee -a $LOGFILE
}   

# ============================ MAIN ===================================

logtext "Starting conversion from $STARTDIR"
logtext  "==================  Starting==================  "
cd $STARTDIR
logtext "starting at dir: $STARTDIR"
recursiveconversion

exit 0

# End of Main


# EOF
