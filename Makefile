
-include .env

.PHONY: all test clean deploy

DEFAULT_ANVIL_ADDRESS := 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install foundry-rs/forge-std --no-commit && forge install Cyfrin/foundry-devops --no-commit && forge install eth-infinitism/account-abstraction@v0.7.0 --no-commit && forge install Openzeppelin/openzeppelin-contracts --no-commit

# update dependencies
update:; forge update

# compile
build:; forge build

# test
test :; forge test 
test-local :; forge test --rpc-url $(RPC_LOCALHOST) -vvv

# test coverage
coverage:; @forge coverage --contracts src
coverage-report:; @forge coverage --contracts src --report debug > coverage.txt

# take snapshot
snapshot :; forge snapshot

# format
format :; forge fmt

# spin up local test network
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# spin up fork
fork :; @anvil --fork-url ${RPC_ETH_MAIN} --fork-block-number 20544360 --fork-chain-id 1 --chain-id 1234

# security
slither :; slither ./src 

# test
test :; @forge test

test-zksync :; @forge test --zksync --system-mode=true

# deployment
deploy-local: 
	@forge script script/DeployMinimalAccount.s.sol:DeployMinimalAccount --rpc-url $(RPC_LOCALHOST) --private-key ${DEFAULT_ANVIL_KEY} --sender ${DEFAULT_ANVIL_ADDRESS} --broadcast 

deploy-arb-sepolia: 
	@forge script script/DeployMinimalAccount.s.sol:DeployMinimalAccount --rpc-url $(RPC_ARB_SEPOLIA) --account ${ACCOUNT_NAME} --sender ${ACCOUNT_ADDRESS} --broadcast --verify --etherscan-api-key ${ARBISCAN_API_KEY} -vvvv

deploy-arb-mainnet: 
	@forge script script/DeployMinimalAccount.s.sol:DeployMinimalAccount --rpc-url $(RPC_ARB_MAIN) --account ${ACCOUNT_NAME} --sender ${ACCOUNT_ADDRESS} --broadcast --verify --etherscan-api-key ${ARBISCAN_API_KEY} -vvvv

senduserops-arb-mainnet:
	@forge script script/SendPackedUserOp.s.sol:SendPackedUserOp --rpc-url $(RPC_ARB_MAIN) --account Test-Account1 --broadcast

# verification
verify-contract:
	@args=$$(cast abi-encode "constructor(address)" 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789); \
	forge verify-contract \
	--chain-id 42161 \
	--watch \
	--constructor-args $$args \
	--etherscan-api-key ${ARBISCAN_API_KEY} \
	--compiler-version v0.8.24+commit.e11b9ed9 \
	0x002FE7559d53a843b127d1f964bc13C38f0d3AD7 \
	src/ethereum/MinimalAccount.sol:MinimalAccount;

# command line interaction
contract-call:
	@cast call <contract address> "FunctionSignature(params)(returns)" arguments --rpc-url ${<RPC>}




-include ${FCT_PLUGIN_PATH}/makefile-external