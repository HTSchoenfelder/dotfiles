#!/bin/bash

# 1. Create the Bash script that runs yay -Sy
echo "Creating /usr/local/bin/update_yay_db.sh..."
sudo bash -c 'cat > /usr/local/bin/update_yay_db.sh <<EOF
#!/bin/bash
yay -Sy
EOF'

# Make the script executable
echo "Setting permissions for /usr/local/bin/update_yay_db.sh..."
sudo chmod +x /usr/local/bin/update_yay_db.sh

# 2. Create the systemd service file
echo "Creating /etc/systemd/system/update-yay-db.service..."
sudo bash -c 'cat > /etc/systemd/system/update-yay-db.service <<EOF
[Unit]
Description=Update Yay Database

[Service]
Type=oneshot
ExecStart=/usr/local/bin/update_yay_db.sh
EOF'

# 3. Create the systemd timer file for hourly execution
echo "Creating /etc/systemd/system/update-yay-db.timer..."
sudo bash -c 'cat > /etc/systemd/system/update-yay-db.timer <<EOF
[Unit]
Description=Run yay database update every hour

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF'

# 4. Enable and start the timer
echo "Enabling and starting the timer..."
sudo systemctl enable --now update-yay-db.timer

# Verify the timer
echo "Checking if the timer is active..."
systemctl list-timers --all | grep update-yay-db.timer

echo "Setup complete. Yay will now update the package sources hourly."
