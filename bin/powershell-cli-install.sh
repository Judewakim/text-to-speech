#!/usr/bin/env bash

#https://docs.aws.amazon.com/powershell/latest/reference/
#https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.4&viewFallbackFrom=powershell11-7.4

sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
source /etc/os-release
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
pwsh