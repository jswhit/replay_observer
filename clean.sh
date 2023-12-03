echo "clean up files `date`"
cd $datapath2
/bin/rm -f sfg*control bfg*control
/bin/rm -f fort*
/bin/rm -f *log
/bin/rm -rf *tmp*
YYYYMMDD=`echo $analdate | cut -c1-8`
HH=`echo $analdate | cut -c9-10`
/bin/rm -rf ${obs_datapath}/gdas.${YYYYMMDD}/${HH}
echo "unwanted files removed `date`"
