#!/usr/bin/env bash

BUILD_TOOLCHAIN_TYPE=$1
BUILD_SPEC_VER=$2
BUILD_DATASET=$3

source build.common

if [[ -z $RISCV || ( ! -d $RISCV ) ]]; then
  >&2 echo '$RISCV is not set, or does not point to a valid directory.'
  >&2 echo 'Set $RISCV to your toolchain installtion path before running this script.'
  exit 1
else
  RISCV_TOOL_PATH=$RISCV
fi

if [[ $BUILD_TOOLCHAIN_TYPE == "newlib" ]]; then
  1>&2 echo "this version of wrapper scripts doesn't support using newlib with clang yet"
  exit -1
elif [[ $BUILD_TOOLCHAIN_TYPE == "glibc" ]]; then
  RISCV_PREFIX=riscv64-unknown-linux-gnu-
else
  >&2 echo "Invalid toolchain type: $BUILD_TOOLCHAIN_TYPE"
  >&2 echo "'newlib' and 'glibc' is supported"
  exit 1
fi

if [[ $BUILD_SPEC_VER != "2006" && $BUILD_SPEC_VER != "2017" ]]; then
  >&2 echo "Invalid SPEC version: $BUILD_SPEC_VER"
  >&2 echo "Only CPU 2006 and 2017 is supported"
  exit 1
fi

if [[ $BUILD_DATASET != "test" && $BUILD_DATASET != "ref" ]]; then
  >&2 echo "Invalid dataset: $BUILD_SPEC_VER"
  >&2 echo "Pick one from \"test\" or \"ref\""
  exit 1
fi

mkdir -p log

# build [TOOL_PATH] [PREFIX] [2006 | 2017] [int | fp] [ref | test] [compile | copy | compile+copy]
build ${RISCV_TOOL_PATH} ${RISCV_PREFIX} ${BUILD_SPEC_VER} int ${BUILD_DATASET} compile+copy 2>&1 | tee log/build_cpu-${BUILD_SPEC_VER}-int_${BUILD_TOOLCHAIN_TYPE}.log
build ${RISCV_TOOL_PATH} ${RISCV_PREFIX} ${BUILD_SPEC_VER} fp  ${BUILD_DATASET} compile+copy 2>&1 | tee log/build_cpu-${BUILD_SPEC_VER}-fp_${BUILD_TOOLCHAIN_TYPE}.log
