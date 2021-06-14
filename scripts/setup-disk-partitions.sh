# setup-disk-partitions.sh

sudo  apt-get install f2fs-tools -y

sudo mkdir /mnt/beegfs_ext4 /mnt/beegfs_btrfs /mnt/beegfs_xfs /mnt/beegfs_f2fs /mnt/cephfs_ext4 /mnt/cephfs_btrfs /mnt/cephfs_xfs /mnt/cephfs_f2fs

sudo parted -a opt /dev/sdb mklabel gpt
Yes

sudo parted -a opt /dev/sdb mkpart primary 0% 10GB

sudo parted -a opt /dev/sdb mkpart beegfs_ext4 ext4 10GB 30GB
sudo parted -a opt /dev/sdb mkpart beegfs_btrfs btrfs 30GB 50GB
sudo parted -a opt /dev/sdb mkpart beegfs_xfs xfs 50GB 70GB
sudo parted -a opt /dev/sdb mkpart beegfs_f2fs ext4 70GB 90GB


sudo parted -a opt /dev/sdb mkpart cephfs_ext4 ext4 90GB 110GB
sudo parted -a opt /dev/sdb mkpart cephfs_btrfs btrfs 110GB 130GB
sudo parted -a opt /dev/sdb mkpart cephfs_xfs xfs 130GB 150GB
sudo parted -a opt /dev/sdb mkpart cephfs_f2fs ext4 150GB 170GB


sudo mkfs.ext4 /dev/sdb2 -f
sudo mkfs.btrfs /dev/sdb3 -f
sudo mkfs.xfs /dev/sdb4 -f
sudo mkfs.f2fs /dev/sdb5 -f

sudo mkfs.ext4 /dev/sdb6 -f
sudo mkfs.btrfs /dev/sdb7 -f
sudo mkfs.xfs /dev/sdb8 -f
sudo mkfs.f2fs /dev/sdb9 -f

sudo mount -t ext4 /dev/sdb2 /mnt/beegfs_ext4
sudo mount -t btrfs /dev/sdb3 /mnt/beegfs_btrfs
sudo mount -t xfs /dev/sdb4 /mnt/beegfs_xfs
sudo mount -t f2fs /dev/sdb5 /mnt/beegfs_f2fs


sudo mount -t ext4 /dev/sdb6 /mnt/cephfs_ext4
sudo mount -t btrfs /dev/sdb7 /mnt/cephfs_btrfs
sudo mount -t xfs /dev/sdb8 /mnt/cephfs_xfs
sudo mount -t f2fs /dev/sdb9 /mnt/cephfs_f2fs


# sudo parted -a opt /dev/sdb print

# mkpart primary 0% 10GB
# 
# mkpart beegfs_ext4 ext4 10GB 30GB
# mkpart beegfs_btrfs btrfs 30GB 50GB
# mkpart beegfs_xfs xfs 50GB 70GB
# 
# mkpart beegfs_f2fs ext4 70GB 90GB
# mkpart cephfs_ext4 ext4 90GB 110GB
# mkpart cephfs_btrfs btrfs 110GB 130GB
# mkpart cephfs_xfs xfs 130GB 150GB
# mkpart cephfs_f2fs ext4 150GB 170GB
