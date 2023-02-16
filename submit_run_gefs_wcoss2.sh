#!/bin/sh

#PBS -j oe
#PBS -N gefs_post
#PBS -l walltime=00:30:00
#PBS -q debug
#PBS -A GFS-DEV
#PBS -l place=vscatter,select=4:ncpus=12
#PBS -V

cd $PBS_O_WORKDIR

set -x

# specify computation resource
export threads=1
export MP_LABELIO=yes
export OMP_NUM_THREADS=$threads
export APRUN="mpiexec -l -n 48 -ppn 12 --cpu-bind core --depth 1"

echo "starting time" 
date

############################################
# Loading module
############################################
module reset
module load intel/19.1.3.304
module load PrgEnv-intel/8.1.0
module load craype/2.7.8
module load cray-mpich/8.1.7
module load cray-pals/1.0.12
module load hdf5/1.10.6
module load netcdf/4.7.4
module load libjpeg/9c
module load prod_util/2.0.8
module list

gitdir=`pwd`
export POSTGPEXEC=${gitdir}/exec/upp.x
export rundir=/u/$USER/ptmp
#export datain=/u/wen.meng/noscrub/ncep_post/gefsv13/data/c00
export datain=/u/wen.meng/noscrub/ncep_post/gefsv13/data/p01


# specify forecast start time and hour for running your post job
export startdate=2022012112
export CC=`echo $startdate | cut -c9-10`
export fhr=015

# specify your running and output directory
export DATA=/lfs/h2/emc/ptmp/${USER}/post_gefs_${startdate}

# specify your home directory 
export homedir=`pwd`/..

export tmmark=tm00

rm -rf $DATA; mkdir -p $DATA
cd $DATA

export NEWDATE=`${NDATE} +${fhr} $startdate`
                                                                                       
export YY=`echo $NEWDATE | cut -c1-4`
export MM=`echo $NEWDATE | cut -c5-6`
export DD=`echo $NEWDATE | cut -c7-8`
export HH=`echo $NEWDATE | cut -c9-10`


cat > itag <<EOF
&model_inputs
fileName='$datain/gefs.t${CC}z.atmf${fhr}.nc'
IOFORM='netcdf'
grib='grib2'
DateStr='${YY}-${MM}-${DD}_${HH}:00:00'
MODELNAME='GFS'
fileNameFlux='$datain/gefs.t${CC}z.sfcf${fhr}.nc'
/
 &NAMPGB
 KPO=50,PO=1000.,975.,950.,925.,900.,875.,850.,825.,800.,775.,750.,725.,700.,675.,650.,625.,600.,575.,550.,525.,500.,475.,450.,425.,400.,375.,350.,325.,300.,275.,250.,225.,200.,175.,150.,125.,100.,70.,50.,40.,30.,20.,15.,10.,7.,5.,3.,2.,1.,0.4,
 /
EOF


rm -f fort.*

cp ${gitdir}/parm/nam_micro_lookup.dat ./eta_micro_lookup.dat

# copy flat files instead
#cp /u/wen.meng/noscrub/ncep_post/post_regression_test_new/fix/postxconfig-NT-GEFS-CHEM.txt ./postxconfig-NT.txt
#cp ${gitdir}/parm/postxconfig-NT-GEFS.txt ./postxconfig-NT.txt
ens_pert_type=pos_pert_fcst  ##pertubation
#ens_pert_type=unpert_lo_res_ctrl_fcst  ##control
sed < ${gitdir}/parm/postxconfig-NT-GEFS.txt -e "s#negatively_pert_fcst#${ens_pert_type}#" > ./postxconfig-NT.txt
#ensemble control
#export e1=1
#export e2=00
#export e3=30
#ensemble pertubation
export e1=3
export e2=01
export e3=30

cp ${gitdir}/parm/params_grib2_tbl_new ./params_grib2_tbl_new

#cp ${gitdir}/parm/optics_luts_DUST.dat ./optics_luts_DUST.dat
#cp ${gitdir}/parm/optics_luts_SALT.dat ./optics_luts_SALT.dat
#cp ${gitdir}/parm/optics_luts_SOOT.dat ./optics_luts_SOOT.dat
#cp ${gitdir}/parm/optics_luts_SUSO.dat ./optics_luts_SUSO.dat
#cp ${gitdir}/parm/optics_luts_WASO.dat ./optics_luts_WASO.dat


${APRUN} ${POSTGPEXEC} < itag > outpost_nems_${NEWDATE}

echo "PROGRAM IS COMPLETE!!!!!"
