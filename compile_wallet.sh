#!/usr/bin/env bash
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# See the COPYING file for license information.
#
# David Hagege <pcboy.pebkac@gmail.com>

if [[ ! -d crystax-ndk-10.3.2/ ]];then
  wget -c https://dl.crystax.net/builds/903/linux/crystax-ndk-10.3.2-b903-linux-x86_64.tar.xz
  tar xvf crystax-ndk-10.3.2-linux-x86_64.tar.xz -C ./crystax-ndk-10.3.2/
fi

export NDK=`pwd`/crystax-ndk-10.3.2/

if [[ ! -d $NDK/cmake/ ]];then
  mkdir $NDK/cmake/
  wget https://raw.githubusercontent.com/crystax/android-platform-ndk/master/cmake/toolchain.cmake -O $NDK/cmake/toolchain.cmake
fi

# build toolchain
export TOOLCHAIN_DIR=`pwd`/android-toolchain
$NDK/build/tools/make-standalone-toolchain.sh --platform=android-9 --install-dir=$TOOLCHAIN_DIR
cp -rf $NDK/sources/boost/*/include/boost/ $TOOLCHAIN_DIR/sysroot/usr/include/

# Get monero
if [[ ! -d ./monero ]];then
  git clone --depth=1 git@github.com:monero-project/monero.git
  sed -i '1 i\#include <sys/endian.h>' monero/src/common/int-util.h
  sed -i 's/dns_utils.cpp//' monero/src/common/CMakeLists.txt
  sed -i '1 i\cmake_minimum_required(VERSION 3.5)' monero/src/CMakeLists.txt
  sed -i 's/static_assert/\/\/static_assert/g' monero/src/common/int-util.h monero/src/crypto/hash-ops.h
  patch monero/src/common/int-util.h int-util.h.patch
fi

pushd monero/src/

cmake -DCMAKE_TOOLCHAIN_FILE=$NDK/cmake/toolchain.cmake -DANDROID_ABI=armeabi-v7a  -DCMAKE_CXX_FLAGS="-std=c++11 -L$NDK/sources/crystax/libs/armeabi-v7a/ -l$NDK/sources/crystax/libs/armeabi-v7a/libcrystax.so -I`pwd`/../contrib/epee/include/ -I`pwd` -I`pwd`/../external/ -I`pwd`/common/ -I`pwd`/../external/db_drivers/liblmdb/  -DDEFAULT_DB_TYPE='\"lmdb\"' -DPER_BLOCK_CHECKPOINT" -DCMAKE_C_FLAGS="-std=gnu11 -I`pwd` -I`pwd`/../contrib/epee/include" -DBUILD_WITH_STANDALONE_TOOLCHAIN=ON -DPER_BLOCK_CHECKPOINT=ON -DANDROID_STANDALONE_TOOLCHAIN=$TOOLCHAIN_DIR
make wallet
popd
