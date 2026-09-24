package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/hamdiBouhani/shiny-mcp/models"
	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

var (
	historyMu sync.Mutex
	history   []models.Calculation
)

func main() {
	s := server.NewMCPServer(
		"calculator",
		"1.0.0",
		server.WithToolCapabilities(false),
		// Enable resources with subscribe support (for future use)
		server.WithResourceCapabilities(true, true),
		// Enable prompts
		server.WithPromptCapabilities(true),
	)

	// --- Tool: add ---
	addTool := mcp.NewTool("add",
		mcp.WithDescription("Add two numbers together"),
		mcp.WithNumber("a", mcp.Required(), mcp.Description("First number")),
		mcp.WithNumber("b", mcp.Required(), mcp.Description("Second number")),
	)
	s.AddTool(addTool, addHandler)

	// --- Resource: calculator://history ---
	s.AddResource(
		mcp.NewResource(
			"calculator://history",
			"Calculation History",
			mcp.WithResourceDescription("List of all calculations performed in this session"),
			mcp.WithMIMEType("application/json"),
		),
		historyResourceHandler,
	)

	// --- Prompt: calculate_prompt ---
	calcPrompt := mcp.NewPrompt("calculate_prompt",
		mcp.WithPromptDescription("Generate a prompt for analyzing a math expression"),
		mcp.WithArgument("expression",
			mcp.RequiredArgument(),
			mcp.ArgumentDescription("The math expression to analyze (e.g., '5 + 3')"),
		),
		mcp.WithArgument("detail",
			mcp.ArgumentDescription("Level of detail: basic or detailed"),
		),
	)
	s.AddPrompt(calcPrompt, calculatePromptHandler)

	// Start over stdio
	if err := server.ServeStdio(s); err != nil {
		fmt.Fprintf(os.Stderr, "Server error: %v\n", err)
		os.Exit(1)
	}
}

// --- Tool handler ---
func addHandler(ctx context.Context, request mcp.CallToolRequest) (*mcp.CallToolResult, error) {
	a, err := request.RequireFloat("a")
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}
	b, err := request.RequireFloat("b")
	if err != nil {
		return mcp.NewToolResultError(err.Error()), nil
	}

	result := a + b

	// Record in history (thread-safe)
	historyMu.Lock()
	history = append(history, models.Calculation{
		Operation: "add",
		A:         a,
		B:         b,
		Result:    result,
		Timestamp: time.Now(),
	})
	historyMu.Unlock()

	return mcp.NewToolResultText(fmt.Sprintf("%g + %g = %g", a, b, result)), nil
}

// --- Resource handler ---
func historyResourceHandler(ctx context.Context, request mcp.ReadResourceRequest) ([]mcp.ResourceContents, error) {
	historyMu.Lock()
	snapshot := make([]models.Calculation, len(history))
	copy(snapshot, history)
	historyMu.Unlock()

	data, err := json.MarshalIndent(snapshot, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("failed to marshal history: %w", err)
	}

	return []mcp.ResourceContents{
		mcp.TextResourceContents{
			URI:      request.Params.URI,
			MIMEType: "application/json",
			Text:     string(data),
		},
	}, nil
}

// --- Prompt handler ---
func calculatePromptHandler(ctx context.Context, request mcp.GetPromptRequest) (*mcp.GetPromptResult, error) {
	expression, ok := request.Params.Arguments["expression"]
	if !ok || expression == "" {
		return nil, fmt.Errorf("expression argument is required")
	}

	// Optional argument with a default
	detail := request.Params.Arguments["detail"]
	if detail == "" {
		detail = "basic"
	}

	var instruction string
	if detail == "detailed" {
		instruction = fmt.Sprintf(
			"Please analyze the following math expression step by step, explaining each operation and verifying the result:\n\n%s",
			expression,
		)
	} else {
		instruction = fmt.Sprintf(
			"Calculate and explain the following expression:\n\n%s",
			expression,
		)
	}

	return mcp.NewGetPromptResult(
		fmt.Sprintf("Analysis for %s", expression),
		[]mcp.PromptMessage{
			mcp.NewPromptMessage(
				mcp.RoleUser,
				mcp.NewTextContent(instruction),
			),
		},
	), nil
}
