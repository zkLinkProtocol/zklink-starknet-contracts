#[contract]
mod Zklink {
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_info;

    // use zklink::contracts::IERC20::IERC20Dispatcher;
    // use zklink::contracts::IERC20::IERC20LibraryDispatcher;

    use zklink::utils::bytes::{Bytes, BytesTrait};
    use zklink::contracts::operations::Operations::{
        OpType,
        OpTypeIntoU8,
        U8TryIntoOpType
    };
    
    
    struct Storage {
        // public, Verifier contract. Used to verify block proof and exit proof
        verifier: ContractAddress,

        // public, Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
        totalBlocksExecuted: u32,

        // public, First open priority request id
        firstPriorityRequestId: u64,

        // public, The the owner of whole system
        networkGovernor: ContractAddress,

        // public, Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
        totalBlocksCommitted: u32,

        // public, Total number of requests
        totalOpenPriorityRequests: u64,

        // public, Total blocks proven
        totalBlocksProven: u32,

        // public, Total number of committed requests.
        // Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
        totalCommittedPriorityRequests: u64,

        // public, Latest synchronized block height
        totalBlocksSynchronized: u32,

        // public, Flag indicates that exodus (mass exit) mode is triggered
        // Once it was raised, it can not be cleared again, and all users must exit
        exodusMode: bool,

        // internal, Root-chain balances (per owner and token id, see packAddressAndTokenId) to withdraw
        // the amount of pending balance need to recovery decimals when withdraw
        // pendingBalances: LegacyMap::<felt252, u128>,

        // public, Flag indicates that a user has exited a certain token balance in the exodus mode
        // The struct of this map is (accountId ,subAccountId, withdrawTokenId, deductTokenId) => performed
        // withdrawTokenId is the token that withdraw to user in l1
        // deductTokenId is the token that deducted from user in l2
        // performedExodus: LegacyMap::<(u32, u8, u16, u16), bool>,

        // internal, Priority Requests mapping (request id - operation)
        // Contains op type, pubdata and expiration block of unsatisfied requests.
        // Numbers are in order of requests receiving
        // priorityRequests: LegacyMap::<u64, >,
    }

}