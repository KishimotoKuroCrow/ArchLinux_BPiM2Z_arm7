# Script to install Arch Linux Arm to BananaPi M2 Zero
## BananaPi M2 Zero board, Quick Specs
* Quad-core 1.296GHz, ARMv7 (Cortex-A7)
* 512MB DDR3 SDRAM
* WiFi (very short range unless antenna is connected)
* Bluetooth
* Micro USB for power
* Micro USB OTG
* Mini HDMI (provided converter doesn't work, use direct cable)
* More info: [BPi M2 Zero Wiki](https://wiki.banana-pi.org/Banana_Pi_BPI-M2_Zero)

## Table of Contents
* [Pre-Requisites](#prerequisites)
* [Setup](#setup)
* [Installation](#installation)
* [Quick Explanation](#explanation)
* [Encountered Problems](#problems)
* [References](#references)

<a name="prerequisites"></a>
## Pre-requisites (guide written in January 2023)
* Arch Linux HOST (my script uses arch-chroot)
* Install the following list of packages from official repository
```
$ sudo pacman -S parted \
                 wget \
                 arm-none-eabi-gcc \
                 arm-none-eabi-binutils \
                 qemu-user-static-binfmt \
                 qemu-user-static
```
* Restart systemd-binfmt.service
```
$ sudo systemctl restart systemd-binfmt.service
```

<a name="setup"></a>
## Setup
1) Change the hostname to the one you want in **_SDCard\_Setup\_Arch\_BPiM2Zero\_Armv7.sh_**
```
HOSTNAME=ALA_BPiM2Z
```
2) Change the personalization parameters in **_Machine\_Setup\_Arch.sh_**
```
USERNAME=bpim2z         # Username of the new account
PASSWORD=monkey         # Password of the new account
ROOTPWD=bananazero      # Root Password
SSHPORT=16500           # New SSH port instead of the default 22
ESSID_NAME=MyWifiName   # Wifi hotspot to connect to
WIFI_PWD=MyWifiPassword # Plain text Wifi password
```
3) Edit the list of packages you want to pre-installed in your setup
   in **_pkglist.txt_**

4) Personalize your configuration for root and local user in **_root\_pref.sh_** and **_user\_pref.sh_**
   respectively.

<a name="installation"></a>
## Installation
Insert your MicroSD card into your machine and determine the disk full partition
```
$ sudo fdisk -l
```
Mine would be sdd, sde, or sdf.  Determine yours and run the script as follows
and wait for it to finish. No need to put "sde1" or "sde2", just "sde" will be fine.
It'll take a while to complete.
```
$ sudo ./SDCard_Setup_ArchBPiM2Zero_Arm7.sh sde
```
At the end of a successful installation, you'll end up with the file "Hostname\_key" in the /_SHARE_ directory. This is used to connect
to your board by SSH.  On your host, you'll need to put that file in **~/.ssh/**. Then, insert the MicroSD card in
your BananaPi and boot it (close to your wifi hotspot if you don't have an antenna). Next, find out
the IP address that's assigned to your board and then create the file **~/.ssh/config** on your host as follows (Linux or Windows).
```
Host MyBananaPi INSERT_IP_ADDR_HERE
Hostname INSERT_IP_ADDR_HERE
IdentityFile ~/.ssh/BPiM2Z_key
user bpim2z # same as above
```
Then, connect to your board remotely using the SSH port number.
```
$ ssh -p 16500 MyBananaPi
```
SSH login by username and password is also possible, but highly discouraged.

<a name="explanation"></a>
## Quick Explanation
###### SDCard\_Setup\_ArchBPiM2Zero\_Arm7.sh
* Creates the necessary partitions, a _SHARE_ FAT32 partition is used to share files between platforms.
* Download the latest Arch Linux ARMv7 image (if not already done)
* Create mount points, extract the image above, copy scripts, chroot for configuration, generate boot scripts
* Create the U-Boot binary file (if not already done) and burn it.

###### Machine\_Setup\_Arch.sh
* Called by **_SDCard\_Setup\_ArchBPiM2Zero\_Arm7.sh_**
* Initialize the Arch Linux system
* Set locale and localtime
* Delete default user "alarm" and create a new user account
* Setup networking and remote connection (SSH using key file)
* Setup scripts for faster boot and reboot/shutdown scripts

###### root\_pref.sh
* Called by **_Machine\_Setup\_Arch.sh_**
* Setup root preferences

###### user\_pref.sh
* Called by **_Machine\_Setup\_Arch.sh_**
* Setup additional user preferences

<a name="problems"></a>
## Encountered Problems
1) No HDMI display no matter what image I burn:
> The provided Mini HDMI to full HDMI converter did not work. I had to get a 
direct cable to get it to work.

2) When compiling on the board, it sometimes kicks me back to login screen:
> The board only has 512MB of memory, you'll need to create a swapfile.
When you're done, delete that swapfile because it's not good to keep it 
in a MicroSD card.
```   
# Create swapfile
$ sudo dd if=/dev/zero of=/swapfile bs=1M count=1024 status=progress
$ sudo chmod 0600 /swapfile
$ sudo mkswap -U clear /swapfile
$ sudo swapon /swapfile
$ sync

# Delete swapfile
$ sudo swapoff /swapfile
$ sudo rm -f /swapfile
```
3) I can't install and configure everything during arch-chroot:
> Not everything can be done during arch-chroot, you'll need to log into the board 
(physically or remotely) and run the commands. To make it easier, I recommend
generate the scripts while in arch-chroot so that once logged in, you can 
simply run the scripts in the designated folders or have them run on 
first boot.

<a name="references"></a>
## References
https://unix.stackexchange.com/questions/501626/create-bootable-sd-card-with-parted \
https://bbs.archlinux.org/viewtopic.php?id=204252 \
https://itsfoss.com/install-arch-raspberry-pi/ \
https://github.com/sosyco/bananapim2zero/blob/master/docs/installation_english.md
