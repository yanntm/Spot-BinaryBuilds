#! /bin/bash

# Minato version
#export SPOTVER=2.14.1

# New dev version with "auto" mode for knowledge integration
export SPOTVER=2.14.5.dev


# restrict/relax version
# export SPOTVER=2.10.4.dev

#wget --progress=dot:mega --no-check-certificate http://www.lrde.epita.fr/dload/spot/spot-$SPOTVER.tar.gz
wget --no-check-certificate http://www.lre.epita.fr/~adl/spot-$SPOTVER.tar.gz

tar zxf spot-$SPOTVER.tar.gz
rm spot-$SPOTVER.tar.gz

mkdir install_dir
mkdir install_dir/usr
mkdir install_dir/usr/local

cd install_dir/usr/local/
export IFOLDER=$(pwd)
cd ../../../spot-*

# From Etienne Renault : allow more acceptance
./configure -C VALGRIND=false --without-included-lbtt --disable-devel --disable-shared --prefix=$IFOLDER --enable-max-accsets=64

# hack the -all-static flag
cd bin
sed -i 's/LDFLAGS = /LDFLAGS = -all-static/g' Makefile
cd ..

# CPPFLAGS='-I%system.pkg64.libboost.path%/include' LDFLAGS='-L%system.pkg64.libboost.path%/lib' VALGRIND=false

make -j2

# make check -j2
make install 

cd ../install_dir

if [ ! -d usr/local ] ; then 
    mkdir usr/
    mkdir usr/local
    mv mingw64/* usr/local/
    \rm -r mingw64
fi


cd usr/local/

cd bin
strip ltlfilt
mv ltlfilt ../../../../website/
strip ltl2tgba
mv ltl2tgba ../../../../website/
strip autfilt
mv autfilt ../../../../website/
cd ..

# our own tool over the Spot C++ API (tools/README.md), static on Linux, beside the Spot binaries;
# skipped where cmake is missing (the Windows job), the tool being for the Linux product
export SPOTPREFIX=$(pwd)
cd ../../..
if command -v cmake > /dev/null ; then
  cmake -S tools -B tools/build -DCMAKE_BUILD_TYPE=Release -DSPOT_ROOT=$SPOTPREFIX
  cmake --build tools/build
  strip tools/build/spotutil
  mv tools/build/spotutil website/
fi
cd install_dir/usr/local

\rm -rf bin/ share/ lib64/
cd ../..

ls -lah

tar cfz ../website/spot_linux.tar.gz *

cd ..
