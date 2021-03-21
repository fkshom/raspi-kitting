# kitting tools for raspberry pi

raspberry pi キッティングスクリプト

## Usage

### Burn and configure

raspberry piのSDカードイメージを入手します。

```sh
$ cd /home/user/raspi_kitting

$ wget https://cdimage.ubuntu.com/releases/20.04.1/release/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
  #=> ref: https://cdimage.ubuntu.com/releases/20.04.1/release/
```
microSDカードを作業用端末に挿入し、デバイスパスを確認します。
```
$ dmesg
  #=> check your microSD card device name. (/dev/sdc)
```
初期設定用ファイルを編集します。編集方法は別項記載。
```
$ vim network-config
$ vim user-config
```
microSDカードに、OSイメージと初期設定を書き込みます。
```
$ ./burn_anf_configure.sh --img ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz --dev /dev/sdc --ip 192.168.3.10/24"
```
microSDカードを抜去し、rasberry piに挿入し、raspberry piの電源をONにします。

cloud-initの設定で2回ほど自動再起動します。5分ほどかかります。

raspiの有線（固定IP）経由で接続するのであればそのIPアドレスにSSHできることを確認します。

```
ssh 192.168.3.10
user: user
pass: ubuntu
```

raspiの無線（DHCP）経由で接続するのであれば、同じwifiに接続している作業用端末でnmapを実行してIPアドレスを特定してからSSHできることを確認します。

```
$ ip a #=> wifiのIPセグメントを調べる
$ sudo nmap -sP 192.168.2.0/24  | grep -b 2 Raspberry
Nmap scan repot for 192.168.2.100
Host is up
MAC Address: B8:27:EB:xx:xx:xx (Raspberry Pi Foundation)

$ ssh 192.168.2.100
user: user
pass: ubuntu
```

## run ansible playbook

SSHできることを確認したら、作業用端末からplaybookを流します。
このplaybookでは、dist-upgradeの実行、xubuntu-desktopと各種パッケージのインストールを行っています。

```sh
$ cd /home/user/raspi_kitting/raspi
$ ansible-playbook -i 192.168.3.10, raspi.yml
  #=> Take a long long time. You can take a break.
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


