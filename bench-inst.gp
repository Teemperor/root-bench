set terminal svg size 500,300  enhanced background rgb 'white'
set output 'benchmark.svg'

set title "Instructions of hsimple"
set style data fsteps
set xlabel "Date\n"
set timefmt '%Y-%m-%d'
set yrange [ 0 : ]
set xdata time
set xtics rotate by 45 offset -3, -3
set autoscale x
#set xrange [ "2017-9-5":"2018-9-5" ]
set ylabel "Instructions"
set format x "%Y-%m-%d"
set grid
set key left
plot 'root.dat' using 1:4 t ''
#     'root-modules.dat' using 1:2 t '', \
#     'root-modules.dat' using 1:2 t 'Instructions (C++ modules)' with points



