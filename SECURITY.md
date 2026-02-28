# 🔒 安全政策

## 支持的版本

| 版本 | 支持状态 |
|------|----------|
| 2026.2.x | ✅ 当前版本 |
| 2026.1.29+ | ✅ 安全版本 |
| < 2026.1.29 | ❌ 不安全（CVE-2026-25253） |

## 报告安全漏洞

如果你发现安全漏洞，请：

1. **不要**公开披露
2. 发送邮件至：leilei369963@outlook.com
3. 包含详细信息：
   - 漏洞描述
   - 复现步骤
   - 影响范围
   - 建议修复（如有）

我们会在 48 小时内回复。

## 已知漏洞

### CVE-2026-25253（已修复）

**严重程度**: 高（CVSS 8.8）

**描述**: WebSocket 跨站劫持漏洞，允许攻击者窃取认证令牌

**影响版本**: < 2026.1.29

**修复版本**: 2026.1.29+

**缓解措施**:
- 升级到最新版本
- 配置 `gateway.bind = "loopback"`
- 禁用 `allowInsecureAuth`

### 恶意技能攻击（持续风险）

**描述**: ClawHub 上的恶意技能可能窃取 API 密钥

**缓解措施**:
- 仅安装可信技能
- 配置技能白名单
- 定期审查已安装技能
- 使用环境变量存储密钥

## 安全最佳实践

### 1. 配置安全

```json
{
  "gateway": {
    "bind": "loopback",
    "controlUi": {
      "allowInsecureAuth": false,
      "dangerouslyDisableDeviceAuth": false
    }
  },
  "skills": {
    "allowlist": ["web-search-free", "github"],
    "denyCommands": ["rm -rf /", "sudo", "curl * | bash"]
  }
}
```

### 2. API 密钥管理

```bash
# ✅ 推荐：使用环境变量
export BAILIAN_API_KEY="sk-xxx"

# ❌ 避免：明文存储在配置文件中
```

### 3. 网络安全

```bash
# 配置防火墙
sudo ufw allow 22/tcp        # SSH
sudo ufw deny 18789          # Gateway 外部访问
sudo ufw allow from 127.0.0.1 to any port 18789  # 本地访问
```

### 4. 定期审计

```bash
# 每周运行安全审计
./scripts/security-audit.sh

# 检查配置变更
git diff ~/.openclaw/openclaw.json
```

### 5. 备份策略

```bash
# 每天备份配置
0 2 * * * cp ~/.openclaw/openclaw.json ~/.openclaw/backup/openclaw-$(date +\%Y\%m\%d).json
```

## 安全检查清单

### 部署前检查

- [ ] OpenClaw 版本 ≥ 2026.1.29
- [ ] Gateway 绑定到 loopback
- [ ] 禁用不安全认证
- [ ] 配置技能白名单
- [ ] 配置危险命令黑名单
- [ ] API 密钥使用环境变量
- [ ] 配置防火墙
- [ ] 启用配置备份

### 定期检查（每周）

- [ ] 运行安全审计
- [ ] 审查配置变更
- [ ] 检查监控日志
- [ ] 更新技能白名单
- [ ] 审查已安装技能

### 事件响应

如果怀疑被攻击：

1. **立即断开网络**
2. **停止 OpenClaw 服务**
3. **保存日志和证据**
4. **撤销所有 API 密钥**
5. **重新部署安全配置**
6. **分析攻击来源**
7. **报告安全事件**

## 资源

- [OpenClaw 官方安全文档](https://docs.openclaw.ai/gateway/security)
- [CVE-2026-25253 详情](https://nvd.nist.gov/vuln/detail/CVE-2026-25253)
- [加固指南](docs/HARDENING-GUIDE.md)
- [事件响应](docs/INCIDENT-RESPONSE.md)

---

**最后更新**: 2026-02-28
**版本**: 1.0.0
