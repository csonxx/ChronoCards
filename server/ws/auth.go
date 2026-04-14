package ws

import (
	"errors"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims represents JWT claims for player authentication
type Claims struct {
	PlayerID string `json:"player_id"`
	jwt.RegisteredClaims
}

// Authenticator handles JWT authentication
type Authenticator struct {
	secret []byte
}

// NewAuthenticator creates a new Authenticator
func NewAuthenticator(secret string) *Authenticator {
	return &Authenticator{secret: []byte(secret)}
}

// ValidateToken validates a JWT token and returns the claims
func (a *Authenticator) ValidateToken(tokenString string) (*Claims, error) {
	if tokenString == "" {
		return nil, errors.New("empty token")
	}

	// Strip "Bearer " prefix if present
	tokenString = strings.TrimPrefix(tokenString, "Bearer ")
	tokenString = strings.TrimSpace(tokenString)

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return a.secret, nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}

	return claims, nil
}

// GenerateToken generates a JWT token for a player (for testing purposes)
func (a *Authenticator) GenerateToken(playerID string, expiresIn time.Duration) (string, error) {
	claims := &Claims{
		PlayerID: playerID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(expiresIn)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "chronocards",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(a.secret)
}
