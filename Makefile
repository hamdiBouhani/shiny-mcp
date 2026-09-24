# Makefile for shiny-mcp-go (Go MCP calculator server)
# Requires GNU Make. On Windows, use Git Bash, WSL, or `choco install make`.

BINARY      := calculator
BINARY_EXE  := $(BINARY).exe
MAIN        := main.go
CLIENT      := ./client/main.go

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
inspector: ## Launch the official MCP Inspector against the source
	npx @modelcontextprotocol/inspector $(GO) run .

.PHONY: inspector-bin
inspector-bin: build ## Launch the Inspector against the compiled binary
	npx @modelcontextprotocol/inspector ./$(BINARY_EXE)

.PHONY: client
client: ## Run the Go test client against the server
	$(GO) run $(CLIENT)

# ---- Testing the New Primitives ----

.PHONY: test-tool
test-tool: ## Test the 'add' tool (prints instructions, then opens Inspector)
	@echo "=== Testing TOOL: add ==="
	@echo "1. In the Inspector, click 'Connect'"
	@echo "2. Go to the 'Tools' tab"
	@echo "3. Select 'add'"
	@echo "4. Enter a=5, b=3"
	@echo "5. Click 'Run Tool'"
	@echo "6. Expected result: 5 + 3 = 8"
	@echo ""
	@echo "Launching Inspector..."
	@$(MAKE) inspector

.PHONY: test-resource
test-resource: ## Test the 'calculator://history' resource
	@echo "=== Testing RESOURCE: calculator://history ==="
	@echo "1. In the Inspector, click 'Connect'"
	@echo "2. Go to the 'Resources' tab"
	@echo "3. You should see 'calculator://history' listed"
	@echo "4. Click 'Read' -- you'll see [] (empty, no calculations yet)"
	@echo "5. Go to the 'Tools' tab, run 'add' with a=5, b=3"
	@echo "6. Return to 'Resources' and click 'Read' again"
	@echo "7. You should now see the calculation recorded"
	@echo ""
	@echo "Launching Inspector..."
	@$(MAKE) inspector

.PHONY: test-prompt
test-prompt: ## Test the 'calculate_prompt' prompt
	@echo "=== Testing PROMPT: calculate_prompt ==="
	@echo "1. In the Inspector, click 'Connect'"
	@echo "2. Go to the 'Prompts' tab"
	@echo "3. Select 'calculate_prompt'"
	@echo "4. Enter expression='5 + 3', detail='detailed'"
	@echo "5. Click 'Get Prompt'"
	@echo "6. You should see a formatted instruction message"
	@echo ""
	@echo "Launching Inspector..."
	@$(MAKE) inspector

.PHONY: test-all
test-all: ## Print the full primitive testing walkthrough
	@echo "==============================================="
	@echo "  Testing all three MCP primitives"
	@echo "==============================================="
	@echo ""
	@echo "First, launch the Inspector (in another terminal):"
	@echo "  make inspector"
	@echo ""
	@echo "--- 1. TOOL: add ---"
	@echo "  Connect -> Tools tab -> select 'add'"
	@echo "  Enter a=5, b=3 -> Run Tool"
	@echo "  Expected: 5 + 3 = 8"
	@echo ""
	@echo "--- 2. RESOURCE: calculator://history ---"
	@echo "  Connect -> Resources tab -> 'calculator://history' -> Read"
	@echo "  First read: []  (empty)"
	@echo "  After running 'add', read again: shows the calculation"
	@echo ""
	@echo "--- 3. PROMPT: calculate_prompt ---"
	@echo "  Connect -> Prompts tab -> 'calculate_prompt'"
	@echo "  expression='5 + 3', detail='detailed' -> Get Prompt"
	@echo "  Expected: a formatted instruction message"
	@echo ""
	@echo "==============================================="

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