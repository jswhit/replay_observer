#!/bin/sh
#SBATCH --cluster=es
#SBATCH --partition=eslogin
#SBATCH -t 01:00:00
#SBATCH -A nggps_psd
#SBATCH -N 1     
#SBATCH -J getreplay_histfiles
#SBATCH -e getreplay_histfiles.out
#SBATCH -o getreplay_histfiles.out

YYYYMMDDHH=${analdate:-$1}
outpath=${datapath2:-$2}
FHMIN=${FHMIN:-$3}
FHMAX=${FHMAX:-$4}
FHOUT=${FHOUT:-$5}
echo $YYYYMMDDHH
echo $outpath
echo $FHMIN
echo $FHMAX
echo $FHOUT

source /lustre/f2/dev/role.epic/contrib/Lmod_init.sh

echo "SLURM_CLUSTER_NAME=$SLURM_CLUSTER_NAME"

if [ $SLURM_CLUSTER_NAME == 'c5' ]; then
   module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c5/modulefiles
   module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c5/spack-stack-1.5.0/envs/unified-env/install/modulefiles/Core
   module load stack-intel/2023.1.0
   module load awscli
elif  [ $SLURM_CLUSTER_NAME == 'es' ]; then
   module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c4/modulefiles
   module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c4/spack-stack-1.5.0/envs/unified-env/install/modulefiles/Core
   module load stack-intel/2022.0.2
   module load awscli
else
   echo "cluster must be es or c5"
   exit 1
fi

which aws
if [ $? -ne 0 ]; then
    echo "no awscli found"
    exit 1
fi

YYYYMM=`echo $YYYYMMDDHH | cut -c1-6`
YYYYMMDD=`echo $YYYYMMDDHH | cut -c1-8`
HH=`echo $YYYYMMDDHH | cut -c9-10`
DD=`echo $YYYYMMDDHH | cut -c7-8`
MM=`echo $YYYYMMDDHH | cut -c5-6`
YYYY=`echo $YYYYMMDDHH | cut -c1-4`
S3PATH=s3://noaa-ufs-gefsv13replay-pds/${YYYY}/${MM}/${YYYYMMDDHH}
mkdir -p $outpath
pushd $outpath
fh=$FHMIN
while [ $fh -le $FHMAX ]; do
  charfhr="fhr"`printf %02i $fh`
  echo "$S3PATH/sfg_${YYYYMMDDHH}_${charfhr}_control"
  #aws s3 ls --no-sign-request $S3PATH/sfg_${YYYYMMDDHH}_${charfhr}_control 
  aws s3 cp --no-sign-request --only-show-errors $S3PATH/sfg_${YYYYMMDDHH}_${charfhr}_control . &
  echo "$S3PATH/bfg_${YYYYMMDDHH}_${charfhr}_control"
  #aws s3 ls --no-sign-request $S3PATH/bfg_${YYYYMMDDHH}_${charfhr}_control 
  aws s3 cp --no-sign-request --only-show-errors $S3PATH/bfg_${YYYYMMDDHH}_${charfhr}_control . &
  fh=$[$fh+$FHOUT]
done
popd

cd build_gsinfo
export SATINFO=$outpath/satinfo
export CONVINFO=$outpath/convinfo
export OZINFO=$outpath/ozinfo
echo "generate satinfo"
sh create_satinfo.sh $analdate > $SATINFO &
echo "generate convinfo"
sh create_convinfo.sh $analdate > $CONVINFO &
echo "generate ozinfo"
sh create_ozinfo.sh $analdate > $OZINFO &
cd ..
wait
ls -l ${outpath}/*fg*control

# now get bufr dumps
sh getawsobs.sh
