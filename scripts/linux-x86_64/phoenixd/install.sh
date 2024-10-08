#!/bin/bash

ALBYHUB_URL="https://getalby.com/install/hub/server-linux-x86_64.tar.bz2"
PHOENIX_VERSION="0.1.5"
PHOENIX_URL="https://github.com/ACINQ/phoenixd/releases/download/v$PHOENIX_VERSION/phoenix-$PHOENIX_VERSION-linux-x64.zip"

echo ""
echo ""
echo "⚡️ Welcome to AlbyHub"
echo "-----------------------------------------"
echo "Installing AlbyHub with phoenixd"
echo ""
read -p "Absolute install directory path (default: $HOME/albyhub-phoenixd): " USER_INSTALL_DIR

INSTALL_DIR="${USER_INSTALL_DIR:-$HOME/albyhub-phoenixd}"

mkdir -p $INSTALL_DIR

cd $INSTALL_DIR

mkdir -p "$INSTALL_DIR/albyhub"
wget $ALBYHUB_URL
tar xvf server-linux-x86_64.tar.bz2 --directory=albyhub
if [[ $? -ne 0 ]]; then
  echo "Failed to unpack Alby Hub. Potentially bzip2 is missing"
  echo "Install it with sudo apt-get install bzip2"
  exit
fi

rm server-linux-x86_64.tar.bz2

### Create start scripts

tee -a $INSTALL_DIR/albyhub/start.sh > /dev/null << EOF
#!/bin/bash

echo "Starting Alby Hub"
phoenix_config_file=/home/ubuntu/.phoenix/phoenix.conf
PHOENIXD_AUTHORIZATION=\$(awk -F'=' '/^http-password/{print \$2}' "\$phoenix_config_file")
WORK_DIR="$INSTALL_DIR/albyhub/data" LN_BACKEND_TYPE=PHOENIX PHOENIXD_ADDRESS="http://localhost:9740" PHOENIXD_AUTHORIZATION=\$PHOENIXD_AUTHORIZATION LOG_EVENTS=true LDK_GOSSIP_SOURCE="" $INSTALL_DIR/albyhub/bin/albyhub
EOF

tee -a $INSTALL_DIR/start.sh > /dev/null << EOF
#!/bin/bash


$INSTALL_DIR/albyhub/start.sh &
echo "Started..."
EOF

chmod +x $INSTALL_DIR/start.sh
chmod +x $INSTALL_DIR/albyhub/start.sh

echo ""
echo ""
echo "Installation done."
echo ""

read -p "Do you want to setup a systemd service? (y/n): " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Run $INSTALL_DIR/start.sh to start phoenixd and Alby Hub"
  echo "DONE"
  exit
fi

sudo tee -a /etc/systemd/system/albyhub.service > /dev/null << EOF
[Unit]
Description=Alby Hub
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
ExecStart=$INSTALL_DIR/albyhub/start.sh

[Install]
WantedBy=multi-user.target
EOF

sudo tee -a /etc/systemd/system/phoenixd.service > /dev/null << EOF
[Unit]
Description=Phoenixd
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=$USER
ExecStart=$INSTALL_DIR/phoenixd/start.sh

[Install]
WantedBy=multi-user.target
EOF

echo ""
echo ""

sudo systemctl enable albyhub
sudo systemctl enable phoenixd
sudo systemctl start phoenixd
sudo systemctl start albyhub

echo "Run 'sudo systemctl start/stop albyhub' to start/stop AlbyHub"
echo "Run 'sudo systemctl start/stop phoenixd' to start/stop phoenixd"
echo ""
echo "✅ DONE."
echo "Alby Hub runs by default on localhost:8080"
