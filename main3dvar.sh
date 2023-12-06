#!/bin/sh

# main driver script

echo "nodes = $NODES"

idate_job=1

while [ $idate_job -le ${ndates_job} ]; do

export startupenv="${datapath}/analdate.sh"
source $startupenv

## this gets done in getreplay_histfiles.sh
#cd build_gsinfo
##/bin/rm -rf $datapath/$analdate
#mkdir -p $datapath/$analdate
#export SATINFO=$datapath/$analdate/satinfo
#export CONVINFO=$datapath/$analdate/convinfo
#export OZINFO=$datapath/$analdate/ozinfo
#echo "generate satinfo"
#sh create_satinfo.sh $analdate > $SATINFO
#echo "generate convinfo"
#sh create_convinfo.sh $analdate > $CONVINFO
#echo "generate ozinfo"
#sh create_ozinfo.sh $analdate > $OZINFO
#cd ..

#------------------------------------------------------------------------
mkdir -p $datapath

echo "BaseDir: ${basedir}"
echo "DataPath: ${datapath}"

############################################################################
# Main Program

#env
echo "starting the cycle (${idate_job} out of ${ndates_job})"

# substringing to get yr, mon, day, hr info
export yr=`echo $analdate | cut -c1-4`
export mon=`echo $analdate | cut -c5-6`
export day=`echo $analdate | cut -c7-8`
export hr=`echo $analdate | cut -c9-10`
export ANALHR=$hr
# set environment analdate
export datapath2="${datapath}/${analdate}/"

# current analysis time.
export analdate=$analdate
# previous analysis time.
FHOFFSET=`expr $ANALINC \/ 2`
export analdatem1=`${incdate} $analdate -$ANALINC`
# next analysis time.
export analdatep1=`${incdate} $analdate $ANALINC`
# beginning of current assimilation window
export analdatem3=`${incdate} $analdate -$FHOFFSET`
# beginning of next assimilation window
export analdatep1m3=`${incdate} $analdate $FHOFFSET`
export hrp1=`echo $analdatep1 | cut -c9-10`
export hrm1=`echo $analdatem1 | cut -c9-10`
export hr=`echo $analdate | cut -c9-10`
export datapathp1="${datapath}/${analdatep1}/"
export datapathm1="${datapath}/${analdatem1}/"
mkdir -p $datapathp1
export CDATE=$analdate

date
echo "analdate minus 1: $analdatem1"
echo "analdate: $analdate"
echo "analdate plus 1: $analdatep1"

# make log dir for analdate
export current_logdir="${datapath2}/logs"
echo "Current LogDir: ${current_logdir}"
mkdir -p ${current_logdir}

export PREINP="${RUN}.t${hr}z."
export PREINP1="${RUN}.t${hrp1}z."
export PREINPm1="${RUN}.t${hrm1}z."

# if ${datapathm1}/cold_start_bias exists, GSI run in 'observer' mode
# to generate diag_rad files to initialize angle-dependent 
# bias correction.
if [ -f ${datapathm1}/cold_start_bias ]; then
   ls -l ${datapathm1}/cold_start_bias
   echo "cold start bias correction"
   export cold_start_bias="true"
else
   export cold_start_bias="false"
fi
echo "cold_start_bias = $cold_start_bias"

# get replay backgrounds, bufr dumps (and create satinfo, convinfo, ozinfo)
echo "$analdate get replay backgrounds and bufr dumps, create info files `date`"
# aws cli only works on eslogin partition on gaea, or service partition on hercules/orion
cat ${machine}_preamble_s3data getreplay_histfiles.sh > job_getreplay.sh
sbatch --wait --export=datapath2=${datapath2},analdate=${analdate},FHMAX=${FHMAX},FHMIN=${FHMIN},FHOUT=${FHOUT},obs_datapath=${obs_datapath} job_getreplay.sh
if [ $? -eq 0 ] && [ -s ${datapath2}/sfg_${analdate}_fhr06_control ] && [ -s ${datapath2}/bfg_${analdate}_fhr06_control ]; then
   echo "$analdate done getting replay backgrounds and bufr dumps `date`"
else
   echo "$analdate failed to get replay backgrounds and bufr dumps `date`"
   exit 1
fi
 
# get obs from aws
#echo "$analdate get bufr dumps `date`"
#if [ $machine == "gaea" ]; then
#   # aws cli only works on eslogin partition
#   sbatch --wait --export=obs_datapath=${obs_datapath},analdate=${analdate} getawsobs.sh
#else
#   sh getawsobs.sh $analdate $obs_datapath > ${current_logdir}/getawsobs.out 2>&1 
#fi
#if [ $? -eq 0 ] && [ -s $obs_datapath/gdas.${yr}${mon}${day}/${hr}/atmos/gdas.t${hr}z.prepbufr ]; then
#   echo "$analdate done getting bufr dumps `date`"
#else
#   echo "$analdate failed to get bufr dumps `date`"
#   exit 1
#fi

type="3DVar"
export charnanal='control' 
export charnanal2='control'
echo "$analdate run $type `date`"
sh ${scriptsdir}/run_gsianal.sh > ${current_logdir}/run_gsianal.out 2>&1
# once gsi has completed, check log files.
gsi_done=`cat ${current_logdir}/run_gsi_anal.log`
if [ $gsi_done == 'yes' ]; then
   echo "$analdate $type analysis completed successfully `date`"
else
   echo "$analdate $type analysis did not complete successfully, exiting `date`"
   exit 1
fi

# cleanup
if [ $do_cleanup == 'true' ]; then
   sh ${scriptsdir}/clean.sh > ${current_logdir}/clean.out 2>&1
fi # do_cleanup = true

wait # wait for backgrounded processes to finish

cd $homedir
if [ $save_hpss == 'true' ]; then
   cat ${machine}_preamble_hpss hpss.sh > job_hpss.sh
elif [ $save_s3 == 'true' ]; then
   cat ${machine}_preamble_s3data s3archive.sh > job_hpss.sh
fi

if [ $save_hpss == 'true' ] || [ $save_s3 == 'true' ]; then
   sbatch --export=machine=${machine},analdate=${analdate},analdate_prod=${analdate_prod},datapath=${datapath},hsidir=${hsidir},save_hpss=${save_hpss},obs_datapath=${obs_datapath} job_hpss.sh
fi

echo "$analdate all done"
exit

# next analdate: increment by $ANALINC
export analdate=`${incdate} $analdate $ANALINC`

echo "export analdate=${analdate}" > $startupenv
echo "export analdate_end=${analdate_end}" >> $startupenv

cd $homedir

if [ $analdate -le $analdate_end ]; then
  idate_job=$((idate_job+1))
else
  idate_job=$((ndates_job+1))
fi

done # next analysis time


if [ $analdate -le $analdate_end ]  && [ $resubmit == 'true' ]; then
   echo "current time is $analdate"
   if [ $resubmit == 'true' ]; then
      echo "resubmit script"
      echo "machine = $machine"
      cat ${machine}_preamble config.sh > job.sh
      sbatch --export=ALL job.sh
   fi
fi

exit 0
