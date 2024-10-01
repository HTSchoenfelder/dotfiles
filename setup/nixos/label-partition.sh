#!/usr/bin/env bash

if [ "$#" -eq 1 ]; then
    label=$1
else
    # Prompt user to type label
    read -p "Enter the label: " label
fi

echo "Label: $label"
read -p "(Press Enter to continue)" enter
echo
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
echo

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
read -p "Enter the number of the partition you want to label $label: " partition_number

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
fs_type=$(lsblk -lno FSTYPE "$selected_partition")

# Label the partition according to its file system
case $fs_type in
  ext[2-4])
    sudo e2label "$selected_partition" $label
    ;;
  btrfs)
    sudo btrfs filesystem label "$selected_partition" $label
    ;;
  xfs)
    sudo xfs_admin -L $label "$selected_partition"
    ;;
  vfat)
    sudo fatlabel "$selected_partition" $label
    ;;
  ntfs)
    sudo ntfslabel "$selected_partition" $label
    ;;
  exfat)
    sudo exfatlabel "$selected_partition" $label
    ;;
  *)
    echo "Unknown or unsupported file system: $fs_type"
    exit 1
    ;;
esac

# Confirm label change
echo "The label of partition $selected_partition has been successfully set to $label"
