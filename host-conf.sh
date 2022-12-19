#!/usr/bin/env bash

echo "Print UID and GID"
printf "UID=$(id -u)\nGID=$(id -g)\n"
sleep 1

sudo apt update && apt-get update;

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update && apt-get install -y -qq --no-install-suggests --no-install-recommends \
        curl \
        libsecp256k1-dev \
        libssl-dev \
        locales \
        ca-certificates \
        apt-transport-https;

rm -rf /var/lib/apt/lists/*;

locale-gen C.UTF-8 || true
export LANG=C.UTF-8

# Set the mirrors to distro-based ones
cat << EOF > $WORKDIR/etc/apt/sources.list
deb http://deb.debian.org/debian $DIST main
deb http://deb.debian.org/debian $DIST-updates main
deb http://deb.debian.org/debian-security $DIST-security main
EOF

# Do a final upgrade.
rootfs_chroot apt-get -o Acquire::Check-Valid-Until=false update
rootfs_chroot apt-get -y -q upgrade

# Clean some apt artifacts
rootfs_chroot apt-get clean

# Delete dirs we don't need, leaving the entries.
rm -rf "${WORKDIR:?}"/dev "$WORKDIR"/proc
mkdir -p "$WORKDIR"/dev "$WORKDIR"/proc

rm -rf "$WORKDIR"/var/lib/apt/lists/httpredir*
rm -rf "$WORKDIR"/etc/apt/apt.conf.d/01autoremove-kernels

# These are showing up as broken symlinks?
rm -rf "$WORKDIR"/usr/share/vim/vimrc
rm -rf "$WORKDIR"/usr/share/vim/vimrc.tiny

# Remove files with non-determinism
rm -rf "$WORKDIR"/var/cache/man
rm -rf "$WORKDIR"/var/cache/ldconfig/aux-cache
rm -rf "$WORKDIR"/var/log/dpkg.log
rm -rf "$WORKDIR"/var/log/bootstrap.log
rm -rf "$WORKDIR"/var/log/alternatives.log
rm -rf "$WORKDIR"/var/log/apt/history.log
rm -rf "$WORKDIR"/var/log/apt/term.log



## Ensure your SWAP is either turned off or set to 0. Add the required parameter to the sysctl.conf
sysctl -w vm.swappiness=0
sysctl -w vm.zone_reclaim_mode=0
sysctl -w  vm.max_map_count=262144


# this fixes QUIC for Linux
# net.core.rmem_max = 26214400
sysctl -w net.core.rmem_max=26214400
sysctl -w net.core.rmem_default=26214400
sysctl -w vm.swappiness=0
sysctl -w vm.zone_reclaim_mode=0

sudo sh -c 'echo "* hard nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "* soft nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root hard nofile 100000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root soft nofile 100000" >> /etc/security/limits.conf'
sleep 1


##############################################
#### CONFIGURE NETWORK TIMING ################
sudo apt update && apt-get --assume-yes install ntp 


###############################################
## [NOTE]. google uses a 'leap smear', stick to 
#           the normal ntp pools!
#
#     see <https://www.ntppool.org/zone/us>
#
#     	   server 0.us.pool.ntp.org
#     	   server 1.us.pool.ntp.org
#     	   server 2.us.pool.ntp.org
#     	   server 3.us.pool.ntp.org
#

sudo sed -i '/^server/d' /etc/ntp.conf
sudo tee -a /etc/ntp.conf << EOF
server time1.google.com iburst
server time2.google.com iburst
server time3.google.com iburst
server time4.google.com iburst
EOF
sleep 1

sudo systemctl restart ntp &> /dev/null || true
sudo systemctl restart ntpd &> /dev/null || true
sudo service ntp restart &> /dev/null || true
sudo service ntpd restart &> /dev/null || true
sudo restart ntp &> /dev/null || true
sudo restart ntpd &> /dev/null || true
ntpq -p

sudo sh -c 'echo "* hard nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "* soft nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root hard nofile 64000" >> /etc/security/limits.conf'
sudo sh -c 'echo "root soft nofile 64000" >> /etc/security/limits.conf'
sleep 1


## [NOTE]. 
# Intel Nehalem chips can be subject to sporadic pauses in certain circumstances 
#   The issue is related to aggressive power-saving optimizations introduced in Intel chips. 
#   Your system may freeze for periods as small as 1/10 of a second and as much as 30 seconds.
#
#   see <https://gpsd.io/gpsd-time-service-howto.html#_power_saving_is_not_your_friend>
#
#GRUB_CMDLINE_LINUX="intel_idle.max_cstate=0"
#nohz=off intel_idle.max_cstate=0
#sed -i s/GRUB_CMDLINE_LINUX=" "/GRUB_CMDLINE_LINUX="intel_idle.max_cstate=0"/g /etc/default/grub 
#sudo update-grub
##############################################
## Commented out b/c this will reboot your system and may no be rel. to your chipset!
## 
## ISC License
## 2022 - The Contributors
