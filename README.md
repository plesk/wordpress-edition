<h1 align="center">Ubuntu Plesk Server</h1>
<p  align="center">
<a href="http://www.apache.org/licenses/LICENSE-2.0"><img src="http://img.shields.io/badge/license-Apache 2-blue.svg" alt="" class="loading" id="image-hash-bc6178aff0e15ee8f4edae603da1dae0507fe3b777dd8805798f27346188a087"></a>
<a href="https://travis-ci.org/VirtuBox/ubuntu-plesk-server"><img src="https://img.shields.io/travis/VirtuBox/ubuntu-plesk-server" alt="" class="loading" id="image-hash-82e1c6d8511303293d97069a09b0af49d3663e60ba7776ae8a0070d3f5341a53"></a>
<img src="https://img.shields.io/github/last-commit/VirtuBox/ubuntu-plesk-server" alt="" class="loading" id="image-hash-f064751bd7f01bbca0f077a9287d0d81a8fb4ebecef5bbc4363f37358ae6a9df"></p>
</p>

This repository contains a bash script to automate Plesk Obsidian deployment on Ubuntu.

## Description

The script settings can be defined in an interactive way by running the script with the flag `--interactive`, or fully non-interactive with arguments like `--mariadb 10.3` to define MariaDB-server version.

## Requirements

* Ubuntu 20.04 LTS
* Ubuntu 18.04 LTS
* Ubuntu 16.04 LTS

## Deploying Plesk

### Interactive install

Interactive installation is available with argument `--interactive`

```bash
bash <(wget -O - vtb.cx/plesk || curl -sL vtb.cx/plesk) --interactive
```

### Custom install

Default setup with MariaDB 10.3

```bash
bash <(wget -O - vtb.cx/plesk || curl -sL vtb.cx/plesk) -y
```
