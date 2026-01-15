# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a **unified asdf plugin repository** that provides a single plugin capable of installing multiple development tools. Instead of maintaining separate plugin repositories for each tool, this repository uses a dispatcher pattern to route installation requests to tool-specific implementations.

Users add this plugin multiple times with different names (e.g., `asdf plugin add jq <repo-url>`), and the plugin automatically detects which tool is being installed based on the directory name where asdf places it.

## Architecture

### Unified Plugin Pattern

The repository follows a dispatcher/router architecture:

```
asdf-plugins/
├── bin/                    # Main dispatcher scripts
│   ├── list-all           # Routes to tool-specific list_all_versions()
│   ├── download           # Routes to tool-specific download_tool()
│   └── install            # Routes to tool-specific install_tool()
├── lib/
│   ├── utils.bash         # Shared utility functions
│   └── tools/             # Tool-specific implementations
│       ├── jq.bash
│       ├── yq.bash
│       ├── kubectl.bash
│       └── ... (one file per tool)
└── README.md
```

### How Tool Detection Works

The dispatcher scripts determine which tool is being installed by:
1. Getting the script's directory: `script_dir="$(dirname "${BASH_SOURCE[0]}")"`
2. Getting the parent directory: `plugin_dir="$(dirname "$script_dir")"`
3. Extracting the tool name: `tool_name="$(basename "$plugin_dir")"`
4. Sourcing the tool-specific implementation: `source "${plugin_dir}/lib/tools/${tool_name}.bash"`

This is the same pattern used by carvel-dev/asdf and allows one plugin repository to support multiple tools.

## Development Workflow

### Adding a New Tool

1. Create a new file in `lib/tools/` named `<tool>.bash`
2. Implement three required functions:
   ```bash
   list_all_versions() {
     # Output space-separated list of versions
   }

   download_tool() {
     local install_type="$1"
     local version="$2"
     local download_path="$3"
     # Download to $download_path
   }

   install_tool() {
     local install_type="$1"
     local version="$2"
     local download_path="$3"
     local install_path="$4"
     # Install from $download_path to $install_path
   }
   ```
3. Use shared utilities from `lib/utils.bash` (already sourced)
4. Test locally: `asdf plugin add <tool-name> /home/dobes/projects/formative/asdf-plugins`

### Key Environment Variables

When asdf executes plugin scripts, it provides these environment variables:
- `ASDF_INSTALL_VERSION` - The version being installed
- `ASDF_INSTALL_PATH` - Where the tool should be installed
- `ASDF_DOWNLOAD_PATH` - Where downloads are staged
- `ASDF_INSTALL_TYPE` - Usually "version", but can be "ref" for git refs

### Testing Plugins

Test plugins locally before committing:
```bash
# Add plugin from local path
asdf plugin add <tool-name> /home/dobes/projects/formative/asdf-plugins/asdf-<tool-name>

# List available versions
asdf list-all <tool-name>

# Install a version
asdf install <tool-name> <version>

# Verify installation
asdf which <tool-name>

# Remove test plugin
asdf plugin remove <tool-name>
```

## Shared Utilities (`lib/utils.bash`)

The utils library provides common functions for tool implementations:

### Version Management
- `list_github_versions <repo> [filter]` - List versions from GitHub releases API
- `list_git_versions <repo> [filter]` - List versions from git tags
- `sort_versions` - Semantic version sorting
- `get_latest_version <repo>` - Get latest version from GitHub

### Platform Detection
- `get_os()` - Returns "darwin" or "linux"
- `get_arch()` - Returns "amd64", "arm64", "386", or "arm"
- `get_platform()` - Returns combined "os_arch" format

### Download & Extract
- `download_file <url> <dest>` - Download file with curl
- `extract_tar_gz <archive> [dest]` - Extract tar.gz archive
- `extract_zip <archive> [dest]` - Extract zip archive
- `curl_wrapper` - curl with proper User-Agent header

### Installation
- `install_binary <src> <dest> <name>` - Copy and make executable
- `error_exit <message> [code]` - Exit with error message

### GitHub API
- `github_releases <repo>` - Query GitHub releases (respects GITHUB_API_TOKEN)

## Supported Tools

Currently implemented tools (22 tools):
- `jq` - JSON processor
- `yq` - YAML processor
- `kubectl` - Kubernetes CLI
- `github-cli` - GitHub CLI (gh)
- `awscli` - AWS CLI
- `kustomize` - Kubernetes configuration management
- `kops` - Kubernetes operations
- `kubeseal` - Sealed Secrets client
- `aws-iam-authenticator` - AWS IAM authenticator for Kubernetes
- `minikube` - Local Kubernetes
- `kubeconform` - Kubernetes manifest validation
- `caddy` - Web server with automatic HTTPS
- `amazon-ecr-credential-helper` - ECR credential helper
- `jwt-cli` - JWT encode/decode tool
- `overmind` - Process manager
- `sinker` - Container image sync tool
- `tmux` - Terminal multiplexer (compiled from source)
- `nodejs` - Node.js runtime

## Code Conventions

- Use `#!/usr/bin/env bash` shebang for shell scripts
- Always `set -euo pipefail` for strict error handling
- Use shared utilities from `lib/utils.bash` (no need to source, already loaded)
- Handle errors explicitly - use `error_exit` for fatal errors
- Follow naming conventions: `list_all_versions`, `download_tool`, `install_tool`
- Test with multiple architectures when possible (amd64, arm64)
