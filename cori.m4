changequote(`[[[', `]]]')dnl
changecom([[[###]]], [[[$$$]]])dnl
#!/bin/bash
#SBATCH -q EXP_QUEUE
#SBATCH -N EXP_NN
#SBATCH -C EXP_NODE_TYPE
#SBATCH -t 00:EXP_TL:00
#SBATCH -o EXP_NAME.txt
#SBATCH -e EXP_NAME.err
#SBATCH -L SCRATCH
#SBATCH -A EXP_ACC

BTIO_DATE="EXP_BTIO_DATE"
HDF5_LIB_PATH=EXP_HDF5_LIB_PATH
HDF5_LIB_DATE="EXP_HDF5_LIB_DATE"
PNC_LIB_PATH=EXP_PNC_LIB_PATH
LOGVOL_LIB_PATH=EXP_LOGVOL_LIB_PATH
LOGVOL_LIB_DATE="EXP_LOGVOL_LIB_DATE"
PPN=EXP_PPN
RTL=EXP_RTL
OUTDIR_ROOT=EXP_OUTDIR_ROOT

OPS=EXP_OP
DIMX=EXP_XL
DIMY=EXP_YL
DIMZ=EXP_ZL
NITR=EXP_RECS

MPI_COLL=0
MPI_INDEP=1
PNC_B=2
PNC_NB=3
HDF5=4
HDF5_LOG=5
APP_NAMES=(mpi_coll mpi_indep pnc_b pnc_nb hdf5 hdf5_log)

APP=btio
APIS=(${PNC_NB} ${HDF5_LOG})

NN=${SLURM_NNODES}
let NP=NN*PPN

# Print exp setting
echo "#%$: btio_hash: EXP_BTIO_HASH"
echo "#%$: pnc_hash: EXP_PNC_HASH"
echo "#%$: pnc_path: ${PNC_LIB_PATH}"
echo "#%$: hdf5_hash: EXP_HDF5_HASH"
echo "#%$: hdf5_path: ${HDF5_LIB_PATH}"
echo "#%$: logvol_hash: EXP_LOGVOL_HASH"
echo "#%$: logvol_path: ${LOGVOL_LIB_PATH}"
echo "#%$: submit_date: EXP_SUBMIT_DATE"
echo "#%$: exe_date: $(date)"
echo "#%$: exp: btio"
echo "#%$: repeation: EXP_RUNS"
echo "#%$: output_folder: EXP_OUTDIR_ROOT"
echo "#%$: number_of_nodes: ${NN}"
echo "#%$: number_of_proc: ${NP}"
echo '-----+-----++----***--------+++++**++++--+---'

echo "mkdir -p ${OUTDIR_ROOT}"
mkdir -p ${OUTDIR_ROOT}
for API in ${APIS[@]}
do
    echo "mkdir -p ${OUTDIR_ROOT}/${APP_NAMES[${API}]}"
    mkdir -p ${OUTDIR_ROOT}/${APP_NAMES[${API}]}
done

export LD_LIBRARY_PATH=${HDF5_LIB_PATH}/lib:${PNC_LIB_PATH}/lib:${LOGVOL_LIB_PATH}/lib:${LD_LIBRARY_PATH}
export H5VL_LOG_METADATA_MERGE=1
export H5VL_LOG_METADATA_ZIP=1
export H5VL_LOG_SEL_ENCODING=1

ulimit -c unlimited

TSTARTTIME=`date +%s.%N`

for i in $(seq EXP_RUNS);
do
    for API in ${APIS[@]}
    do
        OUTDIR=${OUTDIR_ROOT}/${APP_NAMES[${API}]}/
        echo "rm -f ${OUTDIR}/*"
        rm -f ${OUTDIR}/*

        for (( j=0; j<${#OPS}; j++ ));
        do
            OP=${OPS:$j:1}

            echo "========================== BTIO ${APP_NAMES[${API}]} ${OP} =========================="
            >&2 echo "========================== BTIO ${APP_NAMES[${API}]} ${OP}=========================="
            
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
            echo "#%$: logvol_metadata_merge: ${H5VL_LOG_METADATA_MERGE}"
            echo "#%$: logvol_metadata_zip: ${H5VL_LOG_METADATA_ZIP}"
            echo "#%$: logvol_metadata_encoding: ${H5VL_LOG_SEL_ENCODING}"

            echo "m4 -D io_op=${OP} -D io_method=${API} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data"
            m4 -D io_op=${OP} -D io_method=${API} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data

            STARTTIME=`date +%s.%N`

            if [ "${API}" = "5" ] ; then
                export HDF5_VOL_CONNECTOR="LOG under_vol=0;under_info={}"
                export HDF5_PLUGIN_PATH=${LOGVOL_LIB_PATH}/lib
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
