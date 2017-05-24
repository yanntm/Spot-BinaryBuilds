#! /bin/bash

wget  --no-check-certificate https://teamcity.lrde.epita.fr/guestAuth/repository/download/bt18/.lastSuccessful/spot-snapshot.tar.gz

tar zxf spot-snapshot.tar.gz
rm spot-snapshot.tar.gz

mkdir install_dir
cd install_dir
export IFOLDER=$(pwd)
cd ../spot-*

./configure -C VALGRIND=false --without-included-lbtt --disable-devel --disable-shared --disable-python --prefix=$IFOLDER

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
\rm -rf bin/ share/ lib64/
cd ../..


ls -lah

tar cfz ../website/spot_linux.tar.gz *

cd ..
