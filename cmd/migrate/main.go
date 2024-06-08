package main

import (
	"context"
	"io"
	"log/slog"
	"os"
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
	slog.Info("performed migration...")

	return nil
}
