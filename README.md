# ubuntu-setup

## Make an unattended install Ubuntu ISO file

```bash
bash build-iso.sh
```

## Create a VirtualBox virtual machine

```bash
bash build-vbox.sh
```

## Setting up in Ubuntu

```bash
bash setup.sh
```

## Advance

You can use environment variables (optional), see examples below using default argument:

Add following line in your ~/.bashrc:

```bash
export DEBUG="true"
export ISO_URL="https://mirrors.ustc.edu.cn/linuxmint-cd/stable/21.1/linuxmint-21.1-xfce-64bit.iso"
export ISO_FILE="$(basename "$ISO_URL")"
export ISO_DIST_DIR="dist"
export ISO_USERNAME="john"
export ISO_PASSWORD="P123456"
export ISO_FULL_NAME="John Doe"
export ISO_HOST="linuxmint"
export ISO_DOMAIN="myguest.virtualbox.org"
export ISO_LOCALE="zh_CN"
export ISO_TIMEZONE="Asia/Shanghai"
export VBOX_NAME="${ISO_FILE%.*}"
export VBOX_OS_TYPE=Ubuntu_64
export VBOX_CPU_NUMBER=2
export VBOX_MEMORY=2048
export VBOX_VRAM=128
export VBOX_HDD_SIZE=61440
export VBOX_HDD_FORMAT=VDI
```

## One-liner

```bash
wget --show-progress -qO- https://github.com/duzyn/ubuntu-setup/raw/main/build-iso.sh | DEBUG="false" ISO_URL="https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso" USERNAME="john" PASSWORD="111111" FULL_NAME="John Doe" HOST="xubuntu" DOMAIN="guest.virtualbox.org" LOCALE="zh_CN" TIMEZONE="Asia/Shanghai" bash
```

```bash
wget --show-progress -qO- https://github.com/duzyn/ubuntu-setup/raw/main/build-vbox.sh | DEBUG="false" ISO_URL="https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso" VBOX_NAME="xubuntu-20.04.6-desktop-amd64" VBOX_OS_TYPE="Ubuntu_64" VBOX_CPU_NUMBER="2" VBOX_MEMORY="2048" VBOX_VRAM="128" VBOX_HDD_SIZE="61440" VBOX_HDD_FORMAT="VDI" bash
```
