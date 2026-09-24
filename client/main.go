package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/mark3labs/mcp-go/client"
	"github.com/mark3labs/mcp-go/mcp"
)

func main() {
	// Create a client that launches your server as a subprocess
	c, err := client.NewStdioMCPClient("go", []string{}, "run", "C:\\Users\\bouha\\OneDrive\\Documents\\GitHub\\shiny-mcp\\main.go")
	if err != nil {
		log.Fatal(err)
	}
	defer c.Close()

	ctx := context.Background()

	initRequest := mcp.InitializeRequest{}
	initRequest.Params.ProtocolVersion = mcp.LATEST_PROTOCOL_VERSION
	initRequest.Params.ClientInfo = mcp.Implementation{
		Name:    "calculator-client",
		Version: "1.0.0",
	}

	initializeResult, err := c.Initialize(ctx, initRequest)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(initializeResult.ServerInfo)

	// CRITICAL FIX: Give the background reader goroutine time to start.
	// This works around a known race condition in mcp-go (issue #722).
	time.Sleep(500 * time.Millisecond)

	// Call the "add" tool with a=5, b=3
	callRequest := mcp.CallToolRequest{}
	callRequest.Params.Name = "add"
	callRequest.Params.Arguments = map[string]any{
		"a": 5.0,
		"b": 3.0,
	}

	result, err := c.CallTool(ctx, callRequest)
	if err != nil {
		log.Fatalf("CallTool failed: %v", err)
	}

	// Print the result
	if result.IsError {
		log.Fatalf("Tool returned an error: %+v", result)
	}

	for _, content := range result.Content {
		if text, ok := content.(mcp.TextContent); ok {
			fmt.Println(text.Text) // Should print: 5 + 3 = 8
		}
	}
}
