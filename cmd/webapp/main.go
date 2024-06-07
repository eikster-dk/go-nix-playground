package main

import (
	"context"
	"io"
	"log/slog"
	"net"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	ctx := context.Background()
	if err := run(ctx, os.Getenv, os.Stderr); err != nil {
		slog.Error("Unable to run application", "error", err)
		os.Exit(1)
	}
}

type getEnv func(string) string

func getConfig(getEnv getEnv, key, fallback string) string {
	val := getEnv(key)
	if val != "" {
		return val
	}

	return fallback
}

func run(ctx context.Context, getEnv getEnv, stderr io.Writer) error {
	logHandler := slog.NewJSONHandler(stderr, nil)
	jsonLogger := slog.New(logHandler)
	slog.SetDefault(jsonLogger)

	port := getConfig(getEnv, "PORT", "8080")

	srv := NewServer()
	httpServer := &http.Server{
		Addr:    net.JoinHostPort("0.0.0.0", port),
		Handler: srv,
	}

	go func() {
		slog.Info("starting server", "address", httpServer.Addr)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("error listening and serving", "err", err)
		}
	}()

	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		<-ctx.Done()
		shutdownCtx := context.Background()
		shutdownCtx, cancel := context.WithTimeout(shutdownCtx, 30*time.Second)
		defer cancel()
		if err := httpServer.Shutdown(shutdownCtx); err != nil {
			slog.Error("error shutting down http server", "err", err)
		}
	}()
	wg.Wait()

	return nil
}

func NewServer() http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.Logger)

	addRoutes(r)
	return r
}

func addRoutes(r *chi.Mux) {
	r.Get("/*", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello flake"))
	})
}
