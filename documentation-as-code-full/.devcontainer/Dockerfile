FROM mcr.microsoft.com/vscode/devcontainers/base:0-bullseye

ARG PLANT_UML_VERSION="1.2025.7"

ENV DOCKER_BUILDKIT=1

# Install only Java and GraphViz (Node.js will be handled by features)
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
        openjdk-17-jdk \
        graphviz \
        curl \
        # Chromium dependencies for Puppeteer
        ca-certificates \
        fonts-liberation \
        libappindicator3-1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgbm1 \
        libgcc1 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        lsb-release \
        wget \
        xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Create PlantUML directory and download jar
RUN mkdir -p /plantuml \
    && curl -SLo /plantuml/plantuml.jar https://github.com/plantuml/plantuml/releases/download/v${PLANT_UML_VERSION}/plantuml-gplv2-${PLANT_UML_VERSION}.jar \
    && chmod +x /plantuml/plantuml.jar \
    && chown -R vscode:vscode /plantuml

# Switch to vscode user
USER vscode
WORKDIR /workspace