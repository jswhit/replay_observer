echo "clean up files `date`"
cd $datapath2
/bin/rm -f sfg*control bfg*control
/bin/rm -f fort*
/bin/rm -f *log
/bin/rm -rf *tmp*
echo "unwanted files removed `date`"
