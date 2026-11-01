package rights

import (
	"errors"
	"net/url"
	"strings"
	"time"
)

const (
	StatusApproved = "approved"
	MethodEmbed    = "official_embed"
	MethodDirect   = "direct_playback"
	MethodDownload = "download"
	MethodCache    = "cache"
)

var (
	ErrIncompleteGrant = errors.New("rights grant is incomplete")
	ErrNotApproved     = errors.New("rights grant is not approved")
	ErrNotYetValid     = errors.New("rights grant is not active yet")
	ErrExpired         = errors.New("rights grant has expired")
	ErrTerritory       = errors.New("playback is not authorized in this territory")
	ErrMethod          = errors.New("playback method is not permitted")
)

// Grant is the minimum authorization record required before an asset can be played.
// A missing field is a denial, never an implicit permission.
type Grant struct {
	Status          string
	Licensor        string
	EvidenceURL     string
	ValidFrom       time.Time
	ValidUntil      time.Time
	Territories     []string
	PermittedMethod []string
}

// Authorize checks the rights grant at the moment of playback.
// The caller must supply the viewer's resolved ISO-3166-1 alpha-2 territory.
func (g Grant) Authorize(now time.Time, territory, method string) error {
	if strings.TrimSpace(g.Licensor) == "" || !isHTTPSURL(g.EvidenceURL) ||
		g.ValidFrom.IsZero() || g.ValidUntil.IsZero() ||
		!g.ValidUntil.After(g.ValidFrom) || len(g.Territories) == 0 ||
		len(g.PermittedMethod) == 0 {
		return ErrIncompleteGrant
	}

	if g.Status != StatusApproved {
		return ErrNotApproved
	}
	if now.Before(g.ValidFrom) {
		return ErrNotYetValid
	}
	if !now.Before(g.ValidUntil) {
		return ErrExpired
	}
	if !containsFold(g.Territories, territory) {
		return ErrTerritory
	}
	if !containsFold(g.PermittedMethod, method) {
		return ErrMethod
	}

	return nil
}

func isHTTPSURL(raw string) bool {
	parsed, err := url.ParseRequestURI(strings.TrimSpace(raw))
	return err == nil && parsed.Scheme == "https" && parsed.Host != ""
}

func containsFold(values []string, target string) bool {
	target = strings.TrimSpace(target)
	if target == "" {
		return false
	}
	for _, value := range values {
		if strings.EqualFold(strings.TrimSpace(value), target) {
			return true
		}
	}
	return false
}
