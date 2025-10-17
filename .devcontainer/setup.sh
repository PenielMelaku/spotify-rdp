#!/bin/bash
echo "🚀 Setting up Spotify Zero-Rated Proxy..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Squid Proxy
sudo apt install -y squid

# Configure Squid for Spotify
sudo tee /etc/squid/squid.conf > /dev/null <<'EOF'
http_port 3128
http_access allow all
forwarded_for off
via off
dns_v4_first on
cache deny all
request_header_access All allow all
always_direct allow all
EOF

# Start Squid
sudo systemctl start squid
sudo systemctl enable squid

# Install Python backup proxy
sudo apt install -y python3-pip
pip3 install flask requests

# Create Python proxy
sudo tee /app/proxy.py > /dev/null <<'EOF'
from flask import Flask, request, Response
import requests

app = Flask(__name__)

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def proxy(path):
    headers = {
        'Host': 'open.spotify.com',
        'User-Agent': 'Spotify/8.5.0 Android/29',
        'Connection': 'keep-alive'
    }
    url = f'https://open.spotify.com/{path}' if path else 'https://open.spotify.com'
    resp = requests.get(url, headers=headers, verify=False)
    return Response(resp.content, resp.status_code, resp.headers.items())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# Start Python proxy in background
nohup python3 /app/proxy.py > /dev/null 2>&1 &

echo "✅ Setup complete! Proxy running on port 3128"
echo "🔧 Squid Proxy: Port 3128"
echo "🐍 Python Proxy: Port 8080"
