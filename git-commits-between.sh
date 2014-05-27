#!/bin/bash

BASE_NAME=`basename ${0%\.*}`
DAT_FILE=$BASE_NAME.dat
PLOT_FILE=$BASE_NAME.gnuplot
OUT_FILE=$BASE_NAME.png
WIN_FONT_PATH=/cygdrive/c/WINDOWS/Fonts

# Date formats
DATE_FORMAT_DATE="%Y-%m-%d"
DATE_FORMAT_WEEK="%Y-%m-%d"
DATE_FORMAT_MONTH="%Y-%m"
DATE_FORMAT_YEAR="%Y"

###################################################################
# Function:     usage
# Description:  Displays usage
###################################################################
function usage {
  echo "Usage: `basename $0` -s [since] -u [until] -g [day|week|month|year]"
  echo -e "\t-s\tSince"
  echo -e "\t-u\tUntil"
  echo -e "\t-g\tGroup by"
  exit 1
}

# Parse command line arguments
while getopts ":s:u:g:" OPTION
do
  case $OPTION in
    s   ) FROM=$OPTARG;;
    u   ) TO=$OPTARG;;
    g   ) GROUP=$OPTARG;;
    *   ) usage;;   # Default option
  esac
done

# Check that the variables has been set
if [[ -z $FROM ]] || [[ -z $TO ]] || [[ -z $GROUP ]]
then
  usage
fi

shopt -s extglob nocasematch
case $GROUP in
  d?(ay)    ) DATE_FORMAT=$DATE_FORMAT_DATE
              GROUP_BY_STRING=day
              XTICS_FORMAT=$DATE_FORMAT_DATE
              ;;
  w?(eek)   ) DATE_FORMAT=$DATE_FORMAT_WEEK
              GROUP_BY_STRING=week
              XTICS_FORMAT="%Y Week %W"
              ;;
  m?(onth)  ) DATE_FORMAT=$DATE_FORMAT_MONTH
              GROUP_BY_STRING=month
              XTICS_FORMAT="%Y %b"
              ;;
  y?(ear)   ) DATE_FORMAT=$DATE_FORMAT_YEAR
              GROUP_BY_STRING=year
              XTICS_FORMAT=$DATE_FORMAT_YEAR
              ;;
  *         ) usage;;
esac
shopt -u extglob nocasematch



if [[ "$GROUP_BY_STRING" == "week" ]]
then  
  git log --since "$FROM" --until "$TO" --format="%ct" --reverse | \
    xargs -I{} date -d "@{}" +"$DATE_FORMAT_WEEK" | \
    xargs -I DATE bash -c 'date -d "$(( $(date -d "DATE" +%u) - 1 + $(( ($(date -d "today" +%s) - $(date -d "DATE" +%s) )/(60*60*24) )))) days ago" +"$DATE_FORMAT_WEEK %W"' | \
    uniq -c | \
    sed 's/^\s*//' >$DAT_FILE
else
  git log --since "$FROM" --until "$TO" --format="%ct" --reverse | \
    xargs -I{} date -d "@{}" +"$DATE_FORMAT" | \
    uniq -c | \
    sed 's/^\s*//' >$DAT_FILE
fi

echo "set title 'Number of commits per $GROUP_BY_STRING'"              > $PLOT_FILE
echo "set key off"                                                    >> $PLOT_FILE
echo "set xdata time"                                                 >> $PLOT_FILE
echo "set timefmt \"$DATE_FORMAT\""                                   >> $PLOT_FILE
echo "set format x \"$DATE_FORMAT\""                                  >> $PLOT_FILE
echo "set ylabel 'Number of commits'"                                 >> $PLOT_FILE
echo "set yrange [0:*]"                                               >> $PLOT_FILE
echo "set xlabel 'Date'"                                              >> $PLOT_FILE
echo "set y2tics"                                                     >> $PLOT_FILE
echo "set ytics nomirror"                                             >> $PLOT_FILE
echo "set xtics nomirror rotate by -45"                               >> $PLOT_FILE
echo "set xtics format \"$XTICS_FORMAT\""                             >> $PLOT_FILE
echo "set tic scale 0"                                                >> $PLOT_FILE
echo "set terminal png nocrop enhanced font arial 12 size 1280,1024"  >> $PLOT_FILE
echo "set output '$OUT_FILE'"                                         >> $PLOT_FILE
echo "plot '$DAT_FILE' using 2:1 with boxes"                          >> $PLOT_FILE

if [ -d $WIN_FONT_PATH ]
then
  export GDFONTPATH=$WIN_FONT_PATH
fi

gnuplot $PLOT_FILE
if [ $? = 0 ]
then
  # Clean up
  echo "INFO: Success" 
  rm $PLOT_FILE
  rm $DAT_FILE
else
  echo "ERROR: Failed to create graph!"
fi