#!/bin/bash
#COBALT -t 10
#COBALT -n 2
#COBALT --attrs mcdram=cache:numa=quad:ssds=required:ssd_size=16
#COBALT -A ecp-testbed-01
#COBALT -q debug-flat-quad
#COBALT -o btio_1_10.txt
#COBALT -e btio_1_10.err

export n_nodes=$COBALT_JOBSIZE
export n_mpi_ranks_per_node=${PPN}
export n_mpi_ranks=$(($n_nodes * $n_mpi_ranks_per_node))
export n_openmp_threads_per_rank=1
export n_hyperthreads_per_core=1

RUNS=(1) # Number of runs
OUTDIR=/projects/radix-io/khou/FS_56_8M/btio
BBDIR=/local/scratch
PPN=4
#PPN=64
#NN=${COBALT_JOBSIZE}
NN=1
let NP=NN*PPN
let SLEEPNN=${COBALT_JOBSIZE}-NN
TL=300

#EDGEL=sqrt(NP)*16
EDGEL=32
DIMX=${EDGEL}
DIMY=${EDGEL}
DIMZ=512
NITR=8 # 5 * 8 MiB /process

NODE_USED=$(aprun -q ./selnode ${NN} ${COBALT_PARTNAME})
echo "Nodes Available: ${COBALT_PARTNAME}"
echo "Nodes Used: ${NODE_USED}"

echo "mkdir -p ${OUTDIR}"
mkdir -p ${OUTDIR}

TSTARTTIME=`date +%s.%N`

