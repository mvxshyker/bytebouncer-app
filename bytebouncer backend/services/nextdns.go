package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
)

const baseURL = "https://api.nextdns.io"

func apiKey() string { return os.Getenv("NEXTDNS_API_KEY") }

func do(method, path string, body any) ([]byte, int, error) {
	var r io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return nil, 0, err
		}
		r = bytes.NewReader(b)
	}
	req, err := http.NewRequest(method, baseURL+path, r)
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("X-Api-Key", apiKey())
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	data, _ := io.ReadAll(resp.Body)
	return data, resp.StatusCode, nil
}

// CreateProfile creates a new NextDNS profile and returns its ID.
func CreateProfile() (string, error) {
	data, status, err := do("POST", "/profiles", map[string]any{})
	if err != nil {
		return "", err
	}
	if status != 200 && status != 201 {
		return "", fmt.Errorf("nextdns create profile: status %d: %s", status, data)
	}
	var resp struct {
		Data struct {
			ID string `json:"id"`
		} `json:"data"`
	}
	if err := json.Unmarshal(data, &resp); err != nil {
		return "", err
	}
	return resp.Data.ID, nil
}

// EnableBlocklist enables a blocklist on a profile (e.g. "oisd").
func EnableBlocklist(profileID, listID string) error {
	_, status, err := do("POST", fmt.Sprintf("/profiles/%s/privacy/blocklists", profileID),
		map[string]string{"id": listID})
	if err != nil {
		return err
	}
	if status != 200 && status != 201 && status != 204 {
		return fmt.Errorf("nextdns enable blocklist: status %d", status)
	}
	return nil
}

// Analytics holds the response we return to iOS.
type Analytics struct {
	TotalBlocked int      `json:"total_blocked"`
	TopDomains   []Domain `json:"top_domains"`
}

type Domain struct {
	Name    string `json:"name"`
	Queries int    `json:"queries"`
}

// GetAnalytics fetches blocked count + top blocked domains for last 24h.
func GetAnalytics(profileID string) (*Analytics, error) {
	// Status summary
	statusData, statusCode, err := do("GET",
		fmt.Sprintf("/profiles/%s/analytics/status?from=-24h", profileID), nil)
	if err != nil {
		return nil, err
	}
	if statusCode != 200 {
		return nil, fmt.Errorf("nextdns analytics status: %d: %s", statusCode, statusData)
	}
	var statusResp struct {
		Data struct {
			Blocked int `json:"blocked"`
		} `json:"data"`
	}
	if err := json.Unmarshal(statusData, &statusResp); err != nil {
		return nil, err
	}

	// Top blocked domains
	domainData, domainCode, err := do("GET",
		fmt.Sprintf("/profiles/%s/analytics/domains?from=-24h&status=blocked&limit=10", profileID), nil)
	if err != nil {
		return nil, err
	}
	if domainCode != 200 {
		return nil, fmt.Errorf("nextdns analytics domains: %d: %s", domainCode, domainData)
	}
	var domainResp struct {
		Data []struct {
			Name    string `json:"name"`
			Queries int    `json:"queries"`
		} `json:"data"`
	}
	if err := json.Unmarshal(domainData, &domainResp); err != nil {
		return nil, err
	}
	domains := make([]Domain, len(domainResp.Data))
	for i, d := range domainResp.Data {
		domains[i] = Domain{Name: d.Name, Queries: d.Queries}
	}
	return &Analytics{
		TotalBlocked: statusResp.Data.Blocked,
		TopDomains:   domains,
	}, nil
}

// Toggle adds (enabled=true) or removes (enabled=false) an item on a profile sub-path.
// e.g. path = "parentalcontrol/services", id = "instagram"
func Toggle(profileID, subPath, id string, enabled bool) error {
	path := fmt.Sprintf("/profiles/%s/%s", profileID, subPath)
	var status int
	var err error
	if enabled {
		_, status, err = do("POST", path, map[string]string{"id": id})
	} else {
		_, status, err = do("DELETE", fmt.Sprintf("%s/%s", path, id), nil)
	}
	if err != nil {
		return err
	}
	if status != 200 && status != 201 && status != 204 {
		return fmt.Errorf("nextdns toggle %s/%s enabled=%v: status %d", subPath, id, enabled, status)
	}
	return nil
}
