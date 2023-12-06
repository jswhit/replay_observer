# hybrid gain GSI(3DVar)/EnKF workflow
export cores=`expr $NODES \* $corespernode`
echo "running on $machine using $NODES nodes and $cores CORES"
export exptname="replay_observer"

export ndates_job=1 # number of DA cycles to run in one job submission
# resolution of control and ensmemble.
export RES=384  
export RES_CTL=$RES
export rungsi='run_gsi_4densvar.sh'

export do_cleanup='true' 
export resubmit='true'
# python script checkdate.py used to check
# YYYYMMDDHH analysis date string to see if
# full ensemble should be saved to HPSS (returns 0 if 
# HPSS save should be done)
if [ $machine == "orion" ] || [ $machine == "hercules" ]; then
   export save_hpss="false"
   export save_s3="true"
else
   export save_hpss="false"
   export save_s3="true"
fi

if [ $machine == "hercules" ]; then
   source $MODULESHOME/init/sh
   export basedir=/work2/noaa/gsienkf/${USER}
   export datadir=$basedir
   export hsidir="/ESRL/BMC/gsienkf/2year/whitaker/${exptname}"
   export scriptsdir="${basedir}/scripts/${exptname}"
   export homedir=$scriptsdir
   export datapath="${datadir}/${exptname}"
   export logdir="${datadir}/logs/${exptname}"
   export incdate="${scriptsdir}/incdate.sh"
   export obs_datapath=/work/noaa/rstprod/dump
   ulimit -s unlimited
   source $MODULESHOME/init/sh
   #module use /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-dev-20230717/envs/unified-env/install/modulefiles/Core
   module use /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.5.0/envs/unified-env/install/modulefiles/Core
   #module use /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-dev-20230717/envs/unified-env/install/modulefiles/intel-oneapi-mpi/2021.9.0/intel/2021.9.0
   module use /work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.5.0/envs/unified-env/install/modulefiles/intel-oneapi-mpi/2021.9.0/intel/2021.9.0
   module load stack-intel/2021.9.0
   module load stack-intel-oneapi-mpi/2021.9.0
   module load intel-oneapi-mkl/2022.2.1
   module load bufr/11.7.0
   module load crtm/2.4.0
   module load gsi-ncdiag
   module load awscli
   export PATH="/work/noaa/gsienkf/whitaker/miniconda3/bin:$PATH"
   export gsipath=/lustre/f2/dev/Jeffrey.S.Whitaker/GSI
   export fixgsi=${gsipath}/fix
   export fixcrtm=$CRTM_FIX
   export execdir=${scriptsdir}/exec_${machine}
   export gsiexec=${execdir}/gsi.x
elif [ "$machine" == 'gaea' ]; then
   export basedir=/lustre/f2/dev/${USER}
   export datadir=/lustre/f2/scratch/${USER}
   export hsidir="/ESRL/BMC/gsienkf/2year/whitaker/${exptname}"
   export scriptsdir="${basedir}/scripts/${exptname}"
   export homedir=$scriptsdir
   export datapath="${datadir}/${exptname}"
   export logdir="${datadir}/logs/${exptname}"
   export incdate="${scriptsdir}/incdate.sh"
   #export obs_datapath=/lustre/f2/dev/Jeffrey.S.Whitaker/dumps
   export obs_datapath=${datapath}/dumps
   ulimit -s unlimited
   source /lustre/f2/dev/role.epic/contrib/Lmod_init.sh
   module unload cray-libsci
   module load PrgEnv-intel/8.3.3
   module load intel-classic/2023.1.0
   module load cray-mpich/8.1.25
   #module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c5/spack-stack-1.5.0/envs/unified-env/install/modulefiles/Core
   #module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c5/modulefiles
   module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c5/spack-stack-dev-20230717/envs/unified-env/install/modulefiles/Core
   module use /lustre/f2/dev/wpo/role.epic/contrib/spack-stack/c5/modulefiles
   module load stack-intel/2023.1.0
   module load stack-cray-mpich/8.1.25
   module load stack-python/3.9.12
   module load bufr/11.7.0
   module load crtm/2.4.0
   module load gsi-ncdiag
   module load awscli
   export PATH="/lustre/f2/dev/Jeffrey.S.Whitaker/conda/bin:${PATH}"
   export gsipath=/lustre/f2/dev/Jeffrey.S.Whitaker/GSI
   export fixgsi=${gsipath}/fix
   export fixcrtm=$CRTM_FIX
   export execdir=${scriptsdir}/exec_${machine}
   export gsiexec=${execdir}/gsi.x
   #cd $scriptsdir
   #cd build_gsinfo
   #sh create_satinfo.sh 2021010106
   #exit
