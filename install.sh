#!/bin/bash

# Name:         spot
# Version:      0.1.1
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
#
# Packages in tar file:
#
# spark 2.2.0
# hadoop 2.7.3
# hbase 1.3.1
# darknet
# fann
# joda-time 2.4
# opencv

# Get the version of the script from the script itself

start_path=`pwd`
script_version=`cd $start_path ; cat $0 | grep '^# Version' |awk '{print $3}'`

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

# Set up Spark defaults

if [ "$SPARK_VER" = "" ]; then
  SPARK_VER="2.2.0"
  HADOOP_VER="2.7"
  SPARK_TAR="spark-$SPARK_VER-bin-hadoop$HADOOP_VER.tgz"
  SPARK_URL="http://ftp.mirror.aarnet.edu.au/pub/apache/spark/spark-$SPARK_VER/$SPARK_TAR"
  SPARK_DIR="spark-$SPARK_VER-bin-hadoop$HADOOP_VER"
fi

# Set up HBase defaults

if [ "$HBASE_VER" = "" ]; then
  HBASE_VER="1.3.1"
  HBASE_TAR="hbase-$HBASE_VER-bin.tar.gz"
  HBASE_URL="http://ftp.mirror.aarnet.edu.au/pub/apache/hbase/$HBASE_VER/$HBASE_TAR"
  HBASE_DIR="hbase-$HBASE_VER"
fi

# Set up Hadoop defaults

if [ "$HBASE_VER" = "" ]; then
  HADOOP_VER="1.2.1"
  HADOOP_TAR="hadoop-$HADOOP_VER-bin.tar.gz"
  HADOOP_URL="http://ftp.mirror.aarnet.edu.au/pub/apache/hadoop/common/$HADOOP_TAR"
  HADOOP_DIR="hadoop-$HADOOP_VER"
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

if [ "$PYENV_DIR" = "" ]; then
  PYENV_DIR="$USER_HOME/.pyenv"
fi

# Function to clean up user home permissions

clean_up_user_perms () {
  chown -R $USER_NAME:$USER_NAME $USER_HOME
}

# Function to check if we are running in VMware and install tools

install_vmware_tools () {
  check_vmware=`lspci | grep -i vmware`
  if [ ! "$check_vmware" = "" ]; then
    if [ -f "/etc/redhat-release" ]; then
      yum install open-vm-tools -y
    else
      apt-get install open-vm-tools -y
    fi
  fi
}

# Function to check if we are running in VirtualBox and install tools

install_vbox_tools () {
  check_vbox=`dmidecode -t system|grep 'Manufacturer\|Product' |grep VirtualBox`
  if [ ! "$check_vbox" = "" ]; then
    if [ -f "/etc/redhat-release" ]; then
      # Need to fix
      :
    else
      apt-get install virtualbox-guest-dkms -y 
    fi
  fi
}

# Function to check if we are running in a VM and install tools

install_vm_tools () {
  install_vmware_tools
  install_vbox_tools
}

# Function to install and setup pyenv

install_pyenv () {
  profile="$USER_HOME/.bashrc"
  if [ ! -d "$PYENV_DIR" ]; then
    if [ -f "/etc/redhat-release" ]; then
      yum install -y gcc gcc-c++ make git patch openssl-devel zlib-devel readline-devel sqlite-devel bzip2-devel
    else
      apt-get install -y gcc gcc-c++ make git patch openssl-dev zlib-dev readline-dev sqlite-dev bzip2-dev
    fi
    git clone git://github.com/yyuu/pyenv.git $PYENV_DIR
  fi
  pyenv_test=`cat $profile |grep pyenv`
  if [ ! "$pyenv_test" ]; then
    echo "" >> $profile
    echo "export PATH="\$HOME/.pyenv/bin:\$PATH"" >> $profile
    echo "eval \"\$(pyenv init -)\"" >> $profile
    echo "" >> $profile
  fi
}

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
                   openexr-devel libtiff-devel libwebp-devel fann-devel dmidecode; do
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
                   libopenexr-dev libtiff-dev libwebp-dev joda-time* libfann-dev dmidecode; do
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

# Function to install darknet

install_darknet () {
  cd $USER_HOME
  git clone https://github.com/pjreddie/darknet.git
  cd darknet
  sed -i "s/OPENCV=0/OPENCV=1/g" Makefile
  sed -i "s/-Ofast/-O3 -ffast-math/g" Makefile
  export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/usr/local/lib/pkgconfig
  make
}

# function to download and install a binary from a URL

