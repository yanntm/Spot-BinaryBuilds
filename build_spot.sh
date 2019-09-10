#! /bin/bash

export SPOTVER=2.8.1

wget --progress=dot:mega --no-check-certificate http://www.lrde.epita.fr/dload/spot/spot-$SPOTVER.tar.gz

# https://teamcity.lrde.epita.fr/guestAuth/repository/download/bt18/.lastSuccessful/spot-snapshot.tar.gz

tar zxf spot-$SPOTVER.tar.gz
rm spot-$SPOTVER.tar.gz

mkdir install_dir
mkdir install_dir/usr
mkdir install_dir/usr/local

cd install_dir/usr/local/
export IFOLDER=$(pwd)
cd ../../../spot-*

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
