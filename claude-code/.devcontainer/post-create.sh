#!/bin/bash

# Set up shell aliases
echo "==> Setting up shell aliases..."
cat >> ~/.bashrc <<'EOF'

# OpenTofu/Terraform aliases
alias clauded='claude --dangerously-skip-permissions'

EOF