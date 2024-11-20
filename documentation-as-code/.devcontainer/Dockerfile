FROM mcr.microsoft.com/vscode/devcontainers/base:0-bullseye

# RUN apt-get update && apt-get install -y

ENV DOCKER_BUILDKIT=1

RUN sudo apt-get update \
    && sudo apt-get upgrade -y \
    && sudo apt-get install openjdk-17-jdk -y \
	&& sudo apt-get install graphviz -y \
    && sudo apt-get autoremove -y

RUN mkdir plantuml \
    && curl -SLo plantuml/plantuml.jar https://github.com/plantuml/plantuml/releases/download/v1.2024.7/plantuml-1.2024.7.jar \
    && chmod +x plantuml/plantuml.jar