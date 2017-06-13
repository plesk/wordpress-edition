[![Apache 2](http://img.shields.io/badge/license-Apache%202-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

# Plesk WordPress Server Solution

This repository contains all you need to build and customize your personal preconfigured WordPress Server solution with Plesk. The included whitepaper describes the solution in detail and highlights why you should offer it to your customers.

![](https://raw.githubusercontent.com/plesk/ext-welcome-wp/master/_meta/screenshots/1.png)

## Description

tbd

## Requirements

 * Contract with Plesk to be able to retrieve Plesk Licenses from the Key Administrator Server (KA)
 * Provide Plesk Key with Proper Plesk Exension keys associated in cookbook script
 
## Deploying Plesk

    $ sh <(curl http://autoinstall.plesk.com/plesk-installer || wget -O - http://autoinstall.plesk.com/plesk-installer)

### Using the Plesk AutoInstaller Cookbook

1. Install one of the supported Linux Operating Systems ( https://docs.plesk.com/release-notes/onyx/hardware-requirements ) following hardware specs ( https://docs.plesk.com/release-notes/onyx/hardware-requirements/ )

2. shell to server as root

3. Download and Edit Variables noted in install_wordpress_server.sh

4. chmod +x install install_wordpress_server.sh

5. run  ./install_wordpress_server.sh

### Using prebuild Plesk Images

tbd

## Support

tbd
