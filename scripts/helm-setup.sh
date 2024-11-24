#!/bin/bash

# Configuration
NEXUS_URL="http://localhost:8081/repository/helm-repo/" # Replace with your Nexus Helm repo URL
NEXUS_USER="admin" # Nexus username
NEXUS_PASS="admin123" # Nexus password

# Function to install yq
install_yq() {
    echo "Installing 'yq'..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq
        chmod +x /usr/local/bin/yq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install yq || { echo "Error: Homebrew is not installed. Install Homebrew first."; exit 1; }
    else
        echo "Unsupported OS. Please install 'yq' manually from https://github.com/mikefarah/yq"
        exit 1
    fi
    echo "'yq' installed successfully."
}

# Check for dependencies
if ! command -v yq &> /dev/null; then
    echo "'yq' is not installed."
    install_yq
fi

# 1. Get inputs from parameters
if [[ $# -lt 5 ]]; then
    echo "Usage: $0 <CHART_NAME> <IMAGE> <TAG> <PORT> <NAMESPACE> [HOST]"
    exit 1
fi

CHART_NAME=$1
IMAGE=$2
TAG=$3
PORT=$4
NAMESPACE=$5
ENABLE_INGRESS=true
HOST=${6:-"example.com"} # Default ingress host

# 2. Create Helm chart
helm create "$CHART_NAME"

# Change directory to the chart
cd "$CHART_NAME" || { echo "Failed to change directory to $CHART_NAME"; exit 1; }

# 3. Update values.yaml using yq
yq eval ".name = \"$CHART_NAME\"" -i values.yaml
yq eval ".image.repository = \"$IMAGE\"" -i values.yaml
yq eval ".image.tag = \"$TAG\"" -i values.yaml
yq eval ".port = \"$PORT\"" -i values.yaml
yq eval ".namespace = \"$NAMESPACE\"" -i values.yaml

# Add Ingress configuration
if [[ "$ENABLE_INGRESS" == "true" ]]; then
    yq eval ".ingress.enabled = true" -i values.yaml
    yq eval ".ingress.hosts[0].host = \"$HOST\"" -i values.yaml
else
    yq eval ".ingress.enabled = false" -i values.yaml
fi

echo "Updated values.yaml:"
cat values.yaml
