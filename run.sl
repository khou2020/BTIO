#!/bin/bash
#SBATCH -p regular
#SBATCH -N 32 
#SBATCH -C haswell
#SBATCH -t 00:08:00
#SBATCH -o btio_hdf5_32_%j.txt
#SBATCH -e btio_hdf5_32_%j.err
#SBATCH -L SCRATCH
#SBATCH -A m844

NN=${SLURM_NNODES}
#let NP=NN*16
let NP=NN*32 

export LD_LIBRARY_PATH=/global/homes/k/khl7265/.local/hdf5/1.12.0/lib:${HOME}/.local/log_io_vol/profiling/lib:${LD_LIBRARY_PATH}

RUNS=(1 2) # Number of runs

OUTDIR_ROOT=/global/cscratch1/sd/khl7265/FS_64_8M/btio

MPI_COLL=0
MPI_INDEP=1
PNC_B=2
PNC_NB=3
HDF5=4
HDF5_LOG=5

APP_NAMES=(mpi_coll mpi_indep pnc_b pnc_nb hdf5 hdf5_log)

APP=btio
#APIS=(${PNC_NB} ${HDF5} ${HDF5_LOG})
APIS=(${PNC_NB} ${HDF5_LOG})
OPS=(w)
TL=8

#EDGEL=sqrt(NP)*32
EDGEL=1024
DIMX=${EDGEL}
DIMY=${EDGEL}
DIMZ=${EDGEL}
NITR=1 # 5 * 8 MiB /process

echo "mkdir -p ${OUTDIR_ROOT}"
mkdir -p ${OUTDIR_ROOT}
for API in ${APIS[@]}
do
    echo "mkdir -p ${OUTDIR_ROOT}/${APP_NAMES[${API}]}"
    mkdir -p ${OUTDIR_ROOT}/${APP_NAMES[${API}]}
done

ulimit -c unlimited

TSTARTTIME=`date +%s.%N`

for i in ${RUNS[@]}
do
    for API in ${APIS[@]}
    do
        OUTDIR=${OUTDIR_ROOT}/${APP_NAMES[${API}]}/
        echo "rm -f ${OUTDIR}/*"
        rm -f ${OUTDIR}/*

        for OP in ${OPS[@]}
        do
            echo "========================== BTIO ${API} ${OP} =========================="
            >&2 echo "========================== BTIO ${API} ${OP}=========================="
            
            echo "#%$: exp: BTIO"
            echo "#%$: app: ${APP}"
            echo "#%$: api: ${APP_NAMES[${API}]}"
            echo "#%$: operation: ${OP}"
            echo "#%$: number_of_nodes: ${NN}"
            echo "#%$: number_of_proc: ${NP}"
            echo "#%$: dimx: ${DIMX}"
            echo "#%$: dimy: ${DIMY}"
            echo "#%$: dimz: ${DIMZ}"
            echo "#%$: nitr: ${NITR}"

            echo "m4 -D io_method=${API} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data"
            m4 -D io_method=${API} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data

            STARTTIME=`date +%s.%N`

            if [ "${API}" = "5" ] ; then
                export HDF5_VOL_CONNECTOR="LOG under_vol=0;under_info={}"
                export HDF5_PLUGIN_PATH=${HOME}/.local/log_io_vol/profiling/lib
            else
                unset HDF5_VOL_CONNECTOR
                unset HDF5_PLUGIN_PATH
            fi
            
            echo "srun -n ${NP} -t ${TL} ./${APP}"
            srun -n ${NP} -t ${TL} ./${APP}

            ENDTIME=`date +%s.%N`
            TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."$2}'`

            echo "#%$: exe_time: $TIMEDIFF"

            echo "ls -lah ${OUTDIR}"
            ls -lah ${OUTDIR}
            echo "lfs getstripe ${OUTDIR}"
            lfs getstripe ${OUTDIR}

            echo '-----+-----++------------+++++++++--+---'
        done
    done
done

ENDTIME=`date +%s.%N`
TIMEDIFF=`echo "$ENDTIME - $TSTARTTIME" | bc | awk -F"." '{print $1"."$2}'`
echo "-------------------------------------------------------------"
echo "total_exe_time: $TIMEDIFF"
echo "-------------------------------------------------------------"
