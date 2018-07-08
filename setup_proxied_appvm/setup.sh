#!/bin/bash

if [ ${UID} -ne 0 ]; then
  echo "$0 requires root privileges, please run 'sudo $0'"
  exit 1
fi

unpack_dir="$(dirname ${BASH_SOURCE[0]})"
pushd .
cd ${unpack_dir}

# Backup and replace existing boot-up script for VM.
if [ -f rc.local ]; then
  echo "Backing up existing rc.local and overwriting"
  cp -vp /rw/config/rc.local /rw/config/rc.local.backup
  cp -vp rc.local /rw/config/rc.local
else
  echo "Could not find file 'rc.local' in $PWD"
  exit 1
fi

# Create binaries directory in read-write section of VM filesystem.
if [ ! -d /rw/config/bin ]; then
  echo "Creating /rw/config/bin"
  mkdir /rw/config/bin
fi

# Copy WPAD server into place to serve proxy auto-discovery info.
if [ -f qubes-wpad-server ]; then
  echo "Copying qubes-wpad-server to /rw/config/bin"
  cp -vrp qubes-wpad-server /rw/config/bin/
else
  echo "Could not find file 'qubes-wpad-server' in $PWD"
  exit 1
fi

# Override menu shortcuts for apps that require a command-line flag
# to properly accept a proxy (or auto-proxy discovery).  Mostly for
# Chromium and Google Chrome.
if [ -d shortcuts ]; then
  if [ ! -d /rw/config/shortcuts ]; then
    echo "Copying app shortcuts to /rw/config/shortcuts"
    cp -vrp shortcuts /rw/config/
  else
    echo "/rw/config/shortcuts already exists, skipping."
  fi
fi

# Run start-up script so VM restart isn't required to take affect
nohup /rw/config/rc.local >& /dev/null
