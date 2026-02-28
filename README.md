# 🔒 OpenClaw Security Hardening Toolkit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenClaw Version](https://img.shields.io/badge/OpenClaw-2026.2.22+-blue)](https://github.com/openclaw/openclaw)
[![Security](https://img.shields.io/badge/Security-A+-brightgreen)]()

> **一键加固你的 OpenClaw 实例，防范 CVE-2026-25253、恶意技能、凭证泄露等安全威胁**

---

## ⚠️ 为什么需要这个工具？

根据最新安全报告：

- 🔴 **21,000+** OpenClaw 实例公开暴露在互联网
- 🔴 **CVE-2026-25253**: 一键远程代码执行漏洞（CVSS 8.8）
- 🔴 **恶意技能**: ClawHub 供应链攻击窃取 API 密钥
- 🔴 **凭证泄露**: 用户将敏感配置暴露在公网

**这个工具包帮你：**
✅ 自动检测安全风险
✅ 一键加固配置
✅ 持续监控威胁
✅ 生成安全报告

---

## 🚀 快速开始

### 前置要求

- ✅ OpenClaw v2026.1.29+
- ✅ Bash 4.0+
- ✅ **jq**（JSON 处理器）- 可选但推荐

**安装 jq**（推荐但非必需）:
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq

# CentOS/RHEL
sudo yum install jq
```

**注意**: 如果不安装 jq，工具会自动使用降级方案（功能略有受限）

### 1. 运行安全审计

```bash
# 克隆仓库
git clone https://github.com/veryboylb/openclaw-security-hardening.git
cd openclaw-security-hardening

# 运行安全审计
chmod +x scripts/security-audit.sh
./scripts/security-audit.sh
```

### 2. 一键加固

```bash
# 自动加固（推荐）
chmod +x scripts/auto-harden.sh
./scripts/auto-harden.sh

# 或手动选择加固项
./scripts/auto-harden.sh --interactive
```

### 3. 持续监控

```bash
# 启动安全监控（后台运行）
./scripts/security-monitor.sh --daemon

# 查看监控状态
./scripts/security-monitor.sh --status
```

---

## 📦 工具包内容

```
openclaw-security-hardening/
├── scripts/
│   ├── security-audit.sh      # 安全审计脚本
│   ├── auto-harden.sh         # 自动加固脚本
│   ├── security-monitor.sh    # 安全监控脚本
│   ├── check-cve-2026-25253.sh # CVE 检测脚本
│   ├── backup-config.sh       # 配置备份脚本
│   └── restore-config.sh      # 配置恢复脚本
├── configs/
│   ├── secure-openclaw.json   # 安全配置模板
│   ├── firewall-rules.sh      # 防火墙规则
│   └── security-policies.json # 安全策略
├── docs/
│   ├── SECURITY.md            # 安全文档
│   ├── HARDENING-GUIDE.md     # 加固指南
│   └── INCIDENT-RESPONSE.md   # 事件响应
├── examples/
│   ├── secure-deployment/     # 安全部署示例
│   └── enterprise-config/     # 企业配置示例
└── tests/
    ├── test-audit.sh          # 审计测试
    └── test-harden.sh         # 加固测试
```

---

## 🔍 安全审计功能

### 审计内容

| 检查项 | 描述 | 严重性 |
|--------|------|--------|
| **CVE-2026-25253** | 检查是否易受 WebSocket 劫持攻击 | 🔴 严重 |
| **公开暴露** | 检查 Gateway 是否暴露在公网 | 🔴 严重 |
| **API 密钥安全** | 检查 API 密钥是否明文存储 | 🟠 高 |
| **技能权限** | 检查技能是否有过度权限 | 🟠 高 |
| **防火墙配置** | 检查防火墙规则 | 🟡 中 |
| **配置备份** | 检查是否有配置备份 | 🟡 中 |
| **版本更新** | 检查是否为最新版本 | 🟢 低 |

### 审计报告示例

```
========================================
OpenClaw 安全审计报告
========================================
审计时间：2026-02-28 21:30:00
OpenClaw 版本：2026.2.22

[🔴 严重] CVE-2026-25253 漏洞
  - 状态：易受攻击
  - 风险：攻击者可通过恶意链接窃取认证令牌
  - 建议：升级到 v2026.1.29+

[🔴 严重] Gateway 公开暴露
  - 状态：端口 18789 暴露在公网
  - 风险：未授权访问和配置泄露
  - 建议：配置防火墙或仅监听本地

[🟠 高] API 密钥明文存储
  - 状态：~/.openclaw/openclaw.json 包含明文密钥
  - 风险：配置文件泄露导致密钥被盗
  - 建议：使用环境变量或加密存储

[🟡 中] 缺少防火墙规则
  - 状态：未配置防火墙
  - 风险：未授权网络访问
  - 建议：配置 UFW 或 iptables

[🟢 低] 版本过旧
  - 状态：当前版本 2026.2.22，最新 2026.2.26
  - 风险：缺少最新安全修复
  - 建议：运行 openclaw update

========================================
安全评分：45/100（需要立即加固）
========================================
```

---

## 🛡️ 自动加固功能

### 加固内容

#### 1. 修复 CVE-2026-25253
```bash
# 检查版本
openclaw --version

# 升级到安全版本
openclaw update

# 验证修复
./scripts/check-cve-2026-25253.sh
```

#### 2. 配置防火墙
```bash
# 自动配置 UFW 防火墙
sudo ./scripts/auto-harden.sh --firewall

# 规则：
# - 允许 SSH (22)
# - 允许 OpenClaw Gateway (18789) 仅本地访问
# - 允许 Telegram Bot (如果使用)
# - 拒绝其他所有入站连接
```

#### 3. 安全配置
```bash
# 应用安全配置模板
cp configs/secure-openclaw.json ~/.openclaw/openclaw.json

# 关键配置：
{
  "gateway": {
    "bind": "loopback",  # 仅本地访问
    "auth": {
      "mode": "token",
      "token": "secure-random-token"
    },
    "controlUi": {
      "allowInsecureAuth": false,  # 禁用 HTTP
      "dangerouslyDisableDeviceAuth": false  # 启用设备认证
    }
  },
  "skills": {
    "allowlist": ["web-search-free", "github"],  # 技能白名单
    "denyCommands": ["rm -rf", "sudo", "curl | bash"]  # 危险命令黑名单
  }
}
```

#### 4. API 密钥保护
```bash
# 将 API 密钥移到环境变量
export BAILIAN_API_KEY="sk-xxx"
export OPENROUTER_API_KEY="sk-or-xxx"

# 或使用加密存储
./scripts/encrypt-keys.sh
```

#### 5. 配置备份
```bash
# 自动备份配置
./scripts/backup-config.sh

# 输出：
# Backup created: ~/.openclaw/backup/openclaw-backup-20260228-213000.json
```

---

## 📊 安全监控

### 监控功能

```bash
# 启动监控
./scripts/security-monitor.sh --daemon

# 监控内容：
# - 网关连接尝试
# - 技能执行日志
# - API 调用频率
# - 配置文件变更
# - 异常行为检测
```

### 告警通知

支持多种告警方式：

```json
{
  "alerts": {
    "email": "your@email.com",
    "telegram": "@yourbot",
    "webhook": "https://hooks.slack.com/xxx",
    "thresholds": {
      "failed_logins": 5,
      "api_calls_per_minute": 100,
      "config_changes": true
    }
  }
}
```

---

## 📖 文档

### [安全加固指南](docs/HARDENING-GUIDE.md)

详细的安全加固步骤：
1. 环境准备
2. 漏洞扫描
3. 配置加固
4. 防火墙设置
5. 监控部署
6. 定期审计

### [事件响应指南](docs/INCIDENT-RESPONSE.md)

安全事件发生时的响应流程：
1. 识别和评估
2. 遏制和隔离
3. 根除和恢复
4. 事后分析
5. 改进措施

### [安全最佳实践](docs/SECURITY.md)

日常使用中的安全建议：
- 技能安装审查
- API 密钥管理
- 定期更新
- 备份策略
- 访问控制

---

## 🔬 测试

```bash
# 运行所有测试
cd tests
./run-all-tests.sh

# 单独测试
./test-audit.sh
./test-harden.sh
```

---

## 🎯 使用场景

### 场景 1: 个人用户快速加固

```bash
# 一键完成所有加固
./scripts/auto-harden.sh --quick

# 时间：约 5 分钟
# 效果：安全评分从 45 提升到 90+
```

### 场景 2: 企业部署

```bash
# 企业级加固
./scripts/auto-harden.sh --enterprise

# 包含：
# - 集中式日志
# - SIEM 集成
# - 访问审计
# - 合规报告
```

### 场景 3: 安全审计

```bash
# 生成详细审计报告
./scripts/security-audit.sh --report full-report.pdf

# 包含：
# - 风险清单
# - 修复建议
# - 合规检查
# - 趋势分析
```

---

## ⚙️ 系统要求

| 要求 | 详情 |
|------|------|
| **OpenClaw** | v2026.1.29+ |
| **操作系统** | Linux / macOS / WSL2 |
| **依赖** | bash, curl, jq, openssl |
| **权限** | sudo（用于防火墙配置） |

---

## 🚨 警告和免责

⚠️ **重要警告**:

1. **备份先行**: 运行加固脚本前务必备份配置
2. **测试环境**: 建议先在测试环境验证
3. **服务中断**: 某些加固可能导致服务短暂中断
4. **专业建议**: 企业用户建议咨询安全专家

**免责声明**:
本工具按"原样"提供，不保证完全防止所有安全威胁。使用本工具的风险由用户自行承担。

---

## 📈 路线图

### v1.0 (当前版本)
- ✅ 安全审计
- ✅ 自动加固
- ✅ 基础监控
- ✅ 文档和示例

### v1.1 (计划中)
- [ ] Web 管理界面
- [ ] 自动化合规报告
- [ ] 多实例管理
- [ ] 告警集成（Slack/Telegram）

### v2.0 (未来)
- [ ] AI 威胁检测
- [ ] 自动响应
- [ ] 企业 SSO 集成
- [ ] 安全培训和认证

---

## 🤝 贡献

欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md)

### 贡献方式：
- 🐛 报告安全漏洞
- 💡 提出改进建议
- 📝 完善文档
- 🔧 提交代码修复
- 🧪 添加测试用例

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE)

---

## 📞 支持

- **问题反馈**: [GitHub Issues](https://github.com/veryboylb/openclaw-security-hardening/issues)
- **讨论**: [GitHub Discussions](https://github.com/veryboylb/openclaw-security-hardening/discussions)
- **邮件**: leilei369963@outlook.com
- **Twitter**: 

---

## 🙏 致谢

感谢 OpenClaw 社区和安全研究人员的工作：
- OpenClaw 官方团队
- CVE-2026-25253 发现者
- 社区安全贡献者

---

## 📊 星历史

[![Star History Chart](https://api.star-history.com/svg?repos=veryboylb/openclaw-security-hardening&type=Date)](https://star-history.com/#veryboylb/openclaw-security-hardening&Date)

---

**最后更新**: 2026-02-28
**版本**: 1.0.0
**维护者**: veryboylb
