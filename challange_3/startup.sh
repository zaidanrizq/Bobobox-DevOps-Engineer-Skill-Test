#!/bin/bash

set -e

# Wait for system to be ready
sleep 10

# Update & install
apt-get update -y
apt-get install -y nginx

# Ensure service is running
systemctl enable nginx
systemctl restart nginx

# Deploy page
cat <<EOF > /var/www/html/index.html
<html>
  <head><title>OpenTofu</title></head>
  <body>
    <h1>Hello, OpenTofu!</h1>
  </body>
</html>
EOF