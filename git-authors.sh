#!/bin/bash

BASE_NAME=`basename ${0%\.*}`
DAT_FILE=$BASE_NAME.dat
PLOT_FILE=$BASE_NAME.gnuplot
OUT_FILE=$BASE_NAME.png
WIN_FONT_PATH=/cygdrive/c/WINDOWS/Fonts

git log --format="\"%an\"" | sort | uniq -c | sort -r | sed 's/^\s*//' >$DAT_FILE

echo "set title 'Repository Authors'"                                  > $PLOT_FILE
echo "set grid"                                                       >> $PLOT_FILE
echo "set key off"                                                    >> $PLOT_FILE
echo "set ylabel 'Number of commits'"                                 >> $PLOT_FILE
echo "set xlabel 'Author'"                                            >> $PLOT_FILE
echo "set y2tics"                                                     >> $PLOT_FILE
echo "set ytics nomirror"                                             >> $PLOT_FILE
echo "set xtics nomirror rotate by -45"                               >> $PLOT_FILE
echo "set style fill solid"                                           >> $PLOT_FILE
echo "set boxwidth 0.75"                                              >> $PLOT_FILE
echo "set terminal png nocrop enhanced font arial 12 size 1280,1024"  >> $PLOT_FILE
echo "set output '$OUT_FILE'"                                         >> $PLOT_FILE
echo "plot '$DAT_FILE' using 1:xtic(2) with boxes"                    >> $PLOT_FILE

if [ -d $WIN_FONT_PATH ]
then
  export GDFONTPATH=$WIN_FONT_PATH
fi

gnuplot $PLOT_FILE
if [ $? = 0 ]
then
  # Clean up
  rm $PLOT_FILE
  rm $DAT_FILE
else
  echo "ERROR: Failed to create graph!"
fi