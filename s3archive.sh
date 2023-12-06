# need envars:  analdate, datapath, s3path

which aws
if [ $? -ne 0 ]; then
   echo "SLURM_CLUSTER_NAME=$SLURM_CLUSTER_NAME"
   if  [ $SLURM_CLUSTER_NAME == 'es' ]; then #
      source /lustre/f2/dev/role.epic/contrib/Lmod_init.sh
      module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c4/modulefiles
      module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c4/spack-stack-1.5.0/envs/unified-env/install/modulefiles/Core
      module load stack-intel/2022.0.2
      module load awscli
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

cd $datapath
MM=`echo $YYYYMMDDHH | cut -c5-6`
YYYY=`echo $YYYYMMDDHH | cut -c1-4`
if [ $analdate -lt $analdate_prod ];then # put data in spin-up directory
   aws s3 cp --recursive --quiet ${analdate} s3://noaa-ufs-gefsv13replay-pds/spinup/${YYYY}/${MM}/${analdate}/gsi/ --profile noaa-bdp 
else
   aws s3 cp --recursive --quiet ${analdate} s3://noaa-ufs-gefsv13replay-pds/${YYYY}/${MM}/${analdate}/gsi/ --profile noaa-bdp 
fi

if [ $? -ne 0 ]; then
  echo "s3 archive failed "$filename
  exitstat=1
else
  echo "s3 archive succceeded "$filename
  aws s3 ls --no-sign-request s3://noaa-ufs-gefsv13replay-pds/${YYYY}/${MM}/${analdate}/gsi/
  # remove everything except logs, gsistats and  abias* files
  #/bin/rm -f ${analdate}/*diag*nc* ${analdate}/*info* ${analdate}/sanl* ${analdate}/gsiparm.anl
fi
exit $exitstat
