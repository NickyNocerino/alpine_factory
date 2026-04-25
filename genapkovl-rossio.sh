#!/bin/sh -e

HOSTNAME="$1"
if [ -z "$HOSTNAME" ]; then
	echo "usage: $0 hostname"
	exit 1
fi

cleanup() {
	rm -rf "$tmp"
}

makefile() {
	OWNER="$1"
	PERMS="$2"
	FILENAME="$3"
	cat > "$FILENAME"
	chown "$OWNER" "$FILENAME"
	chmod "$PERMS" "$FILENAME"
}

rc_add() {
	mkdir -p "$tmp"/etc/runlevels/"$2"
	ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"
}

tmp="$(mktemp -d)"
trap cleanup EXIT

mkdir -p "$tmp"/etc
makefile root:root 0644 "$tmp"/etc/hostname <<EOF
$HOSTNAME
EOF

mkdir -p "$tmp"/etc/factory
mkdir -p "$tmp"/etc/local.d
cp /home/rossio/factory/mkimg.rossio.sh "$tmp"/etc/factory
cp /home/rossio/factory/genapkovl-rossio.sh "$tmp"/etc/factory
cp /home/rossio/factory/build.sh "$tmp"/etc/factory

makefile root:root 0755 "$tmp"/etc/factory/pull_from_github.sh <<"EOF"
#!/bin/sh

git clone --depth=1 https://gitlab.alpinelinux.org/alpine/aports.git

git clone https://github.com/NickyNocerino/alpine_factory.git
EOF


makefile root:root 0755 "$tmp"/etc/factory/install.sh <<"EOF"
#!/bin/sh

#Set up firstboot script
cp /etc/factory/firstboot.sh /etc/local.d/firstboot.start

#Set the install complete flag and rm the auto_install.start
touch /etc/install_complete
rm /etc/local.d/auto_install.start

setup-keymap us us
setup-timezone -z UTC
setup-sshd -c openssh
setup-ntp -c chrony
setup-disk -m sys /dev/nvme0n1
poweroff
EOF

makefile root:root 0755 "$tmp"/etc/factory/firstboot.sh <<"EOF"
#!/bin/sh -x

[ ! -f /etc/install_complete ] && exit 0
[ -f /etc/firstboot_complete ] && exit 0

# do firstboot stuff

#Set up root and primary user
echo "root:change_me!;" | chpasswd
adduser -D -s /bin/ash rossio
echo "rossio:change_me!" | chpasswd

#Set up the factory for further bootstrapping
mkdir -p /home/rossio/factory
chmod 777 /home/rossio/factory
cp /etc/factory/* /home/rossio/factory
mkdir /home/rossio/factory/iso
chmod 777 /home/rossio/factory/iso
mkdir /home/rossio/factory/temp
chmod 777 /home/rossio/factory/temp


#Set up every boot for later boots and remove first boot
cp /etc/factory/everyboot.sh /etc/local.d/everyboot.start
touch /etc/firstboot_complete
rm -f /etc/local.d/firstboot.start
EOF

makefile root:root 0755 "$tmp"/etc/factory/everyboot.sh <<"EOF"
#!/bin/sh

[ ! -f /etc/install_complete ] && exit 0
[ ! -f /etc/firstboot_complete ] && exit 0

# do every boot stuff
apk update
cpupower frequency-set -g performance


touch /etc/everyboot_complete
EOF


makefile root:root 0755 "$tmp"/etc/local.d/auto_install.start <<EOF
#!/bin/sh

[ -f /etc/install_complete ] && exit 0

#for true automated install, uncomment this
#sh /etc/factory/install.sh

EOF

makefile root:root 0644 "$tmp"/etc/motd <<EOF
Abandon Hope, All Ye Who Enter Here
EOF

makefile root:root 0644 "$tmp"/etc/issue <<'EOF'
***************************************************************************
            ._                                            ,
             (`)..                                    ,.-')
              (',.)-..                            ,.-(..`)         
               (,.' ,.)-..                    ,.-(. `.. )                    
                (,.' ..' .)-..            ,.-( `.. `.. )                     
                 (,.' ,.'  ..')-.     ,.-( `. `.. `.. )                      
                  (,.'  ,.' ,.'  )-.-('   `. `.. `.. )                       
                   ( ,.' ,.'    _== ==_     `.. `.. )                        
                    ( ,.'   _==' ~  ~  `==_    `.. )                     
                     \  _=='   ----..----  `==_   )                     
                  ,.-:    ,----___.  .___----.    -..                        
              ,.-'   (   _--====_  \/  _====--_   )  `-..                 
          ,.-'   .__.'`.  `-_I0_-'    `-_0I_-'  .'`.__.  `-..     
      ,.-'.'   .'      (          |  |          )      `.   `.-..  
  ,.-'    :    `___--- '`.__.    / __ \    .__.' `---___'    :   `-..      
-'_________`-____________'__ \  (O)  (O)  / __`____________-'________`-     
                            \ . _  __  _ . /                               
                             \ `V-'  `-V' |                                 
                              | \ \ | /  /                                 
                               V \ ~| ~/V                                   
                                |  \  /|                                    
                                 \~ | V                                 
                                  \  |                                        
                                   VV

************************* ROSSIO'S ALPINE *****************************
EOF

mkdir -p "$tmp"/etc/network
makefile root:root 0644 "$tmp"/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

EOF

mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/repositories <<EOF
https://dl-cdn.alpinelinux.org/alpine/v3.23/main
https://dl-cdn.alpinelinux.org/alpine/v3.23/community
EOF


mkdir -p "$tmp"/etc/apk
makefile root:root 0644 "$tmp"/etc/apk/world <<EOF
alpine-base
sfdisk
dosfstools
e2fsprogs
grub-efi
git
openssh
abuild
alpine-conf
syslinux
xorriso
squashfs-tools
grub
mtools
bash
nano
cpupower
python3
py3-pip
rustup
EOF

rc_add devfs sysinit
rc_add dmesg sysinit
rc_add mdev sysinit
rc_add hwdrivers sysinit
rc_add modloop sysinit

rc_add hwclock boot
rc_add modules boot
rc_add sysctl boot
rc_add hostname boot
rc_add bootmisc boot
rc_add syslog boot
rc_add networking boot

rc_add mount-ro shutdown
rc_add killprocs shutdown
rc_add savecache shutdown

rc_add local default


tar -c -C "$tmp" etc | gzip -9n > $HOSTNAME.apkovl.tar.gz
