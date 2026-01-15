#!/usr/bin/env bash

set -euo pipefail

# install-all.sh - Install all tools from the asdf-plugins repository
#
# Usage:
#   ./install-all.sh [repo-url-or-path]
#
# If no argument is provided, uses the GitHub repository URL.
# You can also provide a local path for testing.

REPO_URL="${1:-https://github.com/SmartestEdu/asdf-plugins.git}"

# All supported tools
TOOLS=(
  "jq"
  "yq"
  "kubectl"
  "kustomize"
  "kops"
  "kubeseal"
  "kubeconform"
  "minikube"
  "awscli"
  "aws-iam-authenticator"
  "amazon-ecr-credential-helper"
  "github-cli"
  "jwt-cli"
  "nodejs"
  "tmux"
  "overmind"
  "sinker"
  "caddy"
)

echo "=========================================="
echo "asdf-plugins Installation Script"
echo "=========================================="
echo ""
echo "This will install plugins for ${#TOOLS[@]} tools:"
echo "${TOOLS[@]}" | tr ' ' '\n' | sed 's/^/  - /'
echo ""
echo "Repository: $REPO_URL"
echo ""

# Check if asdf is installed
if ! command -v asdf &>/dev/null; then
  echo "Error: asdf is not installed or not in PATH"
  echo "Please install asdf first: https://asdf-vm.com/guide/getting-started.html"
  exit 1
fi

echo "Removing any existing plugins for these tools..."
for tool in "${TOOLS[@]}"; do
  if asdf plugin list 2>/dev/null | grep -q "^${tool}$"; then
    echo "  Removing: $tool"
    asdf plugin remove "$tool" 2>&1 | sed 's/^/    /' || true
  fi
done

echo ""
echo "Adding plugins from $REPO_URL..."
for tool in "${TOOLS[@]}"; do
  echo "  Adding: $tool"
  if asdf plugin add "$tool" "$REPO_URL" 2>&1 | sed 's/^/    /'; then
    echo "    ✓ Success"
  else
    echo "    ✗ Failed"
  fi
done

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. List available versions:  asdf list-all <tool>"
echo "  2. Install a version:        asdf install <tool> <version>"
echo "  3. Set global version:       asdf global <tool> <version>"
echo ""
echo "Example:"
echo "  asdf list-all jq"
echo "  asdf install jq latest"
echo "  asdf global jq latest"
echo ""
