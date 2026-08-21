# This script is meant to be sourced.
# It's not for directly running.

install-yay(){
  x sudo pacman -S --needed --noconfirm base-devel
  x git clone https://aur.archlinux.org/yay-bin.git /tmp/buildyay
  x cd /tmp/buildyay
  x makepkg -o
  x makepkg -se
  x makepkg -i --noconfirm
  x cd ${REPO_ROOT}
  rm -rf /tmp/buildyay
}

remove_deprecated_dependencies(){
  printf "${STY_CYAN}[$0]: Removing deprecated dependencies:${STY_RST}\n"
  local list=()
  list+=(illogical-impulse-{microtex,pymyc-aur,oneui4-icons-git})
  list+=(hyprland-qtutils)
  list+=({quickshell,hyprutils,hyprpicker,hyprlang,hypridle,hyprland-qt-support,hyprland-qtutils,hyprlock,xdg-desktop-portal-hyprland,hyprcursor,hyprwayland-scanner,hyprland}-git)
  list+=(matugen-bin)
  for i in "${list[@]}"; do
    if pacman -Q "$i" &>/dev/null; then
      try sudo pacman --noconfirm -Rdd "$i"
    fi
  done
}

implicitize_old_dependencies(){
  remove_bashcomments_emptylines ./sdata/dist-arch/previous_dependencies.conf ./cache/old_deps_stripped.conf
  readarray -t old_deps_list < ./cache/old_deps_stripped.conf
  pacman -Qeq > ./cache/pacman_explicit_packages
  readarray -t explicitly_installed < ./cache/pacman_explicit_packages

  echo "Attempting to set previously explicitly installed deps as implicit..."
  for i in "${explicitly_installed[@]}"; do for j in "${old_deps_list[@]}"; do
    [ "$i" = "$j" ] && yay -D --asdeps "$i"
  done; done

  return 0
}

if ! command -v pacman >/dev/null 2>&1; then
  printf "${STY_RED}[$0]: pacman not found, it seems that the system is not ArchLinux or Arch-based distros. Aborting...${STY_RST}\n"
  exit 1
fi

if [[ -z "${PACMAN_AUTH:-}" ]]; then
  export PACMAN_AUTH="sudo"
fi

showfun remove_deprecated_dependencies
v remove_deprecated_dependencies

case $SKIP_SYSUPDATE in
  true) true;;
  *) v sudo pacman -Syu;;
esac

repair_pipewire_stack(){
  local packages=(pipewire pipewire-audio pipewire-alsa pipewire-pulse libpipewire gst-plugin-pipewire)
  local package installed candidate
  local needs_repair=false

  [[ "$OS_DISTRO_ID" == "cachyos" ]] || return 0
  command -v vercmp &>/dev/null || return 0
  for package in "${packages[@]}"; do
    installed=$(pacman -Q "$package" 2>/dev/null | awk '{print $2}') || continue
    candidate=$(pacman -Si "$package" 2>/dev/null | awk -F': ' '/^Version/ {print $2; exit}')
    if [[ -n "$installed" && -n "$candidate" ]] && (( $(vercmp "$installed" "$candidate") > 0 )); then
      needs_repair=true
      break
    fi
  done

  if $needs_repair; then
    local pacman_flags=(--needed)
    [[ "$ask" == false ]] && pacman_flags+=(--noconfirm)
    printf "${STY_YELLOW}[$0]: Synchronizing the PipeWire stack with the configured repositories (CachyOS package revision mismatch).${STY_RST}\n"
    x sudo pacman -Syyuu "${pacman_flags[@]}" "${packages[@]}"
  fi
}

if [[ "$SKIP_SYSUPDATE" != true ]]; then
  showfun repair_pipewire_stack
  v repair_pipewire_stack
fi

if ! command -v yay >/dev/null 2>&1;then
  echo -e "${STY_YELLOW}[$0]: \"yay\" not found.${STY_RST}"
  showfun install-yay
  v install-yay
fi

showfun implicitize_old_dependencies
v implicitize_old_dependencies

install-local-pkgbuild() {
  local location=$1
  local installflags=$2

  x pushd $location

  source ./PKGBUILD

  local conflict installed_conflict
  for conflict in "${conflicts[@]-}"; do
    [[ -n "$conflict" ]] || continue
    installed_conflict="$(pacman -Qq "$conflict" 2>/dev/null)"
    if [[ -n "$installed_conflict" ]]; then
      printf "${STY_YELLOW}[$0]: Removing conflicting package $installed_conflict before installing $pkgname.${STY_RST}\n"
      x sudo pacman -R --noconfirm "$installed_conflict"
    fi
  done

  local dependencies=("${depends[@]}" "${makedepends[@]}")
  local missing=()
  local dependency
  for dependency in "${dependencies[@]}"; do
    if ! pacman -T "$dependency" &>/dev/null; then
      missing+=("$dependency")
    fi
  done
  if ((${#missing[@]})); then
    x yay -S --sudoloop $installflags --asdeps "${missing[@]}"
  fi

  x makepkg -Afi --noconfirm
  x popd
}

source ./sdata/dist-arch/metapkgs.sh

metapkgs=()
for name in "${ARCH_METAPKG_NAMES[@]}"; do
  metapkgs+=("./sdata/dist-arch/$name")
done

for i in "${metapkgs[@]}"; do
  metainstallflags="--needed"
  $ask && showfun install-local-pkgbuild || metainstallflags="$metainstallflags --noconfirm"
  v install-local-pkgbuild "$i" "$metainstallflags"
done

install-dinit-service-packages(){
  local -a pkgs=()
  local pkg

  if ! command -v dinitctl >/dev/null 2>&1; then
    return 0
  fi

  for pkg in userspawn-dinit bluez-dinit networkmanager-dinit pipewire-dinit pipewire-pulse-dinit wireplumber-dinit power-profiles-daemon-dinit; do
    if pacman -Si "$pkg" >/dev/null 2>&1; then
      pkgs+=("$pkg")
    fi
  done

  if (( ${#pkgs[@]} > 0 )); then
    printf "${STY_YELLOW}[$0]: Detected dinit init system, installing service packages: ${pkgs[*]}${STY_RST}\n"
    x sudo pacman -S --needed --noconfirm "${pkgs[@]}"
  fi
}
showfun install-dinit-service-packages
v install-dinit-service-packages

if pacman -Qs ^plasma-browser-integration$ ;then SKIP_PLASMAINTG=true;fi
case $SKIP_PLASMAINTG in
  true) true;;
  *)
    if $ask;then
      echo -e "${STY_YELLOW}[$0]: NOTE: The size of \"plasma-browser-integration\" is ~600 KiB, but if you don't yet have KDE on your system it'll pull an extra ~600MiB of packages.${STY_RST}"
      echo -e "${STY_YELLOW}It is needed if you want playtime of media in Firefox to be shown on the music controls widget.${STY_RST}"
      echo -e "${STY_YELLOW}Install it? [y/N]${STY_RST}"
      read -p "====> " p
    else
      p=y
    fi
    case $p in
      y) x sudo pacman -S --needed --noconfirm plasma-browser-integration ;;
      *) echo "Ok, won't install"
    esac
    ;;
esac
