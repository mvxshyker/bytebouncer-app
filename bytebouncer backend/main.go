package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/gofiber/fiber/v2"
	"github.com/mvxshyker/bytebouncer-backend/database"
	"github.com/mvxshyker/bytebouncer-backend/handlers"
)

func main() {
	appToken := os.Getenv("APP_TOKEN")

	db, err := database.Connect(os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatalf("db connect: %v", err)
	}
	defer db.Close()

	if err := database.Migrate(db); err != nil {
		log.Fatalf("db migrate: %v", err)
	}

	app := fiber.New()
	app.Use(authMiddleware(appToken))

	app.Get("/healthz", func(c *fiber.Ctx) error {
		return c.SendString("ok")
	})

	api := app.Group("/api")
	api.Post("/onboard", handlers.Onboard(db))
	api.Get("/analytics", handlers.Analytics(db))
	api.Patch("/settings/services", handlers.SettingsServices(db))
	api.Patch("/settings/natives", handlers.SettingsNatives(db))
	api.Patch("/settings/blocklists", handlers.SettingsBlocklists(db))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-quit
		log.Println("shutting down...")
		_ = app.Shutdown()
	}()

	log.Printf("listening on :%s", port)
	if err := app.Listen(":" + port); err != nil {
		log.Fatalf("server: %v", err)
	}
}

func authMiddleware(appToken string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if c.Path() == "/healthz" {
			return c.Next()
		}
		if appToken != "" && c.Get("X-App-Token") != appToken {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "unauthorized"})
		}
		return c.Next()
	}
}
