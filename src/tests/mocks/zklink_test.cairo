use zklink::utils::data_structures::DataStructures::{
    CommitBlockInfo, StoredBlockInfo, CompressedBlockExtraInfo
};
use zklink::utils::operations::Operations::{OpType};
use zklink::utils::bytes::Bytes;

#[starknet::interface]
trait IZklinkMock<TContractState> {
    fn testCollectOnchainOps(
        self: @TContractState, _newBlockData: CommitBlockInfo
    ) -> (u256, u64, u256, Array<u256>);
    fn testAddPriorityRequest(self: @TContractState, _opType: OpType, _opData: Bytes);
    fn testCommitOneBlock(
        self: @TContractState,
        _previousBlock: StoredBlockInfo,
        _newBlock: CommitBlockInfo,
        _compressed: bool,
        _newBlockExtra: CompressedBlockExtraInfo
    ) -> StoredBlockInfo;
}

#[starknet::contract]
mod ZklinkMock {
    use zklink::contracts::zklink::Zklink;
    use zklink::utils::data_structures::DataStructures::{
        CommitBlockInfo, StoredBlockInfo, CompressedBlockExtraInfo
    };
    use zklink::utils::operations::Operations::{OpType};
    use zklink::utils::bytes::Bytes;

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl ZklinkMockImpl of super::IZklinkMock<ContractState> {
        fn testCollectOnchainOps(
            self: @ContractState, _newBlockData: CommitBlockInfo
        ) -> (u256, u64, u256, Array<u256>) {
            let state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::InternalFunctions::collectOnchainOps(@state, @_newBlockData)
        }

        fn testAddPriorityRequest(self: @ContractState, _opType: OpType, _opData: Bytes) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::InternalFunctions::addPriorityRequest(ref state, _opType, _opData);
        }

        fn testCommitOneBlock(
            self: @ContractState,
            _previousBlock: StoredBlockInfo,
            _newBlock: CommitBlockInfo,
            _compressed: bool,
            _newBlockExtra: CompressedBlockExtraInfo
        ) -> StoredBlockInfo {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::InternalFunctions::commitOneBlock(
                ref state, @_previousBlock, @_newBlock, _compressed, @_newBlockExtra
            )
        }
    }
}
