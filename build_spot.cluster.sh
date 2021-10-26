#! /bin/bash

export SPOTVER=2.9.6

wget --progress=dot:mega --no-check-certificate http://www.lrde.epita.fr/dload/spot/spot-$SPOTVER.tar.gz

# https://teamcity.lrde.epita.fr/guestAuth/repository/download/bt18/.lastSuccessful/spot-snapshot.tar.gz

tar zxf spot-$SPOTVER.tar.gz
rm spot-$SPOTVER.tar.gz


mkdir -p /home/ythierry/usr
mkdir -p /home/ythierry/usr/local


export IFOLDER=/home/ythierry/usr/local/
cd spot-*

# From Etienne Renault : allow more acceptance
./configure -C VALGRIND=false --without-included-lbtt --disable-devel  --prefix=$IFOLDER --enable-max-accsets=64

# hack the -all-static flag
#cd bin
#sed -i 's/LDFLAGS = /LDFLAGS = -all-static/g' Makefile
#cd ..

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
