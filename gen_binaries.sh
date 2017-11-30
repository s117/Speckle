#!/bin/bash
#set -e

#############
# TODO
#  * allow the user to input their desired input set
#  * auto-handle output file generation

if [ -z  "$SPEC_DIR" ]; then 
   echo "  Please set the SPEC_DIR environment variable to point to your copy of SPEC CPU2006 / SPEC CPU2017."
   exit 1
fi

CONFIG=riscv
CONFIG_2K17=riscv_spec2k17
LABEL=riscv-m64
CONFIGFILE=${CONFIG}.cfg
RUN="spike pk -c "
CMD_FILE=commands.txt
INPUT_TYPE=test

# the integer set
BENCHMARKS_INT=(400.perlbench 401.bzip2 403.gcc 429.mcf 445.gobmk 456.hmmer 458.sjeng 462.libquantum 464.h264ref 471.omnetpp 473.astar 483.xalancbmk)
BENCHMARKS_FP=(410.bwaves 416.gamess 433.milc 434.zeusmp 435.gromacs 436.cactusADM 437.leslie3d 444.namd 447.dealII 450.soplex 453.povray 454.calculix 459.GemsFDTD 465.tonto 470.lbm 481.wrf 482.sphinx3)
BENCHMARKS_INT_2K17=(600.perlbench_s 602.gcc_s 605.mcf_s 620.omnetpp_s 623.xalancbmk_s 625.x264_s 631.deepsjeng_s 641.leela_s 648.exchange2_s 657.xz_s)
BENCHMARKS_FP_2K17=(603.bwaves_s 607.cactuBSSN_s 619.lbm_s 621.wrf_s 627.cam4_s 628.pop2_s 638.imagick_s 644.nab_s 649.fotonik3d_s 654.roms_s)

# idiomatic parameter and option handling in sh
compileFlag=false
runFlag=false
copyFlag=false
spec2k17Flag=false
fpFlag=false
inputSet=test
benchSet=none
while test $# -gt 0
do
   case "$1" in
        --compile) 
            compileFlag=true
            ;;
        --run) 
            runFlag=true
            ;;
        --copy)
            copyFlag=true
            ;;
        --spec2k17)
            spec2k17Flag=true
            ;;
        --set) 
            inputSet=$2
            shift
            ;;
        --bench) 
            benchSet=$2
            shift
            ;;
        --*) echo "ERROR: bad option $1"
            echo "  --compile (compile the SPEC benchmarks), --run (to run the benchmarks) --copy (copies, not symlinks, benchmarks to a new dir)"
            exit 1
            ;;
        *) echo "ERROR: bad argument $1"
            echo "  --compile (compile the SPEC benchmarks), --run (to run the benchmarks) --copy (copies, not symlinks, benchmarks to a new dir)"
            exit 2
            ;;
    esac
    shift
done

if [ "$spec2k17Flag" = true ]; then
   echo "Building SPEC 2K17"
   CONFIG=${CONFIG_2K17}

   if [ "$inputSet" = ref ]; then
     runDirInputSet=refspeed
   else
     runDirInputSet=test
   fi

   #If benchset is not specified on the command line
   if [ "$benchSet" = none ]; then
     benchSet=intspeed
   fi

   if [ "$benchSet" = fpspeed ]; then
       BENCHMARKS=("${BENCHMARKS_FP_2K17[@]}")
   else
       BENCHMARKS=("${BENCHMARKS_INT_2K17[@]}")
   fi
else
   #If benchset is not specified on the command line
   if [ "$benchSet" = none ]; then
     benchSet=int
   fi

   if [ "$benchSet" = fp ]; then
      BENCHMARKS=("${BENCHMARKS_FP[@]}")
   else
      BENCHMARKS=("${BENCHMARKS_INT[@]}")
   fi
fi

echo "== Speckle Options =="
echo "  Config : " ${CONFIG}
echo "  Label  : " ${LABEL}
echo "  compile: " ${compileFlag}
echo "  run    : " ${runFlag}
echo "  copy   : " ${copyFlag}
echo "  Input  : " ${inputSet}
echo "  benchset:" ${benchSet}
echo "  benchmarks   : " ${BENCHMARKS[@]}
echo ""


BUILD_DIR=$PWD/build
COPY_DIR=$PWD/${LABEL}-spec-${inputSet}
mkdir -p build;

