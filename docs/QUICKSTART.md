# 🚀 快速开始指南

## 5 分钟快速加固

### 步骤 1: 克隆仓库

```bash
git clone https://github.com/veryboylb/openclaw-security-hardening.git
cd openclaw-security-hardening
```

### 步骤 2: 运行安全审计

```bash
chmod +x scripts/security-audit.sh
./scripts/security-audit.sh
```

**输出示例**:
```
========================================
OpenClaw 安全审计工具 v1.0
========================================

[ℹ️  信息] 审计开始时间：2026-02-28 21:30:00
[ℹ️  信息] OpenClaw 目录：/home/user/.openclaw

[🔴 严重] CVE-2026-25253 漏洞
  - 状态：易受攻击
  - 风险：攻击者可通过恶意链接窃取认证令牌

[🔴 严重] Gateway 公开暴露
  - 状态：端口 18789 暴露在公网

[🟠 高] API 密钥明文存储
  - 状态：配置文件包含明文密钥

========================================
审计总结
========================================
[ℹ️  信息] 安全评分：45/100
[🔴] 安全性危险！请立即加固！
[ℹ️  信息] 运行：./scripts/auto-harden.sh
```

### 步骤 3: 一键加固

```bash
chmod +x scripts/auto-harden.sh
./scripts/auto-harden.sh
```

**交互式模式**（逐步确认）:
```bash
./scripts/auto-harden.sh --interactive
```

### 步骤 4: 验证加固

```bash
./scripts/security-audit.sh
```

**加固后评分应该达到 85-95/100**

### 步骤 5: 重启 OpenClaw

```bash
openclaw gateway restart
```

---

## 常见场景

### 场景 1: 我是新手，第一次使用

```bash
# 1. 运行审计
./scripts/security-audit.sh

# 2. 查看报告
cat security-audit-report-*.md

# 3. 运行加固（交互式）
./scripts/auto-harden.sh --interactive

# 4. 重启 OpenClaw
openclaw gateway restart
```

### 场景 2: 我已经在使用，担心安全问题

```bash
# 1. 立即备份配置
./scripts/backup-config.sh

# 2. 运行加固
./scripts/auto-harden.sh

# 3. 验证
./scripts/security-audit.sh

# 4. 重启
openclaw gateway restart
```

### 场景 3: 企业部署

```bash
# 1. 在测试环境验证
./scripts/auto-harden.sh --interactive

# 2. 审查配置变更
diff ~/.openclaw/openclaw.json.backup ~/.openclaw/openclaw.json

# 3. 应用到生产环境
./scripts/auto-harden.sh

# 4. 配置监控
crontab -e
# 添加：*/5 * * * * /path/to/security-monitor.sh
```

### 场景 4: 怀疑被攻击

```bash
# 1. 立即停止 OpenClaw
openclaw gateway stop

# 2. 保存日志
cp -r ~/.openclaw/logs ./incident-logs-$(date +%Y%m%d-%H%M%S)

# 3. 备份当前配置
cp ~/.openclaw/openclaw.json ./compromised-config-$(date +%Y%m%d-%H%M%S).json

# 4. 撤销所有 API 密钥
# 登录各平台控制台撤销

# 5. 重新部署
./scripts/auto-harden.sh
openclaw gateway restart

# 6. 报告事件
# 查看 docs/INCIDENT-RESPONSE.md
```

---

## 命令参考

### 安全审计

```bash
# 基本用法
./scripts/security-audit.sh

# 输出到文件
./scripts/security-audit.sh > audit.txt

# 生成 Markdown 报告
./scripts/security-audit.sh  # 自动生成 .md 文件
```

### 自动加固

```bash
# 自动模式（无确认）
./scripts/auto-harden.sh

# 交互模式（逐步确认）
./scripts/auto-harden.sh --interactive

# 仅加固配置
./scripts/auto-harden.sh --config-only

# 仅配置防火墙
./scripts/auto-harden.sh --firewall-only
```

### 配置备份

```bash
# 备份配置
./scripts/backup-config.sh

# 列出备份
ls -la ~/.openclaw/backup/

# 恢复配置
./scripts/restore-config.sh openclaw-backup-20260228-213000.json
```

### 安全监控

```bash
# 启动监控
./scripts/security-monitor.sh --daemon

# 查看状态
./scripts/security-monitor.sh --status

# 查看日志
tail -f ~/.openclaw/security-monitor.log

# 停止监控
./scripts/security-monitor.sh --stop
```

---

## 故障排除

### 问题 1: 脚本权限错误

```bash
# 解决方案
chmod +x scripts/*.sh
```

### 问题 2: jq 未安装

```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq

# CentOS/RHEL
sudo yum install jq
```

### 问题 3: 配置备份失败

```bash
# 检查目录权限
ls -la ~/.openclaw/

# 创建备份目录
mkdir -p ~/.openclaw/backup
chmod 700 ~/.openclaw/backup
```

### 问题 4: 防火墙配置失败

```bash
# 检查 UFW 状态
sudo ufw status

# 如果是 inactive，启用它
echo "y" | sudo ufw enable

# 或者跳过防火墙配置
./scripts/auto-harden.sh --skip-firewall
```

### 问题 5: OpenClaw 重启失败

```bash
# 检查配置语法
jq . ~/.openclaw/openclaw.json

# 查看日志
openclaw gateway logs

# 恢复备份
./scripts/restore-config.sh
```

---

## 下一步

完成快速加固后：

1. ✅ **阅读完整文档**: [HARDENING-GUIDE.md](docs/HARDENING-GUIDE.md)
2. ✅ **配置监控**: 设置定期安全审计
3. ✅ **学习最佳实践**: [SECURITY.md](SECURITY.md)
4. ✅ **加入社区**: GitHub Discussions

---

**需要帮助？**

- 📖 查看 [文档](docs/)
- 🐛 报告 [问题](https://github.com/veryboylb/openclaw-security-hardening/issues)
- 💬 参与 [讨论](https://github.com/veryboylb/openclaw-security-hardening/discussions)

**最后更新**: 2026-02-28
