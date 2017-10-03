set terminal svg size 1000,400  enhanced background rgb 'white'
set output 'benchmark.svg'

set multiplot layout 1,2 rowsfirst

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
plot 'root-hsimple-inst.dat' using 1:4 t ''

set title "Memory of hsimple"
set style data fsteps
set xlabel "Date\n"
set timefmt '%Y-%m-%d'
set yrange [ 0 : ]
set xdata time
set xtics rotate by 45 offset -3, -3
set autoscale x
#set xrange [ "2017-9-5":"2018-9-5" ]
set ylabel "Memory in kB"
set format x "%Y-%m-%d"
set grid
set key left
plot 'root-hsimple-mem.dat' using 1:4 t ''
