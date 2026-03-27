#!/usr/bin/env bash

# 1. Clean up old versions
echo "Setting up Docker and dependencies..."
apt-get update
apt-get remove -y docker.io docker-compose docker-doc podman-docker containerd runc || true

# 2. Install Docker
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Clone files
echo "Cloning Dock-arr repository..."
git clone https://github.com/MerlinSting/dock-arr.git /opt/dockarr

echo "Setup Complete!"