Step 1:
# Configure /etc/hosts

# Add:

10.140.82.215 admin 
10.140.83.176 node1
10.140.82.100 node2
10.140.83.60 client1
10.140.83.87 node3


Step 2:
# Configure .ssh/authorized_keys


Step 3:
# configure .ssh/config

Host admin
  Hostname admin
  User ceph
Host node1
  Hostname node1
  User ceph
Host node2
  Hostname node2
  User ceph
Host client1
  Hostname client1
  User ceph
Host node3
  Hostname node3
  User ceph
  
  
sudo systemctl restart sshd


Step 4:

sudo yum update
sudo yum install chrony

- Ensure chrony is running
sudo systemctl status chronyd


Step 5:
- Stop ufw
sudo systemctl stop ufw


Step 6:

- Disable SELINUX
sudo setenforce 0


Step 7:

# install ceph-deploy

sudo yum update

sudo rpm --import 'https://download.ceph.com/keys/release.asc'

- Create
/etc/yum.repos.d/ceph.repo

[ceph]
name=Ceph packages for $basearch
baseurl=https://download.ceph.com/rpm-nautilus/el7/$basearch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-nautilus/el7//noarch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://download.ceph.com/rpm-nautilus/el7/SRPMS
enabled=0
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc



- Add GPG key manually
sudo rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7


sudo yum install ceph-deploy --nobest --skip-broken


######

Install the ceph-cluster
######


mkdir ceph-cluster
cd ceph-cluster

ceph-deploy new node1 osd1 osd2

cat ceph.conf
# Add this >> osd pool default size = 2


ceph-deploy install --release nautilus node1 osd1 osd2

ceph-deploy mon create-initial

ceph-deploy admin node1 osd1 osd2

ceph-deploy mgr create node1

ceph-deploy mds create node1


# on each node :
sudo chmod +r /etc/ceph/ceph.client.admin.keyring


sudo ceph status 


####################################

Creating OSD

# Note : Do not mount file partition on the OSD server, as ceph does not like it.

ceph-deploy osd create --data /dev/sdf1 osd1

ceph-deploy osd create --data /dev/sdf1 osd2


######################################


Check chronyd

- if issues with time synchronization. Check Chronyd and all the systems should have the same source.
- If needed change source in /etc/chrony.conf


#######################################



Setup pool and mount separate Ceph Storage  (Admin method hack)

### Setup another server - call it client1

ceph-deploy install --release nautilus client1 
ceph-deploy admin client1
sudo chmod +r /etc/ceph/ceph.client.admin.keyring

### On the client Host

ceph osd pool create datastore 128 128
rbd create --size 20480 --pool datastore vol01
rbd feature disable datastore/vol01 object-map fast-diff deep-flatten
rbd map vol01 --pool datastore


mkfs.ext4 ... 
mkdir ...
mount /dev/rbd0 ceph_dir

### Remove image

umount /dev/rbd0
sudo rbd unmap --pool datastore vol01


sudo rbd rm --pool datastore vol01
sudo ceph osd pool delete datastore datastore --yes-i-really-really-mean-it

######################################

Check file system blocksizes:

ext4 : 
tune2fs -l /dev/sda1 |grep "^Block size:"


xfs :


btrfs :
sudo btrfs inspect-internal dump-super -f /dev/mapper/cr_root | grep "^sectorsize"

#######################################


# @ Setup Cephfs filesystem


##############
# Mount the right filesystem for the OSDs
#############

sudo mount /dev/sdf7 /var/lib/ceph/osd/ceph-0

##############
# Create the OSDs
#############

sudo bash

UUID=$(uuidgen)

OSD_SECRET=$(ceph-authtool --gen-print-key)

ID=$(echo "{\"cephx_secret\": \"$OSD_SECRET\"}" |    ceph osd new $UUID -i - -n client.bootstrap-osd -k /var/lib/ceph/bootstrap-osd/ceph.keyring)

ceph-authtool --create-keyring /var/lib/ceph/osd/ceph-$ID/keyring --name osd.$ID --add-key $OSD_SECRET

ceph-osd -i $ID --mkfs --osd-uuid $UUID

chown -R ceph:ceph /var/lib/ceph/osd/ceph-$ID

systemctl enable ceph-osd@$ID

systemctl start ceph-osd@$ID



##############
# Setup on the Mons
#############

ceph osd pool create cephfs_data 64
ceph osd pool create cephfs_metadata 64

ceph fs new cephfs cephfs_metadata cephfs_data




##############
# Setup on the Client side
#############

# Prerequisites [Only required once]
# On the client host (Should be able to ssh some Mon)

mkdir -p -m 755 /etc/ceph
ssh osd1 "sudo ceph config generate-minimal-conf" | sudo tee /etc/ceph/ceph.conf

chmod 644 /etc/ceph/ceph.conf

ssh osd1 "sudo ceph fs authorize cephfs client.foo / rw" | sudo tee /etc/ceph/ceph.client.foo.keyring

chmod 600 /etc/ceph/ceph.client.foo.keyring

##############
# To actually mount on the Client Host
#############

mkdir mycephfs
sudo mount -t ceph :/ mycephfs -o name=foo
sudo chmod 777 mycephfs



#######################################


# @ De-Setup Cephfs filesystem

##############
# Unmount at Client host 
#############

sudo umount mycephfs


##############
# Remove fs
#############

ceph fs fail cephfs

ceph fs rm cephfs --yes-i-really-mean-it

##############
# Remove Pool
#############

ceph osd pool delete cephfs_data cephfs_data --yes-i-really-really-mean-it
ceph osd pool delete cephfs_metadata cephfs_metadata --yes-i-really-really-mean-it

##############
# Remove OSDs
#############

ceph osd out 0
sudo systemctl stop ceph-osd@0
# ceph osd down osd.0
ceph osd purge 0 --yes-i-really-mean-it


ceph osd out 1
sudo systemctl stop ceph-osd@1
ceph osd down osd.1
ceph osd purge 1 --yes-i-really-mean-it


#######################################













