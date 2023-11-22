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
sudo echo -e "\nTo keep track of the process:  tail -f /opt/install.log"

cat /local/repository/source/bashrc_template | sudo tee /root/.bashrc

log "Update package repository" 
DEBIAN_FRONTEND=noninteractive sudo apt-get update -y | sudo tee -a /opt/install_log

# add here any tool you want to be installed
log "Install basic tools" 
BASIC_DEP="locate pv mc"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $BASIC_DEP | sudo tee -a /opt/install_log


## don't need these things for now
# log "Installing xfce and vnc server..." 
# DEPS="tightvncserver lightdm lxde xfonts-base libnss3-dev firefox "
# DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DEPS

log "Installing apt-file..."
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends apt-file | sudo tee -a /opt/install_log
DEBIAN_FRONTEND=noninteractive sudo apt-file update | sudo tee -a /opt/install_log

log "Installing DOCA SDKMANAGER dependencies..."
DOCA_SDK_MAN_DEP="gconf-service gconf-service-backend gconf2-common libcanberra-gtk-module libcanberra-gtk0 libgconf-2-4"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DOCA_SDK_MAN_DEP | sudo tee -a /opt/install_log

#setting up extra storage
log "Set permissions for /mydata" 
sudo chmod -R 777 /mydata

log "Installing DOCKER and its dependencies..."
#install dependencies for docker
DOCKER_DEP="apt-transport-https ca-certificates curl gnupg lsb-release"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DOCKER_DEP | sudo tee -a /opt/install_log
#install certificate for docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
#install docker
DOCKER="docker-ce docker-ce-cli containerd.io"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DOCKER | sudo tee -a /opt/install_log

log "Stopping docker daemon and update location for downloading sources..."
sudo /etc/init.d/docker stop
#define new location in docker daemon.json
sudo echo -e "{\n\t\"data-root\":\"/mydata/docker\"\n}" | sudo tee /etc/docker/daemon.json
#rsync old docker files to new locations
rsync -aP /var/lib/docker/ /mydata/docker
#restart docker
/etc/init.d/docker restart


log "Updating system components..."
DEBIAN_FRONTEND=noninteractive sudo apt-get update -y | sudo tee -a /opt/install_log
DEBIAN_FRONTEND=noninteractive sudo apt-get upgrade -y | sudo tee -a /opt/install_log 


log "Installing Bluefield2 drivers and tools..." 
## DOCA v2.0.2 for ubuntu 2024
sudo wget https://www.mellanox.com/downloads/DOCA/DOCA_v2.0.2/doca-host-repo-ubuntu2004_2.0.2-0.0.7.2.0.2027.1.23.04.0.5.3.0_amd64.deb -O /opt/doca-host-repo-ubuntu2004_2.0.2-0.0.7.2.0.2027.1.23.04.0.5.3.0_amd64.deb
DEBIAN_FRONTEND=noninteractive sudo dpkg -i /opt/doca-host-repo-ubuntu2004_2.0.2-0.0.7.2.0.2027.1.23.04.0.5.3.0_amd64.deb
## DOCA v2.2.1 for ubuntu 2204
#sudo wget https://www.mellanox.com/downloads/DOCA/DOCA_v2.2.1/doca-host-repo-ubuntu2204_2.2.1-0.0.3.2.2.1009.1.23.07.0.5.0.0_amd64.deb -O /opt/doca-host-repo-ubuntu2204_2.2.1-0.0.3.2.2.1009.1.23.07.0.5.0.0_amd64.deb
#DEBIAN_FRONTEND=noninteractive sudo dpkg -i /opt/doca-host-repo-ubuntu2204_2.2.1-0.0.3.2.2.1009.1.23.07.0.5.0.0_amd64.deb



DEBIAN_FRONTEND=noninteractive sudo apt-get update -y
DEBIAN_FRONTEND=noninteractive sudo apt install -y --no-install-recommends doca-runtime doca-tools | sudo tee -a /opt/install_log




