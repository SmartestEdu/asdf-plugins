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
  "kubectl-slice"
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
  "shellcheck"
  "shfmt"
  "promtool"
  "ripgrep"
  "ast-grep"
  "acli"
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

get_plugin_url() {
  local tool="$1"
  local plugin_dir="${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/$tool"
  if [ -d "$plugin_dir/.git" ]; then
    git -C "$plugin_dir" remote get-url origin 2>/dev/null || echo ""
  else
    echo ""
  fi
}

echo "Installing/updating plugins from $REPO_URL..."
for tool in "${TOOLS[@]}"; do
  add_output=$(asdf plugin add "$tool" "$REPO_URL" 2>&1)

  if ! echo "$add_output" | grep -qi "already"; then
    echo "  ✓ Added: $tool"
    continue
  fi

  existing_url=$(get_plugin_url "$tool")

  if [ "$existing_url" = "$REPO_URL" ]; then
    echo "  Updating: $tool"
    if asdf plugin update "$tool" 2>&1 | sed 's/^/    /'; then
      echo "    ✓ Updated"
    else
      echo "    ✗ Update failed"
    fi
  else
    echo "  Replacing: $tool (was installed from $existing_url)"
    asdf plugin remove "$tool" 2>&1 | sed 's/^/    /' || true
    if asdf plugin add "$tool" "$REPO_URL" 2>&1 | sed 's/^/    /'; then
      echo "    ✓ Replaced"
    else
      echo "    ✗ Failed"
    fi
  fi
done

echo ""
echo "=========================================="
echo "Installation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. List available versions:  asdf list all <tool>"
echo "  2. Install a version:        asdf install <tool> <version>"
echo "  3. Set global version:       asdf set -u <tool> <version>"
echo ""
echo "Example:"
echo "  asdf list all jq"
echo "  asdf install jq latest"
echo "  asdf set -u jq latest"
echo ""
