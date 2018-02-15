#!/usr/bin/bash
mkdir arm-build
cd arm-build
echo "Downloading prerequisites..."
wget https://mirrors.peers.community/mirrors/gnu/binutils/binutils-2.30.tar.xz
wget -c https://mirrors.sorengard.com/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.gz
wget -c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.15.tar.xz
wget -c https://mirrors.ocf.berkeley.edu/gnu/glibc/glibc-2.27.tar.xz
wget -c https://mirror.clarkson.edu/gnu/gmp/gmp-6.1.2.tar.xz
wget -c https://ftp.wayne.edu/gnu/mpc/mpc-1.1.0.tar.gz
wget -c ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.18.tar.bz2
wget -c ftp://gcc.gnu.org/pub/gcc/infrastructure/cloog-0.18.1.tar.gz
wget -c https://ftp.wayne.edu/gnu/mpfr/mpfr-4.0.1.zip

for file in *.tar*
	do tar -xvf "$file"
done
unzip *.zip

cd gcc-7.3.0
ln -s ../mpfr-4.0.1 mpfr
ln -s ../gmp-6.1.2 gmp
ln -s ../mpc-1.1.0 mpc
ln -s ../isl-0.18 isl
ln -s ../cloog-0.18.1 cloog
cd ..

echo "Creating install directories; you may need to enter your password"
sudo mkdir -p /opt/cross
sudo chown $USER:$USER /opt/cross
export PATH=/opt/cross/bin:$PATH

echo "Building binutils"
sleep 3
mkdir build-binutils
cd build-binutils
../binutils-2.30/configure --prefix=/opt/cross --target=aarch64-linux --disable-multilib
make -j8
make install

echo "Installing linux headers"
sleep 3
cd ../linux-4.15
make ARCH=arm64 INSTALL_HDR_PATH=/opt/cross/aarch64-linux headers_install
cd ..

echo "Building & installing compilers"
sleep 3
mkdir build-gcc
cd build-gcc
../gcc-7.3.0/configure --prefix=/opt/cross --target=aarch64-linux --enable-languages=c,c++ --disable-multilib
make -j8 all-gcc
make install-gcc
cd ..

echo "Installing C library headers and startup files"
sleep 3
mkdir build-glibc
cd build-glibc
../glibc-2.27/configure --prefix=/opt/cross/aarch64-linux --build=$MACHTYPE --host=aarch64-linux --target=aarch64-linux --with-headers=/opt/cross/aarch64-linux/include --disable-multilib libc_cv_forced_unwind=yes
make install-bootstrap-headers=yes install-headers
make -j8 csu/subdir_lib
install csu/crt1.o csu/crti.o csu/crtn.o /opt/cross/aarch64-linux/lib
aarch64-linux-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o /opt/cross/aarch64-linux/lib/libc.so
aarch64-linux-gcc -nostdlib -nostartfiles -static -x c /dev/null -o /opt/cross/aarch64-linux/lib/libc.a
touch /opt/cross/aarch64-linux/include/gnu/stubs.h
cd ..

echo "Building compiler support library"
sleep 3
cd build-gcc
make -j8 all-target-libgcc
make install-target-libgcc
cd ..

echo "Building C standard library"
sleep 3
cd build-glibc
make -j8
make install
cd ..

echo "Building C++ standard library"
sleep 3
cd build-gcc
make -j4
make install
cd ..

echo "Done!"
