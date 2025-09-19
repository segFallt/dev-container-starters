FROM mcr.microsoft.com/vscode/devcontainers/base:0-bullseye

# RUN apt-get update && apt-get install -y

ENV DOCKER_BUILDKIT=1

# 1) Install Node.js, npm, and Mermaid CLI
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash \
    && export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm install 20 \
    && nvm use 20 \
    && nvm alias default 20 \
    && npm install -g @mermaid-js/mermaid-cli

# 2) Install OpenJDK and Graphviz (for PlantUML)
RUN apt-get update \
    && apt-get install -y openjdk-17-jdk graphviz curl \
    && rm -rf /var/lib/apt/lists/*

# 3) Download PlantUML
RUN mkdir plantuml \
    && curl -SLo plantuml/plantuml.jar https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar \
    && chmod +x plantuml/plantuml.jar

# 4) Make Node.js available in PATH for all sessions
ENV PATH="/root/.nvm/versions/node/v20.*/bin:${PATH}"