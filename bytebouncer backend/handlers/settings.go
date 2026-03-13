package handlers

import (
	"github.com/gofiber/fiber/v2"
	"github.com/jackc/pgx/v5"
	"github.com/mvxshyker/bytebouncer-backend/database"
	"github.com/mvxshyker/bytebouncer-backend/services"
)

type settingsRequest struct {
	DeviceID string `json:"device_id"`
	Enabled  bool   `json:"enabled"`
}

// lookupProfile is a shared helper: parse body, find profile, return (profileID, error response sent).
func lookupProfile(c *fiber.Ctx, db *database.Pool) (string, bool) {
	var req settingsRequest
	if err := c.BodyParser(&req); err != nil || req.DeviceID == "" {
		c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "device_id required"})
		return "", false
	}
	user, err := database.GetUserByDeviceID(c.Context(), db, req.DeviceID)
	if err == pgx.ErrNoRows {
		c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "device not found"})
		return "", false
	}
	if err != nil {
		c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "db error"})
		return "", false
	}
	_ = req // enabled is read again per handler — store it on context via Locals
	c.Locals("enabled", req.Enabled)
	return user.ProfileID, true
}

// SettingsServices toggles social media blocking (instagram, tiktok, youtube, facebook).
func SettingsServices(db *database.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		profileID, ok := lookupProfile(c, db)
		if !ok {
			return nil
		}
		enabled := c.Locals("enabled").(bool)
		ids := []string{"instagram", "tiktok", "youtube", "facebook"}
		for _, id := range ids {
			if err := services.Toggle(profileID, "parentalcontrol/services", id, enabled); err != nil {
				return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "nextdns error: " + err.Error()})
			}
		}
		return c.JSON(fiber.Map{"ok": true})
	}
}

// SettingsNatives toggles analytics/crash reporting (apple).
func SettingsNatives(db *database.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		profileID, ok := lookupProfile(c, db)
		if !ok {
			return nil
		}
		enabled := c.Locals("enabled").(bool)
		if err := services.Toggle(profileID, "privacy/natives", "apple", enabled); err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "nextdns error: " + err.Error()})
		}
		return c.JSON(fiber.Map{"ok": true})
	}
}

// SettingsBlocklists toggles ad network blocking (adguard).
func SettingsBlocklists(db *database.Pool) fiber.Handler {
	return func(c *fiber.Ctx) error {
		profileID, ok := lookupProfile(c, db)
		if !ok {
			return nil
		}
		enabled := c.Locals("enabled").(bool)
		if err := services.Toggle(profileID, "privacy/blocklists", "adguard", enabled); err != nil {
			return c.Status(fiber.StatusBadGateway).JSON(fiber.Map{"error": "nextdns error: " + err.Error()})
		}
		return c.JSON(fiber.Map{"ok": true})
	}
}
