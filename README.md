![alt tag](https://raw.githubusercontent.com/lateralblast/spot/master/spot.jpg)

SPOT
====

Scripted Pot (of internet) of Things

Introduction
------------

This script is designed to install the required components for a
Big Data (Teaching and general usage) VM from an existing tar file of
the Big Data user directory (see default USER_NAME, our use -u to set)
with preinstalled packaged, or from scratch by installing required packages

Usage
-----

Get help:

```
$ ./install.sh

Usage ./install.sh -[B|C|D|E|H|X|O|S|T|F|U|Y|K|h] -[f|u|g|t]: -[Z]

-h: Print usage information
-T: Install from preconfigured tar file
-B: Install base support packages
-F: Install packages manually
-f: Specify tar file (otherwise uses default in script)
-C: Install OpenCV manually
-U: Add user
-D: Install Darknet
-S: Install Spark
-E: Install Hadoop
-H: Install HBase
-X: Install VMware Tools
-K: Install pyenv
-Q: Install Scala
-O: Install VirtualBox Guest Additions
-V: Print version information
-Z: Exclude base support package check
-Y: Clean up user home directory permissions
-u: Set Username
-g: Set Usergroup
-t: Set temporary directory
```

Install from default tar file:

```
# ./install.sh -T
```

Install from a specific tar file:

```
# ./install.sh -T -f user.tar.gz
```

Install base packages:

```
# ./install.sh -B
```

Install OpenCV from scratch:

```
# ./install.sh -C
```

Install everything from scratch:

```
# ./install.sh -F
```