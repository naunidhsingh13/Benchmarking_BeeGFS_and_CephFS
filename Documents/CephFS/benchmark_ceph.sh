#!/usr/bin/env bash

set -u
set -e
set -x

CWD=$(pwd)
mkdir -p "BENCHMARKS_Tushar"

#MPI_PROCS=48

PVFS_LOC="/mnt/beegfs"
IOROPTIONS=("-z")
IOSIZES=("1mb" "64kb")

#DSIZE="128m"

SNO=1
FOLDER_INDEX=$(date +%Y%m%d%H%M%S)
CSV_HEADERS="$CWD/BENCHMARKS_Tushar/csv_stuff-$FOLDER_INDEX"

IOREXEC="./ior"
OPENMPIEXEC="mpirun"
BENCHLOG="${CWD}/bench.log"
MPIHOST="${CWD}/config/clients48p"

mkdir -p $CSV_HEADERS
rm -f $BENCHLOG

pdsh -N -w ^config/serverhosts -R ssh "sar -u ALL 1 -o /tmp/cpu > /dev/null 2>&1" &    # CPU
pdsh -N -w ^config/serverhosts -R ssh "sar -dbp 1 -o /tmp/io > /dev/null 2>&1" &       # IO
pdsh -N -w ^config/serverhosts -R ssh "sar -n IP 1 -o /tmp/netip > /dev/null 2>&1" &   # Network
pdsh -N -w ^config/serverhosts -R ssh "sar -n DEV 1 -o /tmp/netdev > /dev/null 2>&1" & # Network

for MPI_PROCS in 8 16 32 40
do
  for ioop in "${IOROPTIONS[@]}" 
  do
    for io in "1mb" "64kb" 
    do
      SNO=$(($SNO + 1))
      DSIZE="$((4096/$MPI_PROCS))m"
      ITER_DIR=$CSV_HEADERS/block${DSIZE}_transfer${io}_ioop${ioop}
      mkdir -p $ITER_DIR
      echo $DSIZE >>$ITER_DIR/total_size.dat
      ${OPENMPIEXEC} --hostfile $MPIHOST -n $MPI_PROCS ${IOREXEC} -t $io -g -b $DSIZE --posix.odirect $ioop -o $PVFS_LOC/testfile >>$ITER_DIR/ior_op.dat
    done
    sleep 120
  done
  sleep 120
done

pdsh -N -w ^config/serverhosts -R ssh "sudo pkill -f \"sar -\""
pdsh -N -w ^config/serverhosts -R ssh "sadf -d /tmp/cpu -- -u ALL 1" >$CSV_HEADERS/cpu.csv
pdsh -N -w ^config/serverhosts -R ssh "sadf -d /tmp/io -- -dbp 1" >$CSV_HEADERS/io.csv
pdsh -N -w ^config/serverhosts -R ssh "sadf -d /tmp/netip -- -n IP 1" >$CSV_HEADERS/netip.csv
pdsh -N -w ^config/serverhosts -R ssh "sadf -d /tmp/netdev -- -n DEV 1" >$CSV_HEADERS/netdev.csv
pdsh -N -w ^config/serverhosts -R ssh "rm /tmp/cpu /tmp/io /tmp/netip /tmp/netdev"
