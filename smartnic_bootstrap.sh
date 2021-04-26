#!/bin/bash
sudo echo -e "\n\n ============ INSTALLATION IS IN PROGRESS =========== " >> /etc/motd
cat /local/repository/source/bashrc_template |sudo tee -a /root/.bashrc

sudo echo -e "\nInstalling MLNX driver..." > /opt/install_log
#sudo echo -e "\nCopy to /opt..." >> /opt/install_log
cd /opt
sudo echo -e "\nDownliading driver to/opt..." >> /opt/install_log
sudo wget  http://www.mellanox.com/downloads/ofed/MLNX_OFED-5.3-1.0.0.1/MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz >> /opt/install_log
#sudo cp /local/repository/source/MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz /opt
#sudo cd /opt
sudo echo -e "\nUncompress..." >> /opt/install_log
sudo tar -xzvf MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64.tgz

cd MLNX_OFED_LINUX-5.3-1.0.0.1-ubuntu20.04-x86_64
sudo echo -e "\nInstall driver..." >> /opt/install_log
sudo ./mlnxofedinstall --auto-add-kernel-support --without-fw-update --force


sudo echo -e "\nEnable openibd" >> /opt/install_log
sudo /etc/init.d/openibd restart >> /opt/install_log

sudo echo -e "\nEnable rshim" >> /opt/install_log
sudo systemctl enable rshim
sudo systemctl start rshim
sudo systemctl status rshim >> /opt/install_log


sudo echo "DISPLAY_LEVEL 1" > /dev/rshim0/misc

sudo echo -e "\nUpdate netplan to assign IP to tmfif_net0..." >> /opt/install_log
sudo cp /local/repository/source/01-netcfg.yaml /etc/netplan/
sudo systemctl restart systemd-networkd
sudo netplan apply

sudo ifconfig tmfifo_net0 >> /opt/install_log

sudo echo -e "\nEnable IP forwarding for the SmartNIC" >> /opt/install_log
sudo echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE

sudo echo -e "\n\n ============ DONE =========== " >> /opt/install_log
sudo echo -e "\n\n ============ INSTALLATION FINISHED =========== " >> /etc/motd