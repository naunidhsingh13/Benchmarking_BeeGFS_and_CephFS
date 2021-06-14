# Import repository key
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -


#Add the Ceph repository to your system. This installation will do Ceph nautilus

echo deb https://download.ceph.com/debian-nautilus/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list


# Update your repository and install ceph-deploy:

sudo apt update
sudo apt -y install ceph-deploy
