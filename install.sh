#!/bin/bash

# Name:         spot
# Version:      0.0.3
# Release:      1
# License:      CC-BA (Creative Commons By Attribution)
#               http://creativecommons.org/licenses/by/4.0/legalcode
# Group:        System
# Source:       N/A
# URL:          http://lateralblast.com.au/
# Distribution: Red Hat Linux, Centos Linux, Ubuntu Linux
# Vendor:       UNIX
# Packager:     Richard Spindler <richard@lateralblast.com.au>
# Description:  Big Data VM Setup script
#               This script is designed to install the required components for a
#               Big Data (Teaching and general usage) VM from an existing tar file of
#               the Big Data user directory (see default USER_NAME, our use -u to set)
#               with preinstalled packaged, or from scratch by installing required packages
 
# Packages in tar file:
#
# spark 2.0, 2.1
# hadoop 2.7.3
# hbase 1.2.4
# darknet
# fann
# joda-time 2.4
# opencv

# Get running directory and set src directory

BASE_DIR=`dirname $0`
SRC_DIR="$BASE_DIR/src"

# Set up OpenCV defaults

if [ "$OPENCV_VER" = "" ]; then
  OPENCV_VER="3.1.0"
  OPENCV_URL="https://github.com/opencv/opencv/archive/$OPENCV_VER.tar.gz"
  OPENCV_DIR="opencv-$OPENCV_VER"
  OPENCV_TAR="$OPENCV_DIR.tar.gz"
  OPENCV_CONTRIB_URL="https://github.com/opencv/opencv_contrib/archive/$OPENCV_VER.tar.gz"
  OPENCV_CONTRIB_DIR="opencv_contrib-$OPENCV_VER"
  OPENCV_CONTRIB_TAR="$OPENCV_CONTRIB_DIR.tar.gz"
fi

# Set up user information (user created for Big Data programs)

if [ "$USER_NAME" = "" ]; then
  USER_NAME="user"
fi
if [ "$USER_GROUP" = "" ]; then
  USER_GROUP=$USER_NAME
fi
if [ "$USER_BASE" = "" ]; then
  USER_BASE="/home"
fi
if [ "$USER_HOME" = "" ]; then
  USER_HOME="/home/$USER_NAME"
fi
if [ "$USER_GCOS" = "" ]; then
  USER_GCOS="Big Data User"
fi
if [ "$SUDO_GROUP" = "" ]; then
  SUDO_GROUP="wheel"
fi
if [ "$SUDO_FILE" = "" ]; then
  SUDO_FILE="/etc/sudoers.d/bdvm"
fi
if [ "$USER_TAR" = "" ]; then
  USER_TAR="/mnt/VMs/Asad/user_snapshot_rs_290817.tar.bz2"
fi

# Function to check we have base packages installed

check_base () {
  if [ -f "/etc/redhat-release" ]; then
    if [ ! -f "/etc/yum.repos.d/atrpms.repo" ]; then
      rpm --import http://packages.atrpms.net/RPM-GPG-KEY.atrpms
      echo "[atrpms]" > /etc/yum.repos.d/atrpms.repo
      echo "name=Fedora Core \$releasever - \$basearch - ATrpms" >> /etc/yum.repos.d/atrpms.repo
      echo "baseurl=http://dl.atrpms.net/el\$releasever-\$basearch/atrpms/stable" >> /etc/yum.repos.d/atrpms.repo
      echo "gpgkey=http://ATrpms.net/RPM-GPG-KEY.atrpms" >> /etc/yum.repos.d/atrpms.repo
      echo "gpgcheck=1" >> /etc/yum.repos.d/atrpms.repo
      echo "enabled=1" >> /etc/yum.repos.d/atrpms.repo
      yum update -y
      yum install ffmpeg ffmpeg-devel -y
    fi
    for package in unzip sudo cmake wget epel-release bsdtar3 bzip2 java-1.8.0-openjdk gcc-c++ gtk2-devel tesseract-devel \
                   yum-utils libavformat-* libtiff-devel libjpeg-devel hdf5-devel python-pip numpy libgphoto2-devel \
                   libdc1394-devel libv4l-devel gstreamer-plugins-base-devel libpng-devel libjpeg-turbo-devel jasper-devel \
                   openexr-devel libtiff-devel libwebp-devel; do
      yum install $package -y
    done
    pip install --upgrade pip
    yum groupinstall development -y
    RHEL_VER=`cat /etc/redhat-release |awk '{print $3}' |cut -f1 -d.`
    if [ "$RHEL_VER" = "7" ]; then
      yum  install joda-time -y
    else
      rpm -Uvh http://mirror.centos.org/centos/7/os/x86_64/Packages/joda-convert-1.3-5.el7.noarch.rpm
      rpm -Uvh http://mirror.centos.org/centos/7/os/x86_64/Packages/joda-time-2.2-3.tzdata2013c.el7.noarch.rpm
    fi
    sudo yum -y install https://centos$RHEL_VER.iuscommunity.org/ius-release.rpm
    yum -y install python36u python36u-pip python36u-devel
  else
    apt-get update
    for package in vim unzip sudo cmake wget bzip2 bsdtar default-jre g++ opencl-1.2 python3 python3-dev libtesseract-dev \
                   libavformat-* libtiff-dev libjpeg-dev libhdf5-dev python-pip libgphoto2-dev python-numpy libgphoto2-dev \
                   libdc1394-22-dev libv4l-dev gstreamer-plugins-base1.0-dev libpng-dev libjpeg-turbo8-dev libjasper-dev \
                   libopenexr-dev libtiff-dev libwebp-dev joda-time*; do
      apt-get install $package -y
    done
    update-alternatives --config java
  fi
  if [ -f "/.dockerenv" ]; then
    if [ -f "/etc/redhat-release" ]; then
      TAR_BIN=`which bsdtar3`
    else
      TAR_BIN=`which bsdtar`
    fi
  else
    TAR_BIN=`which tar`
  fi
}

