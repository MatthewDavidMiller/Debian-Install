#!/bin/bash

# Copyright (c) Matthew David Miller. All rights reserved.
# Licensed under the MIT License.
# Needs to be run as root.
# Install script for a debian server. Use with Debian standard live installer. Run the script when in the live installer.

# Get needed scripts
wget -O 'debian_server_scripts.sh' 'https://raw.githubusercontent.com/MatthewDavidMiller/Debian-Install/stable/linux_scripts/debian_server_scripts.sh'
wget -O 'functions.sh' 'https://raw.githubusercontent.com/MatthewDavidMiller/Bash-Common-Functions/main/functions/functions.sh'

# Source variables
cp 'env.sh' 'env_tmp.sh'
source env.sh

# Source functions
source debian_server_scripts.sh
source functions.sh

# Call functions
list_partitions
specify_debian_version "${specify_version}"
debian_installer_needed_packages

if [[ "${delete_partitions_response}" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    delete_all_partitions_on_a_disk "${disk}"
fi

get_ucode_type "${ucode_response}"
create_basic_partitions "${disk}" "${partition_number1}" "${partition_number2}"
create_basic_filesystems "${partition1}" "${partition2}"
mount_basic_filesystems "${partition1}" "${partition2}"
debootstrap_install_base_packages "${version}"
mount_proc_and_sysfs
get_base_partition_uuids "${partition1}" "${partition2}"
get_interface_name
printf '%s\n' "${interface}" >>'env_tmp.sh'
debian_install_move_to_script_part_2
