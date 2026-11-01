package httpapi
import("crypto/rand";"encoding/hex";"encoding/json";"net/http")
type health struct{Status string `json:"status"`;Service string `json:"service"`}
func New()http.Handler{m:=http.NewServeMux();m.HandleFunc("GET /healthz",healthHandler);m.HandleFunc("GET /readyz",healthHandler);return requestID(security(m))}
func healthHandler(w http.ResponseWriter,r *http.Request){w.Header().Set("Content-Type","application/json; charset=utf-8");w.Header().Set("Cache-Control","no-store");w.WriteHeader(200);_ = json.NewEncoder(w).Encode(health{Status:"ok",Service:"cinema-api"})}
func requestID(next http.Handler)http.Handler{return http.HandlerFunc(func(w http.ResponseWriter,r *http.Request){id:=r.Header.Get("X-Request-ID");if id==""{var b [16]byte;if _,e:=rand.Read(b[:]);e==nil{id=hex.EncodeToString(b[:])}else{id="unavailable"}};w.Header().Set("X-Request-ID",id);next.ServeHTTP(w,r)})}
func security(next http.Handler)http.Handler{return http.HandlerFunc(func(w http.ResponseWriter,r *http.Request){w.Header().Set("X-Content-Type-Options","nosniff");w.Header().Set("X-Frame-Options","DENY");w.Header().Set("Referrer-Policy","no-referrer");w.Header().Set("Content-Security-Policy","default-src 'none'; frame-ancestors 'none'");next.ServeHTTP(w,r)})}