# compile the binaries
if [ "$compileFlag" = true ]; then

   echo "Compiling SPEC..."
   # copy over the config file we will use to compile the benchmarks
   config_status=`cmp $BUILD_DIR/../${CONFIGFILE} $SPEC_DIR/config/${CONFIGFILE}`
   if [ "$config_status" = "" ]; then
      echo "Config is unchanged, not copying to avoid rebuild"
   else
      echo "Config is changed, copying"
      cp -f $BUILD_DIR/../${CONFIGFILE} $SPEC_DIR/config/${CONFIGFILE}
   fi

   if [ "$spec2k17Flag" = true ]; then
      cd $SPEC_DIR; . ./shrc; time runcpu --config ${CONFIG} --size ${inputSet} --action setup --loose --ignore_errors ${benchSet}
   else
      cd $SPEC_DIR; . ./shrc; time runspec --config ${CONFIG} --size ${inputSet} --action setup --loose --ignore_errors ${benchSet}
   fi
  
   if [ "$copyFlag" = true ]; then
      rm -rf $COPY_DIR
      mkdir -p $COPY_DIR
   fi
  
   # copy back over the binaries.  Fuck xalancbmk for being different.
   # Do this for each input type.
   # assume the CPU2006/CPU2017 directories are clean. I've hard-coded the directories I'm going to copy out of

   for b in ${BENCHMARKS[@]}; do
      echo ${b}
      SHORT_EXE=${b##*.} # cut off the numbers ###.short_exe
      if [ $b == "483.xalancbmk" ]; then SHORT_EXE=Xalan; fi #WTF SPEC???
      if [ $b == "602.gcc_s" ]; then SHORT_EXE=sgcc; fi
      if [ $b == "603.bwaves_s" ]; then SHORT_EXE=speed_bwaves; fi
      if [ $b == "625.x264_s" ]; then SHORT_EXE=ldecod_s; fi
      if [ $b == "628.pop2_s" ]; then SHORT_EXE=speed_pop2; fi
      if [ $b == "654.roms_s" ]; then SHORT_EXE=sroms; fi
      
      echo ""
      if [ "$spec2k17Flag" = true ]; then
         BMK_DIR=$SPEC_DIR/benchspec/CPU/$b/run/run_base_${runDirInputSet}_${LABEL}.0000;
         echo "ls $SPEC_DIR/benchspec/CPU/$b/run"
         ls $SPEC_DIR/benchspec/CPU/$b/run
         ls $SPEC_DIR/benchspec/CPU/$b/run/run_base_${runDirInputSet}_${LABEL}.0000
         echo ""
      else
         BMK_DIR=$SPEC_DIR/benchspec/CPU2006/$b/run/run_base_${inputSet}_${CONFIG}.0000;
         echo "ls $SPEC_DIR/benchspec/CPU2006/$b/run"
         ls $SPEC_DIR/benchspec/CPU2006/$b/run
         ls $SPEC_DIR/benchspec/CPU2006/$b/run/run_base_${inputSet}_${CONFIG}.0000
         echo ""
      fi

      # make a symlink to SPEC (to prevent data duplication for huge input files)
      echo "ln -sf $BMK_DIR $BUILD_DIR/${b}_${inputSet}"
      if [ -d $BUILD_DIR/${b}_${inputSet} ]; then
         echo "unlink $BUILD_DIR/${b}_${inputSet}"
         unlink $BUILD_DIR/${b}_${inputSet}
      fi
      ln -sf $BMK_DIR $BUILD_DIR/${b}_${inputSet}

      if [ "$copyFlag" = true ]; then
         echo "---- copying benchmarks ----- "
         mkdir -p $COPY_DIR/$b
         cp -r $BUILD_DIR/../commands $COPY_DIR/commands
         cp $BUILD_DIR/../run.sh $COPY_DIR/run.sh
         sed -i '4s/.*/INPUT_TYPE='${inputSet}' #this line was auto-generated from gen_binaries.sh/' $COPY_DIR/run.sh
         for f in $BMK_DIR/*; do
            echo $f
            if [[ -d $f ]]; then
               cp -r $f $COPY_DIR/$b/$(basename "$f")
            else
               cp $f $COPY_DIR/$b/$(basename "$f")
            fi
         done
         mv $COPY_DIR/$b/${SHORT_EXE}_base.${LABEL} $COPY_DIR/$b/${SHORT_EXE}
      fi
   done
fi

# running the binaries/building the command file
# we could also just run through BUILD_DIR/CMD_FILE and run those...
if [ "$runFlag" = true ]; then

   for b in ${BENCHMARKS[@]}; do
   
      cd $BUILD_DIR/${b}_${inputSet}
      SHORT_EXE=${b##*.} # cut off the numbers ###.short_exe
      # handle benchmarks that don't conform to the naming convention
      if [ $b == "482.sphinx3" ]; then SHORT_EXE=sphinx_livepretend; fi
      if [ $b == "483.xalancbmk" ]; then SHORT_EXE=Xalan; fi
      if [ $b == "602.gcc_s" ]; then SHORT_EXE=sgcc; fi
      if [ $b == "603.bwaves_s" ]; then SHORT_EXE=speed_bwaves; fi
      if [ $b == "625.x264_s" ]; then SHORT_EXE=ldecod_s; fi
      if [ $b == "628.pop2_s" ]; then SHORT_EXE=speed_pop2; fi
      if [ $b == "654.roms_s" ]; then SHORT_EXE=sroms; fi
      
      # read the command file
      IFS=$'\n' read -d '' -r -a commands < $BUILD_DIR/../commands/${b}.${inputSet}.cmd

      for input in "${commands[@]}"; do
         if [[ ${input:0:1} != '#' ]]; then # allow us to comment out lines in the cmd files
            echo "~~~Running ${b}"
            echo "  ${RUN} ${SHORT_EXE}_base.${LABEL} ${input}" 
            eval ${RUN} ${SHORT_EXE}_base.${LABEL} ${input}
         fi
      done
   
   done

fi

echo ""
echo "Done!"
