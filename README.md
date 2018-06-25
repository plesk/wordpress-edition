[![Apache 2](http://img.shields.io/badge/license-Apache%202-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

# Plesk WordPress Edition

This repository contains all you need to build and customize your personal preconfigured WordPress Server solution with Plesk. The included whitepaper describes the solution in detail and highlights why you should offer it to your customers.

![](https://raw.githubusercontent.com/plesk/ext-welcome-wp/master/_meta/screenshots/1.png)

## Description

  Here at Plesk we strive to Simpify the Lives of Web Professionals. This includes our Partners. This cookbook will install and configure Plesk Core, Modules and Bundle Extensions. It will also enable and configure security features and prepare your VM to be used as a VM template. 

## Requirements

 * Contract with Plesk to be able to retrieve Plesk Licenses from the Key Administrator Server (KA)
 * Provide Plesk Key with Proper Plesk Exension keys associated in cookbook script

 or

  * A Plesk license with the [WordPress Pack](https://ext.plesk.com/packages/f8afea30-b1e9-45f5-ab71-437a0ce7c817-offer-wordpress-feature-pack)
 
## Deploying Plesk with WordPress Edition Cookbook

1. Install one of the supported Linux Operating Systems ( https://docs.plesk.com/release-notes/onyx/hardware-requirements ) following hardware specs ( https://docs.plesk.com/release-notes/onyx/hardware-requirements/ )

2. Shell to server as root

3. Download and Edit Variables noted in install_wordpress_edition.sh

4. Execute command 

   $ chmod +x install install_wordpress_edition.sh

5. Execute command 

   $ ./install_wordpress_edition.sh <YOUR_ACTIVATION_KEY>

### Using prebuild Plesk Images

tbd

## Support

tbd
