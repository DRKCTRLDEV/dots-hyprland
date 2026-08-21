# This script is meant to be sourced.
# It's not for directly running.

source ./sdata/dist-arch/metapkgs.sh

for i in "${ARCH_METAPKG_NAMES[@]}" plasma-browser-integration; do
  v yay -Rns $i
done
