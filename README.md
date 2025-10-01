# VS Code Dev Container: Mermaid & PlantUML

This repository provides a pre‑configured VS Code Dev Container that lets you develop in Go and generate diagrams using both **Mermaid** and **PlantUML** with zero setup on your host machine.

---

## Prerequisites

* **Docker** (Docker Desktop on Windows/macOS or Docker Engine on Linux)
* **Visual Studio Code**
* **Remote - Containers** [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension in VS Code

---

## Getting Started in Dev Container

1. **Clone** this repo:

   ```bash
   git clone [repo git url]
   cd [repo directory]
   ```
2. **Open** the folder in VS Code.
3. Press **F1** → **Dev Containers: Reopen in Container**.
4. VS Code will build the Docker image and start a container with Go, Mermaid CLI, and PlantUML ready.

---

## What's Inside the Container

* **Node.js & npm**
* **Mermaid CLI (`mmdc`)** for rendering Mermaid diagrams
* **OpenJDK 11** and **Graphviz** for PlantUML
* **PlantUML JAR** + `plantuml` wrapper script
* Pre‑installed VS Code extensions:

  * `golang.Go` (Go support)
  * `yzhang.markdown-all-in-one` (Markdown tooling & Mermaid support)
  * `jebbs.plantuml` (PlantUML preview & syntax)

---

## Usage

### Mermaid

Create a diagram file, e.g. `diagram.mermaid`:

```text
graph LR
A --> B
B --> C
```

**Render** from the integrated terminal:
```bash
mmdc -i diagram.mermaid -o diagram.svg
````

For any files with .mermaid extension, open the file, then inside the editor window open the context menu and select the preview option `Mermaid:Preview diagram`.  
This will live update as you make changes.

You can also export the diagram with `Mermaid:Generate image`


### PlantUML

Create a `.puml` file, e.g. `example.puml`:

   ```text
   @startuml
   Alice -> Bob: Hello
   @enduml
   ```

For any files with .puml extension, open the file, then inside the editor window open the context menu and select the preview option `Preview Current Diagram`.  
This will live update as you make changes.

You can also export the diagram with `Export Current Diagram`

---

## Rebuilding the Container

Whenever you update `.devcontainer/Dockerfile` or `.devcontainer/devcontainer.json`:

1. Press **F1** → **Dev Containers: Rebuild and Reopen in Container**.
2. Wait for the build to finish, then you’re ready to code.

