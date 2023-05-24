# ubuntu-setup

1. Make an unattended install Ubuntu ISO file:

   ```bash
   bash build.iso
   ```

2. Create a VirtualBox virtual machine:

   ```bash
   bash build.iso
   ```

3. Setting up in Ubuntu:

   ```bash
   wget -O- https://github.com/duzyn/ubuntu-setup/raw/main/setup-ubuntu.sh | bash
   # Or
   wget -O- https://ghproxy.com/github.com/duzyn/ubuntu-setup/raw/main/setup-ubuntu.sh | bash
   ```

4. You can use environment variables (optional), see [config.sh](./config.sh):

    example:

    ```bash
    ISO_URL=https://mirrors.ustc.edu.cn/ubuntu-cdimage/xubuntu/releases/20.04.6/release/xubuntu-20.04.6-desktop-amd64.iso LOCALE=zh_CN TIMEZONE="Asia/Shanghai" bash build-iso.iso

    ```

    ```bash
    USERNAME=john PASSWORD=xxxyyyzzz bash build-iso.iso
    ```

    ```bash
    PROXY=false TOKEN=ghp_jGJPqA0E92ysHCU6H6ATuY4FSyVE12aAnLN bash build-iso.iso wget -O- https://github.com/duzyn/ubuntu-setup/raw/main/setup-ubuntu.sh | bash
    ```