# Function to add a user

add_user () {
  USER_NAME=$1
  USER_HOME=$USER_BASE/$USER_NAME
  groupadd $SUDO_GROUP
  useradd -c "$USER_GCOS" -G $SUDO_GROUP -d $USER_HOME -m $USER_NAME
  echo "%wheel	ALL=(ALL)	NOPASSWD: ALL" > $SUDO_FILE
}

# Function to install from tar ball

tar_install () {
  USER_TAR=$1
  USER_NAME=$2
  USER_HOME=$USER_BASE/$USER_NAME
  cd $USER_HOME
  if [ -f "$USER_TAR" ]; then
    $TAR_BIN -xpjf $USER_TAR
    chown -R $USER_NAME:$USER_GROUP $USER_HOME
  else
    echo "Tar file $USER_TAR does not exist"
    exit
  fi
}

# Install OpenCV

install_opencv () {
  cd $TMP_DIR
  if [ ! -f "$OPENCV_TAR" ]; then
    echo "Downloading $OPENCV_URL to $TMP_DIR/$OPENCV_TAR"
    wget -O $OPENCV_TAR $OPENCV_URL
  fi
  if [ -f "$OPENCV_TAR" ]; then
    if [ ! -d "$OPENCV_DIR" ]; then
      tar -xpf $OPENCV_TAR
    fi
    if [ ! -f "$OPENCV_CONTRIB_TAR" ]; then
      echo "Downloading $OPENCV_CONTRIB_URL to $TMP_DIR/$OPENCV_CONTRIB_TAR"
      wget -O $OPENCV_CONTRIB_TAR $OPENCV_CONTRIB_URL
    fi
    if [ -f "$OPENCV_CONTRIB_TAR" ]; then
      if [ ! -d "$OPENCV_CONTRIB_DIR" ]; then
        tar -xvf $OPENCV_CONTRIB_TAR
      fi
      cd $OPENCV_DIR
      cmake -DWITH_GPHOTO2=OFF -DCMAKE_INSTALL_PREFIX=/usr/local -DOPENCV_EXTRA_MODULES_PATH=../$OPENCV_CONTRIB_DIR/modules
      if [ -f "/etc/redhat-release" ]; then
        cp $SRC_DIR/jas_math.h /usr/include/jasper/jas_math.h
      else
        echo "find_package(HDF5)" >> modules/python/common.cmake
        echo "include_directories(\${HDF5_INCLUDE_DIRS})" >> modules/python/common.cmake
      fi
      make all
      make install
    else
      echo "Failed to download $OPENCV_CONTRIB_URL"
    fi
  else
    echo "Failed to download $OPENCV_URL"
  fi
}

# Do a full install

full_install () {
  install_opencv
  if [ -f "/etc/redhat-release" ]; then
    for package in ; do
      yum install $package -y
    done
  else
    apt-get update
    for package in ; do
      apt-get install $package -y
    done
  fi
}

print_usage () {
  echo ""
  echo "Usage $0 -[B|C|T|U|F|h] -[f|u|g|t]: -[Z]"
  echo ""
  echo "-h: Print usage information"
  echo "-T: Install from preconfigured tar file"
  echo "-B: Install base support packages"
  echo "-F: Install packages manually"
  echo "-f: Specify tar file (otherwise uses default in script)"
  echo "-C: Install OpenCV manually"
  echo "-U: Add user"
  echo "-Z: Exclude base support package check"
  echo "-u: Set Username"
  echo "-g: Set Usergroup"
  echo "-t: Set temporary directory"
  echo ""
}

if [ "$1" = "" ]; then
  print_usage
  exit
fi

while getopts BCTUFZhf:u:g: args; do
  case $args in
  Z)
    exclude_base=1
    ;;
  f)
    USER_TAR=$OPTARG
    ;;
  t)
    TMP_DIR=$OPTARG
    ;;
  u)
    USER_NAME=$OPTARG
    ;;
  g)
    USER_GROUP=$OPTARG
    ;;
  B)
    do_base_check=1
    ;;
  U)
    do_add_user=1
    ;;
  C)
    do_full_install=0
    do_base_check=1
    do_opencv=1
    ;;
  T)
    do_full_install=0
    do_base_check=1
    do_add_user=1
    do_tar_install=1
    ;;
  F)
    do_base_check=1
    do_add_user=1
    do_full_install=1
    ;;
  h)
    print_usage
    exit
    ;;
  *)
    print_usage
    exit
    ;;
  esac
done

# Set up temp dir

if [ "$TMP_DIR" = "" ]; then
  export TMP_DIR="$USER_HOME/tmp"
fi
if [ ! -d "$TMP_DIR" ]; then
  mkdir -p $TMP_DIR
fi

if [ "$exclude_base" = 1 ]; then
  do_base_check=0
fi

if [ "$do_base_check" = 1 ]; then
  check_base
fi

if [ "$do_add_user" = 1 ]; then
  add_user $USER_NAME
fi

if [ "$do_opencv" = 1 ]; then
  install_opencv
fi

if [ "$do_tar_install" = 1 ]; then
  tar_install $USER_TAR $USER_NAME
  exit
fi

if [ "$do_full_install" = 1 ]; then
  full_install
  exit
fi
