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
html_report="$output_dir/benchmarks.html"
echo "Outputting HTML to $html_report"
html_report_tmp="$DIR/report_tmp.html"

./gen_gp.py
./make_build_configs.py

mapfile -t build_names < "$DIR/build_names"
mapfile -t build_ids < "$DIR/build_ids"
mapfile -t build_flags_list < "$DIR/build_flags"
declare -a build_dirs
build_configs="${#build_names[@]}"

for (( i=0; i<$build_configs; i++ ));
do
  echo "Found config $i:"

  build_name="${build_names[$i]}"
  build_id="${build_ids[$i]}"
  build_flags="${build_flags_list[$i]}"

  build_dirs[$i]="$DIR/build-$build_id"
  build_dir="${build_dirs[$i]}"

  echo "  Name: $build_name"
  echo "  ID: $build_id"
  echo "  Flags: $build_flags"
  echo "  Build dir: $build_dir"
done

###################################################################
# Update root
echo "Updating/getting ROOT source"
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

for (( i=0; i<$build_configs; i++ ));
do
  echo "Building config $i:"

  build_name="${build_names[$i]}"
  build_id="${build_ids[$i]}"
  build_flags="${build_flags_list[$i]}"
  build_dir="${build_dirs[$i]}"

  echo "  Name: $build_name"
  echo "  ID: $build_id"
  echo "  Flags: $build_flags"
  echo "  Build dir: $build_dir"

  rm -rf "$build_dir"
  mkdir "$build_dir"
  cd "$build_dir"

  cmake -DCMAKE_C_FLAGS="-march=native -Wno-gnu-statement-expression" \
        -DCMAKE_CXX_FLAGS="-march=native " \
        -Dall=On -Dbuiltin_lz4=On -DCMAKE_BUILD_TYPE=Optimized $build_flags -GNinja ../root

  ionice -t -c 3 nice -n 19 ninja -j3
done

cd "$DIR"

make_profile() {
  safe_name=`echo "$1" | sed "s/\//__/g"`

  for (( i=0; i<$build_configs; i++ ));
  do
    echo "Benchmarking config $i:"

    build_name="${build_names[$i]}"
    build_id="${build_ids[$i]}"
    build_flags="${build_flags_list[$i]}"
    build_dir="${build_dirs[$i]}"

    echo "  Name: $build_name"

    make_profile_single "$1" "$2" "$safe_name" "$build_id" "$build_dir"
  done

  cp bench.gp current_bench.gp
  ./setup_bench.py current_bench.gp "$1"
  gnuplot current_bench.gp
  chmod 755 benchmark.svg
  cp benchmark.svg "$output_dir/root-$safe_name.$git_commit.svg"
  ./post-bench.py "$1 benchmark updated for commit $git_commit" "$output_url/root-$safe_name.$git_commit.svg"
  echo "<img class='benchmark' src='${output_url}/root-${safe_name}.${git_commit}.svg' height='100%'>" >> "$html_report_tmp"
}

make_profile_single() {
  echo "Profiling $1"
  safe_name="$3"
  runs="$2"
  # Record instructions
  rm -f runtime_instructions.all
  build_id="$4"
  build_dir="$5"

  echo "Profiling using instructions of $1..."
  for run in `seq $runs`;
  do
    echo "Iteration $run"
    bash -c "cd $build_dir/tutorials && LD_LIBRARY_PATH=$build_dir/lib:/usr/lib:/usr/lib ROOTIGNOREPREFIX=1 perf stat -e instructions:u $build_dir/bin/root.exe -l -q -b -n -x $1 -e return"  2>perf_out 1>/dev/null
    cat perf_out | grep instructions:u | awk '{print $1}' | tr -d "," >> runtime_instructions.all
  done
  ./make_average.py runtime_instructions.all runtime_instructions
  runtime_inst=`cat runtime_instructions | tr -d '[:space:]'`

  echo "Profiling memory of $1..."
  # Record memory of hsimple
  rm -f runtime_mem.all
  for run in `seq $runs`;
  do
    echo "Iteration $run"
    bash -c "cd $build_dir/tutorials && LD_LIBRARY_PATH=$build_dir/lib:/usr/lib:/usr/lib ROOTIGNOREPREFIX=1 /usr/bin/time -v -o $build_dir/runtime_mem_tmp  $build_dir/bin/root.exe -l -q -b -n -x hsimple.C -e return " 1>/dev/null  2>perf_out
    cat "$build_dir/runtime_mem_tmp" | grep "Maximum resident set size" | awk '{print $6}' >> runtime_mem.all
  done
  ./make_average.py runtime_mem.all runtime_mem
  runtime_mem=`cat runtime_mem | tr -d '[:space:]'`

  echo "$git_time $git_commit $runtime_mem" >> root-$safe_name.mem.$build_id.dat
  echo "$git_time $git_commit $runtime_inst" >> root-$safe_name.inst.$build_id.dat
  sort root-$safe_name.mem.$build_id.dat -o root-$safe_name.mem.$build_id.dat
  sort root-$safe_name.inst.$build_id.dat -o root-$safe_name.inst.$build_id.dat

  cp root-$safe_name.mem.$build_id.dat mem.$build_id.dat
  cp root-$safe_name.inst.$build_id.dat inst.$build_id.dat
}

cp "$DIR/prefix.html" "$html_report_tmp"

./list_benchmarks.py | while read -r line ; do
    make_profile $line
done

cat "$DIR/suffix.html" >> "$html_report_tmp"
echo "Publishing HTML report"
cp "$html_report_tmp" "$html_report"
