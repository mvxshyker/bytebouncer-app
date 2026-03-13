package handlers

import (
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
	"github.com/mvxshyker/bytebouncer-backend/database"
	"github.com/mvxshyker/bytebouncer-backend/services"
)

type settingsRequest struct {
	DeviceID string `json:"device_id"`
	Enabled  bool   `json:"enabled"`
}

// lookupProfile parses the request body and resolves the NextDNS profile ID.
func lookupProfile(c *fiber.Ctx, db *database.Pool) (profileID string, enabled bool, ok bool) {
	var req settingsRequest
	if err := c.BodyParser(&req); err != nil || req.DeviceID == "" {
		c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "device_id required"})
		return "", false, false
	}
	user, err := database.GetUserByDeviceID(c.Context(), db, req.DeviceID)
	if err == pgx.ErrNoRows {
		c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "device not found"})
		return "", false, false
	}
	if err != nil {
		c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db error"})
		return "", false, false
	}
	return user.ProfileID, req.Enabled, true
}

// SettingsServices toggles social media blocking (instagram, tiktok, youtube, facebook).
func SettingsServices(db *database.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		profileID, enabled, ok := lookupProfile(c, db)
		if !ok {
			return nil
		}
		ids := []string{"instagram", "tiktok", "youtube", "facebook"}
		for _, id := range ids {
			if err := services.Toggle(c.Context(), profileID, "parentalcontrol/services", id, enabled); err != nil {
				log.Printf("error: toggle services/%s: %v", id, err)
				return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "failed to update settings"})
			}
		}
		return c.JSON(fiber.Map{"ok": true})
	}
}

// SettingsNatives toggles analytics/crash reporting (apple).
func SettingsNatives(db *database.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		profileID, enabled, ok := lookupProfile(c, db)
		if !ok {
			return nil
		}
		if err := services.Toggle(c.Context(), profileID, "privacy/natives", "apple", enabled); err != nil {
			log.Printf("error: toggle natives/apple: %v", err)
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "failed to update settings"})
		}
		return c.JSON(fiber.Map{"ok": true})
	}
}

// SettingsBlocklists toggles ad network blocking (adguard).
func SettingsBlocklists(db *database.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		profileID, enabled, ok := lookupProfile(c, db)
		if !ok {
			return nil
		}
		if err := services.Toggle(c.Context(), profileID, "privacy/blocklists", "adguard", enabled); err != nil {
			log.Printf("error: toggle blocklists/adguard: %v", err)
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "failed to update settings"})
		}
		return c.JSON(fiber.Map{"ok": true})
	}
}
