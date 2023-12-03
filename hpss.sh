# need envars:  machine, analdate, datapath, hsidir
exitstat=0
if [ $machine == "gaea" ]; then
   htar=/sw/rdtn/hpss/default/bin/htar
   hsi=/sw/rdtn/hpss/default/bin/hsi
else
   source $MODULESHOME/init/sh
   module load hpss
   hsi=`which hsi`
   htar=`which htar`
fi
$hsi ls -l $hsidir
$hsi mkdir ${hsidir}/
cd ${datapath}
$htar -cvf ${hsidir}/${analdate}.tar ${analdate}/*diag*nc* ${analdate}/*info* ${analdate}/*gsi*
$hsi ls -l ${hsidir}/${analdate}.tar
exitstat=$?
if [  $exitstat -ne 0 ]; then
   echo "htar failed ${analdate} with exit status $exitstat..."
   exit 1
fi
exit $exitstat
