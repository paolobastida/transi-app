package entradahttp

import (
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func solicitud(remoteAddr, xff string) *http.Request {
	r := httptest.NewRequest(http.MethodPost, "/auth/login", nil)
	r.RemoteAddr = remoteAddr
	if xff != "" {
		r.Header.Set("X-Forwarded-For", xff)
	}
	return r
}

// Sin proxies de confianza no se mira X-Forwarded-For: un cliente cualquiera
// podría inventarlo para saltarse el límite.
func TestClaveDeIntentoNoConfiaEnXFFPorDefecto(t *testing.T) {
	l := NuevoLimitador(10, time.Minute, nil)
	r := solicitud("203.0.113.5:5555", "1.2.3.4")
	if clave := l.claveDeIntento(r); clave != "203.0.113.5" {
		t.Fatalf("clave = %q, esperaba la IP de conexión", clave)
	}
}

// Aunque el cliente mande un XFF falso, si no viene de un proxy de confianza
// se ignora: rotarlo no cambia la clave (no hay bypass).
func TestClaveDeIntentoIgnoraXFFDeCliente(t *testing.T) {
	l := NuevoLimitador(10, time.Minute, nil)
	a := l.claveDeIntento(solicitud("198.51.100.7:1", "10.0.0.1"))
	b := l.claveDeIntento(solicitud("198.51.100.7:1", "10.0.0.2"))
	if a != b {
		t.Fatalf("rotar XFF cambió la clave: %q vs %q", a, b)
	}
}

// Con un proxy de confianza se usa la IP real que el proxy agregó (la última
// de la cadena), descartando lo que el cliente escribió delante.
func TestClaveDeIntentoConProxyDeConfianza(t *testing.T) {
	l := NuevoLimitador(10, time.Minute, []string{"10.0.0.0/8"})

	// Cliente falsea XFF; el proxy agrega la IP real 9.9.9.9 al final.
	r := solicitud("10.0.0.9:5000", "1.2.3.4, 9.9.9.9")
	if clave := l.claveDeIntento(r); clave != "9.9.9.9" {
		t.Fatalf("clave = %q, esperaba la IP real 9.9.9.9", clave)
	}

	// Salta proxies de confianza intermedios de derecha a izquierda.
	r = solicitud("10.0.0.9:5000", "1.2.3.4, 10.0.0.7")
	if clave := l.claveDeIntento(r); clave != "1.2.3.4" {
		t.Fatalf("clave = %q, esperaba 1.2.3.4", clave)
	}

	// Si no hay XFF, cae a la IP de la conexión.
	r = solicitud("10.0.0.9:5000", "")
	if clave := l.claveDeIntento(r); clave != "10.0.0.9" {
		t.Fatalf("clave = %q, esperaba 10.0.0.9", clave)
	}
}

// Una IP de confianza sin máscara también vale.
func TestParsearProxiesIPSimple(t *testing.T) {
	l := NuevoLimitador(10, time.Minute, []string{"10.1.2.3"})
	if !l.esProxyDeConfianza(net.ParseIP("10.1.2.3")) {
		t.Fatal("10.1.2.3 debería ser de confianza")
	}
	if l.esProxyDeConfianza(net.ParseIP("10.1.2.4")) {
		t.Fatal("10.1.2.4 no debería ser de confianza")
	}
}
