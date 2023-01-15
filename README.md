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

## Setup
1) Change the hostname to the one you want in _SDCard\_Setup\_Arch\_BPiM2Zero\_Armv7.sh_
```
HOSTNAME=
```
2) Change the personalization parameters in _Machine\_Setup\_Arch.sh_
```
USERNAME=
PASSWORD=
ROOTPWD=
SSHPORT=
ESSID_NAME=
WIFI_PWD=
```
3) Edit the list to add or remove packages you want to pre-installed in your setup
   in pkglist.txt

4) Personalize your configuration for root and local user in _root\_pref.sh and user\_pref.sh_
   respectively.

## Installation:
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
## Explanation:

## Encountered problems:
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
