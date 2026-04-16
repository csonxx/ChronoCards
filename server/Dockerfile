# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the server
RUN CGO_ENABLED=0 GOOS=linux go build -o chronocards-server .

# Runtime stage
FROM alpine:3.19

WORKDIR /app

# Install runtime dependencies (ca-certificates for HTTPS, tzdata)
RUN apk add --no-cache ca-certificates tzdata

# Create non-root user
RUN adduser -D -u 1000 appuser

# Copy binary from builder
COPY --from=builder /app/chronocards-server .
COPY --from=builder /app/ws ./ws
COPY --from=builder /app/narrative ./narrative
COPY --from=builder /app/internal ./internal
COPY --from=builder /app/cmd ./cmd

# Create saves directory
RUN mkdir -p /app/saves && chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["./chronocards-server"]
