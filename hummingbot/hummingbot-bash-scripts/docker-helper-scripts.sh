#!/bin/bash
clear

# download docker helper scripts for client and gateway
wget https://raw.githubusercontent.com/hummingbot/deploy-examples/main/bash_scripts/hummingbot-create.sh
wget https://raw.githubusercontent.com/hummingbot/deploy-examples/main/bash_scripts/hummingbot-start.sh
wget https://raw.githubusercontent.com/hummingbot/deploy-examples/main/bash_scripts/hummingbot-update.sh
wget https://raw.githubusercontent.com/hummingbot/deploy-examples/main/bash_scripts/gateway-create.sh
wget https://raw.githubusercontent.com/hummingbot/deploy-examples/main/bash_scripts/gateway-copy-certs.sh

# add permission and PATH
sudo chmod a+x *.sh

echo ""
echo "Successfully downloaded and permission updated!"
echo ""