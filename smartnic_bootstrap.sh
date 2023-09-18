#!/bin/bash

LOGFILE="/opt/install_log"

function log () 
{
  msg=$1
  d=$(date +"[%H:%m:%S] --")

  if [ -f "$LOGFILE" ]
  then
    sudo echo -e "\n${d} ${msg}" | sudo tee -a $LOGFILE
  else
    sudo echo -e "\n${d} ${msg}" | sudo tee $LOGFILE
  fi
}



sudo echo -e "\n\n ============ INSTALLATION IS IN PROGRESS =========== " |sudo tee /etc/motd
sudo date | sudo tee -a /etc/motd

cat /local/repository/source/bashrc_template | sudo tee /root/.bashrc

log "Update package repository" 
DEBIAN_FRONTEND=noninteractive sudo apt-get update -y

# add here any tool you want to be installed
log "Install basic tools" 
BASIC_DEP="locate pv"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $BASIC_DEP


## don't need these things for now
# log "Installing xfce and vnc server..." 
# DEPS="tightvncserver lightdm lxde xfonts-base libnss3-dev firefox "
# DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DEPS


log "Installing DOCA SDKMANAGER dependencies..."
DOCA_SDK_MAN_DEP="gconf-service gconf-service-backend gconf2-common libcanberra-gtk-module libcanberra-gtk0 libgconf-2-4"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DOCA_SDK_MAN_DEP

#setting up extra storage
log "Set permissions for /mydata" 
sudo chmod -R 777 /mydata

log "Installing DOCKER and its dependencies..."
#install dependencies for docker
DOCKER_DEP="apt-transport-https ca-certificates curl gnupg lsb-release"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DOCKER_DEP
#install certificate for docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
#install docker
DOCKER="docker-ce docker-ce-cli containerd.io"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DOCKER

#dpdk and pktgen dependencies
DPDK_DEP="libc6-dev libpcap0.8 libpcap0.8-dev libpcap-dev meson ninja-build libnuma-dev liblua5.3-dev lua5.3"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DPDK_DEP

log "Stopping docker daemon and update location for downloading sources..."
sudo /etc/init.d/docker stop
#define new location in docker daemon.json
sudo echo -e "{\n\t\"data-root\":\"/mydata/docker\"\n}" | sudo tee /etc/docker/daemon.json
#rsync old docker files to new locations
rsync -aP /var/lib/docker/ /mydata/docker
#restart docker
/etc/init.d/docker restart


log "Updating system components..."
DEBIAN_FRONTEND=noninteractive sudo apt-get update -y
DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y


log "Installing Bluefield2 drivers and tools..." 
sudo wget https://www.mellanox.com/downloads/DOCA/DOCA_v2.0.2/doca-host-repo-ubuntu2004_2.0.2-0.0.7.2.0.2027.1.23.04.0.5.3.0_amd64.deb -O /opt/doca-host-repo-ubuntu2004_2.0.2-0.0.7.2.0.2027.1.23.04.0.5.3.0_amd64.deb
DEBIAN_FRONTEND=noninteractive sudo dpkg -i /opt/doca-host-repo-ubuntu2004_2.0.2-0.0.7.2.0.2027.1.23.04.0.5.3.0_amd64.deb
DEBIAN_FRONTEND=noninteractive sudo apt-get update -y
DEBIAN_FRONTEND=noninteractive sudo apt install -y --no-install-recommends doca-runtime doca-tools


#########################
##### OLD STUFF HERE ####
#########################
# cd /opt
# log "Downloading driver to /opt..." 
# sudo wget  http://www.mellanox.com/downloads/ofed/MLNX_OFED-5.3-1.0.0.1/MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz 
# #sudo cp /local/repository/source/MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz /opt
# #sudo cd /opt
# log "Uncompress..."
# sudo tar -xzvf MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz | sudo tee -a /opt/install_log

# cd /opt/MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64/
# log "Install driver..." 
# sudo ./mlnxofedinstall --auto-add-kernel-support --without-fw-update --force |sudo tee -a /opt/install_log

# cd ..
#########################
#########################
#########################

log "Enable openibd" 
sudo /etc/init.d/openibd restart | sudo tee -a /opt/install_log

log "Enable rshim" 
sudo systemctl enable rshim
sudo systemctl start rshim
sudo systemctl status rshim | sudo tee -a /opt/install_log


