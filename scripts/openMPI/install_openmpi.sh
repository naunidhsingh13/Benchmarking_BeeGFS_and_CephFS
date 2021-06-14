cd ~
wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-4.1.0.tar.bz2
tar xf openmpi-4.1.0.tar.bz2
rm openmpi-4.1.0.tar.bz2
cd openmpi-4.1.0/
./configure --prefix=/usr/local |& tee config.out
make -j 8 |& tee make.out
sudo make install |& tee install.out
sudo ldconfig
