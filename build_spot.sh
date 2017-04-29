#! /bin/bash

wget  --no-check-certificate https://teamcity.lrde.epita.fr/guestAuth/repository/download/bt18/.lastSuccessful/spot-snapshot.tar.gz

tar zxf spot-snapshot.tar.gz

cd spot-*
./configure -C VALGRIND=false

# CPPFLAGS='-I%system.pkg64.libboost.path%/include' LDFLAGS='-L%system.pkg64.libboost.path%/lib' VALGRIND=false

make -j2

# make check -j2

cd ..

mkdir install_dir
cd install_dir
export IFOLDER=$(pwd)

cd ../spot-*

make install DESTDIR=$IFOLDER

cd ../install_dir

tar cfz ../website/spot_linux_64.tar.gz *

cd ..
