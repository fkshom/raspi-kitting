# kitting tools for raspberry pi

## Usage

### Burn and configure
```sh

$ git clone https://github.com/fkshom/raspi_kitting
$ cd raspi_kitting

$ wget https://cdimage.ubuntu.com/releases/20.04.1/release/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
  #=> ref: https://cdimage.ubuntu.com/releases/20.04.1/release/

## Insert your microSD card
$ dmesg
  #=> check your microSD card device name. (/dev/sdc)

$ vim network-config
  #=> if needed
$ vim user-config
  #=> if needed
$ ./burn_anf_configure.sh --img ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz --dev /dev/sdc --ip 192.168.3.10/24"

## Remove microSD card and insert to raspberry pi
```

### prepare your machine as router
```sh
$ sudo apt install python3 python3-pip sshpass
$ pip3 install ansible
$ echo "export PATH=~/.local/bin:$PATH" >> ~/.bashrc
$ source ~/.bashrc

$ cd raspi_kitting/router
$ ansible-playbook -i localhost, -c local router.yml
```

### dist-upgrade and install xubuntu-desktop
```sh
$ cd ../raspi
$ ansible-playbook -i 192.168.3.10, raspi.yml
  #=> Take a long long time. You can take a break.
```


