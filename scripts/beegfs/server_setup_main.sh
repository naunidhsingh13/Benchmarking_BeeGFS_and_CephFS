# ----------------------
# server setup main
# ----------------------

# arguments:
# $1 = surver number
# $2 = management ip  	// 10.52.3.28


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
sudo /opt/beegfs/sbin/beegfs-setup-mgmtd -p /home/cc/beegfs/beegfs_mgmtd
sudo /opt/beegfs/sbin/beegfs-setup-meta -p /home/cc/beegfs/beegfs_meta -s $1 -m $2
sudo /opt/beegfs/sbin/beegfs-setup-storage -p /mnt/beegfs_ext4 -s $1 -i 30$1 -m $2


# Start Services
# ----------------------
sudo systemctl start beegfs-mgmtd
sudo systemctl start beegfs-meta
sudo systemctl start beegfs-storage
sudo systemctl start beegfs-helperd
