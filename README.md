![alt tag](https://raw.githubusercontent.com/lateralblast/pot/master/pot.jpg)

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

```
$ ./install.sh -h

Usage ./install.sh -[B|C|T|U|F|h] -[f|u|g|t]: -[Z]

-h: Print usage information
-T: Install from preconfigured tar file
-B: Install base support packages
-F: Install packages manually
-f: Specify tar file (otherwise uses default in script)
-C: Install OpenCV manually
-U: Add user
-Z: Exclude base support package check
-u: Set Username
-g: Set Usergroup
-t: Set temporary directory
```
