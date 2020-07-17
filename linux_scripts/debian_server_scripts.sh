#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.
# Needs to be run as root.
# Install scripts for debian server. Use with Debian standard live installer. Run the script when in the live installer.

function list_partitions() {
    lsblk -f
}

function specify_debian_version() {
    # Parameters
    local specify_version=${1}

    # Specify version
    if [[ "${specify_version}" =~ ^([1])+$ ]]; then
        version='stretch'
    fi

    # Specify version
    if [[ "${specify_version}" =~ ^([2])+$ ]]; then
        version='buster'
    fi
}

function debian_installer_needed_packages() {
    apt-get update
    apt-get install -y gdisk binutils debootstrap dosfstools
}

function delete_all_partitions_on_a_disk() {
    # Parameters
    local disk=${1}

    local response
    read -r -p "Are you sure you want to delete everything on ${disk}? [y/N] " response
    if [[ "${response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        # Deletes all partitions on disk
        sgdisk -Z "${disk}"
        sgdisk -og "${disk}"
    fi
}

function get_ucode_type() {
    # Parameters
    local ucode_response=${1}

    if [[ "${ucode_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
        ucode='intel-microcode'
    else
        ucode='amd-microcode'
    fi
}

function create_basic_partitions() {
    # Parameters
    disk=${1}
    partition_number1=${2}
    partition_number2=${3}

    # Creates two partitions.  First one is a 512 MB EFI partition while the second uses the rest of the free space avalailable to create a Linux filesystem partition.
    sgdisk -n 0:0:+512MiB -c "${partition_number1}":"EFI System Partition" -t "${partition_number1}":ef00 "${disk}"
    sgdisk -n 0:0:0 -c "${partition_number2}":"Linux Filesystem" -t "${partition_number2}":8300 "${disk}"
}

function create_basic_filesystems() {
    # Parameters
    local partition1=${1}
    local partition2=${2}

    mkfs.fat -F32 "${partition1}"
    mkfs.ext4 "${partition2}"
}

function mount_basic_filesystems() {
    # Parameters
    local boot_partition=${1}
    local root_partition=${2}

    mount "${root_partition}" /mnt
    mkdir -p '/mnt/boot/EFI'
    mount "${boot_partition}" '/mnt/boot/EFI'
}

function debootstrap_install_base_packages() {
    # Parameters
    local version=${1}

    debootstrap --arch amd64 --components=main,contrib,non-free ${version} /mnt 'http://mirrors.advancedhosters.com/debian/'
}

function mount_proc_and_sysfs() {
    {
        printf '%s\n' 'proc /mnt/proc proc defaults 0 0'
        printf '%s\n' 'sysfs /mnt/sys sysfs defaults 0 0'
    } >>'/etc/fstab'
    mount proc /mnt/proc -t proc
    mount sysfs /mnt/sys -t sysfs
}

function get_base_partition_uuids() {
    # Parameters
    local partition1=${1}
    local partition2=${2}

    uuid="$(blkid -o value -s UUID "${partition1}")"
    uuid2="$(blkid -o value -s UUID "${partition2}")"
}

function get_interface_name() {
    interface="$(ip route get 8.8.8.8 | sed -nr 's/.*dev ([^\ ]+).*/\1/p')"
    echo "Interface name is ${interface}"
}

function debian_install_move_to_script_part_2() {
    cp debian_server_scripts.sh '/mnt/debian_server_scripts.sh'
    wget -O '/mnt/debian_server_install_part_2.sh' 'https://raw.githubusercontent.com/MatthewDavidMiller/Debian-Install/stable/linux_scripts/debian_server_install_part_2.sh'
    chmod +x '/mnt/debian_server_install_part_2.sh'
    cat <<EOF >'/mnt/temp_variables.sh'
disk="${disk}"
partition_number1="${partition_number1}"
partition_number2="${partition_number2}"
device_hostname="${device_hostname}"
user_name="${user_name}"
partition1="${partition1}"
partition2="${partition2}"
version="${version}"
ucode="${ucode}"
interface="${interface}"
uuid="${uuid}"
uuid2="${uuid2}"
EOF
    LANG=C.UTF-8 chroot /mnt "./debian_server_install_part_2.sh"
}

function debian_create_boot_directories() {
    mkdir -p '/boot/EFI/debian'
}

function debian_create_device_files() {
    apt-get install -y makedev
    cd /dev || exit
    MAKEDEV generic
    cd / || exit
}

function create_basic_partition_fstab() {
    grep -q -E ".*UUID=${uuid} \/boot\/EFI" '/etc/fstab' && sed -i -E "s,.*UUID=${uuid} \/boot\/EFI.*,UUID=${uuid} \/boot\/EFI vfat defaults 0 0," '/etc/fstab' || printf '%s\n' "UUID=${uuid} /boot/EFI vfat defaults 0 0" >>'/etc/fstab'
    grep -q -E ".*\/swapfile" '/etc/fstab' && sed -i -E "s,.*\/swapfile.*,\/swapfile none swap defaults 0 0," '/etc/fstab' || printf '%s\n' "/swapfile none swap defaults 0 0" >>'/etc/fstab'
    grep -q -E ".*UUID=${uuid2} \/" '/etc/fstab' && sed -i -E "s,.*UUID=${uuid2} \/.*,UUID=${uuid2} \/ ext4 defaults 0 0," '/etc/fstab' || printf '%s\n' "UUID=${uuid2} / ext4 defaults 0 0" >>'/etc/fstab'
}

function create_swap_file() {
    # Parameters
    local swap_file_size=${1}

    # Create swapfile
    dd if=/dev/zero of=/swapfile bs=1M count="${swap_file_size}" status=progress
    # Set file permissions
    chmod 600 /swapfile
    # Format file to swap
    mkswap /swapfile
    # Activate the swap file
    swapon /swapfile
}

function mount_all_drives() {
    mount -a
}

function set_timezone() {
    ln -sf '/usr/share/zoneinfo/America/New_York' '/etc/localtime'
}

function debian_setup_locale_package() {
    # Install locale package
    apt-get install -y locales

    # Setup locales
    update-locale "LANG=en_US.UTF-8"
    dpkg-reconfigure --frontend noninteractive locales
}

function set_language() {
    grep -q -E ".*LANG=" '/etc/locale.conf' && sed -i -E "s,.*LANG=.*,LANG=en_US\.UTF-8," '/etc/locale.conf' || printf '%s\n' 'LANG=en_US.UTF-8' >>'/etc/locale.conf'
}

function set_hostname() {
    # Parameters
    local device_hostname=${1}

    rm -f '/etc/hostname'
    printf '%s\n' "${device_hostname}" >>'/etc/hostname'
}

function setup_hosts_file() {
    # Parameters
    local device_hostname=${1}

    grep -q -E ".*127\.0\.0\.1 localhost" '/etc/hosts' && sed -i -E "s,.*127\.0\.0\.1 localhost.*,127\.0\.0\.1 localhost," '/etc/hosts' || printf '%s\n' '127.0.0.1 localhost' >>'/etc/hosts'
    grep -q -E ".*::1 localhost" '/etc/hosts' && sed -i -E "s,.*::1.*,::1 localhost," '/etc/hosts' || printf '%s\n' '::1 localhost' >>'/etc/hosts'
    grep -q -E ".*127\.0\.0\.1 ${device_hostname}\.localdomain ${device_hostname}" '/etc/hosts' && sed -i -E "s,.*127\.0\.0\.1 ${device_hostname}.*,127\.0\.0\.1 ${device_hostname}\.localdomain ${device_hostname}," '/etc/hosts' || printf '%s\n' "127.0.0.1 ${device_hostname}.localdomain ${device_hostname}" >>'/etc/hosts'
}

function debian_setup_mirrors() {
    # Parameters
    local version=${1}

    grep -q -E ".*deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version} main contrib non-free" '/etc/apt/sources.list' && sed -i -E "s,.*deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version} main.*,deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version} main contrib non-free," '/etc/apt/sources.list' || printf '%s\n' "deb https://mirrors.wikimedia.org/debian/ ${version} main contrib non-free" >>'/etc/apt/sources.list'
    grep -q -E ".*deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version} main contrib non-free" '/etc/apt/sources.list' && sed -i -E "s,.*deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version} main.*,deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version} main contrib non-free," '/etc/apt/sources.list' || printf '%s\n' "deb-src https://mirrors.wikimedia.org/debian/ ${version} main contrib non-free" >>'/etc/apt/sources.list'
    grep -q -E ".*deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}-updates main contrib non-free" '/etc/apt/sources.list' && sed -i -E "s,.*deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}-updates main.*,deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}-updates main contrib non-free," '/etc/apt/sources.list' || printf '%s\n' "deb https://mirrors.wikimedia.org/debian/ ${version}-updates main contrib non-free" >>'/etc/apt/sources.list'
    grep -q -E ".*deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}-updates main contrib non-free" '/etc/apt/sources.list' && sed -i -E "s,.*deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}-updates main.*,deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}-updates main contrib non-free," '/etc/apt/sources.list' || printf '%s\n' "deb-src https://mirrors.wikimedia.org/debian/ ${version}-updates main contrib non-free" >>'/etc/apt/sources.list'
    grep -q -E ".*deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}/updates main contrib non-free" '/etc/apt/sources.list' && sed -i -E "s,.*deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}/updates main.*,deb https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}/updates main contrib non-free," '/etc/apt/sources.list' || printf '%s\n' "deb https://mirrors.wikimedia.org/debian/ ${version}/updates main contrib non-free" >>'/etc/apt/sources.list'
    grep -q -E ".*deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}/updates main contrib non-free" '/etc/apt/sources.list' && sed -i -E "s,.*deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}/updates main.*,deb-src https:\/\/mirrors\.wikimedia\.org\/debian\/ ${version}/updates main contrib non-free," '/etc/apt/sources.list' || printf '%s\n' "deb-src https://mirrors.wikimedia.org/debian/ ${version}/updates main contrib non-free" >>'/etc/apt/sources.list'
}

function debian_install_standard_packages() {
    # Parameters
    local ucode=${1}

    tasksel install standard
    apt-get install -y systemd linux-image-amd64 ${ucode} efibootmgr grub-efi initramfs-tools sudo apt-transport-https
}

function debian_update_kernel() {
    update-initramfs -u
}

function apt_clear_cache() {
    apt-get clean
}

function set_root_password() {
    echo 'Set root password'
    passwd root
}

function enable_base_network_connectivity() {
    # Parameters
    local interface=${1}

    grep -q -E ".*auto lo" '/etc/network/interfaces' && sed -i -E "s,.*auto lo.*,auto lo," '/etc/network/interfaces' || printf '%s\n' "auto lo" >>'/etc/network/interfaces'
    grep -q -E ".*iface lo inet loopback" '/etc/network/interfaces' && sed -i -E "s,.*iface lo.*,iface lo inet loopback," '/etc/network/interfaces' || printf '%s\n' "iface lo inet loopback" >>'/etc/network/interfaces'
    grep -q -E ".*auto ${interface}" '/etc/network/interfaces' && sed -i -E "s,.*auto ${interface}.*,auto ${interface}," '/etc/network/interfaces' || printf '%s\n' "auto ${interface}" >>'/etc/network/interfaces'
    grep -q -E ".*iface ${interface}" '/etc/network/interfaces' && sed -i -E "s,.*iface ${interface}.*,iface ${interface} inet dhcp," '/etc/network/interfaces' || printf '%s\n' "iface ${interface} inet dhcp" >>'/etc/network/interfaces'
}

function debian_setup_grub() {
    rm -f '/etc/default/grub'

    grep -q -E ".*GRUB_DEFAULT=" '/etc/default/grub' && sed -i -E "s,.*GRUB_DEFAULT=.*,GRUB_DEFAULT=0," '/etc/default/grub' || printf '%s\n' "GRUB_DEFAULT=0" >>'/etc/default/grub'
    grep -q -E ".*GRUB_TIMEOUT=" '/etc/default/grub' && sed -i -E "s,.*GRUB_TIMEOUT=.*,GRUB_TIMEOUT=0," '/etc/default/grub' || printf '%s\n' "GRUB_TIMEOUT=0" >>'/etc/default/grub'

    grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=debian
    update-grub
}

function create_user() {
    # Parameters
    local user_name=${1}

    useradd -m "${user_name}"
    echo "Set the password for ${user_name}"
    passwd "${user_name}"
    mkdir -p "/home/${user_name}"
    chown "${user_name}" "/home/${user_name}"
}

function add_user_to_sudo() {
    # Parameters
    local user_name=${1}

    grep -q -E ".*${user_name}" '/etc/sudoers' && sed -i -E "s,.*${user_name}.*,${user_name} ALL=\(ALL\) ALL," '/etc/sudoers' || printf '%s\n' "${user_name} ALL=(ALL) ALL" >>'/etc/sudoers'
}

function set_shell_bash() {
    # Parameters
    local user_name=${1}

    chsh -s /bin/bash
    chsh -s /bin/bash "${user_name}"
}
