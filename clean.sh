#!/usr/bin/env bash
pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

if [[ $# != 1 ]]; then
  echo "Usage: $0 [2006|2017|all]"
  exit 1
fi

if [[ "$1" == "2017" || "$1" == "all" ]]; then
  pushd SPEC/cpu2017/benchspec/CPU
  find . -mindepth 2 -maxdepth 2 -type d -name "build" | xargs -d '\n' -- rm -fr
  find . -mindepth 2 -maxdepth 2 -type d -name "run" | xargs -d '\n' -- rm -fr
  find . -mindepth 2 -maxdepth 2 -type d -name "exe" | xargs -d '\n' -- rm -fr
  popd
fi

if [[ "$1" == "2006" || "$1" == "all" ]]; then
  pushd SPEC/cpu2006/benchspec/CPU2006
  find . -mindepth 2 -maxdepth 2 -type d -name "build" | xargs -d '\n' -- rm -fr
  find . -mindepth 2 -maxdepth 2 -type d -name "run" | xargs -d '\n' -- rm -fr
  find . -mindepth 2 -maxdepth 2 -type d -name "exe" | xargs -d '\n' -- rm -fr
  popd
fi

if [[ "$1" == "all" ]]; then
  rm -fr build
  rm -fr riscv-m64-spec
fi