else
   echo "machine must be 'hera', 'orion', 'hercules' or 'gaea' got $machine"
   exit 1
fi

export NOSAT="NO" # if yes, no radiances assimilated
export NOCONV="NO"
export NOTLNMC="NO" # no TLNMC in GSI in GSI EnVar
export NOOUTERLOOP="YES" # no outer loop in GSI EnVar
export NST_GSI=0          # default 0: No NST info at all;
                          #         1: Input NST info but not used in GSI;
                          #         2: Input NST info, used in CRTM simulation, no Tr analysis
                          #         3: Input NST info, used in both CRTM simulation and Tr analysis

export LEVS=127  
export nsig_ext=56
export gpstop=55

# radiance thinning parameters for GSI
export dmesh1=145
export dmesh2=145
export dmesh3=100

export imp_physics=8 # used by GSI, not model

if [ $RES_CTL -eq 768 ]; then
   export LONB_CTL=3072
   export LATB_CTL=1536
   export dt_atmos_ctl=150    
elif [ $RES_CTL -eq 384 ]; then
   export JCAP_CTL=766
   export LONB_CTL=1536
   export LATB_CTL=768
elif [ $RES_CTL -eq 192 ]; then
   export JCAP_CTL=382
   export LONB_CTL=768  
   export LATB_CTL=384
elif [ $RES_CTL -eq 96 ]; then
   export JCAP_CTL=188
   export LONB_CTL=384  
   export LATB_CTL=192
else
   echo "model parameters for control resolution C$RES_CTL not set"
   exit 1
fi

# analysis is done at ensemble resolution
export LONA=$LONB_CTL
export LATA=$LATB_CTL      

export ANALINC=6

export FHMIN=3
export FHMAX=9
export FHOUT=3
# IAU off
export iaufhrs="6"
export iau_delthrs=-1

export RUN=gdas # use gdas or gfs obs

# Analysis increments to zero out
export INCREMENTS_TO_ZERO="'liq_wat_inc','icmr_inc'"
# Stratospheric increments to zero
export INCVARS_ZERO_STRAT="'sphum_inc','liq_wat_inc','icmr_inc'"
export INCVARS_EFOLD="5"
export write_fv3_increment=".false." # don't change this
export WRITE_INCR_ZERO="incvars_to_zero= $INCREMENTS_TO_ZERO,"
export WRITE_ZERO_STRAT="incvars_zero_strat= $INCVARS_ZERO_STRAT,"
export WRITE_STRAT_EFOLD="incvars_efold= $INCVARS_EFOLD,"
export use_correlated_oberrs=".true."
# NOTE: most other GSI namelist variables are in ${rungsi}

# use pre-generated bias files.
#export biascorrdir=${datadir}/biascor

export nitermax=1 # number of retries

export ANAVINFO=${fixgsi}/global_anavinfo_allhydro.l${LEVS}.txt
export NLAT=$((${LATA}+2))
# default is to use berror file in gsi fix dir.
#export BERROR=${basedir}/staticB/global_berror_enkf.l${LEVS}y${NLAT}.f77
#export BERROR=${basedir}/staticB/24h/global_berror.l${LEVS}y${NLAT}.f77_janjulysmooth0p5
#export BERROR=${basedir}/staticB/24h/global_berror.l${LEVS}y${NLAT}.f77_annmeansmooth0p5
export beta_s0=1
export beta_e0=0
export aircraft_t_bc=.true.
export upd_aircraft=.true.

cd $scriptsdir
pwd
echo "run main driver script"
sh ./main3dvar.sh
