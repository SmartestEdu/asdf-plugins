#!/usr/bin/env bash

set -euo pipefail

# test-all.sh - Test all asdf plugins by installing latest versions and checking them

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Tool configurations: tool_name:version_command:version_arg
declare -A TOOLS=(
  ["jq"]="--version"
  ["yq"]="--version"
  ["kubectl"]="version --client"
  ["kustomize"]="version --short"
  ["kops"]="version"
  ["kubeseal"]="--version"
  ["kubeconform"]="-v"
  ["minikube"]="version"
  ["github-cli"]="--version"
  ["jwt-cli"]="--version"
  ["overmind"]="--version"
  ["sinker"]="--version"
  ["caddy"]="version"
  ["nodejs"]="--version"
  ["tmux"]="-V"
)

# Tools that need special handling or are slow to install
SKIP_TOOLS=("awscli" "aws-iam-authenticator" "amazon-ecr-credential-helper")

echo "=========================================="
echo "asdf-plugins Test Script"
echo "=========================================="
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

for tool in "${!TOOLS[@]}"; do
  echo ""
  echo -e "${YELLOW}Testing: $tool${NC}"
  echo "----------------------------------------"

  # List versions
  echo -n "  Listing versions... "
  if VERSIONS=$(asdf list all "$tool" 2>&1 | tail -3); then
    echo -e "${GREEN}✓${NC}"
    echo "    Latest versions: $(echo "$VERSIONS" | tr '\n' ' ')"
  else
    echo -e "${RED}✗${NC}"
    echo "    Error: $VERSIONS"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    continue
  fi

  # Get latest version
  LATEST=$(asdf list all "$tool" 2>&1 | tail -1)
  echo "  Latest version: $LATEST"

  # Install
  echo -n "  Installing $tool $LATEST... "
  if asdf install "$tool" "$LATEST" 2>&1 | grep -q "Installed\|already installed"; then
    echo -e "${GREEN}✓${NC}"
  else
    echo -e "${RED}✗${NC}"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    continue
  fi

  # Get install path
  INSTALL_PATH=$(asdf where "$tool" "$LATEST" 2>/dev/null)

  # Find binary
  if [ -f "$INSTALL_PATH/bin/$tool" ]; then
    BINARY="$INSTALL_PATH/bin/$tool"
  elif [ "$tool" = "github-cli" ] && [ -f "$INSTALL_PATH/bin/gh" ]; then
    BINARY="$INSTALL_PATH/bin/gh"
  elif [ "$tool" = "jwt-cli" ] && [ -f "$INSTALL_PATH/bin/jwt" ]; then
    BINARY="$INSTALL_PATH/bin/jwt"
  elif [ "$tool" = "nodejs" ] && [ -f "$INSTALL_PATH/bin/node" ]; then
    BINARY="$INSTALL_PATH/bin/node"
  else
    echo -e "  ${YELLOW}⚠${NC}  Could not find binary for $tool"
    SKIP_COUNT=$((SKIP_COUNT + 1))
    continue
  fi

  # Run version command
  VERSION_CMD="${TOOLS[$tool]}"
  echo -n "  Running version command... "
  if OUTPUT=$($BINARY $VERSION_CMD 2>&1 | head -1); then
    echo -e "${GREEN}✓${NC}"
    echo "    Output: $OUTPUT"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    echo -e "${RED}✗${NC}"
    echo "    Error: $OUTPUT"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed: $SUCCESS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo -e "${YELLOW}Skipped: $SKIP_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
