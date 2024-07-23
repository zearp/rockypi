# Disk setup
clearpart --initlabel --all
part /boot --asprimary --fstype=vfat --size=300 --label=boot
part swap --asprimary --fstype=swap --size=1024 --label=swap
part / --asprimary --fstype=ext4 --size=2800 --label=RPIROOT

# Repos setup:
url --url https://download.rockylinux.org/pub/rocky/9/BaseOS/aarch64/os/
repo --name="BaseOS" --baseurl=https://download.rockylinux.org/pub/rocky/9/BaseOS/aarch64/os/ --cost=100
repo --name="AppStream" --baseurl=https://download.rockylinux.org/pub/rocky/9/AppStream/aarch64/os/ --cost=200 --install
repo --name="CRB" --baseurl=https://download.rockylinux.org/pub/rocky/9/CRB/aarch64/os/ --cost=300 --install
repo --name="rockyrpi" --baseurl=https://download.rockylinux.org/pub/sig/9/altarch/aarch64/altarch-rockyrpi/ --cost=20
repo --name="rockyextras" --baseurl=https://download.rockylinux.org/pub/rocky/9/extras/aarch64/os/  --cost=20
repo --name="epel" --mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-9&arch=$basearch

# Install process:
keyboard us --xlayouts=us --vckeymap=us
rootpw --lock
timezone --isUtc --nontp UTC
selinux --enforcing
firewall --enabled --port=22:tcp
network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=sshd,NetworkManager,chronyd,cpupower
shutdown
bootloader --location=none
lang en_US.UTF-8
skipx

# Package selection:
%packages
@core
bat
#bc
btop
chrony
cloud-utils-growpart
dnsmasq
epel-release
#eza
#git
glibc-all-langpacks
htop
net-tools
NetworkManager-wifi
bash-completion
#dkms
kernel-tools
langpacks-en
microdnf
mlocate
nano
pciutils
raspberrypi2-kernel4
#raspberrypi2-kernel4-devel
raspberrypi2-firmware
rocky-release-rpi
ripgrep
rsync
speedtest-cli
tar
usbutils
wget
zsh
zsh-autosuggestions
zsh-syntax-highlighting
%end

# Post install scripts:
%post

cat > /etc/modprobe.d/blacklist-rpi.conf << EOF
blacklist brcmfmac
EOF

# Write initial boot line to cmdline.txt (we will update the root partuuid further down)
cat > /boot/cmdline.txt << EOF
console=ttyAMA0,115200 console=tty1 root= rootfstype=ext4 elevator=deadline rootwait net.ifnames=0 biosdevname=0
EOF

# Apparently kickstart user was not working, attempt to do it here?
/sbin/useradd -c "rocky" -G wheel -m -U rocky
echo "rocky" | passwd --stdin rocky

# Cleanup before shipping an image

# Remove ifcfg-link on pre generated images
rm -f /etc/sysconfig/network-scripts/ifcfg-link

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

# Ensure no ssh keys are present
rm -f "/etc/ssh/*_key*"

# Enable CRB
/usr/bin/crb enable

# Clean yum cache
yum clean all

# Fix weird sssd bug, where it gets its folder owned by the unbound user:
chown -R sssd:sssd /var/lib/sss/{db,pipes,mc,pubconf,gpo_cache}

# Setting tuned profile to powersave by default -> sets the CPU governor to "ondemand".  This prevents overheating issues
cat > /etc/sysconfig/cpupower << EOF
# See 'cpupower help' and cpupower(1) for more info
CPUPOWER_START_OPTS="frequency-set -g ondemand"
CPUPOWER_STOP_OPTS="frequency-set -g ondemand"
EOF
systemctl enable cpupower
%end

# Add the PARTUUID of the rootfs partition to the kernel command line
# We must do this *outside* of the chroot, by grabbing the UUID of the loopmounted rootfs
%post --nochroot

# Extract the UUID of the rootfs partition from /etc/fstab
UUID_ROOTFS="$(/bin/cat $INSTALL_ROOT/etc/fstab | \
/bin/awk -F'[ =]' '/\/ / {print $2}')"

# Get the PARTUUID of the rootfs partition
PART_UUID_ROOTFS="$(/sbin/blkid  "$(/sbin/blkid --uuid $UUID_ROOTFS)" | \
/bin/awk '{print $NF}' | /bin/tr -d '"' )"

# Configure the kernel commandline
/bin/sed -i "s/root= /root=${PART_UUID_ROOTFS} /" $INSTALL_ROOT/boot/cmdline.txt
echo "cmdline.txt looks like this, please review:"
/bin/cat $INSTALL_ROOT/boot/cmdline.txt

# Extract UUID of swap partition:
UUID_SWAP=$(/bin/grep 'swap'  $INSTALL_ROOT/etc/fstab  | awk '{print $1}' | awk -F '=' '{print $2}')

# Fix swap partition: ensure page size is 4096 (differs on the aarch64 AWS build host)
/usr/sbin/mkswap -L "_swap" -p 8192  -U "${UUID_SWAP}"  /dev/disk/by-uuid/${UUID_SWAP}

%end

%post
# wireless fix on 3b and zero 2w (image wont boot w/o this fix) 
cd /lib/firmware/brcm
xz -d -k brcmfmac43430-sdio.raspberrypi,3-model-b.txt.xz
%end
