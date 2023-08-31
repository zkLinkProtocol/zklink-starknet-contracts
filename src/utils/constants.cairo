// zkLink configuration constants
// Do not change those value as below, otherwise unit test will fail.
// And this value will be automatically modified by the automated
// deployment script based on the configuration file in the ./etc directory before deployment
// - BLOCK_PERIOD
// - PRIORITY_EXPIRATION
// - UPGRADE_NOTICE_PERIOD
// - CHAIN_ID
// - MIN_CHAIN_ID
// - MAX_CHAIN_ID
// - ALL_CHAINS
// - CHAIN_INDEX
// - ENABLE_COMMIT_COMPRESSED_BLOCK

const EMPTY_STRING_KECCAK: u256 =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

// Bytes in one chunk
// Attention: cairo only supports literal constants now.
//            If you want to change CHUNK_BYTES, you should
//            change the value of Operation chunks such as
//            DEPOSIT_BYTES as well!
const CHUNK_BYTES: usize = 23;

// Bytes of L2 PubKey hash
const PUBKEY_HASH_BYTES: usize = 20;

// Max amount of tokens registered in the network
const MAX_AMOUNT_OF_REGISTERED_TOKENS: u16 = 65535;

// Max account id that could be registered in the network, 2^24 - 1
const MAX_ACCOUNT_ID: u32 = 16777215;

// Max sub account id that could be bound to account id, 2^5 - 1
const MAX_SUB_ACCOUNT_ID: u8 = 31;

// Expected average period of block creation, default 15s
// In starknet, block_number and block_timestamp type is u64
const BLOCK_PERIOD: u64 = 15;

// Operation chunks:
// DEPOSIT_BYTES = 3 * CHUNK_BYTES
// FULL_EXIT_BYTES = 3 * CHUNK_BYTES
// WITHDRAW_BYTES = 3 * CHUNK_BYTES
// FORCED_EXIT_BYTES = 3 * CHUNK_BYTES
// CHANGE_PUBKEY_BYTES = 3 * CHUNK_BYTES
const DEPOSIT_BYTES: usize = 69;
const FULL_EXIT_BYTES: usize = 69;
const WITHDRAW_BYTES: usize = 69;
const FORCED_EXIT_BYTES: usize = 69;
const CHANGE_PUBKEY_BYTES: usize = 69;

// Expiration delta for priority request to be satisfied (in ETH blocks)
// PRIORITY_EXPIRATION(default 80640) = PRIORITY_EXPIRATION_PERIOD / BLOCK_PERIOD, 
const PRIORITY_EXPIRATION: u64 = 0;

// Notice period before activation preparation status of upgrade mode (in seconds)
// NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
// UPGRADE_NOTICE_PERIOD(default 1814400) = MASS_FULL_EXIT_PERIOD(432000, 5 days) + PRIORITY_EXPIRATION_PERIOD + TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT(172800, 2 days)
const UPGRADE_NOTICE_PERIOD: u64 = 0;

// Max commitment produced in zk proof where highest 3 bits is 0
const MAX_PROOF_COMMITMENT: u256 =
    0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

// Bit mask to apply for verifier public input before verifying.
const INPUT_MASK: u256 = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

// Auth fact reset timelock(in seconds)
// AUTH_FACT_RESET_TIMELOCK default is 1 days
const AUTH_FACT_RESET_TIMELOCK: u64 = 86400;

// Max deposit of ERC20 token that is possible to deposit, 2^104 - 1
const MAX_DEPOSIT_AMOUNT: u128 = 20282409603651670423947251286015;

// Chain id defined by ZkLink
const CHAIN_ID: u8 = 1;

// Min chain id defined by ZkLink
const MIN_CHAIN_ID: u8 = 1;

// Max chain id defined by ZkLink
const MAX_CHAIN_ID: u8 = 4;

// All chain index, for example [1, 2, 3, 4] => 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 = 15
const ALL_CHAINS: u256 = 15;

// Chain index, CHAIN_ID is non-zero value
const CHAIN_INDEX: u256 = 1;

// Enable commit a compressed block
// Now, in cairo only literal constants are currently supported.
// It should be 1 if true, be 0 if false.
const ENABLE_COMMIT_COMPRESSED_BLOCK: felt252 = 1;

// When set fee = 100, it means 1%
const MAX_ACCEPT_FEE_RATE: u16 = 10000;

// Token decimals is a fixed value at layer two in ZkLink
const TOKEN_DECIMALS_OF_LAYER2: u8 = 18;

// Global asset account in the network
// Can not deposit to or full exit this account
const GLOBAL_ASSET_ACCOUNT_ID: u32 = 1;
const GLOBAL_ASSET_ACCOUNT_ADDRESS: u256 =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

// USD and USD stable tokens defined by zkLink
// User can deposit USD stable token(eg. USDC, BUSD) to get USD in layer two
// And user also can full exit USD in layer two and get back USD stable tokens
const USD_TOKEN_ID: u16 = 1;
const MIN_USD_STABLE_TOKEN_ID: u16 = 17;
const MAX_USD_STABLE_TOKEN_ID: u16 = 31;
