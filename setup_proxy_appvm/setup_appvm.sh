#!/bin/bash

if [ ${UID} -ne 0 ]; then
  echo "$0 requires root privileges, please run 'sudo $0'"
  exit 1
fi

unpack_dir="$(dirname ${BASH_SOURCE[0]})"
pushd .
cd ${unpack_dir}

if [ -f qubes-firewall-user-script ]; then
  echo "Backing up existing qubes-firewall-user-script"
  echo "Overwriting qubes-firewall-user-script for proxy usage."
  cp -vrp /rw/config/qubes-firewall-user-script /rw/config/qubes-firewall-user-script.backup
  cp -vrp qubes-firewall-user-script /rw/config/qubes-firewall-user-script 
else
  echo "Could not find file 'qubes-firewall-user-script' in $PWD"
  popd
  exit 1
fi

if [ ! -d /rw/config/privoxy ]; then
  echo "Copying privoxy config from /etc/privoxy to /rw/config/privoxy"
  cp -vrp /etc/privoxy /rw/config/privoxy
else
  echo "Privoxy config directory already at /rw/config/privoxy"
  popd
  exit 1
fi

if [ -f privoxy_config ]; then
  echo "Copying local Privoxy config over /rw/config/privoxy/config."
  echo "Original /etc/privoxy/config will *not* be touched."
  cp -v privoxy_config /rw/config/privoxy/config
else
  echo "Could not find file 'privoxy_config' in $PWD"
  popd
  exit 1
fi

popd
service privoxy restart
/rw/config/qubes-firewall-user-script
