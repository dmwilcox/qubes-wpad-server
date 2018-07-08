#!/bin/bash

if [ ${UID} -ne 0 ]; then
  echo "$0 requires root privileges, please run 'sudo $0'"
  exit 1
fi

default_privoxy_unit=/lib/systemd/system/privoxy.service
override_privoxy_unit=/etc/systemd/system/privoxy.service

# Update source repos and install Privoxy.
apt-get update -y
apt-get install privoxy

# Create an override systemd unit for Privoxy to use /rw/config/privoxy
# as the config directory in AppVMs based on this template.
cp -v ${default_privoxy_unit} ${override_privoxy_unit}
sed -i 's/\/etc\/privoxy/\/rw\/config\/privoxy/' ${override_privoxy_unit}

# Reload systemd units to pick-up changes.
systemctl daemon-reload

# In the TemplateVM restarting Privoxy here will fail if the Privoxy
# config directory (/etc/privoxy) has not been copied to the read-write
# location (/rw/config/privoxy). And modified per the setup_appvm.sh
# script.

# If using Qubes 3.2, which copies the TemplateVM /rw/config as a base,
# or would just like a properly running Privoxy in this TemplateVM
# next run setup_appvm.sh.

echo "Run setup_appvm.sh to finish setup in TemplateVM."