############################$$$$$$$###################################
##### MANUAL INSTALL, e.g., FOR UNSUPPORTED DISTRIBUTION VERSIONS ####
###################################$$$$$$$############################
# log "Downloading driver to /opt..." 
# cd /opt
#### UBUNTU 22.04
# sudo wget https://content.mellanox.com/ofed/MLNX_OFED-23.07-0.5.1.2/MLNX_OFED_LINUX-23.07-0.5.1.2-ubuntu22.04-x86_64.tgz

#### UBUNTU 23.04
# sudo wget https://content.mellanox.com/ofed/MLNX_OFED-23.07-0.5.1.2/MLNX_OFED_LINUX-23.07-0.5.1.2-ubuntu23.04-x86_64.tgz

#### DEBIAN 11.3
# sudo wget https://content.mellanox.com/ofed/MLNX_OFED-23.07-0.5.1.2/MLNX_OFED_LINUX-23.07-0.5.1.2-debian11.3-x86_64.tgz


# log "Uncompress..."
# sudo tar -xzvf MLNX_OFED_LINUX-23.07-0.5.1.2-ubuntu22.04-x86_64.tgz | sudo tee -a /opt/install_log

# cd MLNX_OFED_LINUX-23.07-0.5.1.2-ubuntu22.04-x86_64
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


sudo echo "DISPLAY_LEVEL 2" | sudo tee /dev/rshim0/misc

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


log "Downloading the latest BlueOS firmware for the Bluefield" 
cd /opt/

## DOCA 1.0
# sudo wget https://content.mellanox.com/BlueField/BFBs/Ubuntu20.04/DOCA_v1.0_BlueField_OS_Ubuntu_20.04-5.3-1.0.0.0-3.6.0.11699-1-aarch64.bfb -O /opt/DOCA_v1.0_BlueField_OS_Ubuntu_20.04-5.3-1.0.0.0-3.6.0.11699-1-aarch64.bfb
## DOCA 1.5.2
# sudo wget https://content.mellanox.com/BlueField/BFBs/Ubuntu20.04/DOCA_1.5.2_BSP_3.9.6_Ubuntu_20.04-5.2306-LTS.prod.bfb -O /opt/DOCA_1.5.2_BSP_3.9.6_Ubuntu_20.04-5.2306-LTS.prod.bfb
## DOCA 2.0.2
# sudo wget https://content.mellanox.com/BlueField/BFBs/Ubuntu22.04/DOCA_2.0.2_BSP_4.0.3_Ubuntu_22.04-10.23-04.prod.bfb -O /opt/DOCA_2.0.2_BSP_4.0.3_Ubuntu_22.04-10.23-04.prod.bfb
## DOCA 2.2.0
sudo wget https://content.mellanox.com/BlueField/BFBs/Ubuntu22.04/DOCA_2.2.0_BSP_4.2.0_Ubuntu_22.04-2.23-07.prod.bfb -O /opt/DOCA_2.2.0_BSP_4.2.0_Ubuntu_22.04-2.23-07.prod.bfb
log "Writing the latest BlueOS firmware into the Bluefield" 
sudo bfb-install --rshim /dev/rshim0 --bfb /opt/DOCA_2.2.0_BSP_4.2.0_Ubuntu_22.04-2.23-07.prod.bfb | sudo tee -a /opt/install_log


# log "Removing doca-runtime and its dependencies as it will collide with the latest DPDK and Pktgen..."
# DEBIAN_FRONTEND=noninteractive sudo apt-get remove doca-runtime -y 
# DEBIAN_FRONTEND=noninteractive sudo apt-get auto-remove -y 


# sudo mst start
# for i in $(sudo mst status -v|grep BlueField|awk '{print $2}')
# do
#   echo "dev: ${i}"
#   mlxconfig -d $i q | grep -i internal_cpu
# done
# echo -e "\n\nTo change mode: mlxconfig -d /dev/mst/mt41686_pciconf0 s INTERNAL_CPU_MODEL=1"



