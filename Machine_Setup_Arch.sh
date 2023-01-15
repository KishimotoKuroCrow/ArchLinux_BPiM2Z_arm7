#!/bin/bash

#===================
#===================
# PERSONALIZATION
#===================
# User Account
USERNAME=bpim2z
PASSWORD=monkey

# Root Password
ROOTPWD=bananazero

# SSH port
SSHPORT=16500

# Wifi Connection
ESSID_NAME=MyWifiName
WIFI_PWD=MyWifiPassword
#===================
#===================

HOSTNAME=$1
WIFI_INTF=wlan0
STARTSCR=/root/startup.sh
SHUTSCR=/root/shutdown.sh

# Initialize the pacman keys
pacman-key --init
pacman-key --populate archlinuxarm

# Update Arch Linux system
sed -i 's/#Color/Color/g' /etc/pacman.conf
pacman -Syyu --noconfirm

# Set device hostname
echo $HOSTNAME > /etc/hostname

# Set locale
sed -i 's/#en_US/en_US/g' /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Set localtime
ln -sf /usr/share/zoneinfo/US/Central /etc/localtime
hwclock --systohc

# Setup the hosts file
cat > /etc/hosts <<EOL
127.0.0.1 localhost
127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME} pi.hole

::1       ip6-localhost ip6-loopback
EOL
sync

# This is commented out because I ended up not able to login
## Do not clear TTY
#sed -i 's/TTYVTDisallocate=yes/TTYVTDisallocate=no/g' /etc/systemd/system/getty.target.wants/getty\@tty1.service

# Change Root Password
echo root:${ROOTPWD} | chpasswd

# Install packages from a list (to avoid updating this script)
pacman -S --noconfirm --needed - < /root/pkglist.txt
sync

# Set wheel in sudoers (installed from pkglist)
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers

# Setup Wireless Connection
cat > /etc/netctl/wireless_profile <<EOL
Description="Start Wireless Profile"
Interface=${WIFI_INTF}
Connection=wireless
Security=wpa
IP=dhcp
IP6=stateless
ESSID=${ESSID_NAME}
Key=${WIFI_PWD}
EOL

echo '#!/bin/bash' > $STARTSCR
echo 'rfkill block bluetooth; sleep 1' >> $STARTSCR
echo 'netctl start wireless_profile; sleep 5'>> $STARTSCR

echo '#!/bin/bash' > $SHUTSCR
echo 'netctl stop wireless_profile; sleep 5'>> $SHUTSCR

# Remove default user "alarm"
userdel -r alarm

# Add User
useradd -m -G wheel -s /bin/bash -p $(echo ${PASSWORD} | openssl passwd -1 -stdin) $USERNAME

# Create the SSH key and set the ports and permissions
ssh-keygen -A
mkdir -p /home/$USERNAME/.ssh
cat /etc/ssh/ssh_host_rsa_key.pub > /home/$USERNAME/.ssh/authorized_keys
cp /etc/ssh/ssh_host_rsa_key /boot
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/*
chown -R $USERNAME /home/$USERNAME/.ssh

sed -i "s/#Port 22/Port ${SSHPORT}/g" /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords/PermitEmptyPasswords/g' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#X11Forwarding/X11Forwarding/g' /etc/ssh/sshd_config
echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config
echo 'systemctl start sshd.service; sleep 1' >> $STARTSCR
echo 'systemctl stop sshd.service; sleep 1' >> $SHUTSCR

# Set startup and shutdown scripts as executable
chmod +x $STARTSCR
chmod +x $SHUTSCR

# Enable a startup service
cat > /etc/systemd/system/startup.service <<EOL
[Unit]
Description="Startup Service"

[Service]
ExecStart=$STARTSCR

[Install]
WantedBy=multi-user.target
EOL
systemctl enable startup.service

# Enable a shutdown service
cat > /etc/systemd/system/shutdown.service <<EOL
[Unit]
Description="Shutdown Service"

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/true
ExecStop=$SHUTSCR

[Install]
WantedBy=multi-user.target
EOL
systemctl enable shutdown.service

#
# PERSONALIZE ROOT 
#=========================
cd /root/
./root_pref.sh $USERNAME

#
# PERSONALIZE New User
#=========================
cp /root/user_pref.sh /home/$USERNAME/
chown $USERNAME:$USERNAME /home/$USERNAME/user_pref.sh
cd /home/$USERNAME
su $USERNAME ./user_pref.sh $USERNAME ${WIFI_INTF}

# Quit
exit

