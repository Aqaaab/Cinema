package httpapi
import("encoding/json";"net/http";"net/http/httptest";"testing")
func TestHealth(t *testing.T){for _,p:=range []string{"/healthz","/readyz"}{t.Run(p,func(t *testing.T){w:=httptest.NewRecorder();r:=httptest.NewRequest(http.MethodGet,p,nil);New().ServeHTTP(w,r);if w.Code!=200{t.Fatalf("status %d",w.Code)};if w.Header().Get("X-Request-ID")==""{t.Fatal("missing request id")};var v health;if e:=json.Unmarshal(w.Body.Bytes(),&v);e!=nil{t.Fatal(e)};if v.Status!="ok"||v.Service!="cinema-api"{t.Fatalf("unexpected: %+v",v)}})}}
func TestPostNotAllowed(t *testing.T){w:=httptest.NewRecorder();r:=httptest.NewRequest(http.MethodPost,"/healthz",nil);New().ServeHTTP(w,r);if w.Code!=http.StatusMethodNotAllowed{t.Fatalf("got %d",w.Code)}}
