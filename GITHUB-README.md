# 🔒 OpenClaw Security Hardening

**One-click security hardening for OpenClaw. Protect against CVEs, malicious skills, and credential leaks.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Security](https://img.shields.io/badge/Security-A+-brightgreen)]()
[![OpenClaw](https://img.shields.io/badge/OpenClaw-v2026.2.25+-blue)](https://github.com/openclaw/openclaw)
[![Version](https://img.shields.io/badge/version-1.1.0-blue)]()

---

## ⚠️ Why This Exists

- 🔴 **21,000+** OpenClaw instances exposed online
- 🔴 **CVE-2026-25253**: One-click RCE vulnerability (CVSS 8.8)
- 🔴 **Malicious skills**: ClawHub supply chain attacks
- 🔴 **Credential leaks**: API keys in plaintext configs

**This toolkit helps you:**
✅ Audit security risks automatically
✅ Harden configuration in one click
✅ Monitor threats continuously
✅ Generate compliance reports

---

## 🚀 Quick Start (5 Minutes)

```bash
# 1. Clone
git clone https://github.com/YOUR_USERNAME/openclaw-security-hardening.git
cd openclaw-security-hardening

# 2. Audit
chmod +x scripts/security-audit.sh
./scripts/security-audit.sh

# 3. Harden
chmod +x scripts/auto-harden.sh
./scripts/auto-harden.sh

# 4. Restart
openclaw gateway restart
```

**That's it!** Your OpenClaw is now secured. 🎉

---

## 📦 What's Included

| Script | Purpose | Time |
|--------|---------|------|
| `security-audit.sh` | Scan for vulnerabilities | 2 min |
| `auto-harden.sh` | One-click hardening | 3 min |
| `security-monitor.sh` | Continuous monitoring | 1 min setup |
| `backup-config.sh` | Backup configurations | 30 sec |

---

## 🔍 Audit Results Example

```
========================================
OpenClaw Security Audit
========================================

[🔴 CRITICAL] CVE-2026-25253 Vulnerability
  - Status: Vulnerable
  - Risk: Attackers can steal auth tokens via malicious links

[🔴 CRITICAL] Gateway Exposed
  - Status: Port 18789 exposed to internet
  - Risk: Unauthorized access and config leaks

[🟠 HIGH] Plaintext API Keys
  - Status: API keys stored in plaintext
  - Risk: Credential theft if config leaks

[🟡 MEDIUM] No Skill Allowlist
  - Status: All skills can be installed
  - Risk: Malicious skill installation

========================================
Security Score: 45/100 (Needs Immediate Hardening)
========================================
```

---

## 🛡️ Hardening Features

### 1. CVE-2026-25253 Fix
- ✅ Update to safe version (≥2026.1.29)
- ✅ Disable insecure authentication
- ✅ Enable device authentication

### 2. Network Security
- ✅ Bind gateway to localhost only
- ✅ Configure firewall rules (UFW)
- ✅ Block external access

### 3. API Key Protection
- ✅ Move keys to environment variables
- ✅ Encrypt sensitive data
- ✅ Create .env template

### 4. Skill Security
- ✅ Configure skill allowlist
- ✅ Block dangerous commands
- ✅ Review installed skills

### 5. Backup & Recovery
- ✅ Automatic config backup
- ✅ One-click restore
- ✅ Versioned backups

---

## 📊 Before vs After

| Metric | Before | After |
|--------|--------|-------|
| **Security Score** | 45/100 | 90/100 |
| **CVE-2026-25253** | ❌ Vulnerable | ✅ Patched |
| **Gateway Exposure** | ❌ Public | ✅ Local Only |
| **API Keys** | ❌ Plaintext | ✅ Environment |
| **Skill Controls** | ❌ None | ✅ Allowlist + Blocklist |
| **Firewall** | ❌ None | ✅ Configured |
| **Backups** | ❌ None | ✅ Automatic |

---

## 🎯 Use Cases

### For Individuals
- Protect personal API keys
- Secure home automation
- Prevent credential theft

### For Developers
- Secure development environment
- Protect production configs
- Compliance requirements

### For Enterprises
- Multi-instance management
- Security audit reports
- Compliance documentation

---

## 📖 Documentation

- **[Quick Start](docs/QUICKSTART.md)** - Get started in 5 minutes
- **[Hardening Guide](docs/HARDENING-GUIDE.md)** - Detailed security guide
- **[Security Policy](SECURITY.md)** - Vulnerability reporting
- **[Incident Response](docs/INCIDENT-RESPONSE.md)** - What to do if attacked

---

## 🧪 Testing

```bash
# Run all tests
cd tests
./run-all-tests.sh

# Test audit script
./test-audit.sh

# Test hardening script
./test-harden.sh
```

---

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## ⚠️ Disclaimer

**Important**: 
- Always backup before running hardening scripts
- Test in a staging environment first
- Some changes may cause brief service interruption
- Enterprise users should consult security professionals

This tool is provided "as is" without warranty. Use at your own risk.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

## 🙏 Acknowledgments

- OpenClaw Team for the amazing project
- Security researchers who disclosed CVE-2026-25253
- Community contributors and testers

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/openclaw-security-hardening/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/openclaw-security-hardening/discussions)
- **Email**: security@
- **Twitter**: 

---

## 📈 Roadmap

### v1.0 (Current)
- ✅ Security audit
- ✅ Auto hardening
- ✅ Basic monitoring
- ✅ Documentation

### v1.1 (Coming Soon)
- [ ] Web dashboard
- [ ] Automated compliance reports
- [ ] Multi-instance management
- [ ] Alert integrations (Slack/Telegram)

### v2.0 (Future)
- [ ] AI threat detection
- [ ] Automated response
- [ ] Enterprise SSO
- [ ] Security certification

---

**Made with ❤️ for the OpenClaw Community**

**Last Updated**: 2026-02-28
**Version**: 1.0.0
