#!/bin/bash
SH_NAME=$0
set -e

fatal(){
	echo "$1"
	echo "Usage: ${SH_NAME} [2006|2017] [int|fp] [test|ref] [compile+copy|compile|copy]"
    exit 1
}


if [[ $# != 4 ]]; then
  fatal "please provides 4 argument"
else
  if [[ $1 == "2006" ]]; then
    GEN_BINARIES_EXTRA_PARAM=""
  elif [[ $1 == "2017" ]]; then
    GEN_BINARIES_EXTRA_PARAM="--spec2k17"
  else
    fatal "Error: Bad spec version: $1"
  fi

  if [[ $2 == "fp" || $2 == "int" ]]; then
    BENCH_SET=$2
    if [[ $1 == "2017" ]]; then
      BENCH_SET="${BENCH_SET}speed"
    fi
  else
    fatal "Error: Bad benchmark set: $2"
  fi

  if [[ $3 == "test" || $3 == "ref" ]]; then
    SPEC_INPUT_SET=$3
  else
    fatal "Error: Bad input set: $3"
  fi

  if [[ $4 == "compile+copy" ]]; then
		DO_COMPILE="--compile"
		DO_COPY="--copy"
  elif [[ $4 == "compile" ]]; then
		DO_COMPILE="--compile"
		DO_COPY=""
	elif [[ $4 == "copy" ]]; then
		DO_COMPILE=""
		DO_COPY="--copy"
  else
    fatal "Error: Bad mode: $4"
  fi
fi

echo Compiling SPEC CPU$1, input set $3 ...

export SPEC_DIR=$(readlink -f SPEC/cpu$1)

pushd $SPEC_DIR
source ./shrc
popd

./speckle.sh $DO_COMPILE $DO_COPY $GEN_BINARIES_EXTRA_PARAM --bench $BENCH_SET --set $SPEC_INPUT_SET
