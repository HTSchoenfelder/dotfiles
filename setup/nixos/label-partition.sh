#!/bin/bash

# List all partitions and store them in an array
partitions=($(lsblk -lnpo NAME,TYPE | grep part | awk '{print $1}'))

# Check if there are any partitions found
if [ ${#partitions[@]} -eq 0 ]; then
  echo "No partitions found."
  exit 1
fi

# Display partitions with numbers
echo "Available partitions:"
for i in "${!partitions[@]}"; do
  echo "$((i+1)). ${partitions[i]}"
done

# Prompt user to choose a partition
read -p "Enter the number of the partition you want to label 'nixos': " partition_number

# Check if the input is a valid number
if ! [[ "$partition_number" =~ ^[0-9]+$ ]] || [ "$partition_number" -lt 1 ] || [ "$partition_number" -gt "${#partitions[@]}" ]; then
  echo "Invalid input. Please enter a valid number."
  exit 1
fi

# Get the selected partition
selected_partition="${partitions[$((partition_number-1))]}"

# Display selected partition
echo "Selected partition: $selected_partition"

# Get the file system type of the selected partition
fs_type=$(blkid -s TYPE -o value "$selected_partition")

# Label the partition according to its file system
case $fs_type in
  ext[2-4])
    sudo e2label "$selected_partition" nixos
    ;;
  btrfs)
    sudo btrfs filesystem label "$selected_partition" nixos
    ;;
  xfs)
    sudo xfs_admin -L nixos "$selected_partition"
    ;;
  vfat)
    sudo fatlabel "$selected_partition" nixos
    ;;
  ntfs)
    sudo ntfslabel "$selected_partition" nixos
    ;;
  exfat)
    sudo exfatlabel "$selected_partition" nixos
    ;;
  *)
    echo "Unknown or unsupported file system: $fs_type"
    exit 1
    ;;
esac

# Confirm label change
echo "The label of partition $selected_partition has been successfully set to 'nixos'."
