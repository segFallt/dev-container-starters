#!/bin/bash


# Set up shell aliases
echo "==> Setting up shell aliases..."
cat >> ~/.bashrc <<'EOF'

# Claude Code aliases
alias clauded='claude --dangerously-skip-permissions'

EOF

echo "==> Adding project-workflow marketplace..."
claude plugin marketplace add https://github.com/segFallt/project-workflow-claude-plugin.git

# Temporary fix to use npx for claude code cache bug
echo "alias claude='npx -y @anthropic-ai/claude-code'" >> ~/.bashrc
source ~/.bashrc