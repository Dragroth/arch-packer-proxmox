#!/usr/bin/env bash

# Stop on ERROR
set -eu

USERNAME="root"
PASSWORD=$1
HOSTNAME=arch

SWAP_SIZE=$2

COUNTRY=$3
TIMEZONE=$4
KEYMAP="us"
LANGUAGE='en_US.UTF-8'




# Check if there is internet connection
ping -q -c 1 archlinux.org >/dev/null || { echo "No Internet Connection!; "exit 1; }

# Set timezone
timedatectl set-timezone $TIMEZONE

echo ">>>> install: Setting pacman ${COUNTRY} mirrors..."
# pacman-key --init
# pacman -Sy pacman-contrib --noconfirm
curl -s "https://archlinux.org/mirrorlist/?${COUNTRY}&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' > /etc/pacman.d/mirrorlist #| rankmirrors -n 5 -


sgdisk -g /dev/sda

/usr/bin/sgdisk --new=1:0:+400M /dev/sda
/usr/bin/sgdisk --typecode=1:ef00 /dev/sda
mkfs.fat -F 32 /dev/sda1

/usr/bin/sgdisk --new=2:0:0 /dev/sda
/usr/bin/sgdisk --typecode=2:8e00 /dev/sda

pvcreate /dev/sda2
vgcreate vg0 /dev/sda2
lvcreate -L 2G -n lv-swap vg0
lvcreate -l 100%FREE -n lv-root vg0

mkswap /dev/vg0/lv-swap
mkfs.ext4 /dev/vg0/lv-root

mount /dev/vg0/lv-root /mnt
mount --mkdir /dev/sda1 /mnt/boot
swapon /dev/vg0/lv-swap

pacstrap -K /mnt base linux linux-firmware

/usr/bin/arch-chroot /mnt pacman -S --noconfirm gptfdisk openssh syslinux networkmanager intel-ucode vim lvm2 cloud-guest-utils cloud-init qemu-guest-agent less

/usr/bin/arch-chroot /mnt bootctl install

# configure mkinitcpio
/usr/bin/arch-chroot /mnt sed -i '/^HOOKS/s/\(block \)\(.*filesystems\)/\1encrypt lvm2 \2/' /etc/mkinitcpio.conf

# generate initramfs for linux and linux-lts
/usr/bin/arch-chroot /mnt mkinitcpio -p linux

/usr/bin/arch-chroot /mnt systemctl enable cloud-init
/usr/bin/arch-chroot /mnt systemctl enable NetworkManager
/usr/bin/arch-chroot /mnt systemctl enable sshd

/usr/bin/arch-chroot /mnt sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

genfstab -U /mnt >> /mnt/etc/fstab

FILE="/mnt/boot/loader/loader.conf"

echo "default arch.conf" > /mnt/boot/loader/loader.conf

FILE="/mnt/boot/loader/entries/arch.conf"
UUID=$(blkid | grep root | cut -d '"' -f 2)

echo "title   Arch Linux" >> "$FILE"
echo "linux   /vmlinuz-linux" >> "$FILE"
echo "initrd  /intel-ucode.img" >> "$FILE"
echo "initrd  /initramfs-linux.img" >> "$FILE"
echo "options root=/dev/vg0/lv-root rw" >> "$FILE"

echo "root:packer" | chpasswd --root /mnt

/sbin/reboot