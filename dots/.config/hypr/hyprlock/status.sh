#!/usr/bin/env bash

############ Variables ############
enable_battery=false
battery_charging=false
battery_status=""
battery_capacity=""

####### Check availability ########
for battery in /sys/class/power_supply/*BAT*; do
  if [[ -f "$battery/uevent" ]]; then
    enable_battery=true
    battery_status="$(< "$battery/status")"
    battery_capacity="$(< "$battery/capacity")"
    if [[ "$battery_status" == "Charging" ]]; then
      battery_charging=true
    fi
    break
  fi
done

############# Output #############
if [[ $enable_battery == true ]]; then
  if [[ $battery_charging == true ]]; then
    echo -n "(+) "
  fi
  echo -n "${battery_capacity}"%
  if [[ $battery_charging == false ]]; then
    echo -n " remaining"
  fi
fi

echo ''
