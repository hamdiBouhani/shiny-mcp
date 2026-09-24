package main

import (
	"context"
	"fmt"
	"os"

	"github.com/mark3labs/mcp-go/mcp"
	"github.com/mark3labs/mcp-go/server"
)

func main() {
	// Create MCP server
	s := server.NewMCPServer(
		"calculator",
		"1.0.0",
		server.WithToolCapabilities(false),
	)

	// Define the "add" tool
	tool := mcp.NewTool("add",
		mcp.WithDescription("Add two numbers together"),
		mcp.WithNumber("a", mcp.Required(), mcp.Description("First number")),
		mcp.WithNumber("b", mcp.Required(), mcp.Description("Second number")),
	)

	// Register the handler
	s.AddTool(tool, addHandler)

	// Start over stdio (for local AI clients)
	if err := server.ServeStdio(s); err != nil {
		fmt.Fprintf(os.Stderr, "Server error: %v\n", err)
		os.Exit(1)
	}
}

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
	return mcp.NewToolResultText(fmt.Sprintf("%g + %g = %g", a, b, result)), nil
}
