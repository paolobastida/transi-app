package entradahttp

import (
	"net"
	"net/http"
	"strings"
	"time"
)

// limiteCuerpoJSON es el máximo que se acepta en los endpoints JSON. Es
// suficiente para credenciales y formularios de tratamiento, y evita que una
// petición sin autenticación pueda forzar al servidor a leer, por ejemplo,
// 500 MB de JSON en memoria.
const limiteCuerpoJSON = 64 << 10 // 64 KB

// limiteCuerpoMultipart es el máximo para POST /cambios (fotos y audios).
const limiteCuerpoMultipart = 60 << 20 // 60 MB

// limiteArchivo es el máximo por adjunto suelto.
const limiteArchivo = 20 << 20 // 20 MB

// conLimiteCuerpo corta el body si supera el máximo indicado y responde 413.
// Va antes de cualquier lectura del body.
func conLimiteCuerpo(limite int64, siguiente http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.ContentLength > limite {
			escribirError(w, http.StatusRequestEntityTooLarge, "cuerpo_muy_grande",
				"el contenido enviado supera el tamaño permitido")
			return
		}
		// ContentLength puede venir en -1 (chunked): MaxBytesReader lo acota
		// aunque no conozcamos el tamaño de antemano.
		r.Body = http.MaxBytesReader(w, r.Body, limite)
		siguiente(w, r)
	}
}

// ---------------------------------------------------------------------------
// Limitación de intentos
// ---------------------------------------------------------------------------

// Limitador es un token bucket por clave (IP, o IP+email). Es lo bastante
// simple para un MVP y evita tanto la fuerza bruta como el DoS de CPU que
// provoca un bcrypt por cada intento de login sin autenticar.
type Limitador struct {
	Intentos map[string]*ventana
	Maximo   int
	Periodo  time.Duration
	ahora    func() time.Time
	// proxies son las redes de las que SÍ nos creemos el X-Forwarded-For
	// (típicamente el reverse proxy que publica la API). Vacío = no confiar en
	// ninguna cabecera y usar siempre la IP de la conexión.
	proxies []*net.IPNet
}

type ventana struct {
	contador int
	inicio   time.Time
}

// NuevoLimitador crea un limitador: como mucho maximo intentos por clave cada
// ventana. `proxies` son las IP/CIDR de confianza para leer X-Forwarded-For.
func NuevoLimitador(maximo int, periodo time.Duration, proxies []string) *Limitador {
	return &Limitador{
		Intentos: map[string]*ventana{},
		Maximo:   maximo,
		Periodo:  periodo,
		ahora:    time.Now,
		proxies:  parsearProxies(proxies),
	}
}

// parsearProxies acepta direcciones ("10.0.0.1") o redes ("10.0.0.0/8").
func parsearProxies(valores []string) []*net.IPNet {
	var redes []*net.IPNet
	for _, valor := range valores {
		valor = strings.TrimSpace(valor)
		if valor == "" {
			continue
		}
		if _, red, err := net.ParseCIDR(valor); err == nil {
			redes = append(redes, red)
			continue
		}
		if ip := net.ParseIP(valor); ip != nil {
			if ip4 := ip.To4(); ip4 != nil {
				redes = append(redes, &net.IPNet{IP: ip4, Mask: net.CIDRMask(32, 32)})
			} else {
				redes = append(redes, &net.IPNet{IP: ip, Mask: net.CIDRMask(128, 128)})
			}
		}
	}
	return redes
}

// esProxyDeConfianza indica si la IP pertenece a una red de confianza.
func (l *Limitador) esProxyDeConfianza(ip net.IP) bool {
	if ip == nil {
		return false
	}
	for _, red := range l.proxies {
		if red.Contains(ip) {
			return true
		}
	}
	return false
}

// permitir indica si la clave puede intentarlo ahora, y consume un intento.
func (l *Limitador) permitir(clave string) bool {
	if l == nil || l.Maximo <= 0 {
		return true
	}
	ahora := l.ahora()
	v, existe := l.Intentos[clave]
	if !existe || ahora.Sub(v.inicio) > l.Periodo {
		l.Intentos[clave] = &ventana{contador: 1, inicio: ahora}
		return true
	}
	if v.contador >= l.Maximo {
		return false
	}
	v.contador++
	return true
}

// Limpiar borra las claves vencidas. Hay que llamarlo periódicamente para que
// el mapa no crezca sin límite.
func (l *Limitador) Limpiar() {
	if l == nil {
		return
	}
	ahora := l.ahora()
	for clave, v := range l.Intentos {
		if ahora.Sub(v.inicio) > l.Periodo {
			delete(l.Intentos, clave)
		}
	}
}

// conLimiteIntentos corta con 429 cuando la clave se pasa del máximo.
func conLimiteIntentos(l *Limitador, siguiente http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !l.permitir(l.claveDeIntento(r)) {
			w.Header().Set("Retry-After", "60")
			escribirError(w, http.StatusTooManyRequests, "demasiados_intentos",
				"hiciste demasiados intentos; probá de nuevo en un minuto")
			return
		}
		siguiente(w, r)
	}
}

// claveDeIntento devuelve la IP a la que se le imputa el intento.
//
// Solo se mira X-Forwarded-For si quien conecta es un proxy de confianza
// (PROXIES_CONFIABLES). Un cliente cualquiera puede inventar esa cabecera, así
// que confiarla siempre permitía saltar el límite mandando una IP distinta en
// cada intento (y con eso, fuerza bruta sin tope).
//
// Cuando el proxy es de confianza, se recorre la cadena de X-Forwarded-For de
// derecha a izquierda y se toma la primera IP que NO sea a su vez un proxy de
// confianza: esa es la IP real del cliente que el proxy agregó, descartando lo
// que el cliente haya escrito delante.
func (l *Limitador) claveDeIntento(r *http.Request) string {
	host := hostDe(r.RemoteAddr)
	if l == nil || !l.esProxyDeConfianza(net.ParseIP(host)) {
		return host
	}
	partes := strings.Split(r.Header.Get("X-Forwarded-For"), ",")
	for i := len(partes) - 1; i >= 0; i-- {
		candidato := strings.TrimSpace(partes[i])
		ip := net.ParseIP(candidato)
		if ip == nil {
			continue
		}
		if !l.esProxyDeConfianza(ip) {
			return candidato
		}
	}
	return host
}

// hostDe extrae la IP de un RemoteAddr "ip:puerto" (o lo devuelve tal cual).
func hostDe(remoteAddr string) string {
	host, _, err := net.SplitHostPort(remoteAddr)
	if err != nil {
		return remoteAddr
	}
	return host
}
