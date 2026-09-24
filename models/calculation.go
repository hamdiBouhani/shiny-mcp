package models

import "time"

// --- Shared state for calculation history ---
type Calculation struct {
	Operation string    `json:"operation"`
	A         float64   `json:"a"`
	B         float64   `json:"b"`
	Result    float64   `json:"result"`
	Timestamp time.Time `json:"timestamp"`
}
