FROM mcr.microsoft.com/vscode/devcontainers/base:0-bullseye

ENV DOCKER_BUILDKIT=1

# Install only Java and GraphViz (Node.js will be handled by features)
RUN apt-get update \
    && apt-get install -y openjdk-17-jdk graphviz curl \
    && rm -rf /var/lib/apt/lists/*

# Create PlantUML directory and download jar
RUN mkdir -p /plantuml \
    && curl -SLo /plantuml/plantuml.jar https://github.com/plantuml/plantuml/releases/download/v1.2025.7/plantuml-gplv2-1.2025.7.jar \
    && chmod +x /plantuml/plantuml.jar \
    && chown -R vscode:vscode /plantuml

# Switch to vscode user
USER vscode
WORKDIR /workspace