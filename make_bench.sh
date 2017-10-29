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

###################################################################
# Parse script args
echo "Num args: $#"
if [ "$#" -ne 1 ]; then
    git_time=`date "+%F %H:%M"`
    echo "Taking current time"
else
    git_time="$1"
fi
git_day=`echo $git_time | awk '{print $1}'`
echo "Taking benchmark at time $git_time with day $git_day"

###################################################################
# Parse config

output_dir=`./get_config.py output-dir $DIR/build`
echo "Output directory for SVG files is '$output_dir'"
output_url=`./get_config.py output-url`
echo "Output public URL for SVG files is '$output_url'"

###################################################################
# Update root
[[ -d root ]] || git clone https://github.com/root-project/root.git
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

cmake -DCMAKE_C_FLAGS="-march=native -Wno-gnu-statement-expression $EXTRA_CC_FLAGS" \
      -DCMAKE_CXX_FLAGS="-march=native $EXTRA_CC_FLAGS" \
      -Dall=On -Dbuiltin_lz4=On -DCMAKE_BUILD_TYPE=Optimized -GNinja ../root

ionice -t -c 3 nice -n 19 ninja -j3

cd "$DIR"

make_profile() {
  echo "Profiling $1"
  safe_name=`echo "$1" | sed "s/\//__/g"`
  # Record instructions
  rm -f runtime_instructions.all

  echo "Profiling used instructions of $1..."
  for run in `seq $2`;
  do
    echo "Iteration $run"
    bash -c "cd $DIR/build/tutorials && LD_LIBRARY_PATH=$DIR/build/lib:/usr/lib:/usr/lib ROOTIGNOREPREFIX=1 perf stat -e instructions:u $DIR/build/bin/root.exe -l -q -b -n -x $1 -e return"  2>perf_out 1>/dev/null
    cat perf_out | grep instructions:u | awk '{print $1}' | tr -d "," >> runtime_instructions.all
  done
  ./make_average.py runtime_instructions.all runtime_instructions
  runtime_inst=`cat runtime_instructions | tr -d '[:space:]'`

  echo "Profiling memory of $1..."
  # Record memory of hsimple
  rm -f runtime_mem.all
  # Valgrind might return non-zero on a leak, so disable the early exit
  for run in `seq $2`;
  do
    echo "Iteration $run"
    set +e
    bash -c "cd $DIR/build/tutorials && LD_LIBRARY_PATH=$DIR/build/lib:/usr/lib:/usr/lib ROOTIGNOREPREFIX=1 /usr/bin/time -v -o $DIR/build/runtime_mem_tmp  $DIR/build/bin/root.exe -l -q -b -n -x hsimple.C -e return " 1>/dev/null  2>perf_out
    set -e
    cat "$DIR/build/runtime_mem_tmp" | grep "Maximum resident set size" | awk '{print $6}' >> runtime_mem.all
  done
  ./make_average.py runtime_mem.all runtime_mem
  runtime_mem=`cat runtime_mem | tr -d '[:space:]'`

  echo "$git_time $git_commit $runtime_mem" >> root-$safe_name.mem.dat
  echo "$git_time $git_commit $runtime_inst" >> root-$safe_name.inst.dat

  sort root-$safe_name.inst.dat -o inst.dat
  sort root-$safe_name.mem.dat -o mem.dat
  cp bench.gp current_bench.gp
  ./setup_bench.py current_bench.gp "$1"
  gnuplot current_bench.gp
  chmod 755 benchmark.svg
  cp benchmark.svg "$output_dir/root-$safe_name.$git_commit.svg"
  ./post-bench.py "$1 benchmark updated for commit $git_commit (extra compiler flags: $EXTRA_CC_FLAGS )" "$output_url/root-$safe_name.$git_commit.svg"
}



./list_benchmarks.py | while read -r line ; do
    make_profile $line
done
