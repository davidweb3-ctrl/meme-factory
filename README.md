# Meme Factory

一个基于以太坊的去中心化平台，允许用户快速创建 ERC20 Meme Token。平台采用最小代理模式（EIP-1167）来减少 Gas 费用，提高用户体验。

## 🚀 项目特性

- **Gas 优化**: 使用 EIP-1167 最小代理模式，显著减少部署新 Token 的 Gas 费用
- **标准兼容**: 基于 OpenZeppelin ERC20 标准，确保安全性和兼容性
- **Meme 功能**: 内置销毁机制，支持自定义销毁率
- **工厂模式**: 统一的 Token 创建和管理接口
- **完整测试**: 使用 Foundry 进行全面的测试覆盖

## 🏗️ 技术架构

### 核心模块

1. **MemeToken**: ERC20 Token 实现合约
   - 支持自定义 Token 名称、符号、总供应量
   - 内置销毁机制（可配置销毁率）
   - 基于 OpenZeppelin 安全标准

2. **MemeFactory**: Token 工厂合约
   - 使用 EIP-1167 最小代理模式
   - 管理 Token 创建和注册
   - 支持暂停/恢复功能

3. **测试模块**: 全面的测试覆盖
   - 单元测试
   - 集成测试
   - Gas 优化验证

### 技术栈

- **开发框架**: Foundry
- **合约语言**: Solidity 0.8.20+
- **代理模式**: EIP-1167 最小代理
- **标准库**: OpenZeppelin Contracts v5.4.0
- **测试框架**: Foundry Test Suite

## 📁 项目结构

```
meme-factory/
├── docs/
│   └── 技术架构说明文档.md
├── src/
│   ├── MemeToken.sol      # ERC20 Token 实现
│   └── MemeFactory.sol    # Token 工厂合约
├── test/
│   └── MemeFactory.t.sol  # 测试文件
├── script/
│   └── MemeFactory.s.sol  # 部署脚本
├── lib/
│   ├── forge-std/         # Foundry 标准库
│   └── openzeppelin-contracts/  # OpenZeppelin 合约库
├── foundry.toml           # Foundry 配置
└── README.md
```

## 🛠️ 开发环境设置

### 前置要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd meme-factory
```

2. 安装依赖
```bash
forge install
```

3. 编译合约
```bash
forge build
```

4. 运行测试
```bash
forge test
```

## 🧪 测试

项目包含全面的测试套件：

```bash
# 运行所有测试
forge test

# 运行特定测试
forge test --match-test test_FactoryDeployment

# 运行详细测试
forge test -vvv

# 生成 Gas 报告
forge test --gas-report
```

## 🚀 部署

### 本地部署

```bash
# 启动本地节点
anvil

# 部署到本地网络
forge script script/MemeFactory.s.sol --rpc-url http://localhost:8545 --broadcast
```

### 测试网部署

```bash
# 部署到 Sepolia 测试网
forge script script/MemeFactory.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

## 📊 Gas 优化

通过使用 EIP-1167 最小代理模式，相比直接部署完整合约，Gas 费用可减少约 90%：

- 直接部署: ~2,000,000 gas
- 代理部署: ~200,000 gas

## 🔒 安全特性

- 基于 OpenZeppelin 安全标准
- 重入攻击保护
- 访问控制机制
- 暂停/恢复功能
- 完整的测试覆盖

## 📈 未来计划

- [ ] 支持 EIP-2612 签名授权
- [ ] 集成 Layer 2 解决方案
- [ ] 实现更高级的代理模式
- [ ] 添加流动性挖矿功能
- [ ] 社区治理机制

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 📞 联系方式

如有问题，请通过以下方式联系：

- GitHub Issues
- Email: [your-email@example.com]

---

**注意**: 这是一个实验性项目，请在生产环境使用前进行充分测试。