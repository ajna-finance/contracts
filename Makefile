# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env && source ./tests/forge/invariants/scenarios/scenario-${SCENARIO}.sh

all: clean install build

# Clean the repo
clean   :; forge clean

# Install the Modules
install :; git submodule update --init --recursive

# Builds
build   :; forge clean && forge build

# Tests
test                            :; forge test --no-match-test "testLoad|invariant|test_regression"  # --ffi # enable if you need the `ffi` cheat code on HEVM
test-with-gas-report            :; forge test --no-match-test "testLoad|invariant|test_regression" --gas-report # --ffi # enable if you need the `ffi` cheat code on HEVM
test-load                       :; forge test --match-test testLoad --gas-report
test-invariant-all              :; forge t --mt invariant --nmc RegressionTest
test-invariant-erc20            :; forge t --mt invariant --nmc RegressionTest --mc ERC20
test-invariant-erc721           :; forge t --mt invariant --nmc RegressionTest --mc ERC721
test-invariant-position         :; forge t --mt invariant --nmc RegressionTest --mc Position
test-invariant-rewards          :; forge t --mt invariant --nmc RegressionTest --mc Rewards
test-invariant                  :; forge t --mt ${MT} --nmc RegressionTest
test-regression-all             : test-regression-erc20 test-regression-erc721 test-regression-position test-regression-rewards
test-regression-erc20           :; forge t --mt test_regression --mc ERC20
test-regression-erc721          :; forge t --mt test_regression --mc ERC721
test-regression-position        :; forge t --mt test_regression --mc Position
test-regression-rewards         :; forge t --mt test_regression --mc Rewards
test-regression                 :; forge t --mt ${MT}
coverage                        :; forge coverage --no-match-test "testLoad|invariant"
test-invariant-erc20-precision  :; ./tests/forge/invariants/test-invariant-erc20-precision.sh
test-invariant-erc721-precision :; ./tests/forge/invariants/test-invariant-erc721-precision.sh
test-invariant-erc20-buckets    :; ./tests/forge/invariants/test-invariant-erc20-buckets.sh
test-invariant-erc721-buckets   :; ./tests/forge/invariants/test-invariant-erc721-buckets.sh

# Generate Gas Snapshots
snapshot :; forge clean && forge snapshot

analyze:
		slither src/. ; slither src/libraries/external/.


# Deployment
deploy-contracts:
	forge script script/deploy.s.sol \
		--rpc-url ${ETH_RPC_URL} --sender ${DEPLOY_ADDRESS} --keystore ${DEPLOY_KEY} --broadcast -vvv --verify
