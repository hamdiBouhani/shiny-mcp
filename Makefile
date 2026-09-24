# Makefile for shiny-mcp-go (Go MCP calculator server)
# Requires GNU Make. On Windows, use Git Bash, WSL, or `choco install make`.

BINARY      := calculator
BINARY_EXE  := $(BINARY).exe
MAIN        := main.go
CLIENT      := client.go

# Go tooling
GO          := go
GOFLAGS     :=

# Default target
.PHONY: all
all: build

# ---- Build ----

.PHONY: build
build: ## Build the server binary
	$(GO) build $(GOFLAGS) -o $(BINARY_EXE) .

.PHONY: build-linux
build-linux: ## Cross-compile for Linux
	GOOS=linux GOARCH=amd64 $(GO) build -o $(BINARY) .

.PHONY: build-mac
build-mac: ## Cross-compile for macOS (Apple Silicon)
	GOOS=darwin GOARCH=arm64 $(GO) build -o $(BINARY) .

.PHONY: clean
clean: ## Remove build artifacts
	rm -f $(BINARY_EXE) $(BINARY)
	$(GO) clean

# ---- Run / Dev ----

.PHONY: run
run: ## Run the server directly (stdio, waits for input)
	$(GO) run .

.PHONY: inspector
inspector: ## Launch the official MCP Inspector against the server
	npx @modelcontextprotocol/inspector $(GO) run .

.PHONY: inspector-bin
inspector-bin: build ## Launch the Inspector against the compiled binary
	npx @modelcontextprotocol/inspector ./$(BINARY_EXE)

.PHONY: client
client: ## Run the Go test client against the server
	$(GO) run $(CLIENT)

# ---- Quality ----

.PHONY: fmt
fmt: ## Format Go source
	$(GO) fmt ./...

.PHONY: vet
vet: ## Run go vet
	$(GO) vet ./...

.PHONY: tidy
tidy: ## Tidy go.mod / go.sum
	$(GO) mod tidy

.PHONY: check
check: fmt vet ## Format + vet

# ---- Info ----

.PHONY: path
path: build ## Print the absolute path of the binary (for Claude Desktop config)
	@echo "Add this to %APPDATA%\\Claude\\claude_desktop_config.json:"
	@echo "  \"command\": \"$(shell pwd | sed 's|/|\\\\|g')\\\\$(BINARY_EXE)\""

.PHONY: help
help: ## Show this help
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'