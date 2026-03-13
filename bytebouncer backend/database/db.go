package database

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Pool = pgxpool.Pool

func Connect(dsn string) (*Pool, error) {
	if dsn == "" {
		return nil, fmt.Errorf("DATABASE_URL is not set")
	}
	pool, err := pgxpool.New(context.Background(), dsn)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(context.Background()); err != nil {
		return nil, err
	}
	return pool, nil
}

func Migrate(db *Pool) error {
	_, err := db.Exec(context.Background(), `
		CREATE TABLE IF NOT EXISTS users (
			id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			device_id          VARCHAR UNIQUE NOT NULL,
			nextdns_profile_id VARCHAR NOT NULL,
			created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
		)
	`)
	return err
}

type User struct {
	DeviceID  string
	ProfileID string
}

func GetUserByDeviceID(ctx context.Context, db *Pool, deviceID string) (*User, error) {
	row := db.QueryRow(ctx,
		`SELECT device_id, nextdns_profile_id FROM users WHERE device_id = $1`, deviceID)
	u := &User{}
	if err := row.Scan(&u.DeviceID, &u.ProfileID); err != nil {
		return nil, err
	}
	return u, nil
}

func CreateUser(ctx context.Context, db *Pool, deviceID, profileID string) error {
	_, err := db.Exec(ctx,
		`INSERT INTO users (device_id, nextdns_profile_id) VALUES ($1, $2)
		 ON CONFLICT (device_id) DO NOTHING`,
		deviceID, profileID)
	return err
}
