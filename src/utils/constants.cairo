// zkLink configuration constants
use starknet::ContractAddress;

const EMPTY_STRING_KECCAK: u256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

// ERC20 tokens and ETH withdrawals gas limit, used only for complete withdrawals
const WITHDRAWAL_GAS_LIMIT: u256 = 100000;

// Bytes in one chunk
const CHUNK_BYTES: usize = 19;

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
// TODO: replace before deploy
const BLOCK_PERIOD: u64 = 15;

// Operation chunks:
// DEPOSIT_BYTES = 3 * CHUNK_BYTES
// FULL_EXIT_BYTES = 3 * CHUNK_BYTES
// WITHDRAW_BYTES = 3 * CHUNK_BYTES
// FORCED_EXIT_BYTES = 3 * CHUNK_BYTES
// CHANGE_PUBKEY_BYTES = 3 * CHUNK_BYTES
const DEPOSIT_BYTES: usize = 57;
const FULL_EXIT_BYTES: usize = 57;
const WITHDRAW_BYTES: usize = 57;
const FORCED_EXIT_BYTES: usize = 57;
const CHANGE_PUBKEY_BYTES: usize = 57;

// Expiration delta for priority request to be satisfied (in seconds)
// NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
// otherwise incorrect block with priority op could not be reverted.
// PRIORITY_EXPIRATION_PERIOD default is 14 days
const PRIORITY_EXPIRATION_PERIOD: u64 = 1209600;

// Expiration delta for priority request to be satisfied (in ETH blocks)
// PRIORITY_EXPIRATION = PRIORITY_EXPIRATION_PERIOD / BLOCK_PERIOD
// TODO: replace before deploy
const PRIORITY_EXPIRATION: u64 = 80640;

// Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
// MASS_FULL_EXIT_PERIOD default is 5 days
const MASS_FULL_EXIT_PERIOD: u64 = 432000;

// Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
// TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT default is 2 days
const TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT: u64 = 172800;

// Notice period before activation preparation status of upgrade mode (in seconds)
// NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
// UPGRADE_NOTICE_PERIOD = MASS_FULL_EXIT_PERIOD + PRIORITY_EXPIRATION_PERIOD + TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT
// TODO: replace before deploy
const UPGRADE_NOTICE_PERIOD: u64 = 1814400;

// Max commitment produced in zk proof where highest 3 bits is 0
const MAX_PROOF_COMMITMENT: u256 = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

// Bit mask to apply for verifier public input before verifying.
const INPUT_MASK: u256 = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

// Auth fact reset timelock(in seconds)
// AUTH_FACT_RESET_TIMELOCK default is 1 days
const AUTH_FACT_RESET_TIMELOCK: u64 = 86400;

// Max deposit of ERC20 token that is possible to deposit, 2^104 - 1
const MAX_DEPOSIT_AMOUNT: u128 = 20282409603651670423947251286015;

// Chain id defined by ZkLink
// TODO: check before deploy
const CHAIN_ID: u8 = 10;

// Min chain id defined by ZkLink
// TODO: check before deploy
const MIN_CHAIN_ID: u8 = 1;

// Max chain id defined by ZkLink
// TODO: check before deploy
const MAX_CHAIN_ID: u8 = 10;

// All chain index, for example [1, 2, 3, 4] => 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 = 15
// TODO: check before deploy
const ALL_CHAINS: u256 = 1023;

// Chain index, CHAIN_ID is non-zero value
// TODO: check before deploy
const CHAIN_INDEX: u256 = 512;

// Enable commit a compressed block
// TODO: check before deploy
// Now, in cairo only literal constants are currently supported.
// It should be 1 if true, be 0 if false.
const ENABLE_COMMIT_COMPRESSED_BLOCK: bool = 1;

// When set fee = 100, it means 1%
const MAX_ACCEPT_FEE_RATE: u16 = 10000;

// see EIP-712
// CHANGE_PUBKEY_DOMAIN_SEPARATOR = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
const CHANGE_PUBKEY_DOMAIN_SEPARATOR: u256 = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
// CHANGE_PUBKEY_HASHED_NAME =  keccak256("ZkLink");
const CHANGE_PUBKEY_HASHED_NAME: u256 = 0x5d27f4d7e0e8a0cba7984286ccb8f517d40889161f782642f4bde6b8ac718965;
// CHANGE_PUBKEY_HASHED_VERSION = keccak256("1");
const CHANGE_PUBKEY_HASHED_VERSION: u256 = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
// CHANGE_PUBKEY_TYPE_HASH = keccak256("ChangePubKey(bytes20 pubKeyHash,uint32 nonce,uint32 accountId)");
const CHANGE_PUBKEY_TYPE_HASH: u256 = 0x8012078cc90c4c82e493f1a538159fd8621f39392101b34fba2ecd141432580b;

// Token decimals is a fixed value at layer two in ZkLink
const TOKEN_DECIMALS_OF_LAYER2: u8 = 18;

// Global asset account in the network
// Can not deposit to or full exit this account
const GLOBAL_ASSET_ACCOUNT_ID: u32 = 1;
const GLOBAL_ASSET_ACCOUNT_ADDRESS: ContractAddress = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

// USD and USD stable tokens defined by zkLink
// User can deposit USD stable token(eg. USDC, BUSD) to get USD in layer two
// And user also can full exit USD in layer two and get back USD stable tokens
const USD_TOKEN_ID: u16 = 1;
const MIN_USD_STABLE_TOKEN_ID: u16 = 17;
const MAX_USD_STABLE_TOKEN_ID: u16 = 31;