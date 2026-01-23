# This script is meant to be sourced.
# It's not for directly running.

function prepare_systemd_user_service(){
  if [[ ! -e "/usr/lib/systemd/user/ydotool.service" ]]; then
    x sudo ln -s /usr/lib/systemd/{system,user}/ydotool.service
  fi
}

function setup_user_group(){
  if [[ -z $(getent group i2c) ]] && [[ "$OS_GROUP_ID" != "fedora" ]]; then
    # On Fedora this is not needed. Tested with desktop computer with NVIDIA video card.
    x sudo groupadd i2c
  fi

  if [[ "$OS_GROUP_ID" == "fedora" ]]; then
    x sudo usermod -aG video,input "$(whoami)"
  else
    x sudo usermod -aG video,i2c,input "$(whoami)"
  fi
}

function setup_sddm(){
  # Set up SDDM with Sugar Candy theme
  local sddm_conf="/etc/sddm.conf.d/theme.conf"
  local sugar_candy_dir="/usr/share/sddm/themes/sugar-candy"
  local polkit_rules_dir="/etc/polkit-1/rules.d"
  
  # Check if Sugar Candy theme is installed
  if [[ -d "$sugar_candy_dir" ]]; then
    printf "${STY_CYAN}[$0]: Setting up SDDM with Sugar Candy theme...${STY_RST}\n"
    
    # Create SDDM config directory if it doesn't exist (non-fatal if fails)
    sudo mkdir -p /etc/sddm.conf.d 2>/dev/null || true
    
    # Configure SDDM to use Sugar Candy theme
    x sudo bash -c "cat > $sddm_conf << 'EOF'
[Theme]
Current=sugar-candy
EOF"
    
    # Create Backgrounds directory in the theme (non-fatal - might already exist with different perms)
    sudo mkdir -p "$sugar_candy_dir/Backgrounds" 2>/dev/null || {
      # If mkdir fails, try to ensure directory exists anyway
      if [[ ! -d "$sugar_candy_dir/Backgrounds" ]]; then
        printf "${STY_YELLOW}[$0]: Warning: Could not create Backgrounds directory.${STY_RST}\n"
        printf "${STY_YELLOW}[$0]: You may need to create it manually: sudo mkdir -p $sugar_candy_dir/Backgrounds${STY_RST}\n"
      else
        printf "${STY_CYAN}[$0]: Backgrounds directory already exists.${STY_RST}\n"
      fi
    }
    printf "${STY_CYAN}[$0]: Polkit rule installation skipped (deprecated). Using sudoers-based install instead.${STY_RST}\n"

    # Install sddm-theme-helper into /usr/local/bin so it can be run via sudo safely
    if [[ -f "${REPO_ROOT}/dots/.config/quickshell/ii/scripts/colors/sddm/sddm-theme-helper" ]]; then
      x sudo install -m 0755 "${REPO_ROOT}/dots/.config/quickshell/ii/scripts/colors/sddm/sddm-theme-helper" /usr/local/bin/sddm-theme-helper
      printf "${STY_GREEN}[$0]: Installed sddm-theme-helper to /usr/local/bin${STY_RST}\n"
    fi

    # Install sudoers snippet for passwordless sudo of the helper
    if [[ -f "${REPO_ROOT}/dots-extra/sddm/99-sddm-theme-helper.sudoers" ]]; then
      x sudo cp -f "${REPO_ROOT}/dots-extra/sddm/99-sddm-theme-helper.sudoers" /etc/sudoers.d/99-sddm-theme-helper
      x sudo chmod 0440 /etc/sudoers.d/99-sddm-theme-helper
      printf "${STY_GREEN}[$0]: Sudoers entry installed for sddm-theme-helper.${STY_RST}\n"
    fi
    
    # Enable SDDM service
    if [[ ! -z $(systemctl --version) ]]; then
      # Use || true to not fail if already enabled or if another DM is enabled
      sudo systemctl enable sddm 2>/dev/null || {
        printf "${STY_YELLOW}[$0]: Could not enable SDDM (might already be enabled or another DM is in use).${STY_RST}\n"
      }
      printf "${STY_GREEN}[$0]: SDDM setup complete. It will be active on next boot.${STY_RST}\n"
    fi
  else
    printf "${STY_YELLOW}[$0]: Sugar Candy theme not found. Skipping SDDM theme setup.${STY_RST}\n"
    printf "${STY_YELLOW}[$0]: You can install it manually (Arch: yay -S sddm-sugar-candy-git)${STY_RST}\n"
  fi
}
#####################################################################################
# These python packages are installed using uv into the venv (virtual environment). Once the folder of the venv gets deleted, they are all gone cleanly. So it's considered as setups, not dependencies.
showfun install-python-packages
v install-python-packages

showfun setup_user_group
v setup_user_group

if [[ ! -z $(systemctl --version) ]]; then
  # For Fedora, uinput is required for the virtual keyboard to function, and udev rules enable input group users to utilize it.
  if [[ "$OS_GROUP_ID" == "fedora" ]]; then
    v bash -c "echo uinput | sudo tee /etc/modules-load.d/uinput.conf"
    v bash -c 'echo SUBSYSTEM==\"misc\", KERNEL==\"uinput\", MODE=\"0660\", GROUP=\"input\" | sudo tee /etc/udev/rules.d/99-uinput.rules'
  else
    v bash -c "echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf"
  fi
  # TODO: find a proper way for enable Nix installed ydotool. When running `systemctl --user enable ydotool, it errors "Failed to enable unit: Unit ydotool.service does not exist".
  if [[ ! "${INSTALL_VIA_NIX}" == true ]]; then
    if [[ "$OS_GROUP_ID" == "fedora" ]]; then
      v prepare_systemd_user_service
    fi
    # When $DBUS_SESSION_BUS_ADDRESS and $XDG_RUNTIME_DIR are empty, it commonly means that the current user has been logged in with `su - user` or `ssh user@hostname`. In such case `systemctl --user enable <service>` is not usable. It should be `sudo systemctl --machine=$(whoami)@.host --user enable <service>` instead.
    if [[ ! -z "${DBUS_SESSION_BUS_ADDRESS}" ]]; then
      v systemctl --user enable ydotool --now
    else
      v sudo systemctl --machine=$(whoami)@.host --user enable ydotool --now
    fi
  fi
  v sudo systemctl enable bluetooth --now
elif [[ ! -z $(openrc --version) ]]; then
  v bash -c "echo 'modules=i2c-dev' | sudo tee -a /etc/conf.d/modules"
  v sudo rc-update add modules boot
  v sudo rc-update add ydotool default
  v sudo rc-update add bluetooth default

  x sudo rc-service ydotool start
  x sudo rc-service bluetooth start
else
  printf "${STY_RED}"
  printf "====================INIT SYSTEM NOT FOUND====================\n"
  printf "${STY_RST}"
  pause
fi

if [[ "$OS_GROUP_ID" == "gentoo" ]]; then
  v sudo chown -R $(whoami):$(whoami) ~/.local/
fi

v gsettings set org.gnome.desktop.interface font-name 'Google Sans Flex Medium 11 @opsz=11,wght=500'
v gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
v kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly

# Setup SDDM display manager with Sugar Candy theme
showfun setup_sddm
v setup_sddm
