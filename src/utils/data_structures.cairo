mod DataStructures {
    use core::zeroable::Zeroable;
    use core::traits::Into;
    use starknet::contract_address::{
        ContractAddress,
        ContractAddressZeroable,
    };
    use starknet::{
        StorageAccess,
        StorageBaseAddress,
        SyscallResult,
        storage_read_syscall,
        storage_write_syscall,
        storage_address_from_base_and_offset
    };
    use zklink::utils::bytes::{
        Bytes,
        BytesTrait
    };

    #[derive(Copy, Drop, Serde)]
    struct RegisteredToken {
        registered: bool,               // whether token registered to ZkLink or not, default is false
        paused: bool,                   // whether token can deposit to ZkLink or not, default is false
        tokenAddress: ContractAddress,  // the token address
        decimals: u8,                   // the token decimals of layer one
        standard: bool                  // we will not check the balance different of zkLink contract after transfer when a token comply with erc20 standard
    }

    // This trait impl is just for devlopment progress going on.
    // TODO: remove this after StorageAccess derive macro
    impl RegisteredTokenStorageAccess of StorageAccess<RegisteredToken> {
        fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<RegisteredToken> {
            SyscallResult::Ok(RegisteredToken {
                registered: false,
                paused: false,
                tokenAddress: Zeroable::zero(),
                decimals: 0,
                standard: false
            })
        }
        fn write(address_domain: u32, base: StorageBaseAddress, value: RegisteredToken) -> SyscallResult<()> {
            SyscallResult::Ok(())
        }
    }

    // We can set `enableBridgeTo` and `enableBridgeTo` to false
    // to disable bridge when `bridge` is compromised
    #[derive(Copy, Drop, Serde)]
    struct BridgeInfo {
        bridge: ContractAddress,
        enableBridgeTo: bool,
        enableBridgeFrom: bool
    }

    // This trait impl is just for devlopment progress going on.
    // TODO: remove this after StorageAccess derive macro
    impl BridgeInfoStorageAccess of StorageAccess<BridgeInfo> {
        fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<BridgeInfo> {
            SyscallResult::Ok(BridgeInfo{
                bridge: Zeroable::zero(),
                enableBridgeTo: false,
                enableBridgeFrom: false
            })
        }
        fn write(address_domain: u32, base: StorageBaseAddress, value: BridgeInfo) -> SyscallResult<()> {
            SyscallResult::Ok(())
        }
    }

    // block stored data
    // `blockNumber`,`timestamp`,`stateHash`,`commitment` are the same on all chains
    // `priorityOperations`,`pendingOnchainOperationsHash` is different for each chain
    #[derive(Copy, Drop, Serde)]
    struct StoredBlockInfo {
        blockNumber: u64,                   // Rollup block number
        priorityOperations: u64,            // Number of priority operations processed
        pendingOnchainOperationsHash: u256, // Hash of all operations that must be processed after verify
        timestamp: u64,                     // Rollup block timestamp
        stateHash: u256,                    // Root hash of the rollup state
        commitment: u256,                   // Verified input for the ZkLink circuit
        syncHash: u256                      // Used for cross chain block verify
    }

    impl StoredBlockInfoIntoBytes of Into<StoredBlockInfo, Bytes> {
        fn into(self: StoredBlockInfo) -> Bytes {
            let mut bytes = BytesTrait::new_empty();
            bytes.append_u64(self.blockNumber);
            bytes.append_u64(self.priorityOperations);
            bytes.append_u256(self.pendingOnchainOperationsHash);
            bytes.append_u64(self.timestamp);
            bytes.append_u256(self.stateHash);
            bytes.append_u256(self.commitment);

            bytes
        }
    }

    // This trait impl is just for devlopment progress going on.
    // TODO: remove this after StorageAccess derive macro
    impl StoredBlockInfoStorageAccess of StorageAccess<StoredBlockInfo> {
        fn read(address_domain: u32, base: StorageBaseAddress) -> SyscallResult<StoredBlockInfo> {
            SyscallResult::Ok(StoredBlockInfo{
                blockNumber: 0,
                priorityOperations: 0,
                pendingOnchainOperationsHash: u256{low: 0, high: 0},
                timestamp: 0,
                stateHash: u256{low: 0, high: 0},
                commitment: u256{low: 0, high: 0},
                syncHash: u256{low: 0, high: 0}
            })
        }
        fn write(address_domain: u32, base: StorageBaseAddress, value: StoredBlockInfo) -> SyscallResult<()> {
            SyscallResult::Ok(())
        }
    }
    
    #[derive(Copy, Drop, PartialEq)]
    enum ChangePubkeyType {
        ECRECOVER: (),
        CREATE2: (),
    }

    // Data needed to process onchain operation from block public data.
    // Onchain operations is operations that need some processing on L1: Deposits, Withdrawals, ChangePubKey.
    #[derive(Drop, Serde)]
    struct OnchainOperationData {
        ethWitness: Bytes,      // Some external data that can be needed for operation processing
        publicDataOffset: usize // Byte offset in public data for onchain operation
    }

    // Data needed to commit new block
    // `publicData` contain pubdata of all chains when compressed is
    // disabled or only current chain if compressed is enable
    /// `onchainOperations` contain onchain ops of all chains when compressed is
    // disabled or only current chain if compressed is enable
    #[derive(Drop, Serde)]
    struct CommitBlockInfo {
        newStateHash: u256,
        publicData: Bytes,
        timestamp: u64,
        onchainOperations: Array<OnchainOperationData>,
        blockNumber: u64,
        feeAccount: u32
    }

    #[derive(Drop, Serde)]
    struct CompressedBlockExtraInfo {
        publicDataHash: u256,                       // pubdata hash of all chains
        offsetCommitmentHash: u256,                 // all chains pubdata offset commitment hash
        onchainOperationPubdataHashs: Array<u256>   // onchain operation pubdata hash of the all other chains
    }

    // Data needed to execute committed and verified block
    #[derive(Drop, Serde)]
    struct ExecuteBlockInfo {
        storedBlock: StoredBlockInfo,   // the block info that will be executed
        pendingOnchainOpsPubdata: Bytes // onchain ops(e.g. Withdraw, ForcedExit, FullExit) that will be executed
    }

    // Token info stored in zkLink
    #[derive(Drop, Serde)]
    struct Token {
        tokenId: u16,                   // token id defined by zkLink
        tokenAddress: ContractAddress,  // token address in l1
        decimals: u8,                   // token decimals in l1
        standard: bool                  // if token a pure erc20 or not
    }

    // Recursive proof input data (individual commitments are constructed onchain)
    #[derive(Drop, Serde)]
    struct ProofInput {
        recursiveInput: Array<u256>,
        proof: Array<u256>,
        commitments: Array<u256>,
        vkIndexes: Array<u8>,
        subproofsLimbs: Array<u256>
    }
}