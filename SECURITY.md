# Security Policy — StatusPulse

## Secret Management

### Environment Variables

All secrets are managed through environment variables and **never hardcoded** in the source code.

| Secret | Local Development | Production (CI/CD) |
|--------|-------------------|---------------------|
| `DB_PASSWORD` | `.env` file (git-ignored) | GitHub Actions Secret |
| `REDIS_PASSWORD` | `.env` file (git-ignored) | GitHub Actions Secret |
| `SERVER_SSH_KEY` | N/A | GitHub Actions Secret |
| `SERVER_HOST` | N/A | GitHub Actions Secret |
| `ALERT_WEBHOOK_URL` | `.env` file | GitHub Actions Secret |

### Rules

1. **Never commit `.env` files.** The `.gitignore` includes `.env` to prevent accidental exposure.
2. **Use `.env.example`** as a template — it contains placeholder values only.
3. **GitHub Actions secrets** are used for all CI/CD pipeline credentials. These are encrypted at rest and masked in logs.
4. **SSH keys** for deployment are stored exclusively in GitHub Secrets (`SERVER_SSH_KEY`).

## Container Image Scanning

### Current Status

> ⚠️ **Placeholder**: Image scanning is planned but not yet implemented in the CI pipeline.

### Planned Implementation

We recommend integrating one of the following free-tier scanning tools into the CI pipeline:

- **[Trivy](https://github.com/aquasecurity/trivy)** — Open-source vulnerability scanner for containers.
- **[Grype](https://github.com/anchore/grype)** — Fast vulnerability scanner for container images and filesystems.

Example CI step (planned):

```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'ghcr.io/${{ github.repository }}:${{ github.sha }}'
    format: 'sarif'
    output: 'trivy-results.sarif'
```

## Network Security

- **Firewall (UFW)**: Only ports `2222` (SSH), `80` (HTTP), and `443` (HTTPS) are open.
- **SSH Hardening**: Root login disabled, password authentication disabled, custom port 2222.
- **TLS**: Automatic via Caddy — all HTTP traffic is redirected to HTTPS.
- **Rate Limiting**: 100 requests/minute per IP (configured in Caddy/reverse proxy layer).

## Security Headers

The following headers are set on all responses via Caddy:

| Header | Value |
|--------|-------|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` |
| `X-XSS-Protection` | `1; mode=block` |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |

## Reporting Vulnerabilities

If you discover a security vulnerability, please report it responsibly by emailing `security@yourdomain.com`. Do not open a public GitHub issue.
