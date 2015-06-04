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

function get_next_date() {
  FORMATTED_DATE=`date -d "@$1" +"$DATE_FORMAT_DATE"`
  date -d "$FORMATTED_DATE +1 $GROUP_BY_STRING" +%s
}

function get_epoch() {
  date -d "$1" +%s
}

function get_formatted_date() {
  date -d "@$1" +"$DATE_FORMAT"
}

function get_week() {
  date -d "$(( $(date -d "$1" +%u) - 1 + $(( ($(date -d "today" +%s) - $(date -d "$1" +%s) )/(60*60*24) )))) days ago" +"%Y-%m-%d %V"
}

# Parse command line arguments
while getopts "s:u:g:" OPTION
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


FROM_EPOCH=`get_epoch "$FROM"`
TO_EPOCH=`get_epoch "$TO"`
DATES=""

# Get all dates
while [ $FROM_EPOCH -lt $TO_EPOCH ]; do
  FROM_FORMATTED="`get_formatted_date $FROM_EPOCH`"
  if [[ "$GROUP_BY_STRING" == "week" ]]
  then
    DATES+="`get_week $FROM_FORMATTED`\n"
  else
    DATES+="$FROM_FORMATTED\n"
  fi
  NEXT_DAY=`get_next_date $FROM_EPOCH`
  FROM_EPOCH=$NEXT_DAY
done

# Get dates with commits
if [[ "$GROUP_BY_STRING" == "week" ]]
then
  DATES+=`git log --since "$FROM" --until "$TO" --format="%ct" --reverse | \
    xargs -I{} date -d "@{}" +"$DATE_FORMAT_WEEK" | \
    xargs -I COMMIT_DATE bash -c 'date -d "$(( $(date -d "COMMIT_DATE" +%u) - 1 + $(( ($(date -d "today" +%s) - $(date -d "COMMIT_DATE" +%s) )/(60*60*24) )))) days ago" +"%Y-%m-%d %V"'`
else
  DATES+=`git log --since "$FROM" --until "$TO" --format="%ct" --reverse | \
    xargs -I{} date -d "@{}" +"$DATE_FORMAT"`
fi

echo -n -e "$DATES" | \
  sort | \
  uniq -c | \
  sed 's/^\s*//' | \
  awk -F"[ ]" '{print $1 - 1 " " $2}' >$DAT_FILE

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
echo "set style fill solid 1.00 border"                               >> $PLOT_FILE
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
  echo "INFO: Successfully created $OUT_FILE"
  rm $PLOT_FILE
  rm $DAT_FILE
else
  echo "ERROR: Failed to create graph!"
fi
