package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/mvxshyker/bytebouncer-backend/database"
	"github.com/mvxshyker/bytebouncer-backend/handlers"
)

func main() {
	db, err := database.Connect(os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatalf("db connect: %v", err)
	}
	defer db.Close()

	if err := database.Migrate(db); err != nil {
		log.Fatalf("db migrate: %v", err)
	}

	app := fiber.New()
	app.Use(authMiddleware)

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
	log.Fatal(app.Listen(":" + port))
}

func authMiddleware(c *fiber.Ctx) error {
	token := os.Getenv("APP_TOKEN")
	if token != "" && c.Get("X-App-Token") != token {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "unauthorized"})
	}
	return c.Next()
}
