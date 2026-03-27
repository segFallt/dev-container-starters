#!/bin/bash

echo "==> Setting up Ruflo..."
curl -fsSL https://cdn.jsdelivr.net/gh/ruvnet/ruflo@main/scripts/install.sh | bash

echo "==> Setting Ruflo MCP..."
claude mcp add ruflo -- npx -y ruflo@latest mcp start

echo "==> Listing Claude mcp..."
claude mcp list