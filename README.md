# Meme Factory

一个基于 Foundry 的 ERC20 Meme Token 工厂平台，允许用户快速创建和铸造 Meme 代币。

## 🚀 项目概述

Meme Factory 是一个去中心化的代币工厂平台，具有以下特性：

- **快速部署**: 使用 EIP-1167 最小代理模式，大幅降低 Gas 成本
- **灵活铸造**: 支持自定义参数的代币铸造
- **费用分配**: 自动按 1% : 99% 分配费用给项目方和发行者
- **安全可靠**: 基于 OpenZeppelin 库，经过全面测试
- **易于使用**: 简洁的接口设计，支持批量操作

## 📁 项目结构

```
meme-factory/
├── src/                          # 合约源码
│   ├── MemeToken.sol            # Meme 代币合约
│   ├── MemeFactory.sol          # 工厂合约
│   └── IMemeToken.sol           # 代币接口
├── test/                         # 测试文件
│   ├── CoreFunctionalityTest.t.sol    # 核心功能测试
│   ├── SecurityTest.t.sol              # 安全测试
│   ├── DeployMeme.t.sol               # 部署测试
│   └── ...                            # 其他测试文件
├── script/                       # 部署脚本
│   ├── MemeFactory.s.sol        # 工厂部署脚本
│   └── LocalDeploymentTest.s.sol # 本地部署测试
├── docs/                         # 文档
│   ├── 技术架构说明文档.md
│   ├── 安全审查报告.md
│   ├── Phase4-Task4.1-测试报告.md
│   └── Phase5-Task5.1-本地部署验证报告.md
├── lib/                          # 依赖库
│   └── openzeppelin-contracts/   # OpenZeppelin 合约库
├── foundry.toml                  # Foundry 配置
├── README.md                     # 项目说明
└── test-log.txt                  # 测试日志
```

## 🛠️ 技术栈

- **Solidity**: ^0.8.20
- **Foundry**: 开发框架
- **OpenZeppelin**: 安全合约库
- **EIP-1167**: 最小代理模式
- **ERC20**: 代币标准

## 📋 功能特性

### 核心功能
- ✅ **代币部署**: 通过工厂快速部署 Meme 代币
- ✅ **代币铸造**: 支持自定义数量的代币铸造
- ✅ **费用管理**: 自动费用分配和管理
- ✅ **权限控制**: 基于 OpenZeppelin 的访问控制
- ✅ **暂停机制**: 紧急情况下的暂停功能

### 安全特性
- ✅ **重入保护**: 使用 ReentrancyGuard
- ✅ **初始化保护**: 防止重复初始化
- ✅ **输入验证**: 全面的参数验证
- ✅ **边界检查**: 防止溢出和下溢
- ✅ **访问控制**: 严格的权限管理

## 🚀 快速开始

### 环境要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/)

### 安装依赖

```bash
# 克隆项目
git clone <repository-url>
cd meme-factory

# 安装依赖
forge install
```

### 编译合约

```bash
forge build
```

### 运行测试

```bash
# 运行所有测试
forge test

# 运行核心功能测试
forge test --match-contract CoreFunctionalityTest

# 运行安全测试
forge test --match-contract SecurityTest

# 详细输出
forge test -vv
```

## 🧪 测试说明

### 测试套件

项目包含多个测试套件，覆盖不同功能模块：

#### 1. CoreFunctionalityTest (核心功能测试)
- **测试数量**: 7个测试
- **通过率**: 100%
- **覆盖功能**: 代币部署、铸造、费用分配、超额保护

```bash
forge test --match-contract CoreFunctionalityTest -vv
```

#### 2. DeployMemeTest (部署测试)
- **测试数量**: 16个测试
- **通过率**: 100%
- **覆盖功能**: 代币部署、参数验证、事件记录

```bash
forge test --match-contract DeployMemeTest -vv
```

#### 3. InterfaceIntegrationTest (接口集成测试)
- **测试数量**: 4个测试
- **通过率**: 100%
- **覆盖功能**: 接口编译、工厂集成、函数存在性

```bash
forge test --match-contract InterfaceIntegrationTest -vv
```

#### 4. SimpleMintTest (简单铸造测试)
- **测试数量**: 1个测试
- **通过率**: 100%
- **覆盖功能**: 基础铸造功能

```bash
forge test --match-contract SimpleMintTest -vv
```

### 测试结果

最新测试结果（28个测试）：
- **通过测试**: 28个 (100%)
- **失败测试**: 0个 (0%)
- **核心功能**: 100% 通过

### 测试日志

完整的测试日志已保存在 `test-log.txt` 文件中：

```bash
# 查看测试日志
cat test-log.txt

# 查看核心功能测试日志
cat core-functionality-test-log.txt
```

## 🚀 部署说明

### 本地部署 (Anvil)

1. **启动本地链**
```bash
anvil --host 0.0.0.0 --port 8545
```

2. **设置环境变量**
```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

3. **运行部署脚本**
```bash
forge script script/LocalDeploymentTest.s.sol --rpc-url http://localhost:8545 --broadcast -vvv
```

### 生产环境部署

1. **配置网络**
```bash
# 设置 RPC URL
export RPC_URL=<your-rpc-url>

