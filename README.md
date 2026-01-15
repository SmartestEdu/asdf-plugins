# asdf-plugins

A unified asdf plugin repository for managing multiple development tools through a single plugin implementation.

## What is this?

This repository provides an asdf plugin that can install and manage multiple tools. Instead of maintaining separate plugin repositories for each tool, this unified plugin uses a dispatcher pattern to route installation requests to tool-specific implementations.

## Supported Tools

This plugin currently supports 22 tools:

**JSON/YAML Processing:**
- `jq` - Command-line JSON processor
- `yq` - YAML processor

**Kubernetes:**
- `kubectl` - Kubernetes command-line tool
- `kustomize` - Kubernetes native configuration management
- `kops` - Kubernetes Operations
- `kubeseal` - Sealed Secrets client-side utility
- `kubeconform` - Kubernetes manifest validation
- `minikube` - Run Kubernetes locally

**AWS:**
- `awscli` - AWS Command Line Interface
- `aws-iam-authenticator` - AWS IAM Authenticator for Kubernetes
- `amazon-ecr-credential-helper` - Amazon ECR Docker Credential Helper

**Development Tools:**
- `nodejs` - JavaScript runtime
- `github-cli` - GitHub's official command line tool (gh)
- `jwt-cli` - JWT encode/decode/sign tool
- `tmux` - Terminal multiplexer
- `overmind` - Process manager for Procfile-based applications

**Other:**
- `caddy` - Fast web server with automatic HTTPS
- `sinker` - Container image sync tool

## Installation

### Quick Install (All Tools)

Install all 18 supported tools with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/SmartestEdu/asdf-plugins/main/install-all.sh | bash
```

Or download and run the script:

```bash
wget https://raw.githubusercontent.com/SmartestEdu/asdf-plugins/main/install-all.sh
chmod +x install-all.sh
./install-all.sh
```

### Manual Installation

Install tools individually by adding this plugin with the tool name:

```bash
# Add the plugin for each tool you want to use
asdf plugin add jq https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add kubectl https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add nodejs https://github.com/SmartestEdu/asdf-plugins.git
# ... etc
```

Then install specific versions:

```bash
# List all available versions
asdf list-all jq

# Install a specific version
asdf install jq 1.7.1

# Set as global version
asdf global jq 1.7.1

# Or set local version for current directory
asdf local jq 1.7.1
```

## Quick Setup for All Tools

To install all supported tools at once:

```bash
# Add all plugins
asdf plugin add jq https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add yq https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add kubectl https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add github-cli https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add awscli https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add kustomize https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add kops https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add kubeseal https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add aws-iam-authenticator https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add minikube https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add kubeconform https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add caddy https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add amazon-ecr-credential-helper https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add jwt-cli https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add overmind https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add sinker https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add tmux https://github.com/SmartestEdu/asdf-plugins.git
asdf plugin add nodejs https://github.com/SmartestEdu/asdf-plugins.git
```

## How It Works

The plugin uses a dispatcher pattern:
1. When you run `asdf plugin add <tool-name> <repo-url>`, asdf creates a directory named after the tool
2. The plugin's scripts detect which tool is being installed by examining the directory name
3. The request is routed to the appropriate tool-specific implementation in `lib/tools/<tool-name>.bash`

This approach allows one repository to support many tools while sharing common code for downloads, extraction, platform detection, and more.

## Platform Support

Most tools support:
- **OS**: macOS (darwin), Linux
- **Architecture**: x86_64 (amd64), ARM64 (arm64)

Some tools may have limited platform support. Check tool-specific documentation for details.

## Environment Variables

### GitHub API Token
Set `GITHUB_API_TOKEN` to avoid rate limiting when querying GitHub releases:
```bash
export GITHUB_API_TOKEN=your_token_here
```

## Development

See [CLAUDE.md](CLAUDE.md) for development documentation, including:
- Architecture overview
- How to add new tools
- Shared utilities reference
- Testing procedures

## License

This repository is maintained by SmartestEdu/Formative for internal development tools.
