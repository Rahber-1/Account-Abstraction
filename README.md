# ERC-4337 Smart Account with zkSync and Ethereum Support

This project implements an **ERC-4337 Smart Contract Wallet** with support for **Ethereum Sepolia, zkSync Sepolia, and Local (Anvil) networks**. It includes scripts for **deployment**, **configuration**, and **sending user operations**.

## 📂 Project Structure

```
├── src/
│   ├── Ethereum/
│   │   ├── MinimalAccount.sol  # Smart contract for ERC-4337 Minimal Account
│   │   ├── ZkSyncMinimalAccount.sol  # Smart contract for zkSync Minimal Account
│   ├── lib/account-abstraction/ # ERC-4337 dependencies
│   ├── mocks/ # OpenZeppelin mocks (if needed)
├── script/
│   ├── DeployMinimal.s.sol  # Script to deploy MinimalAccount
│   ├── HelperConfig.s.sol  # Network configuration helper
│   ├── SendPackedUserOp.s.sol  # Script to sign and send user operations
├── foundry.toml  # Foundry configuration file
├── README.md  # Project documentation
```

## 🛠 Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (for Solidity development)
- [Node.js & NPM](https://nodejs.org/) (if integrating with frontend or scripts)
- [OpenZeppelin Contracts](https://www.npmjs.com/package/@openzeppelin/contracts)
- [Account Abstraction (ERC-4337)](https://github.com/eth-infinitism/account-abstraction)

## 🚀 Setup

1. **Clone the repository**
   ```sh
   git clone https://github.com/your-repo/erc4337-smart-account.git
   cd erc4337-smart-account
   ```

2. **Install dependencies**
   ```sh
   forge install
   forge install OpenZeppelin/openzeppelin-contracts
   forge install eth-infinitism/account-abstraction
   ```

3. **Compile the contracts**
   ```sh
   forge build
   ```

## 🔨 Deployment

### Deploy MinimalAccount on Ethereum Sepolia

```sh
forge script script/DeployMinimal.s.sol --rpc-url <SEPOLIA_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

### Deploy MinimalAccount on Local Anvil Network

```sh
anvil &
forge script script/DeployMinimal.s.sol --rpc-url http://127.0.0.1:8545 --private-key <ANVIL_PRIVATE_KEY> --broadcast
```

## ⚙️ Configuration

The `HelperConfig.s.sol` file manages network configurations:

- **Ethereum Sepolia** (chain ID `11155111`)
- **zkSync Sepolia** (chain ID `300`)
- **Local Anvil** (chain ID `31337`)

To modify configurations, update `getEthSepoliaConfig()`, `getZksyncSepoliaConfig()`, or `getAnvilConfig()` in `HelperConfig.s.sol`.

## 📩 Sending User Operations

### Generate and Sign a Packed User Operation

```sh
forge script script/SendPackedUserOp.s.sol --rpc-url <NETWORK_RPC> --private-key <YOUR_PRIVATE_KEY>
```

This will:
1. **Generate a signed user operation** using the provided sender and calldata.
2. **Fetch the correct network entry point** from `HelperConfig`.
3. **Sign the operation using the private key**.

## 🛠 Debugging

### Running Tests
```sh
forge test
```

### Foundry Debugging
```sh
forge test -vvvv
```

### Simulate a Deployment
```sh
forge script script/DeployMinimal.s.sol --rpc-url <NETWORK_RPC> --sig "run()"
```

## 📜 License
This project is licensed under the **MIT License**.



