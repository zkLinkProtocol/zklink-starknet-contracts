#[contract]
mod Zklink {
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_info;

    use zklink::contracts::IERC20::IERC20Dispatcher;
    use zklink::contracts::IERC20::IERC20LibraryDispatcher;

    use zklink::utils::bytes::{Bytes, BytesTrait};
    use zklink::utils::operations::Operations::{
        OpType,
        OpTypeIntoU8,
        U8TryIntoOpType,
        PriorityOperation,
    };
    use zklink::utils::storage::Storage::{
        RegisteredToken,
        BridgeInfo,
        StoredBlockInfo
    };
    
    
    struct Storage {
        // public
        // Verifier contract. Used to verify block proof and exit proof
        verifier: ContractAddress,

        // public
        // Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
        totalBlocksExecuted: u32,

        // public
        // First open priority request id
        firstPriorityRequestId: u64,

        // public
        // The the owner of whole system
        networkGovernor: ContractAddress,

        // public
        // Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
        totalBlocksCommitted: u32,

        // public
        // Total number of requests
        totalOpenPriorityRequests: u64,

        // public
        // Total blocks proven
        totalBlocksProven: u32,

        // public
        // Total number of committed requests.
        // Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
        totalCommittedPriorityRequests: u64,

        // public
        // Latest synchronized block height
        totalBlocksSynchronized: u32,

        // public
        // Flag indicates that exodus (mass exit) mode is triggered
        // Once it was raised, it can not be cleared again, and all users must exit
        exodusMode: bool,

        // internal
        // Root-chain balances (per owner and token id, see packAddressAndTokenId) to withdraw
        // the amount of pending balance need to recovery decimals when withdraw
        pendingBalances: LegacyMap::<felt252, u128>,

        // public
        // Flag indicates that a user has exited a certain token balance in the exodus mode
        // The struct of this map is (accountId ,subAccountId, withdrawTokenId, deductTokenId) => performed
        // withdrawTokenId is the token that withdraw to user in l1
        // deductTokenId is the token that deducted from user in l2
        performedExodus: LegacyMap::<(u32, u8, u16, u16), bool>,

        // internal
        // Priority Requests mapping (request id - operation)
        // Contains op type, pubdata and expiration block of unsatisfied requests.
        // Numbers are in order of requests receiving
        priorityRequests: LegacyMap::<u64, PriorityOperation>,

        // public
        // User authenticated fact hashes for some nonce.
        // (owner, nonce) => hash.
        authFacts: LegacyMap::<(ContractAddress, u32), u256>,

        // internal
        // Timer for authFacts entry reset (address, nonce) => timer.
        // Used when user wants to reset `authFacts` for some nonce.
        authFactsResetTimer: LegacyMap::<(ContractAddress, u32), u64>,

        // internal
        // Stored hashed StoredBlockInfo for some block number
        // Block number is u64 in Starknet
        storedBlockHashes: LegacyMap::<u64, u256>,

        // internal
        // if (`synchronizedChains` | CHAIN_INDEX) == `ALL_CHAINS` defined in `constants.cairo` then blocks at `blockHeight` and before it can be executed
        // the key is the `syncHash` of `StoredBlockInfo`
        // the value is the `synchronizedChains` of `syncHash` collected from all other chains
        synchronizedChains: LegacyMap::<u256, u256>,

        // public
        // Accept infos of fast withdraw of account
        // (accountId, keccak256(receiver, tokenId, amount, withdrawFeeRate, nonce)) => accepter address
        accepts: LegacyMap::<(u32, u256), ContractAddress>,

        // internal
        // Broker allowance used in accept, accepter can authorize broker to do accept
        // Similar to the allowance of transfer in ERC20
        // (tokenId, accepter, broker) => allowance
        brokerAllowances: LegacyMap::<(u16, ContractAddress, ContractAddress), u128>,

        // public
        // A set of permitted validators
        validators: LegacyMap::<ContractAddress, bool>,

        // public
        // A map of registered token infos
        tokens: LegacyMap::<u16, RegisteredToken>,

        // public
        // A map of registered token infos
        tokenIds: LegacyMap::<ContractAddress, u16>,

        // public
        // using map instead of array, index => BridgeInfo
        bridges: LegacyMap::<u256, BridgeInfo>,

        // public
        // 0 is reversed for non-exist bridge, existing bridges are indexed from 1
        bridgeIndex: LegacyMap::<ContractAddress, u256>,
    }

}