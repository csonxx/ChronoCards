// Package main is the entry point for the ChronoCards WebSocket server.
package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/csonxx/ChronoCards/server/narrative"
	"github.com/csonxx/ChronoCards/server/ws"
)

func main() {
	addr := flag.String("addr", ":8080", "WebSocket server address")
	jwtSecret := flag.String("jwt-secret", "chronocards-secret-key-change-in-production", "JWT secret key")
	flag.Parse()

	// Initialize LLM narrative service
	narrativeSvc := narrative.NewNarrativeService("")
	log.Printf("[Narrative] LLM service initialized (MINIMAX_API_KEY env var: %v)", os.Getenv("MINIMAX_API_KEY") != "")

	handler := ws.NewHandler(*jwtSecret, narrativeSvc)

	// Graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		sigCh := make(chan os.Signal, 1)
		signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
		<-sigCh
		log.Println("[WS] Shutting down...")
		cancel()
		shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer shutdownCancel()
		handler.Shutdown(shutdownCtx)
		os.Exit(0)
	}()

	log.Printf("[WS] ChronoCards WebSocket server starting on %s", *addr)
	if err := handler.Run(*addr); err != nil {
		log.Fatalf("[WS] Server error: %v", err)
	}

	<-ctx.Done()
}
