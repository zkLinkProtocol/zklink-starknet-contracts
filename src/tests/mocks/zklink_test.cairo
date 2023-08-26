use starknet::ContractAddress;
use zklink::utils::data_structures::DataStructures::{
    CommitBlockInfo, StoredBlockInfo, CompressedBlockExtraInfo
};
use zklink::utils::operations::Operations::{OpType};
use zklink::utils::bytes::Bytes;

#[starknet::interface]
trait IZklinkMock<TContractState> {
    fn depositERC20(
        self: @TContractState,
        _token: ContractAddress,
        _amount: u128,
        _zkLinkAddress: u256,
        _subAccountId: u8,
        _mapping: bool
    );
    fn acceptERC20(
        self: @TContractState,
        _acceptor: ContractAddress,
        _accountId: u32,
        _receiver: ContractAddress,
        _tokenId: u16,
        _amount: u128,
        _withdrawFeeRate: u16,
        _accountIdOfNonce: u32,
        _subAccountIdOfNonce: u8,
        _nonce: u32,
        _amountTransfer: u128
    );
    fn requestFullExit(
        self: @TContractState, _accountId: u32, _subAccountId: u8, _tokenId: u16, _mapping: bool
    );
    fn performExodus(
        self: @TContractState,
        _storedBlockInfo: StoredBlockInfo,
        _owner: u256,
        _accountId: u32,
        _subAccountId: u8,
        _withdrawTokenId: u16,
        _deductTokenId: u16,
        _amount: u128,
        _proof: Array<u256>
    );
    fn cancelOutstandingDepositsForExodusMode(
        self: @TContractState, _n: u64, _depositsPubdata: Array<Bytes>
    );
    fn activateExodusMode(self: @TContractState);
    fn brokerAllowance(
        self: @TContractState, _tokenId: u16, _acceptor: ContractAddress, _broker: ContractAddress
    ) -> u128;
    fn brokerApprove(
        self: @TContractState, _tokenId: u16, _broker: ContractAddress, _amount: u128
    ) -> bool;
    fn addToken(
        self: @TContractState,
        _tokenId: u16,
        _tokenAddress: ContractAddress,
        _decimals: u8,
        _standard: bool
    );
    fn setTokenPaused(self: @TContractState, _tokenId: u16, _paused: bool);
    fn setExodus(self: @TContractState, _exodusMode: bool);
    fn setAcceptor(self: @TContractState, _accountId: u32, _hash: u256, _acceptor: ContractAddress);
    fn setTotalOpenPriorityRequests(self: @TContractState, _totalOpenPriorityRequests: u64);
    fn getPriorityHash(self: @TContractState, _index: u64) -> u256;
    fn getAcceptor(self: @TContractState, _accountId: u32, _hash: u256) -> ContractAddress;
    fn getPendingBalance(self: @TContractState, _address: u256, _tokenId: u16) -> u128;
    fn mockExecBlock(self: @TContractState, _storedBlockInfo: StoredBlockInfo);
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
}

#[starknet::contract]
mod ZklinkMock {
    use debug::PrintTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::testing::set_caller_address;
    use zklink::contracts::zklink::Zklink;
    use zklink::contracts::zklink::Zklink::{
        exodusModeContractMemberStateTrait, priorityRequestsContractMemberStateTrait,
        acceptsContractMemberStateTrait, storedBlockHashesContractMemberStateTrait,
        totalBlocksExecutedContractMemberStateTrait, pendingBalancesContractMemberStateTrait,
        totalOpenPriorityRequestsContractMemberStateTrait
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

        fn acceptERC20(
            self: @ContractState,
            _acceptor: ContractAddress,
            _accountId: u32,
            _receiver: ContractAddress,
            _tokenId: u16,
            _amount: u128,
            _withdrawFeeRate: u16,
            _accountIdOfNonce: u32,
            _subAccountIdOfNonce: u8,
            _nonce: u32,
            _amountTransfer: u128
        ) {
            set_caller_address(get_caller_address());
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::acceptERC20(
                ref state,
                _acceptor,
                _accountId,
                _receiver,
                _tokenId,
                _amount,
                _withdrawFeeRate,
                _accountIdOfNonce,
                _subAccountIdOfNonce,
                _nonce,
                _amountTransfer
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

        fn performExodus(
            self: @ContractState,
            _storedBlockInfo: StoredBlockInfo,
            _owner: u256,
            _accountId: u32,
            _subAccountId: u8,
            _withdrawTokenId: u16,
            _deductTokenId: u16,
            _amount: u128,
            _proof: Array<u256>
        ) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::performExodus(
                ref state,
                _storedBlockInfo,
                _owner,
                _accountId,
                _subAccountId,
                _withdrawTokenId,
                _deductTokenId,
                _amount,
                _proof
            );
        }
        fn cancelOutstandingDepositsForExodusMode(
            self: @ContractState, _n: u64, _depositsPubdata: Array<Bytes>
        ) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::cancelOutstandingDepositsForExodusMode(ref state, _n, _depositsPubdata);
        }

        fn activateExodusMode(self: @ContractState) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::activateExodusMode(ref state);
        }

        fn brokerAllowance(
            self: @ContractState,
            _tokenId: u16,
            _acceptor: ContractAddress,
            _broker: ContractAddress
        ) -> u128 {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::brokerAllowance(@state, _tokenId, _acceptor, _broker)
        }

        fn brokerApprove(
            self: @ContractState, _tokenId: u16, _broker: ContractAddress, _amount: u128
        ) -> bool {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            set_caller_address(get_caller_address());
            Zklink::Zklink::brokerApprove(ref state, _tokenId, _broker, _amount)
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

        fn setExodus(self: @ContractState, _exodusMode: bool) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.exodusMode.write(_exodusMode);
        }

        fn setAcceptor(
            self: @ContractState, _accountId: u32, _hash: u256, _acceptor: ContractAddress
        ) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.accepts.write((_accountId, _hash), _acceptor);
        }

        fn setTotalOpenPriorityRequests(self: @ContractState, _totalOpenPriorityRequests: u64) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.totalOpenPriorityRequests.write(_totalOpenPriorityRequests);
        }

        fn getPriorityHash(self: @ContractState, _index: u64) -> u256 {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.priorityRequests.read(_index).hashedPubData
        }

        fn getAcceptor(self: @ContractState, _accountId: u32, _hash: u256) -> ContractAddress {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.accepts.read((_accountId, _hash))
        }

        fn getPendingBalance(self: @ContractState, _address: u256, _tokenId: u16) -> u128 {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.pendingBalances.read((_address, _tokenId))
        }

        fn mockExecBlock(self: @ContractState, _storedBlockInfo: StoredBlockInfo) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            let hash = Zklink::hashStoredBlockInfo(_storedBlockInfo);
            state.storedBlockHashes.write(_storedBlockInfo.blockNumber, hash);
            state.totalBlocksExecuted.write(_storedBlockInfo.blockNumber);
        }

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
    }
}
