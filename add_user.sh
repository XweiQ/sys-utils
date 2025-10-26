#!/bin/bash
# A simple script to batch add new users and set up Miniconda.

# --- Edit the list of usernames to add here ---
# Separate with spaces, put them inside the parentheses
USERNAMES=("simu1")
# ---

echo "--- Preparing to add ${#USERNAMES[@]} users ---"

# Loop over each username in the list
for USERNAME in "${USERNAMES[@]}"; do
  echo "============================================="
  echo " Processing user: $USERNAME"
  echo "============================================="

  echo "--- 1. Creating user: $USERNAME ---"
  sudo useradd -m -c "$USERNAME" -s /bin/bash -g ds $USERNAME

  echo "--- 2. Setting password for $USERNAME (please enter manually) ---"
  sudo passwd $USERNAME

  echo "--- 3. Setting up Miniconda for $USERNAME ---"
  sudo /usr/local/sbin/setup_new_user_conda.sh $USERNAME

  echo "--- User $USERNAME completed ---"
  echo ""
done

echo "--- Batch add operation completed ---"