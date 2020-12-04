#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.

# Part 2 of install script for Debian.

# Source variables
source env_tmp.sh

# Source functions
source debian_server_scripts.sh
source functions.sh

# Call functions
debian_create_boot_directories
debian_create_device_files
create_basic_partition_fstab
mount_all_drives
debian_setup_locale_package
debian_setup_mirrors "${version}"
debian_install_standard_packages "${ucode}"
debian_update_kernel
apt_clear_cache
set_root_password
enable_base_network_connectivity "${interface}"
debian_setup_grub
