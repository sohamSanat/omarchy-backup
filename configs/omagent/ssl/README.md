# Omagent TLS / SSL Certificates

This directory stores the local HTTPS / WSS certificates (`cert.pem` and `key.pem`) used by `omagent-mobile-bridge` (port 7890) to serve the Nothing Phone PWA over a secure local connection.

For security reasons, private keys are excluded from git.
`restore.sh` automatically generates a fresh self-signed 365-day RSA certificate and key if none are found:

```bash
openssl req -x509 -newkey rsa:2048 -keyout ~/.config/omagent/ssl/key.pem \
  -out ~/.config/omagent/ssl/cert.pem -days 365 -nodes \
  -subj "/CN=omagent.local"
```
