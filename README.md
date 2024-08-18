# FOUNDRY STARTER

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?style=for-the-badge)
![Forge](https://img.shields.io/badge/forge-v0.2.0-blue.svg?style=for-the-badge)
![Solc](https://img.shields.io/badge/solc-v0.8.20-blue.svg?style=for-the-badge)
[![GitHub License](https://img.shields.io/github/license/trashpirate/foundry-starter?style=for-the-badge)](https://github.com/trashpirate/foundry-starter/blob/master/LICENSE)

[![Website: nadinaoates.com](https://img.shields.io/badge/Portfolio-00e0a7?style=for-the-badge&logo=Website)](https://nadinaoates.com)
[![LinkedIn: nadinaoates](https://img.shields.io/badge/LinkedIn-0a66c2?style=for-the-badge&logo=LinkedIn&logoColor=f5f5f5)](https://linkedin.com/in/nadinaoates)
[![Twitter: N0_crypto](https://img.shields.io/badge/@N0_crypto-black?style=for-the-badge&logo=X)](https://twitter.com/N0_crypto)

## About

1. Create a basic account abstraction contract on Ethereum:  
   A EOA is the owner of the MinimalAccount Contract which implements account abstraction. This way MinimalAccount constitutes a smart contract wallet can execute transactions on behalf of the wallet owner. The interesting feature of this is that the wallet can be transferred to a different owner whithout revealing the private key.
   Another way to validate a transaction could be that the EOA needs to hold an specific NFT.
2. Create a basic account abstraction contract on ZkSync
3. Deploy, and send a userOp / transaction through them (only ZkSync)

## Notes

Zksync uses multiple system contracts to handle operations such as deploying a contract. On Ethereum, contracts are deployed by sending a transaction without a receiver. That way the nodes know it's a deployment and not a regular transaction.

### ZkSync Transaction Type 113 (0x71) 
**Phase 1: Validation** 
1. The user sends the transaction to the ZkSync API client (like a "light node")
2. The ZkSync API client checks if the nonce is unique by querying the NonceHolder system contract: the NonceHolder contract stores the nonce for each account/contract.
3. The ZkSync API client calls validateTransaction, which MUST update the nonce in the NonceHolder contract. The msg.sender is always the bootloader system contract (like a super admin) for a 113 transaction (gets automatically rerouter to the bootloader contract).
4. The ZkSync API client checks if nonce is updated.
5. The ZkSync API client calls payForTransaction, or prepareForPaymaster & validateAndPayForPaymasterTransaction (checks if there are engouh funds to pay for the transaction).
6. The ZkSync API client verifies that the bootloader gets paid


**Phase 2: Execution**
1. The ZkSync API client passes the validated transaction to the main node / sequencer (as of today, they are the same).
2. Main node will call the executeTransaction function
3. If a paymaster is used, the postTransaction is called


## Installation

### Install dependencies

```bash
$ make install
```

## Usage

Before running any commands, create a .env file and add the following environment variables:

```bash
# network configs
RPC_LOCALHOST="http://127.0.0.1:8545"

# ethereum nework
RPC_TEST=<rpc url>
RPC_MAIN=<rpc url>
ETHERSCAN_KEY=<api key>

# accounts to deploy/interact with contracts
ACCOUNT_NAME="account name"
ACCOUNT_ADDRESS="account address"
```

Update chain ids in the `HelperConfig.s.sol` file for the chain you want to configure:

- Ethereum: 1 | Sepolia: 11155111
- Base: 8453 | Base sepolia: 84532
- Bsc: 56 | Bsc Testnet: 97

### Run tests

```bash
$ forge test
```

### Deploy contract on testnet

```bash
$ make deploy-arb-sepolia
```

### Deploy contract on mainnet

```bash
$ make deploy-arb-mainnet
```

## Deployments on Arbitrum

### Testnet
https://sepolia.arbiscan.io/address/0x6ac50f54ae891746c4c4ef7e9f46f0b293fd8989

### Mainnet
https://arbiscan.io/address/0xdcdf94053c9fcfe5bb7525c060b47bbc6d166ce3

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Author

👤 **Nadina Oates**

- Website: [nadinaoates.com](https://nadinaoates.com)
- Twitter: [@N0_crypto](https://twitter.com/N0_crypto)
- Github: [@trashpirate](https://github.com/trashpirate)
- LinkedIn: [@nadinaoates](https://linkedin.com/in/nadinaoates)

## 📝 License

Copyright © 2024 [Nadina Oates](https://github.com/trashpirate).
