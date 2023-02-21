#! /bin/bash

export SPOTVER=2.11.1.dev

#wget --progress=dot:mega --no-check-certificate http://www.lrde.epita.fr/dload/spot/spot-$SPOTVER.tar.gz
wget --progress=dot:mega --no-check-certificate https://www.lrde.epita.fr/~adl/spot-$SPOTVER.tar.gz

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

\rm -rf bin/ share/ lib64/
cd ../..

ls -lah

tar cfz ../website/spot_linux.tar.gz *

cd ..
