export USER_NAME="ceph-admin"
export USER_PASS="StrOngP@ssw0rd"
sudo useradd --create-home -s /bin/bash ${USER_NAME}
echo "${USER_NAME}:${USER_PASS}"|sudo chpasswd
echo "${USER_NAME} ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/${USER_NAME}
sudo chmod 0440 /etc/sudoers.d/${USER_NAME}
