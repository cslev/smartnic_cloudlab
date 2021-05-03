#!/bin/bash
sudo echo -e "\n\n ============ INSTALLATION IS IN PROGRESS =========== " |sudo tee -a /etc/motd
sudo date | sudo tee -a /etc/motd

cat /local/repository/source/bashrc_template |sudo tee -a /root/.bashrc

sudo echo -e "\nInstalling MLNX driver..." |sudo tee /opt/install_log
#sudo echo -e "\nCopy to /opt..." >> /opt/install_log
cd /opt
sudo echo -e "\nDownliading driver to/opt..." |sudo tee -a /opt/install_log
sudo wget  http://www.mellanox.com/downloads/ofed/MLNX_OFED-5.3-1.0.0.1/MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz >> /opt/install_log
#sudo cp /local/repository/source/MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz /opt
#sudo cd /opt
sudo echo -e "\nUncompress..." |sudo tee -a /opt/install_log
sudo tar -xzvf MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz

cd MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64
sudo echo -e "\nInstall driver..." |sudo tee -a /opt/install_log
sudo ./mlnxofedinstall --auto-add-kernel-support --ovs-dpdk --without-fw-update --force
cd ..

sudo echo -e "\nEnable openibd" |sudo tee -a /opt/install_log
sudo /etc/init.d/openibd restart |sudo tee -a /opt/install_log

sudo echo -e "\nEnable rshim" |sudo tee -a /opt/install_log
sudo systemctl enable rshim
sudo systemctl start rshim
sudo systemctl status rshim |sudo tee -a /opt/install_log


sudo echo "DISPLAY_LEVEL 1" |sudo tee /dev/rshim0/misc

sudo echo -e "\nUpdate netplan to assign IP to tmfif_net0..." |sudo tee -a /opt/install_log
sudo cp /local/repository/source/01-netcfg.yaml /etc/netplan/
sudo systemctl restart systemd-networkd
sudo netplan apply

sudo ifconfig tmfifo_net0 |sudo tee -a /opt/install_log

sudo echo -e "\nEnable IP forwarding for the SmartNIC" |sudo tee -a /opt/install_log
sudo echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE


sudo echo -e "\nInstalling xfce and vnc server..." | sudo tee -a /opt/install_log
DEPS="tightvncserver lightdm lxde xfonts-base libnss3-dev"
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $DEPS

sudo echo -e "\nInstalling DOCA SDKMANAGER dependencies..." | sudo tee -a /opt/install_log
DOCA_SDK_MAN_DEP="gconf-service gconf-service-backend gconf2-common libcanberra-gtk-module libcanberra-gtk0 libgconf-2-4"
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $DOCA_SDK_MAN_DEP

#setting up extra storage
sudo echo -e "\nSet permissions for /mydata" | sudo tee -a /opt/install_log
sudo chmod -R 777 /mydata

sudo echo -e "\nInstalling DOCKER and its dependencies..." | sudo tee -a /opt/install_log
#install dependencies for docker
DOCKER_DEP="apt-transport-https ca-certificates curl gnupg lsb-release"
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $DOCKER_DEP
#install certificate for docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
#install docker
DOCKER="docker-ce docker-ce-cli containerd.io"
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $DOCKER

sudo echo -e "\nStopping docker daemon and update location for downloading sources..."  | sudo tee -a /opt/install_log
sudo /etc/init.d/docker stop
#define new location in docker daemon.json
echo -e "{\n\t\"data-root\":\"/mydata/docker\"\n}" > /etc/docker/daemon.json
#rsync old docker files to new locations
rsync -aP /var/lib/docker/ /mydata/docker
#restart docker
/etc/init.d/docker restart

sudo mst start
for i in $(sudo mst status -v|grep BlueField|awk '{print $2}')
do
  echo "dev: ${i}"
  mlxconfig -d $i q | grep -i internal_cpu
done
echo -e "\n\nTo change mode: mlxconfig -d /dev/mst/mt41686_pciconf0 s INTERNAL_CPU_MODEL=1"


# FORBIDDEN - HAVE TO BE LOGGED IN :(
# cd ..
# sudo echo -e "\nInstall mlnx-dpdk..." |sudo tee -a /opt/install_log
# wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu2004/mlnx-dpdk_20.11-1mlnx1_amd64.deb
# wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu2004/mlnx-dpdk-dev_20.11-1mlnx1_amd64.deb
# DEBIAN_FRONTEND=noninteractive dpkg --force -i mlnx-dpdk_20.11-1mlnx1_amd64.deb


# sudo echo -e "\nInstall rxptools and dpi tools..." |sudo tee -a /opt/install_log
# wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu1804_ubuntu2004/rxp-compiler_21.02.3_amd64.deb
# wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu2004/rxpbench_21.03_20210401_0_ubuntu_20_amd64.deb
# wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu2004/doca-dpi-tools_21.03.038-1_amd64.deb



sudo echo -e "\n\n ============ DONE =========== " |sudo tee -a /opt/install_log
sudo echo -e "\n\n ============ INSTALLATION FINISHED =========== " |sudo tee -a /etc/motd
sudo date | sudo tee -a /etc/motd

