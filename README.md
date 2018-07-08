# qubes-wpad-server

Proxy Auto-Discovery for QubesOS

## Problem:

Using IP whitelists for making VMs with limited network access in Qubes
is time consuming and problematic (CDNs, load balancing, 3rd-parties, etc).

Creating individual proxies for several VMs should not mean duplicate
templates, hard-coded proxy values and generally mucking around in
configs.

## Solution Overview

Leverage an existing privacy focused proxy [(Privoxy)](http://www.privoxy.org/),
create **one** proxy VM template and **zero** *proxied* VM templates.

Don't worry about your configs being overwritten by upgrades. And use standard,
and very simple, mechanisms in Qubes to setup proxy VMs and proxy client VMs.

## Installation

#### Only Debian templates in Qubes 3.2 and 4.0 are supported. (PRs welcome)

### Download

To be added after first release and some testing.  In the meantime clone the repo
or download a zip.

## Setup

Setup is mildly involved so scripts have been provided to simplify the setup
a proxy template, proxy AppVM and client AppVM.

After initial setup, all configuration of the proxy must be done in the proxy
AppVM (not the template).  And additional configuration for some programs in
the client VM must be done separately (some examples are provided under
'Additional Configurations' below).

### Create Proxy TemplateVM

#### Overview

- Create and start a clone of the base Debian template, or other Debian-based
  template.
- Copy in the ```setup_proxy_appvm``` directory from qubes-wpad-server.
- Run the ```setup_templatevm.sh``` script which installs Privoxy and modifies its
  start-up to use an alternative config directory.
- (Optionally) Run the ```setup_appvm.sh``` to create the alternate config
  directory in the TemplateVM, *highly recommended for Qubes 3.2 users*.

### Step-by-Step

From Dom0:
```bash
qvm-clone debian-9 debian-9-proxy
```

From VM with qubes-wpad-server downloaded:
```bash
qvm-copy-to-vm debian-9-proxy qubes-wpad-server/setup_proxy_appvm
```

From new proxy template VM:
```bash
# Where $VM is the name of the sender of setup_proxy_appvm
mv -iv QubesIncoming/$VM/setup_proxy_appvm $HOME/
sudo ./setup_proxy_appvm/setup_templatevm.sh
# Optionally setup working Privoxy config for TemplateVM too.
sudo ./setup_proxy_appvm/setup_appvm.sh
```

### Create Proxy AppVM

#### Overview

- Create new Qubes VM with the new proxy template VM.
- In new VM settings deny all network traffic outbound except port 80 and 443.
- Copy in ```setup_proxy_appvm``` directory from qubes-wpad-server.
- Run the ```setup_appvm.sh``` to finish setup of Privoxy.

#### Step-by-Step

From VM with qubes-wpad-server downloaded:
```bash
NEW_PROXY_VM=www-proxy
qvm-copy-to-vm $NEW_PROXY_VM qubes-wpad-server/setup_proxy_appvm
```
From new proxy template VM:
```bash
# Where $VM is the name of the sender of setup_proxy_appvm
mv -iv QubesIncoming/$VM/setup_proxy_appvm $HOME/
# Setup working Privoxy config and firewall rules for ingress to proxy.
sudo ./setup_proxy_appvm/setup_appvm.sh
```

### Setup Proxy Client VM

#### Overview

- Copy ```setup_proxied_appvm``` directory to new or existing AppVM.
- Change target AppVM network VM to the newly setup Proxy VM.
- Change target AppVM Firewall Rules to 'Limit outgoing Internet connections to'
  and provide no exceptions. (This will deny all *forwarding* of traffic by the
  Proxy VM, which must be proxied instead, or it will be dropped)**.
- Run ```setup.sh``` to configure qubes-wpad-server and Chrome/Chromium
  menu shortcuts.
- (Optional): Configure other things to use the proxy (Firefox, terminal,
  package manager, etc).

** Caveats apply: If you want to use something like SSH forwarding that traffic
   makes sense, so create an exception to allow port 22 traffic to be forwarded.
   And so forth for protocols that don't behave well with HTTP/HTTPS proxies.

#### Step-by-Step

```bash
NEW_CLIENT_VM=www
qvm-copy-to-vm $NEW_CLIENT_VM qubes-wpad-server/setup_proxied_appvm
```

From the new client AppVM:
```bash
# Where $VM is the name of the sender of setup_proxied_appvm
mv -iv QubesIncoming/$VM/setup_proxied_appvm $HOME/
# Setup qubes-wpad-proxy and custom init for shortcuts and wpad hostname.
sudo ./setup_proxied_appvm/setup.sh
```

## Usage

The fastest and simplest way to use Privoxy is to use the ```trustfile```.
This should be enabled by default with the bundled Privoxy config, and if you
don't want this comment the trustfile option.

**Note**: These edits *must* take place in the Proxy VM to allow the client VM
  to access the specified domains.

Below is a simplistic example of enabling access to Github, Debian Apt Repos
and PyPi (the Python package manager).  This would be appended to the bottom
of the file ```/rw/config/privoxy/trust```.

When this file is changed Privoxy will automatically reload it.

```text
# Updates
~security.debian.org
~security-cdn.debian.org
~deb.qubes-os.org
~http.debian.net
~cdn-fastly.deb.debian.org
~prod.debian.map.fastly.net
~deb.debian.org

# github
~.github.com

# GoLang
~golang.org
~gopkg.in
~go.googlesource.com
# go binary package
~dl.google.com

# Python
~pypi.python.org
```

More advanced patterns and usage on the trustfile can be found on
[Privoxy's site](http://www.privoxy.org/user-manual/config.html#TRUSTFILE).

Collection of domains needed for a VM takes time and will involve failures
in the near term, see 'Troubleshooting' below.


## Troubleshooting

Getting the filtering proxy setup takes time and a careful eye to the network
problems.

- Be sure to take cues from Chrome/Chromium/Firefox Inspector when using a
browser, especially the 'Console' and 'Network' tabs.

- On the command line ensure common environment variables are set (see below)
  or command line flags are set.  Also be aware that while Privoxy will
  forward to non-standard ports (say for a RESTful service on port 9000) the
  Proxy VM itself cannot forward packets destined for port 9000 unless you
  add that exception in the Firewall Rules f

## Additional Configurations

- Configure the Apt package manager to use the proxy:
```bash
# Get the proxy IP aka the default gateway
PROXY=$(ip route get 8.8.8.8|awk {'print $3'}|xargs)

# Write a config snippet to make Apt use the proxy
cat << EOF | sudo tee /etc/apt/apt.conf.d/80proxy
Acquire::http::proxy "http://${PROXY}:8118/";
Acquire::ftp::proxy "ftp://${PROXY}:8118/";
Acquire::https::proxy "https://${PROXY}:8118/";
EOF

# Update Apt
sudo apt-get update
```

- Configure *most* command-line programs to use the proxy:
```bash

# Get the proxy IP aka the default gateway
echo "
PROXY=\$(ip route get 8.8.8.8|awk {'print \$3'}|xargs)
HTTP_PROXY=\$PROXY
HTTPS_PROXY=\$PROXY
http_proxy=\$PROXY
https_proxy=\$PROXY
export HTTP_PROXY HTTPS_PROXY http_proxy https_proxy" >> $HOME/.bashrc
```

- Firefox supports configuring auto-proxy discovery from within the
  application, versus on the command-line.  Hover on the tab bar and press
  'Alt' to show the Menus.  Open 'Edit -> Preferences' and scroll to the
  bottom to 'Network Proxy'.  Select 'Auto-detect proxy settings for this
  network' or if there are issues with that specify the 'Automatic proxy
  configuration URL' as ```http://localhost/wpad.dat```.

- The scripts support running the proxy in the same VM as the browser (versus
in a separate VM which is the default).  This can be done simply by using one
AppVM and it's corresponding template for all setup. And modifying the rc.local
in the client/proxy AppVM to uncomment ```proxy_ip=127.0.0.1```.

## Outstanding Issues

- Support a minimal template like fedora-minimal-27/28 for the proxy TemplateVM.
- More example trust file entries, and perhaps a script to assemble snippets
  of them so automation becomes possible.
- App: More flags for qubes-wpad-server for exceptions, etc.
- Documentation: Command-line for setting up firewall rules + network VMs.
- Deploy: Salt formula for configuring AppVM and filtering proxy, end to end.
