
#!/usr/bin/env bash
set -Eeuo pipefail

echo "[Cleanup] Starting image cleanup..."

export DEBIAN_FRONTEND=noninteractive

# --------------------------------------------------
# 1. Remove APT cache and downloaded package files
# --------------------------------------------------

echo "[Cleanup] Cleaning APT cache..."

apt-get clean
apt-get autoclean

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/apt/archives/*.deb

# --------------------------------------------------
# 2. Remove temporary files
# --------------------------------------------------

echo "[Cleanup] Removing temporary files..."

rm -rf /tmp/*
rm -rf /var/tmp/*

# --------------------------------------------------
# 3. Remove package manager temporary files
# --------------------------------------------------

rm -rf /var/lib/dpkg/tmp.ci
rm -rf /var/lib/dpkg/info/*.list-old

# --------------------------------------------------
# 4. Remove unnecessary documentation and cache
# --------------------------------------------------

echo "[Cleanup] Removing unnecessary cache..."

rm -rf /root/.cache/*
rm -rf /home/kasm-default-profile/.cache/*
rm -rf /home/kasm-user/.cache/*

# --------------------------------------------------
# 5. Ensure Desktop directory exists
# --------------------------------------------------

mkdir -p /home/kasm-default-profile/Desktop
mkdir -p /home/kasm-user/Desktop

# --------------------------------------------------
# 6. Fix permissions
# --------------------------------------------------

chown -R 1000:0 /home/kasm-default-profile
chown -R 1000:0 /home/kasm-user

chmod 755 /home/kasm-default-profile
chmod 755 /home/kasm-user

# --------------------------------------------------
# 7. Remove installation scripts
# --------------------------------------------------

echo "[Cleanup] Cleanup completed."
