package handlers

import (
	"fmt"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
	"github.com/mvxshyker/bytebouncer-backend/database"
	"github.com/mvxshyker/bytebouncer-backend/services"
)

type onboardRequest struct {
	DeviceID string `json:"device_id"`
}

func Onboard(db *database.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		var req onboardRequest
		if err := c.BodyParser(&req); err != nil || req.DeviceID == "" {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "device_id required"})
		}

		// Idempotent: return existing profile if already onboarded
		existing, err := database.GetUserByDeviceID(c.Context(), db, req.DeviceID)
		if err == nil {
			return c.JSON(fiber.Map{"doh_url": dohURL(existing.ProfileID)})
		}
		if err != pgx.ErrNoRows {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db error"})
		}

		profileID, err := services.CreateProfile()
		if err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "failed to create nextdns profile"})
		}

		// Enable OISD blocklist by default
		if err := services.EnableBlocklist(profileID, "oisd"); err != nil {
			// Non-fatal: log and continue
			c.Context().Logger().Printf("warn: enable oisd: %v", err)
		}

		if err := database.CreateUser(c.Context(), db, req.DeviceID, profileID); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db error"})
		}

		return c.Status(fiber.StatusCreated).JSON(fiber.Map{"doh_url": dohURL(profileID)})
	}
}

func dohURL(profileID string) string {
	return fmt.Sprintf("https://dns.nextdns.io/%s", profileID)
}
