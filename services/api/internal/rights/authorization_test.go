package rights

import (
	"errors"
	"testing"
	"time"
)

func validGrant() Grant {
	return Grant{
		Status:          StatusApproved,
		Licensor:        "Example Rights Holder",
		EvidenceURL:     "https://rights.example.org/grants/123",
		ValidFrom:       time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
		ValidUntil:      time.Date(2027, 1, 1, 0, 0, 0, 0, time.UTC),
		Territories:     []string{"US", "GB"},
		PermittedMethod: []string{MethodEmbed},
	}
}

func TestAuthorize(t *testing.T) {
	now := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)
	tests := []struct {
		name      string
		grant     Grant
		territory string
		method    string
		wantErr   error
	}{
		{name: "approved grant", grant: validGrant(), territory: "us", method: MethodEmbed},
		{name: "pending grant", grant: func() Grant { g := validGrant(); g.Status = "pending"; return g }(), territory: "US", method: MethodEmbed, wantErr: ErrNotApproved},
		{name: "not started", grant: func() Grant { g := validGrant(); g.ValidFrom = now.Add(time.Hour); return g }(), territory: "US", method: MethodEmbed, wantErr: ErrNotYetValid},
		{name: "expired", grant: func() Grant { g := validGrant(); g.ValidUntil = now; return g }(), territory: "US", method: MethodEmbed, wantErr: ErrExpired},
		{name: "wrong territory", grant: validGrant(), territory: "DE", method: MethodEmbed, wantErr: ErrTerritory},
		{name: "method not permitted", grant: validGrant(), territory: "US", method: MethodDirect, wantErr: ErrMethod},
		{name: "missing evidence", grant: func() Grant { g := validGrant(); g.EvidenceURL = ""; return g }(), territory: "US", method: MethodEmbed, wantErr: ErrIncompleteGrant},
		{name: "non HTTPS evidence", grant: func() Grant { g := validGrant(); g.EvidenceURL = "http://rights.example.org/grants/123"; return g }(), territory: "US", method: MethodEmbed, wantErr: ErrIncompleteGrant},
		{name: "missing expiry", grant: func() Grant { g := validGrant(); g.ValidUntil = time.Time{}; return g }(), territory: "US", method: MethodEmbed, wantErr: ErrIncompleteGrant},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			err := test.grant.Authorize(now, test.territory, test.method)
			if test.wantErr == nil && err != nil {
				t.Fatalf("Authorize() error = %v, want nil", err)
			}
			if test.wantErr != nil && !errors.Is(err, test.wantErr) {
				t.Fatalf("Authorize() error = %v, want %v", err, test.wantErr)
			}
		})
	}
}
