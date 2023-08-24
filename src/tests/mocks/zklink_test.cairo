use starknet::ContractAddress;
use zklink::utils::data_structures::DataStructures::{
    CommitBlockInfo, StoredBlockInfo, CompressedBlockExtraInfo
};
use zklink::utils::operations::Operations::{OpType};
use zklink::utils::bytes::Bytes;

#[starknet::interface]
trait IZklinkMock<TContractState> {
    fn testCollectOnchainOps(
        self: @TContractState, _newBlockData: CommitBlockInfo
    ) -> (u256, u64, Bytes, Array<u256>);
    fn testAddPriorityRequest(self: @TContractState, _opType: OpType, _opData: Bytes);
    fn testCommitOneBlock(
        self: @TContractState,
        _previousBlock: StoredBlockInfo,
        _newBlock: CommitBlockInfo,
        _compressed: bool,
        _newBlockExtra: CompressedBlockExtraInfo
    ) -> StoredBlockInfo;
    fn setExodus(self: @TContractState, _exodusMode: bool);
    fn depositERC20(
        self: @TContractState,
        _token: ContractAddress,
        _amount: u128,
        _zkLinkAddress: u256,
        _subAccountId: u8,
        _mapping: bool
    );
    fn requestFullExit(
        self: @TContractState, _accountId: u32, _subAccountId: u8, _tokenId: u16, _mapping: bool
    );
    fn addToken(
        self: @TContractState,
        _tokenId: u16,
        _tokenAddress: ContractAddress,
        _decimals: u8,
        _standard: bool
    );
    fn setTokenPaused(self: @TContractState, _tokenId: u16, _paused: bool);
    fn getPriorityHash(self: @TContractState, _index: u64) -> u256;
}

#[starknet::contract]
mod ZklinkMock {
    use debug::PrintTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::testing::set_caller_address;
    use zklink::contracts::zklink::Zklink;
    use zklink::contracts::zklink::Zklink::{
        exodusModeContractStateTrait, priorityRequestsContractStateTrait
    };
    use zklink::utils::data_structures::DataStructures::{
        CommitBlockInfo, StoredBlockInfo, CompressedBlockExtraInfo
    };
    use zklink::utils::operations::Operations::{OpType};
    use zklink::utils::bytes::Bytes;

    #[storage]
    struct Storage {
        _governor: ContractAddress, 
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _verifierAddress: ContractAddress,
        _networkGovernor: ContractAddress,
        _blockNumber: u64,
        _timestamp: u64,
        _stateHash: u256,
        _commitment: u256,
        _syncHash: u256
    ) {
        self._governor.write(_networkGovernor);
        let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
        Zklink::constructor(
            ref state,
            _verifierAddress,
            _networkGovernor,
            _blockNumber,
            _timestamp,
            _stateHash,
            _commitment,
            _syncHash
        );
    }

    #[external(v0)]
    impl ZklinkMockImpl of super::IZklinkMock<ContractState> {
        fn testCollectOnchainOps(
            self: @ContractState, _newBlockData: CommitBlockInfo
        ) -> (u256, u64, Bytes, Array<u256>) {
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

        fn setExodus(self: @ContractState, _exodusMode: bool) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.exodusMode.write(_exodusMode);
        }

        fn depositERC20(
            self: @ContractState,
            _token: ContractAddress,
            _amount: u128,
            _zkLinkAddress: u256,
            _subAccountId: u8,
            _mapping: bool
        ) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            set_caller_address(get_caller_address());
            Zklink::Zklink::depositERC20(
                ref state, _token, _amount, _zkLinkAddress, _subAccountId, _mapping
            );
        }

        fn requestFullExit(
            self: @ContractState, _accountId: u32, _subAccountId: u8, _tokenId: u16, _mapping: bool
        ) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            set_caller_address(get_caller_address());
            Zklink::Zklink::requestFullExit(
                ref state, _accountId, _subAccountId, _tokenId, _mapping
            );
        }

        fn addToken(
            self: @ContractState,
            _tokenId: u16,
            _tokenAddress: ContractAddress,
            _decimals: u8,
            _standard: bool
        ) {
            // only governor can add token
            set_caller_address(self._governor.read());
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::addToken(ref state, _tokenId, _tokenAddress, _decimals, _standard);
        }

        fn setTokenPaused(self: @ContractState, _tokenId: u16, _paused: bool) {
            // only governor can set token paused
            set_caller_address(self._governor.read());
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::setTokenPaused(ref state, _tokenId, _paused);
        }

        fn getPriorityHash(self: @ContractState, _index: u64) -> u256 {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.priorityRequests.read(_index).hashedPubData
        }
    }
}
