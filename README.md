# qubes-wpad-server

Used to provide proxy auto-discovery services for VMs in QubesOS.

## Problem:
Setting up proxies in Qubes means either moving configuration of
*where* the proxy runs into the template (brittle) or moving it into
the /rw somehow.

Firefox can gracefully do the latter, by providing proxy configuration
in the application -- but Google Chrome + Chromium cannot.  This results
in needing to modify system files to easily launch Chrome/Chromium
in the standard manner from Dom0.

## Solution Overview

Supports either running the proxy in the same VM as the browser **or**
in a separate VM, typically the NetVM of the client VM.

Modify template(s) to run Privoxy/proxy-of-choice and point the start-up
file at a config stored in ```/rw``` to allow for easy customization, and
several differently configured proxies.

On the client side modify ```.desktop``` file for Chrome/Chromium to use proxy
auto-discovery, add a 'wpad' entry to ```/etc/hosts``` for the localhost, and
run the qubes-wpad-server in ```/rw/config/rc.local```.

If the NetVM will serve as the proxy allow connections inbound to the proxy
and persist firewall rule changes in ```/rw/config/qubes-firewall-user-script```.

## Detailed Setup

TODO

stuff here
