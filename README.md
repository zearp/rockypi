# RockyPi
Rocky Linux for Raspberry Pi

Aim of this repo is to host my own kickstart and an image to use on my Pi's. Forked from the [official](https://git.resf.org/sig_altarch/RockyRpi) Rocky repo and modified to my liking. Kickstarts make it very easy to adjust the packages. It is great and really speaks for itself when you edit the kickstart file.

## Build your own image:
Quick and easy steps to make your own image. note an image only be built on an existing arm64 EL installation, like Rocky or Fedora.
```
sudo dnf -y install epel-release git && sudo dnf -y install appliance-tools
git clone https://github.com/zearp/rockypi && cd rockypi && chmod 755 make_image.sh
sudo ./make_image.sh /home/$USER/rockypi/ && sudo mv RockyPi/RockyPi-sda.raw rockypi.img && sudo chown $USER:$USER rockypi.img && ll rockypi.img
```
Login and password for the sudo enabled default user is ```rocky/rocky``` unless you changed it in the kickstart file.

## Post install:
- Change shell to zsh:
  ```sudo usermod --shell /usr/bin/zsh $USER```
- Expand root filesystem:
  ```sudo rootfs-expand```
- Fix wireless by removing the rpi module blacklist:
  ```sudo rm /etc/modprobe.d/blacklist-rpi.conf```
- Run wifi fix if applicable (zero2 needs it):
  ```sudo fix-wifi-rpi.sh```
- Update the system:
  ```sudo dnf --refresh -y update```
- Reboot to apply changes, not strickly needed unless there was a kernel update. Reloading the blacklisted module (```sudo modprobe brcmfmac```) should work getting wireless back.

## My ```/boot/config.txt``` tweaks:
```
arm_boost=1
disable_overscan=1
dtparam=audio=off
gpu=16
framebuffer_height=720
framebuffer_width=1280
```
Optional ones like setting the usb boot bit and disabling onboard wifi/bt.
```
program_usb_boot_mode=1
dtoverlay=disable-wifi
dtoverlay=disable-bt
```

## Extras
```
sudo rpm -i https://kojipkgs.fedoraproject.org//packages/rust-eza/0.19.3/1.el9/aarch64/eza-0.19.3-1.el9.aarch64.rpm
sudo rpm -i https://kojipkgs.fedoraproject.org/packages/wavemon/0.9.4/4.fc38/aarch64/wavemon-0.9.4-4.fc38.aarch64.rpm
sudo rm /etc/skel/.zshrc
sudo wget -q -nc -4 --no-check-certificate https://raw.githubusercontent.com/zearp/pumice/main/assets/dot_zshrc -O /etc/skel/.zshrc
```
