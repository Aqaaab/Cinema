package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestHealthEndpoints(t *testing.T) {
	handler := New()
	paths := []string{"/healthz", "/readyz", "/v1/health"}

	for _, path := range paths {
		t.Run(path, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, path, nil)
			recorder := httptest.NewRecorder()

			handler.ServeHTTP(recorder, req)

			if recorder.Code != http.StatusOK {
				t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
			}
			if got := recorder.Header().Get("Content-Type"); got != "application/json; charset=utf-8" {
				t.Fatalf("Content-Type = %q", got)
			}
			if got := recorder.Header().Get("X-Content-Type-Options"); got != "nosniff" {
				t.Fatalf("X-Content-Type-Options = %q", got)
			}
			if got := recorder.Header().Get("X-Request-ID"); !isValidRequestID(got) {
				t.Fatalf("expected valid X-Request-ID header, got %q", got)
			}

			var body healthResponse
			if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
				t.Fatalf("invalid JSON response: %v", err)
			}
			if body.Status != "ok" || body.Service != "cinema-api" {
				t.Fatalf("unexpected response: %+v", body)
			}
		})
	}
}

func TestRequestIDIsPreserved(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	req.Header.Set("X-Request-ID", "test-request-123")
	recorder := httptest.NewRecorder()

	New().ServeHTTP(recorder, req)

	if got := recorder.Header().Get("X-Request-ID"); got != "test-request-123" {
		t.Fatalf("request id = %q, want %q", got, "test-request-123")
	}
}

func TestHealthDoesNotAllowPost(t *testing.T) {
	req := httptest.NewRequest(http.MethodPost, "/healthz", nil)
	recorder := httptest.NewRecorder()

	New().ServeHTTP(recorder, req)

	if recorder.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusMethodNotAllowed)
	}
}

func TestInvalidRequestIDIsReplaced(t *testing.T) {
	invalidIDs := []string{
		"short",
		"bad value",
		"bad\r\nX-Injected: yes",
		strings.Repeat("a", 129),
	}

	for _, invalidID := range invalidIDs {
		t.Run(invalidID, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
			req.Header.Set("X-Request-ID", invalidID)
			recorder := httptest.NewRecorder()

			New().ServeHTTP(recorder, req)

			got := recorder.Header().Get("X-Request-ID")
			if got == invalidID {
				t.Fatalf("invalid request id was preserved: %q", got)
			}
			if !isValidRequestID(got) {
				t.Fatalf("replacement request id is invalid: %q", got)
			}
		})
	}
}
