package entradahttp

import (
	"encoding/json"
	"net/http"
)

type cuerpoProfesional struct {
	Nombre       string `json:"nombre"`
	Especialidad string `json:"especialidad"`
}

type respuestaProfesional struct {
	ID           string `json:"id"`
	Nombre       string `json:"nombre"`
	Especialidad string `json:"especialidad"`
}

func (s *Servidor) manejarCrearProfesional(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	var cuerpo cuerpoProfesional
	if err := json.NewDecoder(r.Body).Decode(&cuerpo); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
		return
	}
	p, err := s.profesionales.Crear(r.Context(), actual.ID, cuerpo.Nombre, cuerpo.Especialidad)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusCreated, respuestaProfesional{ID: p.ID, Nombre: p.Nombre, Especialidad: p.Especialidad})
}

func (s *Servidor) manejarListarProfesionales(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	profesionales, err := s.profesionales.Listar(r.Context(), actual.ID)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	respuesta := make([]respuestaProfesional, 0, len(profesionales))
	for _, p := range profesionales {
		respuesta = append(respuesta, respuestaProfesional{ID: p.ID, Nombre: p.Nombre, Especialidad: p.Especialidad})
	}
	escribirJSON(w, http.StatusOK, respuesta)
}

func (s *Servidor) manejarEditarProfesional(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	var cuerpo cuerpoProfesional
	if err := json.NewDecoder(r.Body).Decode(&cuerpo); err != nil {
		escribirError(w, http.StatusBadRequest, "json_invalido", "el cuerpo no es JSON válido")
		return
	}
	p, err := s.profesionales.Editar(r.Context(), actual.ID, r.PathValue("id"), cuerpo.Nombre, cuerpo.Especialidad)
	if err != nil {
		s.manejarError(w, err)
		return
	}
	escribirJSON(w, http.StatusOK, respuestaProfesional{ID: p.ID, Nombre: p.Nombre, Especialidad: p.Especialidad})
}

func (s *Servidor) manejarDesactivarProfesional(w http.ResponseWriter, r *http.Request) {
	actual, ok := usuarioDesdeContexto(r.Context())
	if !ok {
		escribirError(w, http.StatusUnauthorized, "no_autenticado", "sesión no válida")
		return
	}
	if err := s.profesionales.Desactivar(r.Context(), actual.ID, r.PathValue("id")); err != nil {
		s.manejarError(w, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
