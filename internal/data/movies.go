package data

import (
	"time"
)

type Movie struct {
	ID        int       `json:"id"`
	CreatedAt time.Time `json:"-"` // Use the - directive
	Title     string    `json:"title"`
	Year      int       `json:"year,omitzero"`    // Add the omitzero directive
	Runtime   Runtime   `json:"runtime,omitzero"` // Add the omitzero directive
	Genres    []string  `json:"genres,omitzero"`  // Add the omitzero directive
	Version   int       `json:"version"`
}