for i in ${RUNS[@]}
do
    # Ncmpio    
    echo "========================== NCMPI =========================="
    >&2 echo "========================== NCMPI =========================="

    echo "#%$: io_driver: ncmpi"
    echo "#%$: number_of_nodes: ${NN}"
    echo "#%$: number_of_proc: ${NP}"
    echo "#%$: io_mode: blocking_coll"

    echo "rm -f ${OUTDIR}/*"
    rm -f ${OUTDIR}/*
    
    let IO_METHOD=2
    echo "m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data"
    m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data

    STARTTIME=`date +%s.%N`

    aprun -n ${NP} -N ${PPN} -t ${TL} -L ${NODE_USED} ./btio

    ENDTIME=`date +%s.%N`
    TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."$2}'`

    echo "#%$: exe_time: $TIMEDIFF"

    echo "ls -lah ${OUTDIR}"
    ls -lah ${OUTDIR}
    echo "lfs getstripe ${OUTDIR}"
    lfs getstripe ${OUTDIR}

    echo '-----+-----++------------+++++++++--+---'

    # Ncmpio NB

    echo "========================== NCMPI NB =========================="
    >&2 echo "========================== NCMPI NB =========================="
    
    echo "#%$: io_driver: ncmpi"
    echo "#%$: number_of_nodes: ${NN}"
    echo "#%$: number_of_proc: ${NP}"
    echo "#%$: io_mode: nonblocking_coll"

    echo "rm -f ${OUTDIR}/*"
    rm -f ${OUTDIR}/*
    
    let IO_METHOD=3
    echo "m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data"
    m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data

    STARTTIME=`date +%s.%N`

    aprun -n ${NP} -N ${PPN} -t ${TL} -L ${NODE_USED}  ./btio

    ENDTIME=`date +%s.%N`
    TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."$2}'`

    echo "#%$: exe_time: $TIMEDIFF"

    echo "ls -lah ${OUTDIR}"
    ls -lah ${OUTDIR}
    echo "lfs getstripe ${OUTDIR}"
    lfs getstripe ${OUTDIR}

    echo '-----+-----++------------+++++++++--+---' 

    # BB LPP P

    echo "========================== BB LPP P ALL =========================="
    >&2 echo "========================== BB LPP P ALL =========================="

    echo "#%$: io_driver: bb_lpp_private"
    echo "#%$: number_of_nodes: ${NN}"
    echo "#%$: number_of_proc: ${NP}"
    echo "#%$: io_mode: blocking_coll"

    echo "rm -f ${OUTDIR}/*"
    rm -f ${OUTDIR}/*

    let IO_METHOD=12
    echo "m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data"
    m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data

    STARTTIME=`date +%s.%N`

    aprun -n ${NP} -N ${PPN}  -t ${TL} -L ${NODE_USED} -e PNETCDF_HINTS="nc_burst_buf=enable;nc_burst_buf_del_on_close=disable;nc_burst_buf_overwrite=enable;nc_burst_buf_dirname=${BBDIR}" ./btio
    
    ENDTIME=`date +%s.%N`
    TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."$2}'`

    echo "#%$: exe_time: $TIMEDIFF"

    echo "ls -lah ${OUTDIR}"
    ls -lah ${OUTDIR}
    echo "lfs getstripe ${OUTDIR}"
    lfs getstripe ${OUTDIR}

    echo '-----+-----++------------+++++++++--+---'
    
    # BB LPN S

    echo "========================== BB LPN P =========================="
    >&2 echo "========================== BB LPN P =========================="

    echo "#%$: io_driver: bb_lpn_private"
    echo "#%$: number_of_nodes: ${NN}"
    echo "#%$: number_of_proc: ${NP}"
    echo "#%$: io_mode: blocking_coll"

    echo "rm -f ${OUTDIR}/*"
    rm -f ${OUTDIR}/*

    let IO_METHOD=12
    echo "m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data"
    m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data

    STARTTIME=`date +%s.%N`

    aprun -n ${NP} -N ${PPN}  -t ${TL} -L ${NODE_USED} -e PNETCDF_HINTS="nc_burst_buf=enable;nc_burst_buf_del_on_close=disable;nc_burst_buf_shared_logs=enable;nc_burst_buf_overwrite=enable;nc_burst_buf_dirname=${BBDIR}" ./btio

    ENDTIME=`date +%s.%N`
    TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."$2}'`

    echo "#%$: exe_time: $TIMEDIFF"

    echo "ls -lah ${OUTDIR}"
    ls -lah ${OUTDIR}
    echo "lfs getstripe ${OUTDIR}"
    lfs getstripe ${OUTDIR}

    echo '-----+-----++------------+++++++++--+---'
    
    # BB LPP P Itr

    echo "========================== BB LPP P Itr =========================="
    >&2 echo "========================== BB LPP P Itr =========================="

    echo "#%$: io_driver: bb_lpp_private_itr"
    echo "#%$: number_of_nodes: ${NN}"
    echo "#%$: number_of_proc: ${NP}"
    echo "#%$: io_mode: blocking_coll"

    echo "rm -f ${OUTDIR}/*"
    rm -f ${OUTDIR}/*

    let IO_METHOD=2
    echo "m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data"
    m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=${OUTDIR} inputbt.m4 > inputbt.data

    STARTTIME=`date +%s.%N`

    aprun -n ${NP} -N ${PPN} -t ${TL} -L ${NODE_USED} -e PNETCDF_HINTS="nc_burst_buf=enable;nc_burst_buf_del_on_close=disable;nc_burst_buf_overwrite=enable;nc_burst_buf_dirname=${BBDIR}" ./btio
    
    ENDTIME=`date +%s.%N`
    TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."$2}'`

    echo "#%$: exe_time: $TIMEDIFF"

    echo "ls -lah ${OUTDIR}"
    ls -lah ${OUTDIR}
    echo "lfs getstripe ${OUTDIR}"
    lfs getstripe ${OUTDIR}

    echo '-----+-----++------------+++++++++--+---'
    
    # LogFS

    echo "========================== Logfs =========================="
    >&2 echo "========================== Logfs =========================="
    
    echo "#%$: io_driver: logfs"
    echo "#%$: number_of_nodes: ${NN}"
    echo "#%$: number_of_proc: ${NP}"
    echo "#%$: io_mode: blocking_coll"

    echo "rm -f ${OUTDIR}/*"
    rm -f ${OUTDIR}/*

    let IO_METHOD=2
    echo "m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=logfs:${OUTDIR} inputbt.m4 > inputbt.data"
    m4 -D io_method=${IO_METHOD} -D n_itr=${NITR} -D dim_x=${DIMX} -D dim_y=${DIMY} -D dim_z=${DIMZ} -D out_dir=logfs:${OUTDIR} inputbt.m4 > inputbt.data

    STARTTIME=`date +%s.%N`

    aprun -n ${NP} -N ${PPN} -t ${TL} -L ${NODE_USED} -e PNETCDF_HINTS="logfs_replayonclose=true;logfs_info_logbase=${BBDIR}/;logfs_flushblocksize=268435456" ./btio_logfs

    ENDTIME=`date +%s.%N`
    TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."$2}'`

    echo "#%$: exe_time: $TIMEDIFF"

    echo "ls -lah ${OUTDIR}"
    ls -lah ${OUTDIR}
    echo "lfs getstripe ${OUTDIR}"
    lfs getstripe ${OUTDIR}
    
    echo '-----+-----++------------+++++++++--+---'
done

ENDTIME=`date +%s.%N`
TIMEDIFF=`echo "$ENDTIME - $TSTARTTIME" | bc | awk -F"." '{print $1"."$2}'`
echo "-------------------------------------------------------------"
echo "total_exe_time: $TIMEDIFF"
echo "-------------------------------------------------------------"

