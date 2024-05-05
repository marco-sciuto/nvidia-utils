#!/bin/bash

# Coolbits
cat <<EOF > /usr/share/X11/xorg.conf.d/20-coolbits.conf
Section "OutputClass"
    Identifier "nvidia"
    MatchDriver "nvidia-drm"
    Driver "nvidia"
    Option "Coolbits" "8"
EndSection
EOF

gdmuid=`cat /etc/passwd | grep gdm | awk -F ':' '{print $3}'`

# Udervolt script
cat <<EOF > ~/.local/bin/nvidia-undervolt
#!/bin/bash

nvidia-smi -pm 1
nvidia-smi -i 0 -lgc 0,1980
DISPLAY=:0 XAUTHORITY=/run/user/$gdmuid/gdm/Xauthority nvidia-settings -a [gpu:0]/GPUGraphicsClockOffsetAllPerformanceLevels=150 \
-a [gpu:0]/GPUMemoryTransferRateOffsetAllPerformanceLevels=750

#https://bugs.launchpad.net/ubuntu/+source/linux/+bug/2060268
#rm /dev/dri/card0
#set the parameter on grub as mentioned in comment #32

# -a [gpu:0]/GPUFanControlState=1 \
# -a [fan:0]/GPUTargetFanSpeed=75 \
# -a [fan:1]/GPUTargetFanSpeed=75 \
# -a [gpu:0]/GPUPowerMizerMode=1 \
#nvidia-smi -i 0 -pl 200
EOF
chmod +755 ~/.local/bin/nvidia-undervolt

# Autostart script
cat <<EOF > /etc/systemd/system/nvidia-undervolt.service
[Unit]
Description=Undervolt Nvidia GPU
After=runlevel4.target

[Service]
Type=oneshot
Environment="DISPLAY=:0"
Environment="XAUTHORITY=/etc/X11/.Xauthority"
ExecStart=$HOME/.local/bin/nvidia-undervolt

[Install]
WantedBy=multi-user.target
EOF
chown root:root /etc/systemd/system/nvidia-undervolt.service
chmod 644 /etc/systemd/system/nvidia-undervolt.service
sudo systemctl enable nvidia-undervolt.service

# Enable AllowGSYNCCompatible
cat <<EOF > ~/.config/autostart/nvidia-settings.desktop
[Desktop Entry]
Type=Application
Exec=nvidia-settings -a CurrentMetaMode="nvidia-auto-select +0+0 {AllowGSYNCCompatible=On}"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[it_IT]=Nvidia G-Sync
Name=Nvidia G-Sync
Comment[it_IT]=
Comment=
EOF

#In case of overclock not applied
#https://wiki.archlinux.org/title/NVIDIA/Troubleshooting#Overclocking_not_working_with_Unknown_Error
#echo "\nneeds_root_rights=yes" >> /etc/X11/Xwrapper.config
