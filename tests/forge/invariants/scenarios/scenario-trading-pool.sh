#!/bin/bash
# configuration for panic exit from pool
export QUOTE_PRECISION=6
export COLLATERAL_PRECISION=6
export BUCKET_INDEX_ERC20=2000
export BUCKET_INDEX_ERC721=1000
export NO_OF_BUCKETS=20
export MIN_QUOTE_AMOUNT_ERC20=1000
# 1e30
export MAX_QUOTE_AMOUNT_ERC20=1000000000000000000000000000000
export MIN_COLLATERAL_AMOUNT_ERC20=1000
# 1e30
export MAX_COLLATERAL_AMOUNT_ERC20=1000000000000000000000000000000
export MIN_QUOTE_AMOUNT_ERC721=1000
# 1e30
export MAX_QUOTE_AMOUNT_ERC721=1000000000000000000000000000000
export MIN_COLLATERAL_AMOUNT_ERC721=1
export MAX_COLLATERAL_AMOUNT_ERC721=100
# 1 minute
export SKIP_TIME=60
export FOUNDRY_INVARIANT_RUNS=1
export FOUNDRY_INVARIANT_DEPTH=1000
export FOUNDRY_INVARIANT_SHRINK_SEQUENCE=false
export LOGS_VERBOSITY=1