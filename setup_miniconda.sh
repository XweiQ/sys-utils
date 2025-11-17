#!/bin/bash

# ==============================================================================
# setup_new_user_conda.sh
#
# Purpose: Automatically downloads and installs Miniconda in a new user's
#          home directory.
# Usage:   sudo ./setup_new_user_conda.sh USERNAME
#
# WARNING: This script MUST be run with sudo (as root).
# ==============================================================================

# (1) Check if running as root (sudo)
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: This script must be run using 'sudo'." >&2
  exit 1
fi

# (2) Check if a username was provided
USERNAME=$1
if [ -z "$USERNAME" ]; then
  echo "ERROR: Please provide a username." >&2
  echo "Usage: sudo $0 USERNAME" >&2
  exit 1
fi

# (3) Check if the user exists and has a home directory
USER_HOME=$(eval echo "~$USERNAME")
if ! id "$USERNAME" &>/dev/null; then
  echo "ERROR: User '$USERNAME' does not exist." >&2
  exit 1
fi
if [ ! -d "$USER_HOME" ]; then
  echo "ERROR: Home directory not found for '$USERNAME': $USER_HOME" >&2
  echo "Did you use 'useradd -m' to create the user?" >&2
  exit 1
fi

# --- Configuration ---
MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_DIR="$USER_HOME/miniconda3"
INSTALLER_PATH="$USER_HOME/miniconda_installer.sh"

echo "============================================="
echo "Preparing setup for user:   $USERNAME"
echo "User home directory:      $USER_HOME"
echo "Installing Miniconda to:  $MINICONDA_DIR"
echo "============================================="

# (4) Check if already installed
if [ -d "$MINICONDA_DIR" ]; then
  echo "WARNING: Directory '$MINICONDA_DIR' already exists. Skipping installation."
  exit 0
fi

# (5) CRITICAL STEP: Use 'sudo -u USER' to run all commands
# This ensures all created files are owned by the new user, NOT by root.

echo "1/4: Downloading installer as '$USERNAME'..."
sudo -u "$USERNAME" wget -q $MINICONDA_URL -O "$INSTALLER_PATH"
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to download Miniconda." >&2
  exit 1
fi

echo "2/4: Running silent install as '$USERNAME'..."
# -b: Batch mode (no questions)
# -p: Specify installation prefix (path)
sudo -u "$USERNAME" bash "$INSTALLER_PATH" -b -p "$MINICONDA_DIR"
if [ $? -ne 0 ]; then
  echo "ERROR: Miniconda installation failed." >&2
  exit 1
fi

echo "3/4: Initializing Conda (configuring .bashrc) as '$USERNAME'..."
# Find the conda executable
CONDA_BIN="$MINICONDA_DIR/bin/conda"
if [ ! -f "$CONDA_BIN" ]; then
  echo "ERROR: Could not find conda executable at: $CONDA_BIN" >&2
  exit 1
fi
sudo -u "$USERNAME" -H bash -c "cd $USER_HOME && $CONDA_BIN init bash"

echo "4/4: Cleaning up installer..."
sudo -u "$USERNAME" rm "$INSTALLER_PATH"

echo ""
echo "Success!"
echo "Conda has been installed for '$USERNAME' in '$MINICONDA_DIR'."
echo "Please ask '$USERNAME' to log out completely and log back in for changes to take effect."
