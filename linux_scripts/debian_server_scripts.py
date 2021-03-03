# Credits
# https://stackoverflow.com/questions/6004073/how-can-i-create-directories-recursively
# https://www.geeksforgeeks.org/python-os-makedirs-method/

import subprocess
import os


def debian_installer_needed_packages():
    subprocess.call([r'apt-get', r'update'])
    subprocess.call([r'apt-get', r'install', r'-y', r'gdisk',
                     r'binutils', r'debootstrap', r'dosfstools'])


def create_basic_partitions(disk, partition_number1, partition_number2):
    # Creates two partitions.  First one is a 512 MB EFI partition while the second uses the rest of the free space avalailable to create a Linux filesystem partition.
    subprocess.call([r'sgdisk', r'-n', r'0:0:+512MiB', r'-c', partition_number1 +
                     r':EFI System Partition', r'-t', partition_number1 + r':ef00', disk])
    subprocess.call([r'sgdisk', r'-n', r'0:0:0', r'-c', partition_number2 +
                     r':Linux Filesystem', r'-t', partition_number2 + r':8300', disk])


def create_basic_filesystems(partition1, partition2):
    subprocess.call([r'mkfs.fat', r'-F32', partition1])
    subprocess.call([r'mkfs.ext4', partition2])


def mount_basic_filesystems(boot_partition, root_partition):
    subprocess.call([r'mount', root_partition, r'/mnt'])
    os.makedirs(r'/mnt/boot/EFI', exist_ok=True)
    subprocess.call([boot_partition, r'/mnt/boot/EFI'])


def debootstrap_install_base_packages(version):
    subprocess.call([r'debootstrap', r'--arch', r'amd64', r'--components=main,contrib,non-free',
                     version, r'/mnt' r'http://mirrors.advancedhosters.com/debian/'])
