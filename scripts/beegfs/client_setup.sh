# ----------------------
# client setup
# ----------------------

# arguments:
# $1 = management ip


# download packages and dependencies
# ----------------------
sudo wget -O /etc/apt/sources.list.d/beegfs_deb9.list https://www.beegfs.io/release/beegfs_7.2.1/dists/beegfs-deb9.list
wget -q https://www.beegfs.io/release/beegfs_7.2.1/gpg/DEB-GPG-KEY-beegfs -O- | sudo apt-key add -

sudo apt update && \
sudo apt upgrade -y && \
sudo apt-get install linux-headers-`uname -r` -y

# install packages
# ----------------------
sudo apt install beegfs-mgmtd -y && \
sudo apt install beegfs-meta libbeegfs-ib -y && \
sudo apt install beegfs-storage libbeegfs-ib -y && \
sudo apt install beegfs-client beegfs-helperd beegfs-utils -y


# Setup services
# ----------------------
sudo /opt/beegfs/sbin/beegfs-setup-client -m $1


# Start Services
# ----------------------
sudo systemctl start beegfs-helperd
sudo systemctl start beegfs-client
