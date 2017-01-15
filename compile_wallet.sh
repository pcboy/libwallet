#!/usr/bin/env bash
#
#          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                  Version 2, December 2004
#
#  Copyright (C) 2004 Sam Hocevar
#  14 rue de Plaisance, 75014 Paris, France
#  Everyone is permitted to copy and distribute verbatim or modified
#  copies of this license document, and changing it is allowed as long
#  as the name is changed.
#  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#  0. You just DO WHAT THE FUCK YOU WANT TO.
#
#
#  David Hagege <david.hagege@gmail.com>
#
set -euo pipefail

pushd `dirname $0`

if [[ ! -d crystax-ndk-10.3.2/ ]];then
  wget -c https://us.crystax.net/download/crystax-ndk-10.3.2-linux-x86_64.tar.xz
  tar xvf crystax-ndk-10.3.2-linux-x86_64.tar.xz 
fi

export NDK=`pwd`/crystax-ndk-10.3.2/

if [[ ! -d $NDK/cmake/ ]];then
  mkdir $NDK/cmake/
  wget https://raw.githubusercontent.com/crystax/android-platform-ndk/master/cmake/toolchain.cmake -O $NDK/cmake/toolchain.cmake
fi

# build toolchain
export TOOLCHAIN_DIR=`pwd`/android-toolchain
if [[ ! -d $TOOLCHAIN_DIR ]];then
  $NDK/build/tools/make-standalone-toolchain.sh --platform=android-9 --install-dir=$TOOLCHAIN_DIR
  cp -rf $NDK/sources/boost/*/include/boost/ $TOOLCHAIN_DIR/sysroot/usr/include/
fi

# Get monero
if [[ ! -d ./monero ]];then
  git clone --branch=v0.10.0 --depth=1 git@github.com:monero-project/monero.git
  sed -i '1 i\#include <sys/endian.h>' monero/src/common/int-util.h
  sed -i 's/dns_utils.cpp//' monero/src/common/CMakeLists.txt
  sed -i '1 i\cmake_minimum_required(VERSION 3.5)' monero/src/CMakeLists.txt
  sed -i 's/static_assert/\/\/static_assert/g' monero/src/common/int-util.h monero/src/crypto/hash-ops.h
  patch monero/src/common/int-util.h int-util.h.patch
fi

pushd monero/
cmake .
make version

pushd src/

cmake -DCMAKE_TOOLCHAIN_FILE=$NDK/cmake/toolchain.cmake -DANDROID=true -DANDROID_ABI=armeabi-v7a  -DCMAKE_CXX_FLAGS="-std=c++11 -L$NDK/sources/crystax/libs/armeabi-v7a/ -l$NDK/sources/crystax/libs/armeabi-v7a/libcrystax.so -I`pwd`/../contrib/epee/include/ -I`pwd` -I`pwd`/../external/ -I`pwd`/common/ -I`pwd`/../external/db_drivers/liblmdb/  -DDEFAULT_DB_TYPE='\"lmdb\"' -DPER_BLOCK_CHECKPOINT" -DCMAKE_C_FLAGS="-std=gnu11 -I`pwd` -I`pwd`/../contrib/epee/include" -DBUILD_WITH_STANDALONE_TOOLCHAIN=ON -DPER_BLOCK_CHECKPOINT=ON -DANDROID_STANDALONE_TOOLCHAIN=$TOOLCHAIN_DIR || true
make wallet
popd
popd
popd
