mod DataStructures {
    use zeroable::Zeroable;
    use traits::{Into, TryInto, Default};
    use option::OptionTrait;
    use clone::Clone;
    use starknet::contract_address::{ContractAddress, ContractAddressZeroable,};
    use starknet::{
        Store, StorageBaseAddress, SyscallResult, storage_read_syscall, storage_write_syscall,
        storage_address_from_base_and_offset
    };
    use zklink::utils::bytes::{Bytes, BytesTrait, ReadBytes};

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct RegisteredToken {
        registered: bool, // whether token registered to ZkLink or not, default is false
        paused: bool, // whether token can deposit to ZkLink or not, default is false
        tokenAddress: ContractAddress, // the token address
        decimals: u8 // the token decimals of layer one
    }

    /// block stored data
    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct StoredBlockInfo {
        blockNumber: u64, // Rollup block number
        preCommittedBlockNumber: u64, // The pre not empty block number committed
        priorityOperations: u64, // Number of priority operations processed
        pendingOnchainOperationsHash: u256, // Hash of all operations that must be processed after verify
        syncHash: u256 // Used for cross chain block verify
    }

    impl StoredBlockInfoIntoBytes of Into<StoredBlockInfo, Bytes> {
        fn into(self: StoredBlockInfo) -> Bytes {
            let mut bytes = BytesTrait::new();
            bytes.append_u64(self.blockNumber);
            bytes.append_u64(self.preCommittedBlockNumber);
            bytes.append_u64(self.priorityOperations);
            bytes.append_u256(self.syncHash);

            bytes
        }
    }

    // Data needed to process onchain operation from block public data.
    // Onchain operations is operations that need some processing on L1: Deposits, Withdrawals, ChangePubKey.
    #[derive(Drop, Serde)]
    struct OnchainOperationData {
        // ethWitness: Bytes, // Some external data that can be needed for operation processing
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

    // Data needed to execute committed and verified block
    #[derive(Drop, Serde)]
    struct ExecuteBlockInfo {
        storedBlock: StoredBlockInfo, // the block info that will be executed
        pendingOnchainOpsPubdata: Array<
            Bytes
        > // onchain ops(e.g. Withdraw, ForcedExit, FullExit) that will be executed
    }

    #[derive(Copy, Drop, PartialEq, Serde, starknet::Store)]
    // Upgrade mode statuses
    enum UpgradeStatus {
        Idle: (),
        NoticePeriod: ()
    }
}
