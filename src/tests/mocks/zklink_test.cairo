use zklink::utils::data_structures::DataStructures::{CommitBlockInfo};

#[starknet::interface]
trait IZklinkMock<TContractState> {
    fn testCollectOnchainOps(
        self: @TContractState, _newBlockData: CommitBlockInfo
    ) -> (u256, u64, u256, Array<u256>);
}

#[starknet::contract]
mod ZklinkMock {
    use zklink::contracts::zklink::Zklink;
    use zklink::utils::data_structures::DataStructures::{CommitBlockInfo};

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
    }
}
