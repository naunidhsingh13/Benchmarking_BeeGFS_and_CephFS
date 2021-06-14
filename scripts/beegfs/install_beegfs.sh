sudo wget -O /etc/apt/sources.list.d/beegfs_deb9.list https://www.beegfs.io/release/beegfs_7.2.1/dists/beegfs-deb9.list
wget -q https://www.beegfs.io/release/beegfs_7.2.1/gpg/DEB-GPG-KEY-beegfs -O- | sudo apt-key add -

sudo apt update
sudo apt upgrade -y
sudo apt-get install linux-headers-`uname -r` -y
