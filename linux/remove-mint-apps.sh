#!/bin/bash
#
# Script to remove default applications from Linux Mint
# Usage: ./remove-mint-apps.sh
#

set -e

# Define all applications in a single array of "package_name|display_name|package_type" entries
# Package type can be: apt, snap, flatpak, wildcard
declare -a MINT_APPS=(
  "hexchat|HexChat IRC client|apt"
  "thunderbird|Thunderbird email client|apt"
  "rhythmbox|Rhythmbox music player|apt"
  "pix|Pix image viewer/organizer|apt"
  "hypnotix|Hypnotix IPTV client|apt"
  "celluloid|Celluloid video player|apt"
  "drawing|Drawing application|apt"
  "libreoffice-*|LibreOffice suite|wildcard"
  "transmission-gtk|Transmission torrent client|apt"
  "warpinator|Warpinator file sharing tool|apt"
  "timeshift|Timeshift backup tool|apt"
  "gnome-calendar|GNOME Calendar|apt"
  "mintchat|Mint Chat (Matrix client)|apt"
)

# Function to display available default applications
show_defaults() {
  echo "Common default applications in Linux Mint:"

  local i=1
  for app in "${MINT_APPS[@]}"; do
    IFS="|" read -r package display type <<< "$app"
    echo "$i. $display ($package, $type)"
    ((i++))
  done
}

# Function to remove a specific application
remove_app() {
  local app=$1
  local name=$2
  local type=$3

  echo "Removing $name..."

  case $type in
    apt)
      sudo apt purge -y "$app"
      ;;
    snap)
      sudo snap remove "$app"
      ;;
    flatpak)
      sudo flatpak uninstall -y "$app"
      ;;
    wildcard)
      if [ "$app" = "libreoffice-*" ]; then
        sudo apt purge -y libreoffice-*
      else
        sudo apt purge -y "$app"
      fi
      ;;
    *)
      echo "Unknown package type: $type"
      return 1
      ;;
  esac

  echo "$name removed successfully."
  echo ""
}

# Function to list all packages for selection
list_packages_for_selection() {
  local selected_packages=$1

  local i=1
  for app in "${MINT_APPS[@]}"; do
    IFS="|" read -r package display type <<< "$app"

    # Check if this package is selected
    if [[ "$selected_packages" == *"$package|"* ]]; then
      echo "$i. [X] $display ($type)"
    else
      echo "$i. [ ] $display ($type)"
    fi

    ((i++))
  done
}

# Check if required package managers are installed
check_package_managers() {
  # Check for apt (should be present on all Mint systems)
  if ! command -v apt &> /dev/null; then
    echo "Error: apt package manager not found. This script requires apt."
    exit 1
  fi

  # Check for snap
  if ! command -v snap &> /dev/null; then
    echo "Warning: snap package manager not found. Installing snap..."
    sudo apt update
    sudo apt install -y snapd
  fi

  # Check for flatpak
  if ! command -v flatpak &> /dev/null; then
    echo "Warning: flatpak package manager not found. Installing flatpak..."
    sudo apt update
    sudo apt install -y flatpak
  fi
}

# Main script
echo "===== Linux Mint Default Application Remover ====="
echo "This script will help you remove default applications from Linux Mint."
echo ""

# Check for required package managers
check_package_managers

# Show available applications
show_defaults
echo ""

echo "How would you like to proceed?"
echo "1. Remove specific applications"
echo "2. Interactive menu"
echo "3. Remove all default applications"
read -p "Enter your choice (1/2/3): " choice

case $choice in
  1)
    # Get applications to remove
    read -p "Enter the numbers of applications to remove (separated by space): " selections

    for selection in $selections; do
      if [[ "$selection" =~ ^[0-9]+$ && "$selection" -ge 1 && "$selection" -le "${#MINT_APPS[@]}" ]]; then
        # Get the package info for this index (array is 0-based, but menu is 1-based)
        app="${MINT_APPS[$selection-1]}"
        IFS="|" read -r package display type <<< "$app"
        remove_app "$package" "$display" "$type"
      else
        echo "Invalid selection: $selection"
      fi
    done
    ;;

  2)
    # Interactive menu
    selected_packages=""

    while true; do
      clear
      echo "===== Select applications to remove ====="
      list_packages_for_selection "$selected_packages"
      echo ""
      echo "Commands:"
      echo "  Enter a number to toggle selection"
      echo "  Type 'a' to select all applications"
      echo "  Type 'n' to deselect all applications"
      echo "  Type 'r' to remove selected applications"
      echo "  Type 'q' to quit without making changes"
      echo ""
      read -p "> " selection

      if [[ "$selection" =~ ^[0-9]+$ && "$selection" -ge 1 && "$selection" -le "${#MINT_APPS[@]}" ]]; then
        # Toggle selection
        app="${MINT_APPS[$selection-1]}"
        IFS="|" read -r package display type <<< "$app"

        if [[ "$selected_packages" == *"$package|"* ]]; then
          # Remove from selection
          selected_packages=${selected_packages/"$package|"/}
        else
          # Add to selection
          selected_packages="$selected_packages$package|"
        fi
      elif [ "$selection" == "a" ]; then
        # Select all applications
        selected_packages=""
        for app in "${MINT_APPS[@]}"; do
          IFS="|" read -r package display type <<< "$app"
          selected_packages="$selected_packages$package|"
        done
      elif [ "$selection" == "n" ]; then
        # Deselect all applications
        selected_packages=""
      elif [ "$selection" == "r" ]; then
        # Remove selected applications
        if [ -z "$selected_packages" ]; then
          echo "No applications selected."
          sleep 1
          continue
        fi

        echo "The following applications will be removed:"
        for app in "${MINT_APPS[@]}"; do
          IFS="|" read -r package display type <<< "$app"
          if [[ "$selected_packages" == *"$package|"* ]]; then
            echo "  - $display ($type)"
          fi
        done

        read -p "Are you sure you want to continue? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
          for app in "${MINT_APPS[@]}"; do
            IFS="|" read -r package display type <<< "$app"
            if [[ "$selected_packages" == *"$package|"* ]]; then
              remove_app "$package" "$display" "$type"
            fi
          done
          break
        fi
      elif [ "$selection" == "q" ]; then
        echo "Exiting without removing applications."
        exit 0
      else
        echo "Invalid selection. Please try again."
        sleep 1
      fi
    done
    ;;

  3)
    # Remove all applications
    echo "Removing all default applications..."
    echo "This will remove all applications listed above."
    read -p "Are you sure you want to continue? (y/n): " confirm

    if [ "$confirm" = "y" ]; then
      for app in "${MINT_APPS[@]}"; do
        IFS="|" read -r package display type <<< "$app"
        remove_app "$package" "$display" "$type"
      done
    else
      echo "Operation cancelled."
      exit 0
    fi
    ;;

  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

# Clean up
echo "Cleaning up..."
sudo apt autoremove -y
sudo apt autoclean

echo "All selected applications have been removed successfully."
