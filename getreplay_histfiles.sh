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

which aws
if [ $? -ne 0 ]; then
   echo "SLURM_CLUSTER_NAME=$SLURM_CLUSTER_NAME"
   if  [ $SLURM_CLUSTER_NAME == 'es' ]; then #
      module use /ncrc/proj/epic/spack-stack/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core
      module load stack-intel/2023.1.0
      module load awscli-v2
   elif [ $SLURM_CLUSTER_NAME == 'hercules' ]; then
      module purge
      module use /work/noaa/epic/role-epic/spack-stack/hercules/modulefiles
      module use /work/noaa/epic/role-epic/spack-stack/hercules//spack-stack-1.5.0/envs/unified-env/install/modulefiles/Core
      module load stack-intel/2021.9.0
      module load awscli
   else
      echo "cluster must be 'hercules' or 'es' (gaea)"
      exit 1
   fi
fi
which aws
if [ $? -ne 0 ]; then
   echo "awscli not found"
   exit 1
fi

YYYYMM=`echo $YYYYMMDDHH | cut -c1-6`
YYYYMMDD=`echo $YYYYMMDDHH | cut -c1-8`
HH=`echo $YYYYMMDDHH | cut -c9-10`
DD=`echo $YYYYMMDDHH | cut -c7-8`
MM=`echo $YYYYMMDDHH | cut -c5-6`
YYYY=`echo $YYYYMMDDHH | cut -c1-4`
if [ $analdate -lt $analdate_prod ]; then # get data from spin-up directory
   S3PATH=s3://noaa-ufs-gefsv13replay-pds/spinup/${YYYY}/${MM}/${YYYYMMDDHH}
else
   S3PATH=s3://noaa-ufs-gefsv13replay-pds/${YYYY}/${MM}/${YYYYMMDDHH}
fi
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
