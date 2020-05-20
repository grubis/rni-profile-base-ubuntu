#!/bin/bash

# Copyright (C) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause

set -a

#this is provided while using Utility OS
source /opt/bootstrap/functions



# --- Add Packages
ubuntu_bundles="openssh-server"
ubuntu_packages="wget iotedge"

# --- List out any docker images you want pre-installed separated by spaces. ---
pull_sysdockerimagelist=""

# --- List out any docker tar images you want pre-installed separated by spaces.  We be pulled by wget. ---
wget_sysdockerimagelist="" 

# --- Install Extra Packages ---
run "Installing Extra Packages on Ubuntu ${param_ubuntuversion}" \
    "docker run -i --rm --privileged --name ubuntu-installer ${DOCKER_PROXY_ENV} -v /dev:/dev -v /sys/:/sys/ -v $ROOTFS:/target/root ubuntu:${param_ubuntuversion} sh -c \
    'mount --bind dev /target/root/dev && \
    mount -t proc proc /target/root/proc && \
    mount -t sysfs sysfs /target/root/sys && \
    LANG=C.UTF-8 chroot /target/root sh -c \
        \"$(echo ${INLINE_PROXY} | sed "s#'#\\\\\"#g") export TERM=xterm-color && \
        export DEBIAN_FRONTEND=noninteractive && \
        apt install -y tasksel && \
        curl https://packages.microsoft.com/config/ubuntu/18.04/multiarch/prod.list > ./microsoft-prod.list && \
        cp ./microsoft-prod.list /etc/apt/sources.list.d/ && \
        curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
		cp ./microsoft.gpg /etc/apt/trusted.gpg.d/ && \
		mkdir /etc/iotedge && \
		apt update && \
        tasksel install ${ubuntu_bundles} && \
        apt install -y ${ubuntu_packages} && \
        dmidecode -s system-uuid | sed 's:-::g' > /etc/iotedge/uuid.txt && \
        dmidecode -s system-serial-number > /etc/iotedge/serial.txt\"'" \
     ${PROVISION_LOG}  
#       sed -i \"s#<SYMMETRIC_KEY>#\$(</etc/iotedge/uuid.txt sed 's/[\\&/]/\\\\&/g')#g\" /etc/iotedge/config.yaml && \
#	   	sed -i \"s#<REGISTRATION_ID>#\$(</etc/iotedge/serial.txt sed 's/[\\&/]/\\\\&/g')#g\" /etc/iotedge/config.yaml\"'" \
#		systemctl stop iotedge && \   
#		wget --header \"Authorization: token ${param_token}\" -O - ${param_bootstrapurl}/conf/iotagentconfig.yaml > /etc/iotedge/iotagentconfig.yaml && \    
#		sed -i \"s#<SYMMETRIC_KEY>#$UUID#g\" /etc/iotedge/config.yaml && \
#   	sed -i \"s#<REGISTRATION_ID>#$SN#g\" /etc/iotedge/config.yaml\"'" \    	
#		export UUID=$(dmidecode -s system-uuid) && \
#    	export UUID=${UUID//-} && \
#    	sed -i "\s#<SYMMETRIC_KEY>#$UUID#g\" /etc/iotedge/config.yaml && \
#    	export SN=$(dmidecode -s system-serial-number) && \
#    	sed -i "\s#<REGISTRATION_ID>#$SN#g\" /etc/iotedge/config.yaml\"'" \

# rm -f /etc/iotedge/config.yaml && \

sed -i "s#<REGISTRATION_ID>#$(<$ROOTFS/etc/iotedge/serial.txt sed 's/[\&/]/\\&/g')#g" $ROOTFS/etc/iotedge/config.yaml
    
# --- Pull any and load any system images ---
for image in $pull_sysdockerimagelist; do
	run "Installing system-docker image $image" "docker exec -i system-docker docker pull $image" "$TMP/provisioning.log"
done
for image in $wget_sysdockerimagelist; do
	run "Installing system-docker image $image" "wget -O- $image 2>> $TMP/provisioning.log | docker exec -i system-docker docker load" "$TMP/provisioning.log"
done
