# This script is meant to be sourced.
# It's not for directly running.

# See https://github.com/end-4/dots-hyprland/issues/2137
#
# Stage 1 todos:
# TODO: Properly handle hyprland config, ~/.config/hypr/hyprland.conf should be overwritten only when firstrun
# TODO: add --exp-files-path <path>   Use <path> instead of the default yaml config
# TODO: add --exp-files-regen         Force copy the default config to ${EXP_FILE_PATH} (auto do this when not existed)
# TODO: Implement versioning, i.e. when user-defined yaml config file has version number mismatch with the default one, produce error. If only minor version number is not the same, the error can be ommitted via --exp-file-no-strict .
# TODO: add --exp-files-no-strict     Ignore error when minor version number is not the same
# TODO: When --via-nix is specified, use dots-extra/vianix/hypridle.conf instead
#
# Stage 2 todos:
# TODO: Implement bool key symlink (both read-write and read-only), when the value of `symlink` is true, then instead using `rsync` or `cp`, use `ln`.
# TODO: add --exp-file-reset-symlink  Try to remove all symlink in .config and .local, which point to the local repo
# TODO: Update help and doc about `--exp-files` and the yaml config, including the possible values of mode.
#
# Stage 3 todos:
# TODO: Implement user-define yaml with merging (override) ability for user who only wants little customization and is satisfied with most of the defaults. User can use `./install-files.yaml` as custom config. When `./install-files.yaml` exists and have correct major version number, merge it together with `sdata/step/3.install-files.yaml` to generate a `cache/install-files.final.yaml` to determine how to copy files. About how to merge two yaml files, I know some software such as rime input method and docker supports a override yaml config, which we may reference from. See also https://github.com/mikefarah/yq/discussions/1437
# TODO: Implement variants like keybindings, terminals, etc under user_preferences.

# Configuration file
CONFIG_FILE="sdata/subcmd-install/3.files-exp.yaml"

# Compare hashes of files/directories, return true if they are the same, false otherwise
files_are_same() {
	local path1="$1"
	local path2="$2"

	# Check if paths exist
	if [[ ! -e "$path1" || ! -e "$path2" ]]; then
		return 1
	fi

	# For directories, use find + md5sum to compare recursively
	# For files, use md5sum directly
	if [[ -d "$path1" && -d "$path2" ]]; then
		# Compare directory contents using find and md5sum
		local hash1=$(find "$path1" -type f -exec md5sum {} \; | sort -k 2 | md5sum | awk '{print $1}')
		local hash2=$(find "$path2" -type f -exec md5sum {} \; | sort -k 2 | md5sum | awk '{print $1}')
		[[ "$hash1" == "$hash2" ]]
	elif [[ -f "$path1" && -f "$path2" ]]; then
		# Compare file hashes
		local hash1=$(md5sum "$path1" | awk '{print $1}')
		local hash2=$(md5sum "$path2" | awk '{print $1}')
		[[ "$hash1" == "$hash2" ]]
	else
		# One is a file, one is a directory - different types
		return 1
	fi
}

# Find next backup number
get_next_backup_number() {
	local base_path="$1"
	local counter=1

	while [[ -e "${base_path}.old.${counter}" ]]; do
		((counter++))
	done

	echo $counter
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

# Read patterns from YAML file
readarray patterns < <(yq -o=j -I=0 '.patterns[]' "$CONFIG_FILE")

# Process each pattern
for pattern in "${patterns[@]}"; do
	from=$(echo "$pattern" | yq '.from' - | envsubst)
	to=$(echo "$pattern" | yq '.to' - | envsubst)
	mode=$(echo "$pattern" | yq '.mode' - | envsubst)

	# Handle fontconfig fontset override
	# If FONTSET_DIR_NAME is set and this is the fontconfig pattern, use the fontset instead
	if [[ "$from" == "dots/.config/fontconfig" ]] && [[ -n "${FONTSET_DIR_NAME:-}" ]]; then
		from="dots-extra/fontsets/${FONTSET_DIR_NAME}"
		echo "Using fontset \"${FONTSET_DIR_NAME}\" for fontconfig"
	fi

	echo "Processing: $from -> $to (mode: $mode)"

	# Build exclude arguments for rsync
	excludes=()
	if echo "$pattern" | yq -e '.excludes' >/dev/null 2>&1; then
		while IFS= read -r exclude; do
			excludes+=(--exclude "$exclude")
		done < <(echo "$pattern" | yq -r '.excludes[]')
	fi

	# Check if source exists
	if [[ ! -e "$from" ]]; then
		echo "Warning: Source does not exist: $from (skipping)"
		continue
	fi

	# Ensure destination directory exists for files
	if [[ -f "$from" ]]; then
		v mkdir -p "$(dirname "$to")"
	fi

	# Execute based on mode
	case "$mode" in
	"sync")
		if [[ -d "$from" ]]; then
			warning_overwrite
			v rsync -av --delete "${excludes[@]}" "$from/" "$to/"
		else
			warning_overwrite
			# For files, don't use trailing slash and don't use --delete
			v rsync -av "${excludes[@]}" "$from" "$to"
		fi
		;;
	"soft")
		warning_overwrite
		if [[ -d "$from" ]]; then
			v rsync -av "${excludes[@]}" "$from/" "$to/"
		else
			# For files, don't use trailing slash
			v rsync -av "${excludes[@]}" "$from" "$to"
		fi
		;;
	"hard")
		v cp -r "$from" "$to"
		;;
	"hard-backup")
		if [[ -e "$to" ]]; then
			if files_are_same "$from" "$to"; then
				echo "Files are identical, skipping backup"
			else
				backup_number=$(get_next_backup_number "$to")
				v mv "$to" "$to.old.$backup_number"
				v cp -r "$from" "$to"
			fi
		else
			v cp -r "$from" "$to"
		fi
		;;
	"soft-backup")
		if [[ -e "$to" ]]; then
			if files_are_same "$from" "$to"; then
				echo "Files are identical, skipping backup"
			else
				v cp -r "$from" "$to.new"
			fi
		else
			v cp -r "$from" "$to"
		fi
		;;
	"skip")
		echo "Skipping $from"
		;;
	"skip-if-exists")
		if [[ -e "$to" ]]; then
			echo "Skipping $from (destination exists)"
		else
			v cp -r "$from" "$to"
		fi
		;;
	*)
		echo "Unknown mode: $mode"
		;;
	esac
done
