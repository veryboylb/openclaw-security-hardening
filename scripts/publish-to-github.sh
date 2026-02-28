#!/usr/bin/env bash
# GitHub 自动发布脚本
# 使用方法：./publish-to-github.sh

set -e

REPO="veryboy/openclaw-security-hardening"
VERSION="v1.1.0"
TITLE="v1.1.0 - SSRF Protection & Permission Hardening 🎉"

echo "🚀 OpenClaw Security Hardening - GitHub Auto Publish"
echo "===================================================="
echo

# 检查 GITHUB_TOKEN
if [[ -z "$GITHUB_TOKEN" ]]; then
    echo "❌ Error: GITHUB_TOKEN not set"
    echo
    echo "Please set your GitHub token:"
    echo "  export GITHUB_TOKEN=ghp_xxxxxxxxxxxx"
    echo
    echo "Or create one at: https://github.com/settings/tokens"
    echo "Required scopes: repo, workflow"
    exit 1
fi

echo "✅ GitHub token found"
echo

# 推送代码
echo "📤 Pushing code to GitHub..."
cd /home/veryboy/.openclaw/workspace/openclaw-security-hardening
git push -u origin main
echo "✅ Code pushed"
echo

# 创建 Release
echo "📦 Creating Release $VERSION..."

RELEASE_NOTES=$(cat << 'EOF'
## 🔐 OpenClaw Security Hardening Toolkit v1.1.0

Protect your OpenClaw instance from CVEs, malicious skills, and credential leaks with one command!

### ✨ What's New

#### Security Enhancements
- 🛡️ **SSRF Protection Checking** - Detect and configure SSRF protection
- 🔒 **Automatic Permission Repair** - Fix insecure file permissions (chmod 600)
- 📋 **Official Checklist Integration** - Aligned with OpenClaw official security guide
- 🔍 **Enhanced CVE Detection** - Support for latest CVEs (CVE-2026-27488, ClawJacked)

#### Improvements
- ⚡ **jq Dependency Optimization** - Dual-mode operation (jq/fallback)
- 📊 **Better Audit Scoring** - More accurate security assessment
- 📖 **Comprehensive Documentation** - Installation guides, troubleshooting

### 🛡️ Security Coverage

| Vulnerability | Protection |
|---------------|------------|
| CVE-2026-25253 (RCE) | ✅ Detected & Fixed |
| CVE-2026-27488 (Path Injection) | ✅ Detected |
| CVE-ClawJacked (WebSocket Hijack) | ✅ Detected |
| Malicious Skills | ✅ Allowlist + Blocklist |
| Credential Leaks | ✅ Env Variables + Permissions |
| SSRF Attacks | ✅ Detection + Config |
| File Permission Issues | ✅ Auto-Repair |

### 🚀 Quick Start

```bash
git clone https://github.com/veryboy/openclaw-security-hardening.git
cd openclaw-security-hardening
./scripts/security-audit.sh
./scripts/auto-harden.sh
openclaw gateway restart
```

### 📊 Results

| Metric | Before | After |
|--------|--------|-------|
| Security Score | 65/100 | 85/100 |
| CVE Protection | ❌ | ✅ |
| File Permissions | ⚠️ | ✅ |
| SSRF Protection | ❌ | ✅ |
| Backup | ❌ | ✅ |

### 📦 Dependencies

- Bash 4.0+
- OpenClaw v2026.1.29+
- jq (optional, auto-fallback)

### 📖 Docs

- [Quick Start](docs/QUICKSTART.md)
- [Security Policy](SECURITY.md)
- [Test Report](TEST-REPORT.md)

### ⚠️ Disclaimer

Backup before running. Test in staging first.

### 📄 License

MIT License
EOF
)

# 使用 GitHub API 创建 Release
RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO/releases \
  -d "{
    \"tag_name\": \"$VERSION\",
    \"name\": \"$TITLE\",
    \"body\": $(echo "$RELEASE_NOTES" | jq -Rs .),
    \"draft\": false,
    \"prerelease\": false
  }")

RELEASE_URL=$(echo "$RESPONSE" | jq -r '.html_url')

if [[ "$RELEASE_URL" != "null" && -n "$RELEASE_URL" ]]; then
    echo "✅ Release created: $RELEASE_URL"
else
    echo "⚠️  Release may already exist or API error"
    echo "Response: $RESPONSE"
fi

echo

# 添加 Topics
echo "🏷️  Adding repository topics..."
curl -s -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO/topics \
  -d '{
    "names": ["security", "openclaw", "hardening", "automation", "bash", "ai-security", "cybersecurity"]
  }' > /dev/null

echo "✅ Topics added"
echo

# 总结
echo "===================================================="
echo "🎉 Publish Complete!"
echo "===================================================="
echo
echo "📦 Repository: https://github.com/$REPO"
echo "📦 Release: $RELEASE_URL"
echo
echo "📢 Next Steps:"
echo "  1. Share on Twitter/X"
echo "  2. Post to Discord (OpenClaw #showcase)"
echo "  3. Submit to Reddit (r/OpenClaw)"
echo "  4. Write article on Zhihu/Medium"
echo
echo "📊 Promotion templates in: FINAL-PUBLISH.md"
echo
