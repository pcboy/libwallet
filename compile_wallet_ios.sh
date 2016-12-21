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

# Get monero
if [[ ! -d ./monero ]];then
  git clone --depth=1 git@github.com:monero-project/monero.git
  sed -i '' 's/dns_utils.cpp//' monero/src/common/CMakeLists.txt
  #patch monero/src/common/int-util.h int-util.h.patch
fi

if [[ $1 == "x86_64" ]];then
  export CC="$(xcrun --sdk iphonesimulator --find clang) -isysroot $(xcrun --sdk iphonesimulator --show-sdk-path) -arch x86_64"
  export CXX=$CC
else
  export CC="$(xcrun --sdk iphoneos --find clang) -isysroot $(xcrun --sdk iphoneos --show-sdk-path) -arch armv7 -arch armv7s -arch arm64"
  export CXX=$CC
fi

pushd monero
cmake .
make 
popd
popd
