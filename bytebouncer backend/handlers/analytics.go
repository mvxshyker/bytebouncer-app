package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
	"github.com/mvxshyker/bytebouncer-backend/database"
	"github.com/mvxshyker/bytebouncer-backend/services"
)

func Analytics(db *database.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		deviceID := c.Query("device_id")
		if deviceID == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "device_id required"})
		}

		user, err := database.GetUserByDeviceID(c.Context(), db, deviceID)
		if err == pgx.ErrNoRows {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "device not found"})
		}
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db error"})
		}

		analytics, err := services.GetAnalytics(user.ProfileID)
		if err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "failed to fetch analytics"})
		}

		return c.JSON(analytics)
	}
}
