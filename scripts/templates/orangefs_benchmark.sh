#! /usr/bin/env bash

set -u
set -e
set -x

CWD=$(pwd)
ORANGEFS_STUFF="$CWD"
# ORANGEFS_CONFS="$CWD/conf/"
DL="$CWD/darshan_logs"
HACC_VAL=4194304
#HACC_VAL=16777216
MPI_PROCS=40
TIERS=( "ssd" "hdd" )
PVFS_LOC="/mnt/nvme/nrajesh/write/generic"
# CLIENTS=( 16 8 4 1 )
CLIENTS=( 16 8 4 )
SERVERS=( 16 8 4 )
NETWORKS=( 40 10 )
IOROPTIONS=( "" "-z" )
# IOROPTIONS=( "" )
# IOSIZES=( "16mb" "1mb" "1kb" )
IOSIZES=( "1mb" "16mb" "1kb" )
# DSIZE="512m"
DSIZE="256m"
MDFILES=10000
SNO=1
FOLDER_INDEX=$(date +%Y%m%d%H%M%S)
CSV_HEADERS="$CWD/csv_stuff-$FOLDER_INDEX"

IOREXEC="/mnt/common/nrajesh/sources/spack/opt/spack/linux-centos7-skylake_avx512/gcc-7.3.0/ior-3.3.0-snqphmjtltxqqm2v6hfmadt7dst3p4pl/bin/ior"
OPENMPIEXEC="/mnt/common/nrajesh/sources/spack/opt/spack/linux-centos7-skylake_avx512/gcc-7.3.0/openmpi-4.0.5-bely7blnsxukny5uxhd3km75fnep2voh/bin/mpirun"
DEPLOYMENTLOG="${CWD}/deploy.log"
BENCHLOG="${CWD}/bench.log"
MPIHOST="${CWD}/mpi_host"


mkdir -p $CSV_HEADERS
rm -f $DEPLOYMENTLOG
rm -f $BENCHLOG

function ProgressBar {
    # Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
    # Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}
# Magic number 12 is number of confs per tier
# TOTALOPS=$(( 12 * ${#IOSIZES[@]} * ${#TIERS[@]} * ${#CLIENTS[@]} * ${#SERVERS[@]} * ${#NETWORKS[@]} * ${#IOROPTIONS} ))
TOTALOPS=$(( 12 * 3 * 2 * 3 * 3 * 2 * 2 ))
# s/n clients servers network device storage config req_size mdm_reqs_per_process IO_type Total_Size mdm_time write_time read_time
## TODO device: add logic to change the DataStorageSpace and MetadataStorageSpace between nvme, ssd and hdd (change the val in the config)

for TIER in "${TIERS[@]}"
do
    for NET in "${NETWORKS[@]}"
    do
	for SI in "${SERVERS[@]}"
	do
	    for CI in "${CLIENTS[@]}"
	    do
		# ORANGEFS_CONFS="${CWD}/conf_${TIER}/orangefs_${SI}_${NET}.conf"
		ORANGEFS_CONF_LOC="${CWD}/conf_${TIER}_${SI}_${NET}"
		HOSTSERVER="${CWD}/hostfiles/hostfile_servers_${SI}_${NET}"
		HOSTCLIENT="${CWD}/hostfiles/hostfile_clients_${CI}_${NET}"

		for ORANGEFS_CONFS in $ORANGEFS_CONF_LOC/*
		do

		    cd $ORANGEFS_STUFF
		    bash deploy.sh ${ORANGEFS_CONFS} ${HOSTSERVER} ${HOSTCLIENT} >> ${DEPLOYMENTLOG}
		    # ProgressBar ${SNO} ${TOTALOPS}
		    echo -e "\r\r\r\r\r\r\r\r\r\r\r\r ${SNO} / ${TOTALOPS}"
		    cd $PVFS_LOC

		    for ioop in "${IOROPTIONS[@]}"
		    do
			for io in "${IOSIZES[@]}"
			do
			    # add another look for TODO device
			    echo $SNO >> $CSV_HEADERS/sno
			    SNO=$(( $SNO + 1 ))
			    echo $SI >> $CSV_HEADERS/servers
			    echo ${TIER} >> $CSV_HEADERS/device
			    echo "PFS" >> $CSV_HEADERS/storage
			    echo $ORANGEFS_CONFS >> $CSV_HEADERS/confs
			    echo $io >> $CSV_HEADERS/req_size

			    echo ${NET} >> $CSV_HEADERS/network
			    # set +e

			    echo $CI >> $CSV_HEADERS/clients

			    if [ "$ioop" == "" ]
			    then
				echo "sequential" >> $CSV_HEADERS/iotype
			    else
				echo "random" >> $CSV_HEADERS/iotype
			    fi

			    DSIZE="256m"


			    if [ $NET == 10 ]
			    then
				DSIZE="128m"
			    fi

			    if [ "$io" == "1kb" ]
			    then
				DSIZE="8m"
			    fi

			    echo $DSIZE >> $CSV_HEADERS/total_size
			    rm -f $MPIHOST
			    for i in $(cat ${HOSTCLIENT})
			    do
				echo "$i slots=40" >> $MPIHOST
			    done

			    echo "########## $ORANGEFS_CONFS ####################" >> ${BENCHLOG}
			    ${OPENMPIEXEC} --hostfile $MPIHOST -n $MPI_PROCS ${IOREXEC} -t $io -g -b $DSIZE $ioop -o $PVFS_LOC/testfile >> $CSV_HEADERS/ior_op

			done

		    done
		    cd  $ORANGEFS_STUFF
		    bash stop_all.sh ${ORANGEFS_CONFS} ${HOSTSERVER} ${HOSTCLIENT} >> ${DEPLOYMENTLOG}
		done
	    done
	done

    done
done