install_bin_from_url () {
  bin_url=$1
  bin_tar=$2
  bin_dir=$3
  cd $TMP_DIR
  if [ ! -f "$bin_tar" ]; then
    echo "Downloading $bin_url to $TMP_DIR/$bin_tar"
    wget -O $bin_tar $bin_url
  fi
  if [ -f "$bin_tar" ]; then
    cd $USER_HOME
    if [ ! -d "$bin_dir" ]; then
      tar -xpzf $TMP_DIR/$bin_tar
    fi
  else
    echo "Failed to download $bin_url"
  fi
}

# function to install Spark

install_spark () {
  install_bin_from_url $SPARK_URL $SPARK_TAR $SPARK_DIR
}

# function to install HBase 

install_hbase () {
  install_bin_from_url $HBASE_URL $HBASE_TAR $HBASE_DIR
}

# function to install Hadoop

install_hadoop () {
  install_bin_from_url $HADOOP_URL $HADOOP_TAR $HADOOP_DIR
}

# Function to install OpenCV

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

# Function to do a full install

full_install () {
  install_opencv
  install_hbase
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
  echo "Usage $0 -[B|C|D|E|H|X|O|S|T|F|U|Y|K|h] -[f|u|g|t]: -[Z]"
  echo ""
  echo "-h: Print usage information"
  echo "-T: Install from preconfigured tar file"
  echo "-B: Install base support packages"
  echo "-F: Install packages manually"
  echo "-f: Specify tar file (otherwise uses default in script)"
  echo "-C: Install OpenCV manually"
  echo "-U: Add user"
  echo "-D: Install Darknet"
  echo "-S: Install Spark"
  echo "-E: Install Hadoop"
  echo "-H: Install HBase"
  echo "-X: Install VMware Tools"
  echo "-K: Install pyenv"
  echo "-O: Install VirtualBox Guest Additions"
  echo "-V: Print version information"
  echo "-Z: Exclude base support package check"
  echo "-Y: Clean up user home directory permissions"
  echo "-u: Set Username"
  echo "-g: Set Usergroup"
  echo "-t: Set temporary directory"
  echo ""
}

if [ "$1" = "" ]; then
  print_usage
  exit
fi

exclude_base=0
do_base=0
do_opencv=0
do_darknet=0
do_user=0
do_tar=0
do_spark=0
do_hadoop=0
do_hbase=0
do_vmtools=0
do_vwtools=0
do_vbtools=0
do_pyenv=0

while getopts BCDSTUFZVhf:u:g: args; do
  case $args in
  Z)
    exclude_base=1
    ;;
  V)
    echo $script_version
    exit
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
    do_base=1
    ;;
  Y)
    clean_up_user_perms
    exit
    ;;
  U)
    do_user=1
    ;;
  C)
    do_base=1
    do_opencv=1
    ;;
  D)
    do_base=1
    do_opencv=1
    do_darknet=1
    ;;
  E)
    do_base=1
    do_hadoop=1
    ;;
  H)
    do_base=1
    do_hbase=1
    ;;
  K)
    do_pyenv=1
    ;;
  S)
    do_base=1
    do_spark=1
    ;;
  X)
    do_base=1
    do_vwtools=1
    ;;
  O)
    do_base=1
    do_vbtools=1
    ;;
  T)
    do_base=1
    do_user=1
    do_tar=1
    ;;
  F)
    do_base=1
    do_user=1
    do_opencv=1
    do_darknet=1
    do_spark=1
    do_hadoop=1
    do_hbase=1
    do_vmtools=1
    do_pyenv=1
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
  do_base=0
fi

if [ "$do_base" = 1 ]; then
  check_base
fi

if [ "$do_user" = 1 ]; then
  add_user $USER_NAME
fi

if [ "$do_opencv" = 1 ]; then
  install_opencv
fi

if [ "$do_darknet" = 1 ]; then
  install_darknet
fi

if [ "$do_spark" = 1 ]; then
  install_spark
fi

if [ "$do_hadoop" = 1 ]; then
  install_hadoop
fi

if [ "$do_hbase" = 1 ]; then
  install_hbase
fi

if [ "$do_vmtools" = 1 ]; then
  install_vm_tools
fi

if [ "$do_vwtools" = 1 ]; then
  install_vmware_tools
fi

if [ "$do_vbtools" = 1 ]; then
  install_vbox_tools
fi

if [ "$do_pyenv" = 1 ]; then
  install_pyenv
fi

if [ "$do_tar" = 1 ]; then
  tar_install $USER_TAR $USER_NAME
  exit
fi

clean_up_user_perms

