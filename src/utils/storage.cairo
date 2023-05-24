mod Storage {
    use core::zeroable::Zeroable;
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
    
}