use starknet::ContractAddress;
use zklink_starknet_utils::bytes::Bytes;
use zklink::utils::data_structures::DataStructures::{CommitBlockInfo, StoredBlockInfo};
use zklink::utils::operations::Operations::{OpType, Withdraw};

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
        _receiver: ContractAddress,
        _token: ContractAddress,
        _amount: u128,
        _withdrawFeeRate: u16,
        _accountIdOfNonce: u32,
        _subAccountIdOfNonce: u8,
        _nonce: u32
    );
    fn requestFullExit(
        self: @TContractState, _accountId: u32, _subAccountId: u8, _tokenId: u16, _mapping: bool
    );
    fn cancelOutstandingDepositsForExodusMode(
        self: @TContractState, _n: u64, _depositsPubdata: Array<Bytes>
    );
    fn withdrawPendingBalance(
        self: @TContractState, _owner: ContractAddress, _tokenId: u16, _amount: u128
    ) -> u128;
    fn activateExodusMode(self: @TContractState);
    fn addToken(
        self: @TContractState, _tokenId: u16, _tokenAddress: ContractAddress, _decimals: u8
    );
    fn setTokenPaused(self: @TContractState, _tokenId: u16, _paused: bool);
    fn setExodus(self: @TContractState, _exodusMode: bool);
    fn setAcceptor(self: @TContractState, _hash: u256, _acceptor: ContractAddress);
    fn setTotalOpenPriorityRequests(self: @TContractState, _totalOpenPriorityRequests: u64);
    fn getPriorityHash(self: @TContractState, _index: u64) -> u256;
    fn getAcceptor(self: @TContractState, _hash: u256) -> ContractAddress;
    fn getPendingBalance(self: @TContractState, _address: u256, _tokenId: u16) -> u128;
    fn mockExecBlock(self: @TContractState, _storedBlockInfo: StoredBlockInfo);
    fn testCollectOnchainOps(
        self: @TContractState, _newBlockData: CommitBlockInfo
    ) -> (u256, u64, u256);
    fn testAddPriorityRequest(
        self: @TContractState, _opType: OpType, _opData: Bytes, _hashInputSize: usize
    );
    fn testCommitOneBlock(
        self: @TContractState, _previousBlock: StoredBlockInfo, _newBlock: CommitBlockInfo
    ) -> StoredBlockInfo;
    fn testExecuteWithdraw(self: @TContractState, _op: Withdraw);
}

#[starknet::contract]
mod ZklinkMock {
    use debug::PrintTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::testing::set_caller_address;
    use zklink_starknet_utils::bytes::Bytes;
    use zklink::contracts::zklink::Zklink;
    use zklink::contracts::zklink::Zklink::{
        exodusModeContractMemberStateTrait, priorityRequestsContractMemberStateTrait,
        acceptsContractMemberStateTrait, storedBlockHashesContractMemberStateTrait,
        totalBlocksExecutedContractMemberStateTrait, pendingBalancesContractMemberStateTrait,
        totalOpenPriorityRequestsContractMemberStateTrait
    };
    use zklink::utils::data_structures::DataStructures::{CommitBlockInfo, StoredBlockInfo};
    use zklink::utils::operations::Operations::{OpType, Withdraw};

    #[storage]
    struct Storage {
        _governor: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _master: ContractAddress,
        _verifierAddress: ContractAddress,
        _networkGovernor: ContractAddress,
        _blockNumber: u64
    ) {
        self._governor.write(_networkGovernor);
        let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
        Zklink::constructor(ref state, _master, _verifierAddress, _networkGovernor, _blockNumber);
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
            _receiver: ContractAddress,
            _token: ContractAddress,
            _amount: u128,
            _withdrawFeeRate: u16,
            _accountIdOfNonce: u32,
            _subAccountIdOfNonce: u8,
            _nonce: u32
        ) {
            set_caller_address(get_caller_address());
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::acceptERC20(
                ref state,
                _receiver,
                _token,
                _amount,
                _withdrawFeeRate,
                _accountIdOfNonce,
                _subAccountIdOfNonce,
                _nonce
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

        fn cancelOutstandingDepositsForExodusMode(
            self: @ContractState, _n: u64, _depositsPubdata: Array<Bytes>
        ) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::cancelOutstandingDepositsForExodusMode(ref state, _n, _depositsPubdata);
        }

        fn withdrawPendingBalance(
            self: @ContractState, _owner: ContractAddress, _tokenId: u16, _amount: u128
        ) -> u128 {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::withdrawPendingBalance(ref state, _owner, _tokenId, _amount)
        }

        fn activateExodusMode(self: @ContractState) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::activateExodusMode(ref state);
        }

        fn addToken(
            self: @ContractState, _tokenId: u16, _tokenAddress: ContractAddress, _decimals: u8
        ) {
            // only governor can add token
            set_caller_address(self._governor.read());
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::Zklink::addToken(ref state, _tokenId, _tokenAddress, _decimals);
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

        fn setAcceptor(self: @ContractState, _hash: u256, _acceptor: ContractAddress) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.accepts.write(_hash, _acceptor);
        }

        fn setTotalOpenPriorityRequests(self: @ContractState, _totalOpenPriorityRequests: u64) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.totalOpenPriorityRequests.write(_totalOpenPriorityRequests);
        }

        fn getPriorityHash(self: @ContractState, _index: u64) -> u256 {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.priorityRequests.read(_index).hashedPubData
        }

        fn getAcceptor(self: @ContractState, _hash: u256) -> ContractAddress {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            state.accepts.read(_hash)
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
        ) -> (u256, u64, u256) {
            let state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::InternalFunctions::collectOnchainOpsOfCompressedBlock(@state, @_newBlockData)
        }

        fn testAddPriorityRequest(
            self: @ContractState, _opType: OpType, _opData: Bytes, _hashInputSize: usize
        ) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::InternalFunctions::addPriorityRequest(
                ref state, _opType, _opData, _hashInputSize
            );
        }

        fn testCommitOneBlock(
            self: @ContractState, _previousBlock: StoredBlockInfo, _newBlock: CommitBlockInfo,
        ) -> StoredBlockInfo {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::InternalFunctions::commitOneCompressedBlock(
                ref state, @_previousBlock, @_newBlock
            )
        }

        fn testExecuteWithdraw(self: @ContractState, _op: Withdraw) {
            let mut state: Zklink::ContractState = Zklink::contract_state_for_testing();
            Zklink::InternalFunctions::_executeWithdraw(
                ref state,
                _op.accountId,
                _op.subAccountId,
                _op.nonce,
                _op.owner,
                _op.tokenId,
                _op.amount,
                _op.fastWithdrawFeeRate,
                _op.withdrawToL1
            );
        }
    }
}