sudo echo "DISPLAY_LEVEL 1" | sudo tee /dev/rshim0/misc

log "Update netplan to assign IP to tmfif_net0..."
sudo cp /local/repository/source/01-netcfg.yaml /etc/netplan/
sudo systemctl restart systemd-networkd
sudo netplan apply

sudo ifconfig tmfifo_net0 |sudo tee -a /opt/install_log

log "Enable IP forwarding and NAT for the SmartNIC" 
sudo echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
sudo iptables -A FORWARD -o eno1 -j ACCEPT
sudo iptables -A FORWARD -m state --state ESTABLISHED,RELATED -i eno1 -j ACCEPT


log "Downloading the latest BlueOS firmware (22.04-10.23-04) for the Bluefield" 
cd /opt/
sudo wget https://content.mellanox.com/BlueField/BFBs/Ubuntu22.04/DOCA_2.0.2_BSP_4.0.3_Ubuntu_22.04-10.23-04.prod.bfb
log "Writing the latest BlueOS firmware (22.04-10.23-04) into the Bluefield" 
sudo bfb-install --rshim /dev/rshim0 --bfb DOCA_2.0.2_BSP_4.0.3_Ubuntu_22.04-10.23-04.prod.bfb



# sudo mst start
# for i in $(sudo mst status -v|grep BlueField|awk '{print $2}')
# do
#   echo "dev: ${i}"
#   mlxconfig -d $i q | grep -i internal_cpu
# done
# echo -e "\n\nTo change mode: mlxconfig -d /dev/mst/mt41686_pciconf0 s INTERNAL_CPU_MODEL=1"


# sudo echo -e "\nInstalling DPDK..." | sudo tee -a /opt/install_log
# cd /opt
# sudo wget https://fast.dpdk.org/rel/dpdk-20.11.1.tar.xz 
# sudo tar -xJvf dpdk-20.11.1.tar.xz |sudo tee -a /opt/install_log
# cd dpdk-stable-20.11.1
# export RTE_SDK=/opt/dpdk-stable-20.11.1
# export RTE_TARGET=x86_64-native-linuxapp-gcc
# #export RTE_TARGET=arm64-armv8-linuxapp-gcc <-- this would be for the Bluefield, but now we are on the host
# sudo meson -Dexamples=all build |sudo tee -a /opt/install_log
# sudo ninja -C build | sudo tee -a /opt/install_log
# sudo ninja -C build install | sudo tee -a /opt/install_log

# sudo echo -e "\nInstalling pktgen..." | sudo tee -a /opt/install_log
# cd /opt
# sudo wget https://git.dpdk.org/apps/pktgen-dpdk/snapshot/pktgen-dpdk-pktgen-21.02.0.tar.xz 
# sudo tar -xJvf pktgen-dpdk-pktgen-21.02.0.tar.xz | sudo tee -a /opt/install_log
# cd pktgen-dpdk-pktgen-21.02.0/
# sudo make | sudo tee -a /opt/install_log
# sudo ldconfig

log "Enabling hugepages..." 
sudo echo 12280 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
mountpoint -q /dev/hugepages || mount -t hugetlbfs nodev /dev/hugepages

# # FORBIDDEN - HAVE TO BE LOGGED IN :(
# # cd ..
# # sudo echo -e "\nInstall mlnx-dpdk..." |sudo tee -a /opt/install_log
# # wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu2004/mlnx-dpdk_20.11-1mlnx1_amd64.deb
# # wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu2004/mlnx-dpdk-dev_20.11-1mlnx1_amd64.deb
# # DEBIAN_FRONTEND=noninteractive dpkg --force -i mlnx-dpdk_20.11-1mlnx1_amd64.deb


# # sudo echo -e "\nInstall rxptools and dpi tools..." |sudo tee -a /opt/install_log
# # wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu1804_ubuntu2004/rxp-compiler_21.02.3_amd64.deb
# # wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu2004/rxpbench_21.03_20210401_0_ubuntu_20_amd64.deb
# # wget https://developer.nvidia.com/networking/secure/doca-sdk/DOCA_1.0/DOCA_10_b163/ubuntu2004/doca-dpi-tools_21.03.038-1_amd64.deb


log "Updatedb..." 
sudo updatedb

log "\n\n ============ DONE =========== "
sudo echo -e "\n\n ============ INSTALLATION FINISHED =========== " |sudo tee -a /etc/motd
sudo date | sudo tee -a /etc/motd

