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

```bash
wget -qO- https://github.com/duzyn/ubuntu-setup/raw/main/build-iso.sh | DEBUG="false" ISO_URL="https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso" USERNAME="john" PASSWORD="111111" FULL_NAME="John Doe" HOST="xubuntu" DOMAIN="xubuntu.guest.virtualbox.org" LOCALE="zh_CN" TIMEZONE="Asia/Shanghai" bash
```

```bash
wget -qO- https://github.com/duzyn/ubuntu-setup/raw/main/build-vbox.sh | DEBUG="false" ISO_URL="https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso" VBOX_NAME="xubuntu-20.04.6-desktop-amd64" VBOX_OS_TYPE="Ubuntu_64" VBOX_CPU_NUMBER="2" VBOX_MEMORY="2048" VBOX_VRAM="128" VBOX_HDD_SIZE="61440" VBOX_HDD_FORMAT="VDI" bash
```

```bash
wget -qO- https://github.com/duzyn/ubuntu-setup/raw/main/setup-ubuntu.sh | DEBUG="false" VTOYBOOT="false" LOCALE="zh_CN" APT_MIRROR="mirrors.ustc.edu.cn" NPM_REGISTRY_MIRROR="https://registry.npmmirror.com" bash
```