log "Installing DPDK and pktgen dependencies..." 
DPDK_DEP="libc6-dev libpcap0.8 libpcap0.8-dev libpcap-dev meson ninja-build libnuma-dev liblua5.3-dev lua5.3 luarocks python3-pyelftools build-essential librte-pmd-mlx5-20.0 ibverbs-providers libibverbs-dev mlnx-ofed-kernel-only"
DPDK_DEP="${DPDK_DEP} python3-sphinxcontrib.apidoc doxygen libarchive-dev libjansson-dev libbsd-dev libelf-dev mstflint libbpf-dev cmake"
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends $DPDK_DEP | sudo tee -a /opt/install_log




log "Removing mlnx-dpdk as it will collide with the latest DPDK and Pktgen..."
DEBIAN_FRONTEND=noninteractive sudo apt-get remove mlnx-dpdk -y 
sudo ldconfig

log "\nInstalling DPDK..." 
cd /opt
#sudo wget https://fast.dpdk.org/rel/dpdk-20.11.9.tar.xz 
sudo wget https://fast.dpdk.org/rel/dpdk-23.07.tar.xz
#sudo tar -xJf dpdk-20.11.9.tar.xz | sudo tee -a /opt/install_log
sudo tar -xJf dpdk-23.07.tar.xz | sudo tee -a /opt/install_log
# sudo ln -s /opt/dpdk-stable-20.11.9/ /opt/dpdk ## /opt/dpdk is set as RTE_SDK in bashrc 
sudo ln -s /opt/dpdk-23.07/ /opt/dpdk ## /opt/dpdk is set as RTE_SDK in bashrc
cd dpdk
sudo meson -Dexamples=all build | sudo tee -a /opt/install_log
#########################
### DPDK + CUDA #########
#########################
# we have to install cuda toolkit from https://developer.nvidia.com/cuda-toolkit
# and if installed but headers are not found by DPDK during meson build: 
## - download the header files 
# git clone https://gitlab.com/nvidia/headers/cuda-individual/cudart
## - then when compiling DPDK with meson, set the path to be included
# meson -Dexamples=all -Dc_args=-I/home/csikorl/cudart build


sudo ninja -C build | sudo tee -a /opt/install_log
sudo ninja -C build install | sudo tee -a /opt/install_log
sudo ldconfig

log "\nInstalling CJSON lua library..."
cd /opt
sudo wget https://www.kyne.com.au/%7Emark/software/download/lua-cjson-2.1.0.tar.gz
sudo tar -xzf lua-cjson-2.1.0.tar.gz | sudo tee -a /opt/install_log
cd lua-cjson-2.1.0
sudo luarocks make | sude tee -a /opt/install_log
sudo ldconfig


log "\nInstalling pktgen..." 
cd /opt
# sudo wget https://git.dpdk.org/apps/pktgen-dpdk/snapshot/pktgen-dpdk-pktgen-21.03.1.tar.xz
sudo wget https://github.com/pktgen/Pktgen-DPDK/archive/refs/tags/pktgen-23.06.1.tar.gz
sudo tar -xzf pktgen-23.06.1.tar.gz | sudo tee -a /opt/install_log
cd Pktgen-DPDK-pktgen-23.06.1
sudo make buildlua | sudo tee -a /opt/install_log
sudo ldconfig

log "Enabling hugepages..." 
sudo echo 16384 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
sudo umount -q /dev/hugepages
sudo mkdir -p /mnt/huge
sudo mount -t hugetlbfs nodev /mnt/huge
sudo echo "vm.nr_hugepages = 16384" | sudo tee -a /etc/sysctl.conf

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
sudo echo -e "\n\n ============ INSTALLATION FINISHED =========== " |sudo tee /etc/motd
sudo date | sudo tee -a /etc/motd
sudo echo -e "############## WARNING DPDK And PKTGEN USERS ##############" |sudo tee -a /etc/motd
sudo echo -e "you may delete 'mlnx-dpdk' package if the newest pktgen complains as:" |sudo tee -a /etc/motd
sudo echo -e "Symbol \`rte_eth_fp_ops' has different size in shared object, consider re-linking" |sudo tee -a /etc/motd
sudo echo -e "###########################################################" |sudo tee -a /etc/motd
sudo echo -e "\nTo see install log:  less /opt/install.log"


