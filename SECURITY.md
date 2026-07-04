# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x     | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of RNF seriously. If you discover a security vulnerability, please report it responsibly.

### How to Report

**DO NOT** open a public GitHub issue for security vulnerabilities.

Instead, please report vulnerabilities via one of these channels:

1. **Email:** Send details to **security@rnf-app.com**
2. **GitHub Security Advisories:** Use the [private vulnerability reporting](../../security/advisories/new) feature on this repository

### What to Include

- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested fix (if any)
- Your contact information for follow-up

### What to Expect

| Timeline | Action |
|----------|--------|
| 24 hours | Acknowledgment of your report |
| 72 hours | Initial assessment and severity classification |
| 7 days   | Detailed response with remediation plan |
| 30 days  | Fix deployed (for critical/high severity) |
| 90 days  | Fix deployed (for medium/low severity) |

### Scope

The following are in scope for security reports:

- Authentication and authorization bypasses
- Data exposure or leakage
- Injection vulnerabilities (SQL, XSS, etc.)
- Insecure data storage on device
- API key exposure
- Supabase Row Level Security bypasses
- Privilege escalation

### Out of Scope

- Denial of service attacks
- Social engineering
- Physical access attacks
- Issues in third-party dependencies (report to the upstream project)
- Issues requiring jailbroken/rooted devices

### Safe Harbor

We will not take legal action against researchers who:

- Make a good faith effort to avoid privacy violations, data destruction, and service disruption
- Only interact with accounts they own or with explicit permission
- Do not exploit the vulnerability beyond what is necessary to confirm it
- Report the vulnerability promptly and do not disclose it publicly before a fix is available

### Recognition

We appreciate security researchers who help keep RNF safe. With your permission, we will:

- Credit you in our security changelog
- Add you to our Hall of Fame (if established)

### Data Handling

RNF follows these security principles:

- **No PII in crash reports** — User IDs are SHA-256 hashed before transmission
- **Row Level Security** — All Supabase tables enforce RLS policies
- **Secrets management** — API keys are injected at build time, never committed to source control
- **Certificate pinning** — Network communications use certificate validation
- **Keychain storage** — Sensitive tokens stored in iOS Keychain, not UserDefaults

## Dependencies

We use Dependabot to monitor dependencies for known vulnerabilities. Critical patches are prioritized within 48 hours of disclosure.
