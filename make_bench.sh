#!/bin/bash

###################################################################
# Setup the shell
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"
export LANG=C

# We want to stop on an error to not record corrupt data
set -e

###################################################################
# Setup ccache
ccache -s
export CC="clang"
export CXX="clang++"
export PATH="/usr/lib/ccache/bin/:$PATH"

echo "Num args: $#"
if [ "$#" -ne 1 ]; then
    git_time=`date "+%F %H:%M"`
    echo "Taking current time"
else
    git_time="$1"
fi
git_day=`echo $git_time | awk '{print $1}'`
echo "Taking benchmark at time $git_time with day $git_day"

cd root
git reset --hard
git clean -fd
git checkout master
git pull
git fetch --all
git checkout `git rev-list -n 1 --before="$git_time" master`
git_commit=`git log -1 --format="%H"   `
cd "$DIR"

rm -rf build
mkdir build
cd build

cmake -DCMAKE_C_FLAGS="-march=native -Wno-gnu-statement-expression" \
      -DCMAKE_CXX_FLAGS="-march=native" \
      -Dall=On -Dbuiltin_lz4=On -DCMAKE_BUILD_TYPE=Release -GNinja ../root

ionice -t -c 3 nice -n 19 ninja -j2 -l1

cd "$DIR"

# Record instructions of hsimple
rm -f build/tutorials/hsimple.root
rm -f runtime_instructions
# perf stat -e instructions:u ls /usr/share 2> perf_out ; cat perf_out | grep instructions:u | awk '{print $1}' | tr -d ","
bash -c "cd /home/root-bench/build/tutorials && LD_LIBRARY_PATH=/home/root-bench/build/lib:/usr/lib:/usr/lib ROOTIGNOREPREFIX=1 perf stat -e instructions:u /home/root-bench/build/bin/root.exe -l -q -b -n -x hsimple.C -e return"  2>perf_out 1>/dev/null
cat perf_out | grep instructions:u | awk '{print $1}' | tr -d "," > runtime_instructions
runtime_inst=`cat runtime_instructions | tr -d '[:space:]'`

# Record memory of hsimple
#valgrind --tool=massif --pages-as-heap=yes --massif-out-file=massif.out ls -alht /usr/ 1>/dev/null 2>/dev/null
rm -f build/tutorials/hsimple.root
rm -f runtime_mem
# Valgrind might return non-zero on a leak, so disable the early exit
set +e
bash -c "cd /home/root-bench/build/tutorials && LD_LIBRARY_PATH=/home/root-bench/build/lib:/usr/lib:/usr/lib ROOTIGNOREPREFIX=1 valgrind --tool=massif --pages-as-heap=yes --massif-out-file=/home/root-bench/massif.out /home/root-bench/build/bin/root.exe -l -q -b -n -x hsimple.C -e return " 1>/dev/null  2>perf_out
set -e
grep mem_heap_B massif.out | sed -e 's/mem_heap_B=\(.*\)/\1/' | sort -g | tail -n 1 | awk '{print $0 "/1000" }' | bc > runtime_mem
runtime_mem=`cat runtime_mem | tr -d '[:space:]'`

echo "$git_time $git_commit $runtime_mem" >> root-hsimple-mem.dat
echo "$git_time $git_commit $runtime_inst" >> root-hsimple-inst.dat



sort root-hsimple-inst.dat -o root-hsimple-inst.dat
cp root-hsimple-inst.dat root.dat
gnuplot bench-inst.gp
cp benchmark.svg root-hsimple-inst.svg
chmod 755 root-hsimple-inst.svg
cp root-hsimple-inst.svg /var/www/pub/benchs/root-hsimple-inst-$git_commit.svg
./post-bench.py "hsimple benchmark updated (instructions)" "https://teemperor.de/pub/benchs/root-hsimple-inst-$git_commit.svg"

sort root-hsimple-mem.dat -o root-hsimple-mem.dat
cp root-hsimple-mem.dat root.dat
gnuplot bench-mem.gp
cp benchmark.svg root-hsimple-mem.svg
chmod 755 root-hsimple-mem.svg
cp root-hsimple-mem.svg /var/www/pub/benchs/root-hsimple-mem-$git_commit.svg
./post-bench.py "hsimple benchmark updated (memory)" "https://teemperor.de/pub/benchs/root-hsimple-mem-$git_commit.svg"

