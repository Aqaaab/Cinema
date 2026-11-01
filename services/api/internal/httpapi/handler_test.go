package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
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
			if got := recorder.Header().Get("X-Request-ID"); got == "" {
				t.Fatal("expected X-Request-ID header")
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
