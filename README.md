# ubuntu-setup

1. Make an unattended install Ubuntu ISO file:

   ```bash
   bash build-iso.sh
   ```

2. Create a VirtualBox virtual machine:

   ```bash
   bash build-vbox.sh
   ```

3. Setting up in Ubuntu:

   ```bash
   bash setup.sh
   Or
   wget -O- https://github.com/duzyn/ubuntu-setup/raw/main/setup.sh | bash
   # Or
   wget -O- https://ghproxy.com/github.com/duzyn/ubuntu-setup/raw/main/setup.sh | bash
   ```

4. You can use environment variables (optional), see example below:

    example:

    ```bash
    DEBUG=true ISO_URL=https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso USERNAME=john PASSWORD=111111 FULL_NAME="John Doe" HOST=xubuntu DOMAIN=xubuntu.guest.virtualbox.org LOCALE=zh_CN TIMEZONE=Asia/Shanghai bash build-iso.sh
    ```

    ```bash
    DEBUG=true SOURCE_ISO=xubuntu-20.04.6-desktop-amd64.iso VBOX_NAME=xubuntu-20.04.6-desktop-amd64 VBOX_OS_TYPE=Ubuntu_64 VBOX_CPU_NUMBER=2 VBOX_MEMORY=2048 VBOX_VRAM=128 VBOX_HDD_SIZE=61440 VBOX_HDD_FORMAT=VDI bash build-vbox.sh
    ```

    ```bash
    DEBUG=true PROXY=true TOKEN=ghp_jGJPqA0E92ysHCU6H6ATuY4FSyVE12aAnLN wget -O- https://github.com/duzyn/ubuntu-setup/raw/main/setup-ubuntu.sh | bash
    ```
