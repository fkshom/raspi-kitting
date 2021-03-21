# kitting tools for raspberry pi

raspberry pi キッティングスクリプト

## Usage

キッティングに当たり、raspiの有線LANを使うかWifiを使うかを決めます。

有線LANを推奨します。

**有線LANの場合**
- メリット
  - SSID情報が残らない
  - 複数台のセットアップを行う場合は、proxyを経由させることでaptパッケージのダウンロードが早くなる
  - IPアドレスが固定なので、わかりやすい
- デメリット
  - 有線LANの環境整備と、作業用端末の構築を行っておく必要がある（dnsmasq, squidのインストール。ただしplaybookを用意済み）

**Wifiの場合**
- メリット
  - 作業用端末の事前構築は不要（ansibleのみあればよい）
- デメリット
  - SSID情報を後で消す必要がある
  - aptサーバーが遅いので、パッケージダウンロードに時間がかかる
  - DHCPでIPを取得するので、nmapなどでIPアドレスを探索する必要がある
  - 物理ホストとraspiが同じWifiセグメントに所属していないと作業がやりにくい

### 作業用端末の構築（キッティングに有線LANを使う場合）

仮想マシンを作成し、作業用端末兼ルーターとして次の設定を行います。

- Ubuntu 18.04 or Ubuntu 20.04
- ストレージ：30GB程度（squidキャッシュ用）
- 2つのNICを作成
  - ens33: インターネット接続用。NATインタフェース使用。
  - ens37: raspiとの有線LAN接続用。物理ホストの有線LANにブリッジ。
    - IPアドレス：192.168.3.1/24
    - デフォルトゲートウェイ：なし

次に、ansibleをインストールします。
```
$ sudo apt install python3 python3-pip sshpass
$ pip3 install ansible
$ echo "export PATH=~/.local/bin:$PATH" >> ~/.bashrc
$ source ~/.bashrc
```

playbookを利用して、作業用端末をルーター化し、dnsmasq(DHCPサーバ、DNSサーバ)とsquidをインストールします。
```
$ cd /home/user/raspi-kitting/router
$ ansible-playbook -i localhost, -c local router.yml
```

設定状況が正しいかを確認します。

```
$ systemctl status dhsmasq
  #=> Activeであること
$ systemctl status squid
  #=> Activeであること
$ iptables -nvL
$ iptables -nvL -t nat
  #=> PREROUTINGチェインに、透過プロキシ用設定が入っていること
    #=> ens37で受信したdstport:80のパケットは、squid(port:3128)にリダイレクトする。
  #=> POSTROUTINGチェインにMASQUERADE設定が入っていること
    #=> ens37で受信したdstport:80以外のパケットは、NATしてインターネットに流す
```

### 作業用端末の構築（キッティングにWifiを使う場合）

仮想マシンを作成し、作業用端末として次の設定を行います。

- Ubuntu 18.04 or Ubuntu 20.04
- ストレージ：適当
- 1つのNICを作成
  - ens33: インターネット接続用。仮想ネットワークエディタを使って、ブリッジネットワークとして物理ホストのWifiを選択しておきます。これでraspiが使うWifiと同じセグメントに所属させることができます。

次に、ansibleをインストールします。
```
$ sudo apt install python3 python3-pip sshpass
$ pip3 install ansible
$ echo "export PATH=~/.local/bin:$PATH" >> ~/.bashrc
$ source ~/.bashrc
```

### SDカードイメージの準備、cloud-init初期設定ファイルの準備とイメージの書き込み

作業用端末で実施します。
raspberry piのSDカードイメージを入手します。

```sh
$ cd /home/user/raspi-kitting

$ wget https://cdimage.ubuntu.com/releases/20.04.1/release/ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz
  #=> ref: https://cdimage.ubuntu.com/releases/20.04.1/release/
```
microSDカードを作業用端末に挿入し、デバイスパスを確認します。
```
$ dmesg | grep sd  #=> sdb, sdcなど
```
初期設定用ファイルを編集します。編集方法は別項記載。
```
$ vim network-config
$ vim user-config
```
microSDカードに、OSイメージと初期設定を書き込みます。
```
$ sudo ./burn_and_configure.sh --img ubuntu-20.04.1-preinstalled-server-arm64+raspi.img.xz --dev /dev/sdc --ip 192.168.3.10/24"

# --img IMG: イメージファイル名
# --dev DEV: SDカードのデバイスファイルパス
# --ip  IP : raspiの有線LANに設定する固定IPアドレス。network-configファイルのIPADDR部分がこのIPアドレスに置換されます
```
書き込みが完了したら自動でアンマウントされます。
そのままmicroSDカードを抜去し、rasberry piに挿入し、raspberry piの電源をONにします。

cloud-initの設定で2回ほど自動再起動します。キーボード設定のためにinitrd再作成が必要なため、5～10分ほどかかります。

raspiの有線LAN（固定IP）経由で接続するのであればそのIPアドレスにSSHできることを確認します。

```
ssh user@192.168.3.10
pass: ubuntu
```

raspiのWifi（DHCP）経由で接続するのであれば、同じwifiに接続している作業用端末でnmapを実行してIPアドレスを特定してからSSHできることを確認します。

```
$ ip a #=> wifiのIPセグメントを調べる
$ sudo nmap -sP 192.168.2.0/24  | grep -b 2 Raspberry
Nmap scan repot for 192.168.2.100
Host is up
MAC Address: B8:27:EB:xx:xx:xx (Raspberry Pi Foundation)

$ ssh user@192.168.2.100
pass: ubuntu
```

## run ansible playbook

SSHできることを確認したら、作業用端末からplaybookを流します。
このplaybookでは、dist-upgradeの実行、xubuntu-desktopのインストールと、adb,scrcpyパッケージのインストールを行っています。

```sh
$ cd /home/user/raspi-kitting/raspi

# 単体ホストをキッティングする場合
## raspiの有線LANを使う場合
$ ansible-playbook -i 192.168.3.10, raspi.yml -u user -e hostname=raspi1 -e default_route=192.168.3.1

## raspiのWifiを使う場合
$ ansible-playbook -i 192.168.2.100, raspi.yml -u user -e hostname=raspi1

# 複数ホストを同時にキッティングする場合
$ vim inventory
$ vim group_vars/raspi/main.yml
```

ここからは、2時間程度かかります。
進捗状況が気になる場合は、別のターミナルを開き、SSHを使ってterm.logファイルの内容を確認します。
```
$ ssh -l user 192.168.2.10 tail -F /var/log/apt/term.log

# -F: ファイルのinodeが変更されたら再読み込みする
```