# 设置私钥
export PRIVATE_KEY=<your-private-key>
```

2. **部署工厂合约**
```bash
forge script script/MemeFactory.s.sol --rpc-url $RPC_URL --broadcast --verify
```

## 📖 使用指南

### 1. 部署代币

```solidity
// 通过工厂部署代币
address tokenAddress = factory.deployMeme{value: 0.01 ether}(
    "My Meme Token",    // 代币名称
    "MMT",              // 代币符号
    1_000_000 * 10**18, // 总供应量限制
    1000,               // 每次铸造数量
    1 wei               // 代币价格
);
```

### 2. 铸造代币

```solidity
// 铸造代币
uint256 mintAmount = 1000;
uint256 payment = mintAmount * token.price();
factory.mintMeme{value: payment}(tokenAddress, mintAmount);
```

### 3. 查询代币信息

```solidity
IMemeToken token = IMemeToken(tokenAddress);

// 获取代币信息
string memory name = token.name();
string memory symbol = token.symbol();
uint256 totalSupply = token.totalSupply();
uint256 balance = token.balanceOf(user);
```

## 🔧 配置说明

### Foundry 配置

项目使用 `foundry.toml` 进行配置：

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.25"
optimizer = true
optimizer_runs = 200
via_ir = false
verbosity = 2
fuzz = { runs = 1000 }
invariant = { runs = 256 }
gas_reports = ["*"]
```

### 默认参数

工厂合约的默认参数：

- **总供应量限制**: 1,000,000,000 个代币
- **每次铸造**: 100,000,000 个代币
- **代币价格**: 0.001 ETH
- **创建费用**: 0.01 ETH

## 📊 费用结构

### 创建费用
- **代币创建**: 0.01 ETH
- **费用用途**: 工厂维护和开发

### 铸造费用
- **项目方**: 1% (用于平台维护)
- **发行者**: 99% (给代币发行者)
- **计算方式**: `mintAmount * tokenPrice`

## 🛡️ 安全考虑

### 已实施的安全措施

1. **重入攻击保护**: 使用 OpenZeppelin ReentrancyGuard
2. **初始化保护**: 防止重复初始化攻击
3. **访问控制**: 基于角色的权限管理
4. **输入验证**: 全面的参数验证
5. **边界检查**: 防止整数溢出和下溢

### 安全审计

项目已通过全面的安全测试，包括：
- 边界条件测试
- 异常情况处理
- 访问控制验证
- 重入攻击测试

详细的安全审查报告请参考 `docs/安全审查报告.md`。

## 📈 性能优化

### Gas 优化

- **最小代理**: 使用 EIP-1167 减少部署成本
- **批量操作**: 支持批量代币创建
- **存储优化**: 合理的存储布局设计

### 成本估算

- **工厂部署**: ~2,000,000 gas
- **代币创建**: ~600,000 gas
- **代币铸造**: ~50,000 gas

## 🤝 贡献指南

### 开发环境设置

1. **Fork 项目**
2. **创建功能分支**
3. **编写测试**
4. **提交 Pull Request**

### 代码规范

- 使用 Solidity 0.8.20+
- 遵循 OpenZeppelin 最佳实践
- 编写完整的测试用例
- 添加详细的注释

## 📄 许可证

MIT License

## 📞 联系方式

- **项目地址**: [GitHub Repository]
- **文档**: [Documentation]
- **问题反馈**: [Issues]

## 🎯 路线图

### 已完成功能
- ✅ 基础代币工厂
- ✅ 铸造功能
- ✅ 费用分配
- ✅ 安全测试
- ✅ 本地部署验证

### 计划功能
- 🔄 多链支持
- 🔄 代币模板库
- 🔄 治理功能
- 🔄 前端界面

## 📚 相关文档

- [技术架构说明文档](docs/技术架构说明文档.md)
- [安全审查报告](docs/安全审查报告.md)
- [测试报告](docs/Phase4-Task4.1-测试报告.md)
- [部署验证报告](docs/Phase5-Task5.1-本地部署验证报告.md)

## 🏆 测试截图

### 核心功能测试通过
```
Ran 7 tests for test/CoreFunctionalityTest.t.sol:CoreFunctionalityTest
[PASS] test_CompleteWorkflow() (gas: 822669)
[PASS] test_CustomMintAmount() (gas: 737216)
[PASS] test_DefaultParameters() (gas: 638896)
[PASS] test_FeeDistributionCorrectness() (gas: 745422)
[PASS] test_MemeDeployment() (gas: 661330)
[PASS] test_OverflowMintRevert() (gas: 782131)
[PASS] test_SingleMintSuccess() (gas: 746832)
Suite result: ok. 7 passed; 0 failed; 0 skipped
```

### 本地部署验证成功
```
=== Deployment Test Completed Successfully! ===
Factory deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Token deployed at: 0xB7A5bd0345EF1Cc5E66bf61BdeC17D2461fBd968
Token balance verification: Correct: true
Minted amount verification: Correct: true
Total supply verification: Correct: true
```

---

**Meme Factory** - 让 Meme 代币创建变得简单、安全、高效！ 🚀