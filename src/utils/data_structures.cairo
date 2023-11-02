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
        decimals: u8, // the token decimals of layer one
        standard: bool // we will not check the balance different of zkLink contract after transfer when a token comply with erc20 standard
    }

    // We can set `enableBridgeTo` and `enableBridgeTo` to false
    // to disable bridge when `bridge` is compromised
    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct BridgeInfo {
        bridge: ContractAddress,
        enableBridgeTo: bool,
        enableBridgeFrom: bool
    }

    // block stored data
    // `blockNumber`,`timestamp`,`stateHash`,`commitment` are the same on all chains
    // `priorityOperations`,`pendingOnchainOperationsHash` is different for each chain
    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct StoredBlockInfo {
        blockNumber: u64, // Rollup block number
        priorityOperations: u64, // Number of priority operations processed
        pendingOnchainOperationsHash: u256, // Hash of all operations that must be processed after verify
        timestamp: u64, // Rollup block timestamp
        stateHash: u256, // Root hash of the rollup state
        commitment: u256, // Verified input for the ZkLink circuit
        syncHash: u256 // Used for cross chain block verify
    }

    impl StoredBlockInfoIntoBytes of Into<StoredBlockInfo, Bytes> {
        fn into(self: StoredBlockInfo) -> Bytes {
            let mut bytes = BytesTrait::new();
            bytes.append_u64(self.blockNumber);
            bytes.append_u64(self.priorityOperations);
            bytes.append_u256(self.pendingOnchainOperationsHash);
            bytes.append_u64(self.timestamp);
            bytes.append_u256(self.stateHash);
            bytes.append_u256(self.commitment);
            bytes.append_u256(self.syncHash);

            bytes
        }
    }

    // Data needed to process onchain operation from block public data.
    // Onchain operations is operations that need some processing on L1: Deposits, Withdrawals, ChangePubKey.
    #[derive(Drop, Serde)]
    struct OnchainOperationData {
        ethWitness: Bytes, // Some external data that can be needed for operation processing
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
        publicDataHash: u256, // pubdata hash of all chains
        offsetCommitmentHash: u256, // all chains pubdata offset commitment hash
        onchainOperationPubdataHashs: Array<u256> // onchain operation pubdata hash of the all other chains
    }

    impl CompressedBlockExtraInfoDefault of Default<CompressedBlockExtraInfo> {
        fn default() -> CompressedBlockExtraInfo {
            CompressedBlockExtraInfo {
                publicDataHash: Default::default(),
                offsetCommitmentHash: Default::default(),
                onchainOperationPubdataHashs: Default::default()
            }
        }
    }

    // Data needed to execute committed and verified block
    #[derive(Drop, Serde)]
    struct ExecuteBlockInfo {
        storedBlock: StoredBlockInfo, // the block info that will be executed
        pendingOnchainOpsPubdata: Array<Bytes> // onchain ops(e.g. Withdraw, ForcedExit, FullExit) that will be executed
    }

    // Token info stored in zkLink
    #[derive(Drop, Copy, Serde)]
    struct Token {
        tokenId: u16, // token id defined by zkLink
        tokenAddress: ContractAddress, // token address in l1
        decimals: u8, // token decimals in l1
        standard: bool // if token a pure erc20 or not
    }

    // Recursive proof input data (individual commitments are constructed onchain)
    #[derive(Drop, Serde, Clone)]
    struct ProofInput {
        recursiveInput: Array<u256>,
        proof: Array<u256>,
        commitments: Array<u256>,
        vkIndexes: Array<u8>,
        subproofsLimbs: Array<u256>
    }

    #[derive(Copy, Drop, PartialEq, Serde, starknet::Store)]
    // Upgrade mode statuses
    enum UpgradeStatus {
        Idle: (),
        NoticePeriod: ()
    }
}
