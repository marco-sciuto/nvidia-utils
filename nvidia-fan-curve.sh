#! /bin/bash

#----------------------------------------------------------------------
# Description: custom fan speed management for NVIDIA GPUs on Linux
#
# Author: Marco Sciuto
# System: Linux 4.4.0-28-generic #47-Ubuntu SMP Fri Jun 24 10:09:13 UTC
#         2016 x86_64 x86_64 x86_64 GNU/Linux
#
# Tested on: GIGABYTE GeForce GTX 770 2 GB OC (GV-N770OC-2GD)
#            NVIDIA Driver v367.27
#
# WARNING: I am not liable for any damage to your GPU if you decide to
#          use this script
#
#----------------------------------------------------------------------

polltime=1 # in seconds

trap ctrl_c INT

ctrl_c() {
	echo
	echo -n "Resetting GPU fan management: "
	nvidia-settings -a "[gpu:0]/GPUFanControlState=0" &>/dev/null && echo "OK" || echo "Failed!"
	exit 0
}

setspeed()
{
	echo "GPU Temperature: $1. Setting GPU fan speed to $2"
	nvidia-settings -a "[gpu:0]/GPUFanControlState=1" -a "[fan:0]/GPUTargetFanSpeed=$2" &> /dev/null

}

result=$(nvidia-settings -a "[gpu:0]/GPUFanControlState=1" | grep "assigned value 1")
test -z "$result" && echo "Fan speed management is not supported on this GPU. Exiting" && exit 1

while :; do
	temp=$(nvidia-settings -q GPUCoreTemp -t | head -1)

	if [ $temp -le 45 ]; then
		fanspeed=25
	elif [ $temp -eq 46 ]; then
		fanspeed=28
	elif [ $temp -le 50 ]; then
		fanspeed=$(echo "scale=0; (20*$temp-850)/3" | bc -l)
	elif [ $temp -le 85 ]; then
		fanspeed=$(echo "scale=0; (10*$temp-150)/7" | bc -l)
	else
		fanspeed=100
	fi

	setspeed $temp $fanspeed
	sleep $polltime
done
