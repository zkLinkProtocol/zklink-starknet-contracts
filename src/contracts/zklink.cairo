use starknet::{ContractAddress, ClassHash, EthAddress};
use zklink::utils::data_structures::DataStructures::{
    StoredBlockInfo, CommitBlockInfo, ExecuteBlockInfo, RegisteredToken
};
use zklink_starknet_utils::bytes::Bytes;

#[starknet::interface]
trait IZklink<TContractState> {
    fn depositERC20(
        ref self: TContractState,
        _token: ContractAddress,
        _amount: u128,
        _zkLinkAddress: u256,
        _subAccountId: u8,
        _mapping: bool
    );
    fn acceptERC20(
        ref self: TContractState,
        _receiver: ContractAddress,
        _token: ContractAddress,
        _amount: u128,
        _fastWithdrawFeeRate: u16,
        _accountIdOfNonce: u32,
        _subAccountIdOfNonce: u8,
        _nonce: u32
    );
    fn requestFullExit(
        ref self: TContractState, _accountId: u32, _subAccountId: u8, _tokenId: u16, _mapping: bool
    );
    fn withdrawToL1(
        ref self: TContractState,
        _owner: EthAddress,
        _token: ContractAddress,
        _amount: u128,
        _fastWithdrawFeeRate: u16,
        _accountIdOfNonce: u32,
        _subAccountIdOfNonce: u8,
        _nonce: u32,
    );
    fn activateExodusMode(ref self: TContractState);
    fn cancelOutstandingDepositsForExodusMode(
        ref self: TContractState, _n: u64, _depositsPubdata: Array<Bytes>
    );
    fn setAuthPubkeyHash(ref self: TContractState, _pubkeyHash: felt252, _nonce: u32);
    fn withdrawPendingBalance(
        ref self: TContractState, _owner: ContractAddress, _tokenId: u16, _amount: u128
    ) -> u128;
    fn commitCompressedBlocks(
        ref self: TContractState,
        _lastCommittedBlockData: StoredBlockInfo,
        _newBlocksData: Array<CommitBlockInfo>
    );
    fn executeCompressedBlocks(ref self: TContractState, _blocksData: Array<ExecuteBlockInfo>);
    fn revertBlocks(
        ref self: TContractState,
        _latestCommittedBlock: StoredBlockInfo,
        _blocksToRevert: Array<StoredBlockInfo>
    );
    fn sendSyncHash(ref self: TContractState, _block: StoredBlockInfo);
    fn receiveBlockConfirmation(ref self: TContractState, _blockNumber: u64);
    fn changeGovernor(ref self: TContractState, _newGovernor: ContractAddress);
    fn addToken(
        ref self: TContractState, _tokenId: u16, _tokenAddress: ContractAddress, _decimals: u8
    );
    fn setTokenPaused(ref self: TContractState, _tokenId: u16, _tokenPaused: bool);
    fn setValidator(ref self: TContractState, _validator: ContractAddress, _active: bool);
    fn setGateway(ref self: TContractState, _gateway: ContractAddress);
    fn setSyncService(ref self: TContractState, _syncService: ContractAddress);
    fn getPendingBalance(self: @TContractState, _address: u256, _tokenId: u16) -> u128;
    fn verifier(self: @TContractState) -> ContractAddress;
    fn syncService(self: @TContractState) -> ContractAddress;
    fn totalBlocksExecuted(self: @TContractState) -> u64;
    fn firstPriorityRequestId(self: @TContractState) -> u64;
    fn networkGovernor(self: @TContractState) -> ContractAddress;
    fn totalBlocksCommitted(self: @TContractState) -> u64;
    fn totalOpenPriorityRequests(self: @TContractState) -> u64;
    fn totalBlocksProven(self: @TContractState) -> u64;
    fn totalCommittedPriorityRequests(self: @TContractState) -> u64;
    fn totalBlocksSynchronized(self: @TContractState) -> u64;
    fn exodusMode(self: @TContractState) -> bool;
    fn authFacts(self: @TContractState, _owner: ContractAddress, _nonce: u32) -> u256;
    fn accepts(self: @TContractState, _hash: u256) -> ContractAddress;
    fn validators(self: @TContractState, _validator: ContractAddress) -> bool;
    fn tokens(self: @TContractState, _tokenId: u16) -> RegisteredToken;
    fn tokenIds(self: @TContractState, _tokenAddress: ContractAddress) -> u16;
    fn getNoticePeriod(self: @TContractState) -> u256;
    fn isReadyForUpgrade(self: @TContractState) -> bool;
    fn getMaster(self: @TContractState) -> ContractAddress;
    fn transferMastership(ref self: TContractState, _newMaster: ContractAddress);
    fn upgrade(ref self: TContractState, impl_hash: ClassHash);
    fn gateway(self: @TContractState) -> ContractAddress;
}

#[starknet::contract]
mod Zklink {
    use zeroable::Zeroable;
    use traits::{Into, TryInto, Index, Default};
    use option::OptionTrait;
    use array::{ArrayTrait, SpanTrait};
    use dict::Felt252DictTrait;
    use dict::Felt252DictEntryTrait;
    use box::BoxTrait;
    use clone::Clone;
    use starknet::{
        ContractAddress, ClassHash, contract_address_const, Felt252TryIntoContractAddress,
        get_contract_address, get_caller_address, get_block_info, get_block_timestamp, EthAddress
    };
    use core::starknet::info::get_block_number;

    use super::IZklinkDispatcher;
    use super::IZklinkDispatcherTrait;
    use zklink::contracts::verifier::IVerifierDispatcher;
    use zklink::contracts::verifier::IVerifierDispatcherTrait;
    use zklink::contracts::l2gateway::IL2GatewayDispatcher;
    use zklink::contracts::l2gateway::IL2GatewayDispatcherTrait;
    use zklink::contracts::syncservice::ISyncServiceDispatcher;
    use zklink::contracts::syncservice::ISyncServiceDispatcherTrait;
    use openzeppelin::token::erc20::interface::IERC20CamelDispatcher;
    use openzeppelin::token::erc20::interface::IERC20CamelDispatcherTrait;

    use zklink_starknet_utils::bytes::{Bytes, BytesTrait, ReadBytes};
    use zklink_starknet_utils::math::{fast_power10, u256_fast_pow2};
    use zklink_starknet_utils::utils::uint_min;

    use zklink::utils::operations::Operations::{
        OpType, OpTypeIntoU8, OpTypeReadBytes, U8TryIntoOpType, PriorityOperation,
        OperationReadTrait, OperationWriteTrait, Deposit, DepositReadOperation, FullExit,
        FullExitReadOperation, ForcedExit, ForcedExitReadOperation, Withdraw, WithdrawReadOperation,
        ChangePubKey, ChangePubKeyReadOperation, PUBKEY_HASH_BYTES, CHANGE_PUBKEY_CHECK_OFFSET
    };
    use zklink::utils::data_structures::DataStructures::{
        RegisteredToken, StoredBlockInfo, CommitBlockInfo, ExecuteBlockInfo, OnchainOperationData
    };
    use zklink::utils::utils::{concatHash, pubKeyHash, concatTwoHash};
    use zklink::utils::constants::{
        EMPTY_STRING_KECCAK, MAX_AMOUNT_OF_REGISTERED_TOKENS, MAX_ACCOUNT_ID, MAX_SUB_ACCOUNT_ID,
        CHUNK_BYTES, DEPOSIT_BYTES, CHANGE_PUBKEY_BYTES, WITHDRAW_BYTES, FORCED_EXIT_BYTES,
        FULL_EXIT_BYTES, DEPOSIT_CHECK_BYTES, FULL_EXIT_CHECK_BYTES, PRIORITY_EXPIRATION,
        UPGRADE_NOTICE_PERIOD, MAX_DEPOSIT_AMOUNT, MAX_PROOF_COMMITMENT, INPUT_MASK,
        AUTH_FACT_RESET_TIMELOCK, CHAIN_ID, MIN_CHAIN_ID, MAX_CHAIN_ID, ALL_CHAINS, MASTER_CHAIN_ID,
        MAX_ACCEPT_FEE_RATE, TOKEN_DECIMALS_OF_LAYER2, GLOBAL_ASSET_ACCOUNT_ID,
        GLOBAL_ASSET_ACCOUNT_ADDRESS, USD_TOKEN_ID, MIN_USD_STABLE_TOKEN_ID, MAX_USD_STABLE_TOKEN_ID
    };

    /// Storage
    #[storage]
    struct Storage {
        // public
        // master address, which can call upgrade functions
        master: ContractAddress,
        // internal
        // ReentrancyGuard flag
        entered: bool,
        // public
        // Verifier contract. Used to verify block proof and exit proof
        verifier: ContractAddress,
        // public
        // The gateway is used for communicating with L1
        gateway: ContractAddress,
        // public
        // Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
        totalBlocksExecuted: u64,
        // public
        // First open priority request id
        firstPriorityRequestId: u64,
        // public
        // The the owner of whole system
        networkGovernor: ContractAddress,
        // public
        // Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
        totalBlocksCommitted: u64,
        // public
        // Total number of requests
        totalOpenPriorityRequests: u64,
        // public
        // Total blocks proven
        totalBlocksProven: u64,
        // public
        // Total number of committed requests.
        // Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
        totalCommittedPriorityRequests: u64,
        // public
        // Latest synchronized block height
        totalBlocksSynchronized: u64,
        // public
        // Flag indicates that exodus (mass exit) mode is triggered
        // Once it was raised, it can not be cleared again, and all users must exit
        exodusMode: bool,
        // internal
        // Balances to withdraw, (owner, tokenId) => amount
        // The type of owner is u256, which can both storing evm address and starknet address 
        // the amount of pending balance need to recovery decimals when withdraw
        pendingBalances: LegacyMap::<(u256, u16), u128>,
        // internal
        // Store withdraw data hash that need to be relayed to L1 by gateway
        // The key is the withdraw data hash
        // The value is a flag to indicating whether withdraw exists
        pendingL1Withdraws: LegacyMap::<u256, bool>,
        // internal
        // Priority Requests mapping (request id - operation)
        // Contains op type, pubdata and expiration block of unsatisfied requests.
        // Numbers are in order of requests receiving
        priorityRequests: LegacyMap::<u64, PriorityOperation>,
        // public
        // User authenticated fact hashes for some nonce.
        // (owner, nonce) => hash.
        authFacts: LegacyMap::<(ContractAddress, u32), u256>,
        // internal
        // Timer for authFacts entry reset (address, nonce) => timer.
        // Used when user wants to reset `authFacts` for some nonce.
        authFactsResetTimer: LegacyMap::<(ContractAddress, u32), u64>,
        // internal
        // Stored hashed StoredBlockInfo for some block number
        // Block number is u64 in Starknet
        storedBlockHashes: LegacyMap::<u64, u256>,
        // public
        // Accept infos of withdraw
        // keccak256(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, token, amount, fastWithdrawFeeRate) => acceptor address
        accepts: LegacyMap::<u256, ContractAddress>,
        // public
        // A set of permitted validators
        validators: LegacyMap::<ContractAddress, bool>,
        // public
        // A map of registered token infos
        tokens: LegacyMap::<u16, RegisteredToken>,
        // public
        // A map of registered token infos
        tokenIds: LegacyMap::<ContractAddress, u16>,
        /// public
        /// A service that sending and receiving cross chain sync message
        syncService: ContractAddress,
    }

    /// Events
    // Event emitted when a block is committed
    #[derive(Drop, starknet::Event)]
    struct BlockCommit {
        #[key]
        blockNumber: u64
    }

    // Event emitted when a block is proven
    #[derive(Drop, starknet::Event)]
    struct BlockProven {
        #[key]
        blockNumber: u64
    }

    /// Event emitted when a block is synced
    #[derive(Drop, starknet::Event)]
    struct BlockSynced {
        #[key]
        blockNumber: u64
    }

    // Event emitted when a block is executed
    #[derive(Drop, starknet::Event)]
    struct BlockExecuted {
        #[key]
        blockNumber: u64
    }

    // Event emitted when user funds are withdrawn from the zkLink state and contract
    #[derive(Drop, starknet::Event)]
    struct Withdrawal {
        #[key]
        tokenId: u16,
        amount: u128
    }

    // Event emitted when user funds are withdrawn from the zkLink state but not from contract
    #[derive(Drop, starknet::Event)]
    struct WithdrawalPending {
        #[key]
        tokenId: u16,
        #[key]
        recepient: u256,
        amount: u128
    }

    // Event emitted when user sends a authentication fact (e.g. pub-key hash)
    #[derive(Drop, starknet::Event)]
    struct FactAuth {
        #[key]
        sender: ContractAddress,
        nonce: u32,
        fact: felt252
    }

    // Event emitted when authentication fact reset clock start
    #[derive(Drop, starknet::Event)]
    struct FactAuthResetTime {
        #[key]
        sender: ContractAddress,
        nonce: u32,
        time: u64
    }

    // Event emitted when blocks are reverted
    #[derive(Drop, starknet::Event)]
    struct BlocksRevert {
        totalBlocksVerified: u64,
        totalBlocksCommitted: u64
    }

    // Exodus mode entered event
    #[derive(Drop, starknet::Event)]
    struct ExodusMode {
        exodusMode: bool
    }

    // New priority request event. Emitted when a request is placed into mapping
    #[derive(Drop, starknet::Event)]
    struct NewPriorityRequest {
        sender: ContractAddress,
        serialId: u64,
        opType: OpType,
        pubData: Bytes,
        expirationBlock: u64
    }

    // Event emitted when acceptor accept a fast withdraw
    #[derive(Drop, starknet::Event)]
    struct Accept {
        acceptor: ContractAddress,
        receiver: ContractAddress,
        token: ContractAddress,
        amount: u128,
        withdrawFeeRate: u16,
        accountIdOfNonce: u32,
        subAccountIdOfNonce: u8,
        nonce: u32,
        amountReceive: u128
    }

    // Token added to ZkLink net
    // Log token decimals on this chain to let L2 know(token decimals maybe different on different chains)
    #[derive(Drop, starknet::Event)]
    struct NewToken {
        #[key]
        tokenId: u16,
        #[key]
        token: ContractAddress,
        decimals: u8
    }

    // Governor changed
    #[derive(Drop, starknet::Event)]
    struct NewGovernor {
        governor: ContractAddress
    }

    // Validator's status updated
    #[derive(Drop, starknet::Event)]
    struct ValidatorStatusUpdate {
        #[key]
        validatorAddress: ContractAddress,
        isActive: bool
    }

    // Token pause status update
    #[derive(Drop, starknet::Event)]
    struct TokenPausedUpdate {
        #[key]
        tokenId: u16,
        paused: bool
    }

    /// Sync service changed
    #[derive(Drop, starknet::Event)]
    struct SetSyncService {
        #[key]
        newSyncService: ContractAddress,
    }

    // Event emitted when user funds are withdrawn from the zkLink state to L1 and contract
    #[derive(Drop, starknet::Event)]
    struct WithdrawalL1 {
        #[key]
        withdrawHash: u256
    }

    // Event emitted when user funds are withdrawn from the zkLink state to L1 but not from contract
    #[derive(Drop, starknet::Event)]
    struct WithdrawalPendingL1 {
        #[key]
        withdrawHash: u256,
    }

    // Gateway address changed
    #[derive(Drop, starknet::Event)]
    struct SetGateway {
        #[key]
        newGateway: ContractAddress
    }

    /// Event emitted when send sync hash to master chain
    #[derive(Drop, starknet::Event)]
    struct SendSyncHash {
        syncHash: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BlockCommit: BlockCommit,
        BlockProven: BlockProven,
        BlockSynced: BlockSynced,
        BlockExecuted: BlockExecuted,
        Withdrawal: Withdrawal,
        WithdrawalPending: WithdrawalPending,
        FactAuth: FactAuth,
        FactAuthResetTime: FactAuthResetTime,
        BlocksRevert: BlocksRevert,
        ExodusMode: ExodusMode,
        NewPriorityRequest: NewPriorityRequest,
        Accept: Accept,
        NewToken: NewToken,
        NewGovernor: NewGovernor,
        ValidatorStatusUpdate: ValidatorStatusUpdate,
        TokenPausedUpdate: TokenPausedUpdate,
        SetSyncService: SetSyncService,
        WithdrawalL1: WithdrawalL1,
        WithdrawalPendingL1: WithdrawalPendingL1,
        SetGateway: SetGateway,
        SendSyncHash: SendSyncHash
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        _master: ContractAddress,
        _verifierAddress: ContractAddress,
        _networkGovernor: ContractAddress,
        _blockNumber: u64
    ) {
        assert(_verifierAddress.is_non_zero(), 'i0');
        assert(_networkGovernor.is_non_zero(), 'i2');

        self.master.write(_master);
        self.verifier.write(_verifierAddress);
        self.networkGovernor.write(_networkGovernor);

        let storedBlockZero = StoredBlockInfo {
            blockNumber: _blockNumber,
            blockSequence: 0,
            priorityOperations: 0,
            pendingOnchainOperationsHash: EMPTY_STRING_KECCAK,
            syncHash: EMPTY_STRING_KECCAK
        };

        self.storedBlockHashes.write(0, hashStoredBlockInfo(storedBlockZero));
    }

    #[external(v0)]
    impl Zklink of super::IZklink<ContractState> {
        // Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
        // it MUST be ok to call other external functions within from this function
        // when the token(eg. erc777) is not a pure erc20 token
        // Parameters:
        //  _token Token address
        //  _amount Token amount
        //  _zkLinkAddress The receiver Layer 2 address
        //  _subAccountId The receiver sub account
        //  _mapping If true and token has a mapping token, user will receive mapping token at l2
        fn depositERC20(
            ref self: ContractState,
            _token: ContractAddress,
            _amount: u128,
            _zkLinkAddress: u256,
            _subAccountId: u8,
            _mapping: bool
        ) {
            self.start();
            self.deposit(_token, _amount, _zkLinkAddress, _subAccountId, _mapping);
            self.end();
        }

        // Acceptor accept a erc20 token fast withdraw, acceptor will get a fee for profit
        // Parameters:
        //  acceptor Acceptor who accept a fast withdraw
        //  receiver User receive token from acceptor (the owner of withdraw operation)
        //  tokenId Token id
        //  amount The amount of withdraw operation
        //  fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
        //  nonceFromAccountId Account that supply nonce, may be different from accountId
        //  nonceFromSubAccountId SubAccount that supply nonce
        //  nonce SubAccount nonce, used to produce unique accept info
        fn acceptERC20(
            ref self: ContractState,
            _receiver: ContractAddress,
            _token: ContractAddress,
            _amount: u128,
            _fastWithdrawFeeRate: u16,
            _accountIdOfNonce: u32,
            _subAccountIdOfNonce: u8,
            _nonce: u32
        ) {
            self.start();

            // Checks
            let sender = get_caller_address();
            let amountReceive = self
                ._checkAccept(
                    sender,
                    _receiver,
                    _token,
                    _amount,
                    _fastWithdrawFeeRate,
                    _accountIdOfNonce,
                    _subAccountIdOfNonce,
                    _nonce
                );

            // Interactions
            let _ = IERC20CamelDispatcher { contract_address: _token }
                .transferFrom(sender, _receiver, amountReceive.into());

            self
                .emit(
                    Accept {
                        acceptor: sender,
                        receiver: _receiver,
                        token: _token,
                        amount: _amount,
                        withdrawFeeRate: _fastWithdrawFeeRate,
                        accountIdOfNonce: _accountIdOfNonce,
                        subAccountIdOfNonce: _subAccountIdOfNonce,
                        nonce: _nonce,
                        amountReceive: amountReceive,
                    }
                );

            self.end();
        }

        // Register full exit request - pack pubdata, add priority request
        // Parameters:
        //  _accountId Numerical id of the account
        //  _subAccountId The exit sub account
        //  _tokenId Token id
        //  _mapping If true and token has a mapping token, user's mapping token balance will be decreased at l2
        fn requestFullExit(
            ref self: ContractState,
            _accountId: u32,
            _subAccountId: u8,
            _tokenId: u16,
            _mapping: bool
        ) {
            self.start();
            self.active();
            // Checks
            // accountId and subAccountId MUST be valid
            assert(_accountId <= MAX_ACCOUNT_ID && _accountId != GLOBAL_ASSET_ACCOUNT_ID, 'a0');
            assert(_subAccountId <= MAX_SUB_ACCOUNT_ID, 'a1');
            // token MUST be registered to ZkLink
            let rt = self.tokens.read(_tokenId);
            assert(rt.registered, 'a2');
            // when full exit stable tokens (e.g. USDC, BUSD) with mapping, USD will be deducted from account
            // and stable token will be transfer from zkLink contract to account address
            // all other tokens don't support mapping
            let mut srcTokenId = _tokenId;
            if _mapping {
                assert(
                    _tokenId >= MIN_USD_STABLE_TOKEN_ID && _tokenId <= MAX_USD_STABLE_TOKEN_ID, 'a3'
                );
                srcTokenId = USD_TOKEN_ID;
            }

            // Effects
            let sender = get_caller_address();
            let op = FullExit {
                chainId: CHAIN_ID,
                accountId: _accountId,
                subAccountId: _subAccountId,
                owner: sender, // Only the owner of account can fullExit for them self
                tokenId: _tokenId,
                srcTokenId: srcTokenId,
                amount: 0, // unknown at this point
            };

            let pubData = op.writeForPriorityQueue();
            self.addPriorityRequest(OpType::FullExit(()), pubData, FULL_EXIT_CHECK_BYTES);

            self.end();
        }

        // Withdraw token to L1 for user by gateway
        // Parameters:
        //  _owner User receive token on L1
        //  _tokenId Token id
        //  _amount The amount(recovered decimals) of withdraw operation
        //  _fastWithdrawFeeRate Fast withdraw fee rate taken by acceptor
        //  _accountIdOfNonce Account that supply nonce, may be different from accountId
        //  _subAccountIdOfNonce SubAccount that supply nonce
        //  _nonce SubAccount nonce, used to produce unique accept info
        fn withdrawToL1(
            ref self: ContractState,
            _owner: EthAddress,
            _token: ContractAddress,
            _amount: u128,
            _fastWithdrawFeeRate: u16,
            _accountIdOfNonce: u32,
            _subAccountIdOfNonce: u8,
            _nonce: u32,
        ) { // TODO
        // // Checks
        // // ensure withdraw data is not executed
        // let withdrawHash = getFastWithdrawHash(
        //     _accountIdOfNonce,
        //     _subAccountIdOfNonce,
        //     _nonce,
        //     _owner.into(),
        //     _tokenId,
        //     _amount,
        //     _fastWithdrawFeeRate
        // );
        // assert(self.pendingL1Withdraws.read(withdrawHash) == true, 'M0');

        // // token MUST be registered to ZkLink
        // let rt = self.tokens.read(_tokenId);
        // assert(rt.registered, 'M1');

        // // Effects
        // self.pendingL1Withdraws.write(withdrawHash, false);

        // // Interactions
        // // transfer token to gateway
        // IERC20CamelDispatcher { contract_address: rt.tokenAddress }.approve(
        //     self.gateway.read(),
        //     _amount.into()
        // );
        // IL2GatewayDispatcher { contract_address: self.gateway.read() }.withdrawERC20(
        //     _owner, rt.tokenAddress, _amount, withdrawHash
        // );
        }

        // Checks if Exodus mode must be entered. If true - enters exodus mode and emits ExodusMode event.
        // Exodus mode must be entered in case of current ethereum block number is higher than the oldest
        // of existed priority requests expiration block number.
        fn activateExodusMode(ref self: ContractState) {
            self.start();
            self.active();
            let blockNumber = get_block_number();
            let expirationBlock = self
                .priorityRequests
                .read(self.firstPriorityRequestId.read())
                .expirationBlock;
            let trigger: bool = ((blockNumber >= expirationBlock) && (expirationBlock != 0));

            if trigger {
                self.exodusMode.write(true);
                self.emit(Event::ExodusMode(ExodusMode { exodusMode: true }));
            }

            self.end();
        }

        // Accrues users balances from deposit priority requests in Exodus mode
        // WARNING: Only for Exodus mode
        // Canceling may take several separate transactions to be completed
        // Parameters:
        //  _n number of requests to process
        //  _depositsPubdataSize deposit pubData size in bytes
        //  _depositsPubdata deposit details
        fn cancelOutstandingDepositsForExodusMode(
            ref self: ContractState, _n: u64, _depositsPubdata: Array<Bytes>
        ) {
            self.start();
            self.notActive();
            // Checks
            let toProcess: u64 = uint_min(self.totalOpenPriorityRequests.read(), _n);
            assert(toProcess > 0, 'A0');

            // Effects
            let mut currentDepositIdx: usize = 0;
            // overflow is impossible, firstPriorityRequestId >= 0 and toProcess > 0
            let mut lastPriorityRequestId: u64 = self.firstPriorityRequestId.read() + toProcess - 1;
            let mut id: u64 = self.firstPriorityRequestId.read();
            loop {
                if id > lastPriorityRequestId {
                    break;
                }

                let pr: PriorityOperation = self.priorityRequests.read(id);
                if pr.opType == OpType::Deposit(()) {
                    let depositPubdata = _depositsPubdata[currentDepositIdx];
                    let depositPubdataHash: u256 = depositPubdata
                        .keccak_for_check(DEPOSIT_CHECK_BYTES);
                    assert(depositPubdataHash == pr.hashedPubData, 'A1');
                    currentDepositIdx += 1;

                    let op = DepositReadOperation::readFromPubdata(depositPubdata);
                    // amount of Deposit has already improve decimals
                    self.increaseBalanceToWithdraw(op.owner, op.tokenId, op.amount);
                }

                // after return back deposited token to user, delete the priorityRequest to avoid redundant cancel
                // other priority requests(ie. FullExit) are also be deleted because they are no used anymore
                // and we can get gas reward for free these slots
                self.priorityRequests.write(id, Default::default());

                id += 1;
            };

            self.firstPriorityRequestId.write(self.firstPriorityRequestId.read() + toProcess);
            self.totalOpenPriorityRequests.write(self.totalOpenPriorityRequests.read() - toProcess);

            self.end();
        }

        // Set data for changing pubkey hash using onchain authorization.
        // Transaction author (msg.sender) should be L2 account address.
        // New pubkey hash can be reset, to do that user should send two transactions:
        //  1. First `setAuthPubkeyHash` transaction for already used `_nonce` will set timer.
        //  2. After `AUTH_FACT_RESET_TIMELOCK` time is passed second `setAuthPubkeyHash` transaction will reset pubkey hash for `_nonce`.
        // Parameters:
        //  _pubkeyHash New pubkey hash
        //  _nonce Nonce of the change pubkey L2 transaction
        fn setAuthPubkeyHash(ref self: ContractState, _pubkeyHash: felt252, _nonce: u32) {
            self.start();
            self.active();

            let sender = get_caller_address();
            if self.authFacts.read((sender, _nonce)) == 0 {
                self.authFacts.write((sender, _nonce), pubKeyHash(_pubkeyHash));
                self
                    .emit(
                        Event::FactAuth(
                            FactAuth { sender: sender, nonce: _nonce, fact: _pubkeyHash }
                        )
                    );
            } else {
                let currentResetTimer: u64 = self.authFactsResetTimer.read((sender, _nonce));
                let timestamp = get_block_timestamp();
                if currentResetTimer == 0 {
                    self.authFactsResetTimer.write((sender, _nonce), timestamp);
                    self
                        .emit(
                            Event::FactAuthResetTime(
                                FactAuthResetTime { sender: sender, nonce: _nonce, time: timestamp }
                            )
                        );
                } else {
                    assert((timestamp - currentResetTimer) >= AUTH_FACT_RESET_TIMELOCK, 'B1');
                    self.authFactsResetTimer.write((sender, _nonce), 0);
                    self.authFacts.write((sender, _nonce), pubKeyHash(_pubkeyHash));
                    self
                        .emit(
                            Event::FactAuth(
                                FactAuth { sender: sender, nonce: _nonce, fact: _pubkeyHash }
                            )
                        );
                }
            }

            self.end();
        }

        // Withdraws tokens from zkLink contract to the owner
        // NOTE: We will call ERC20.transfer(.., _amount), but if according to internal logic of ERC20 token zkLink contract
        // balance will be decreased by value more then _amount we will try to subtract this value from user pending balance
        // Parameters:
        //  _owner Address of the tokens owner
        //  _tokenId Token id
        //  _amount Amount to withdraw to request.
        // Returns:
        //  The actual withdrawn amount
        fn withdrawPendingBalance(
            ref self: ContractState, _owner: ContractAddress, _tokenId: u16, _amount: u128
        ) -> u128 {
            self.start();

            // Checks
            let rt: RegisteredToken = self.tokens.read(_tokenId);
            assert(rt.registered, 'b0');

            // Set the available amount to withdraw
            let owner: u256 = extendAddress(_owner);
            let balance: u128 = self.pendingBalances.read((owner, _tokenId));
            let withdrawBalance = recoveryDecimals(balance, rt.decimals);
            let amount = uint_min(_amount, withdrawBalance);
            assert(amount > 0, 'b1');

            // Interactions
            IERC20CamelDispatcher { contract_address: rt.tokenAddress }
                .transfer(_owner, amount.into());

            self
                .pendingBalances
                .write((owner, _tokenId), balance - improveDecimals(amount, rt.decimals));
            self.emit(Event::Withdrawal(Withdrawal { tokenId: _tokenId, amount: amount }));

            self.end();
            amount
        }

        // Commit compressed block
        // 1. Checks onchain operations of current chain, timestamp.
        // 2. Store block commitments, sync hash.
        fn commitCompressedBlocks(
            ref self: ContractState,
            _lastCommittedBlockData: StoredBlockInfo,
            _newBlocksData: Array<CommitBlockInfo>
        ) {
            self.start();
            self.active();
            self.onlyValidator();
            // Checks
            let newBlocksDataLen = _newBlocksData.len();
            assert(newBlocksDataLen > 0, 'f0');
            // Check that we commit blocks after last committed block
            let mut _totalBlocksCommitted: u64 = self.totalBlocksCommitted.read();
            assert(
                self
                    .storedBlockHashes
                    .read(_totalBlocksCommitted) == hashStoredBlockInfo(_lastCommittedBlockData),
                'f1'
            );

            // Effects
            let mut i = 0;
            let mut _lastCommittedBlockData = _lastCommittedBlockData;
            loop {
                if i == newBlocksDataLen {
                    break;
                }
                _lastCommittedBlockData = self
                    .commitOneCompressedBlock(@_lastCommittedBlockData, _newBlocksData[i]);

                // forward `totalCommittedPriorityRequests` because it's will be reused in the next `commitOneCompressedBlock`
                self
                    .totalCommittedPriorityRequests
                    .write(
                        self.totalCommittedPriorityRequests.read()
                            + _lastCommittedBlockData.priorityOperations
                    );
                self
                    .storedBlockHashes
                    .write(_totalBlocksCommitted + 1, hashStoredBlockInfo(_lastCommittedBlockData));
                _totalBlocksCommitted += 1;
                i += 1;
            };
            assert(
                self.totalCommittedPriorityRequests.read() <= self.totalOpenPriorityRequests.read(),
                'f2'
            );

            self.totalBlocksCommitted.write(_totalBlocksCommitted);

            // log the last new committed block number
            self
                .emit(
                    Event::BlockCommit(
                        BlockCommit { blockNumber: _lastCommittedBlockData.blockNumber }
                    )
                );

            // only for test, can not be used in production
            if self.syncService.read().is_zero() {
                self.totalBlocksSynchronized.write(_lastCommittedBlockData.blockNumber);
            }
            self.end();
        }

        // Execute blocks, completing priority operations and processing withdrawals.
        // 1. Processes all pending operations (Send Exits, Complete priority requests)
        // 2. Finalizes block on Ethereum
        fn executeCompressedBlocks(ref self: ContractState, _blocksData: Array<ExecuteBlockInfo>) {
            self.start();
            self.active();
            self.onlyValidator();

            let _blocksData: Span<ExecuteBlockInfo> = _blocksData.span();
            let nBlocks = _blocksData.len().into();
            assert(nBlocks > 0, 'd0');

            let latestExecutedBlock: @ExecuteBlockInfo = _blocksData[nBlocks - 1];
            let latestExecutedBlockNumber = *latestExecutedBlock.storedBlock.blockNumber;
            assert(latestExecutedBlockNumber <= self.totalBlocksSynchronized.read(), 'd1');

            let mut priorityRequestsExecuted = 0;
            let mut _totalBlocksExecuted = self.totalBlocksExecuted.read();
            let mut i: usize = 0;
            loop {
                if i.into() == nBlocks {
                    break;
                }
                let _executedBlockIdx = _totalBlocksExecuted + i.into() + 1;
                let _blockExecuteData: @ExecuteBlockInfo = _blocksData[i];
                assert(*_blockExecuteData.storedBlock.blockSequence == _executedBlockIdx, 'd2');
                self.executeOneBlock(_blockExecuteData, _executedBlockIdx);
                priorityRequestsExecuted += *_blockExecuteData.storedBlock.priorityOperations;
                i += 1;
            };

            self
                .firstPriorityRequestId
                .write(self.firstPriorityRequestId.read() + priorityRequestsExecuted);
            self
                .totalCommittedPriorityRequests
                .write(self.totalCommittedPriorityRequests.read() - priorityRequestsExecuted);
            self
                .totalOpenPriorityRequests
                .write(self.totalOpenPriorityRequests.read() - priorityRequestsExecuted);

            self.totalBlocksExecuted.write(_totalBlocksExecuted + nBlocks.into());

            self
                .emit(
                    Event::BlockExecuted(BlockExecuted { blockNumber: latestExecutedBlockNumber })
                );

            self.end();
        }

        // Reverts unExecuted blocks
        fn revertBlocks(
            ref self: ContractState,
            _latestCommittedBlock: StoredBlockInfo,
            _blocksToRevert: Array<StoredBlockInfo>
        ) {
            self.start();
            self.onlyValidator();

            let mut blocksCommitted: u64 = self.totalBlocksCommitted.read();
            let blocksToRevert: u32 = uint_min(
                _blocksToRevert.len(),
                (blocksCommitted - self.totalBlocksExecuted.read()).try_into().unwrap()
            );
            let mut revertedPriorityRequests: u64 = 0;
            let mut i: usize = 0;

            loop {
                if i == blocksToRevert {
                    break;
                }

                let storedBlockInfo: StoredBlockInfo = *_blocksToRevert[i];
                assert(
                    self
                        .storedBlockHashes
                        .read(blocksCommitted) == hashStoredBlockInfo(storedBlockInfo),
                    'c'
                );

                // delete storedBlockHashes[blocksCommitted];
                self.storedBlockHashes.write(blocksCommitted, 0);

                blocksCommitted -= 1;
                revertedPriorityRequests += storedBlockInfo.priorityOperations;

                i += 1;
            };
            assert(
                self
                    .storedBlockHashes
                    .read(blocksCommitted) == hashStoredBlockInfo(_latestCommittedBlock),
                'c1'
            );

            self.totalBlocksCommitted.write(blocksCommitted);
            self
                .totalCommittedPriorityRequests
                .write(self.totalCommittedPriorityRequests.read() - revertedPriorityRequests);
            if (_latestCommittedBlock.blockNumber < self.totalBlocksSynchronized.read()) {
                self.totalBlocksSynchronized.write(_latestCommittedBlock.blockNumber);
            }

            self
                .emit(
                    Event::BlocksRevert(
                        BlocksRevert {
                            totalBlocksVerified: self.totalBlocksExecuted.read(),
                            totalBlocksCommitted: blocksCommitted
                        }
                    )
                );

            self.end();
        }

        /// Send sync hash to master chain
        fn sendSyncHash(ref self: ContractState, _block: StoredBlockInfo) {
            self.onlyValidator();

            assert(_block.blockNumber > self.totalBlocksSynchronized.read(), 'j0');
            assert(
                self.storedBlockHashes.read(_block.blockSequence) == hashStoredBlockInfo(_block),
                'j1'
            );

            ISyncServiceDispatcher { contract_address: self.syncService.read() }
                .sendSyncHash(_block.syncHash);

            self.emit(Event::SendSyncHash(SendSyncHash { syncHash: _block.syncHash }));
        }

        /// Receive block sync result from master chain
        fn receiveBlockConfirmation(ref self: ContractState, _blockNumber: u64) {
            self.onlySyncService();

            if (_blockNumber > self.totalBlocksSynchronized.read()) {
                self.totalBlocksSynchronized.write(_blockNumber);
                self.emit(Event::BlockSynced(BlockSynced { blockNumber: _blockNumber }));
            }
        }

        // Change current governor
        // Parameters:
        //  _newGovernor Address of the new governor
        fn changeGovernor(ref self: ContractState, _newGovernor: ContractAddress) {
            self.onlyGovernor();

            assert(_newGovernor != Zeroable::zero(), 'H');
            if _newGovernor != self.networkGovernor.read() {
                self.networkGovernor.write(_newGovernor);
                self.emit(Event::NewGovernor(NewGovernor { governor: _newGovernor }));
            }
        }

        // Add token to the list of networks tokens
        // Parameters:
        //  _tokenId Token id
        //  _tokenAddress Address of the token
        //  _decimals Token decimals of layer one
        //  _standard If token is a standard erc20
        fn addToken(
            ref self: ContractState, _tokenId: u16, _tokenAddress: ContractAddress, _decimals: u8
        ) {
            self.onlyGovernor();

            // token id MUST be in a valid range
            assert(_tokenId > 0, 'I0');
            assert(_tokenId <= MAX_AMOUNT_OF_REGISTERED_TOKENS, 'I0');
            // token MUST be not zero address
            assert(_tokenAddress != Zeroable::zero(), 'I1');
            // revert duplicate register
            let mut rt: RegisteredToken = self.tokens.read(_tokenId);
            assert(!rt.registered, 'I2');
            assert(self.tokenIds.read(_tokenAddress) == 0, 'I2');
            // token decimals of layer one MUST not be larger than decimals defined in layer two
            assert(_decimals <= TOKEN_DECIMALS_OF_LAYER2, 'I3');

            rt.registered = true;
            rt.tokenAddress = _tokenAddress;
            rt.decimals = _decimals;
            self.tokens.write(_tokenId, rt);
            self.tokenIds.write(_tokenAddress, _tokenId);
            self.emit(NewToken { tokenId: _tokenId, token: _tokenAddress, decimals: _decimals });
        }

        // Pause token deposits for the given token
        // Parameters:
        //  _tokenId Token id
        //  _tokenPaused Token paused status
        fn setTokenPaused(ref self: ContractState, _tokenId: u16, _tokenPaused: bool) {
            self.onlyGovernor();

            let mut rt: RegisteredToken = self.tokens.read(_tokenId);
            assert(rt.registered, 'K');

            if rt.paused != _tokenPaused {
                rt.paused = _tokenPaused;
                self.tokens.write(_tokenId, rt);
                self
                    .emit(
                        Event::TokenPausedUpdate(
                            TokenPausedUpdate { tokenId: _tokenId, paused: _tokenPaused }
                        )
                    );
            }
        }

        // Change validator status (active or not active)
        // Parameters:
        //  _validator Validator address
        //  _active Active flag
        fn setValidator(ref self: ContractState, _validator: ContractAddress, _active: bool) {
            self.onlyGovernor();
            if self.validators.read(_validator) != _active {
                self.validators.write(_validator, _active);
                self
                    .emit(
                        Event::ValidatorStatusUpdate(
                            ValidatorStatusUpdate {
                                validatorAddress: _validator, isActive: _active
                            }
                        )
                    );
            }
        }

        // Set gateway address
        // Parameters:
        //  _gateway gateway address
        fn setGateway(ref self: ContractState, _gateway: ContractAddress) {
            self.onlyGovernor();
            self.gateway.write(_gateway);
            self.emit(Event::SetGateway(SetGateway { newGateway: _gateway }));
        }

        /// Set sync service address
        /// Parameters:
        ///  _syncService new sync service address
        fn setSyncService(ref self: ContractState, _syncService: ContractAddress) {
            self.onlyGovernor();
            self.syncService.write(_syncService);
            self.emit(Event::SetSyncService(SetSyncService { newSyncService: _syncService }));
        }

        // =============view functions=============
        // Returns amount of tokens that can be withdrawn by `address` from zkLink contract
        // Parameters:
        //  _address Address of the tokens owner
        //  _tokenId Token id
        // Returns:
        //  The pending balance(without recovery decimals) can be withdrawn
        fn getPendingBalance(self: @ContractState, _address: u256, _tokenId: u16) -> u128 {
            self.pendingBalances.read((_address, _tokenId))
        }

        // get verifier contract address
        fn verifier(self: @ContractState) -> ContractAddress {
            self.verifier.read()
        }

        /// get syncService contract address
        fn syncService(self: @ContractState) -> ContractAddress {
            self.syncService.read()
        }

        fn totalBlocksExecuted(self: @ContractState) -> u64 {
            self.totalBlocksExecuted.read()
        }

        fn firstPriorityRequestId(self: @ContractState) -> u64 {
            self.firstPriorityRequestId.read()
        }

        // Return the network governor
        fn networkGovernor(self: @ContractState) -> ContractAddress {
            self.networkGovernor.read()
        }

        fn totalBlocksCommitted(self: @ContractState) -> u64 {
            self.totalBlocksCommitted.read()
        }

        fn totalOpenPriorityRequests(self: @ContractState) -> u64 {
            self.totalOpenPriorityRequests.read()
        }

        fn totalBlocksProven(self: @ContractState) -> u64 {
            self.totalBlocksProven.read()
        }

        fn totalCommittedPriorityRequests(self: @ContractState) -> u64 {
            self.totalCommittedPriorityRequests.read()
        }

        fn totalBlocksSynchronized(self: @ContractState) -> u64 {
            self.totalBlocksSynchronized.read()
        }
        fn exodusMode(self: @ContractState) -> bool {
            self.exodusMode.read()
        }

        fn authFacts(self: @ContractState, _owner: ContractAddress, _nonce: u32) -> u256 {
            self.authFacts.read((_owner, _nonce))
        }

        fn accepts(self: @ContractState, _hash: u256) -> ContractAddress {
            self.accepts.read(_hash)
        }

        fn validators(self: @ContractState, _validator: ContractAddress) -> bool {
            self.validators.read(_validator)
        }

        fn tokens(self: @ContractState, _tokenId: u16) -> RegisteredToken {
            self.tokens.read(_tokenId)
        }
        fn tokenIds(self: @ContractState, _tokenAddress: ContractAddress) -> u16 {
            self.tokenIds.read(_tokenAddress)
        }

        // Notice period before activation preparation status of upgrade mode
        fn getNoticePeriod(self: @ContractState) -> u256 {
            return UPGRADE_NOTICE_PERIOD.into();
        }

        // Checks that contract is ready for upgrade
        // Returns: bool flag indicating that contract is ready for upgrade
        fn isReadyForUpgrade(self: @ContractState) -> bool {
            !self.exodusMode.read()
        }

        fn getMaster(self: @ContractState) -> ContractAddress {
            self.master.read()
        }

        fn transferMastership(ref self: ContractState, _newMaster: ContractAddress) {
            self.requireMaster(get_caller_address());
            assert(
                _newMaster != Zeroable::zero(), '1d'
            ); // otp11 - new masters address can't be zero address
            self.setMaster(_newMaster);
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            self.requireMaster(get_caller_address());
            assert(!impl_hash.is_zero(), 'upg11');
            starknet::replace_class_syscall(impl_hash).unwrap();
        }

        fn gateway(self: @ContractState) -> ContractAddress {
            self.gateway.read()
        }
    }

    #[generate_trait]
    impl InternalOwnableImpl of InternalOwnableTrait {
        fn setMaster(ref self: ContractState, _newMaster: ContractAddress) {
            self.master.write(_newMaster);
        }

        fn requireMaster(self: @ContractState, _address: ContractAddress) {
            assert(self.master.read() == _address, '1c'); // oro11 - only by master
        }
    }

    #[generate_trait]
    impl ModifierImpl of ModifierTrait {
        // Checks that current state not is exodus mode
        #[inline(always)]
        fn active(self: @ContractState) {
            assert(!self.exodusMode.read(), '0');
        }

        // Checks that current state is exodus mode
        #[inline(always)]
        fn notActive(self: @ContractState) {
            assert(self.exodusMode.read(), '1');
        }

        fn start(ref self: ContractState) {
            assert(!self.entered.read(), 'ReentrancyGuard: reentrant call');
            self.entered.write(true);
        }

        fn end(ref self: ContractState) {
            self.entered.write(false);
        }

        /// Check if msg sender is a governor
        #[inline(always)]
        fn onlyGovernor(self: @ContractState) {
            assert(get_caller_address() == self.networkGovernor.read(), '3');
        }

        /// Check if msg sender is a validator
        #[inline(always)]
        fn onlyValidator(self: @ContractState) {
            assert(self.validators.read(get_caller_address()), '4');
        }

        /// Check if msg sender is sync service
        #[inline(always)]
        fn onlySyncService(self: @ContractState) {
            assert(get_caller_address() == self.syncService.read(), '6');
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        // Deposit ERC20 token internal function
        // Parameters:
        //  _token Token address
        //  _amount Token amount
        //  _zkLinkAddress The receiver Layer 2 address
        //  _subAccountId The receiver sub account
        //  _mapping If true and token has a mapping token, user will receive mapping token at l2
        fn deposit(
            ref self: ContractState,
            _tokenAddress: ContractAddress,
            _amount: u128,
            _zkLinkAddress: u256,
            _subAccountId: u8,
            _mapping: bool
        ) {
            self.active();
            // checks
            // disable deposit to zero address or global asset account
            // global asset account is 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            // user can not deposit to this account, skip this check
            assert(
                _zkLinkAddress.is_non_zero() && _zkLinkAddress != GLOBAL_ASSET_ACCOUNT_ADDRESS, 'e1'
            );
            // subAccountId MUST be valid
            assert(_subAccountId <= MAX_SUB_ACCOUNT_ID, 'e2');
            // token MUST be registered to ZkLink and deposit MUST be enabled
            let tokenId = self.tokenIds.read(_tokenAddress);
            // 0 is a invalid token and MUST NOT register to zkLink contract
            assert(tokenId != 0, 'e3');
            let rt = self.tokens.read(tokenId);
            assert(rt.registered, 'e3');
            assert(!rt.paused, 'e4');

            // transfer erc20 token from sender to zkLink contract
            IERC20CamelDispatcher { contract_address: _tokenAddress }
                .transferFrom(get_caller_address(), get_contract_address(), _amount.into());

            // improve decimals before send to layer two
            let _amount = improveDecimals(_amount, rt.decimals);
            // disable deposit with zero amount
            assert(_amount > 0 && _amount <= MAX_DEPOSIT_AMOUNT, 'e0');

            // only stable tokens(e.g. USDC, BUSD) support mapping to USD when deposit
            let mut targetTokenId = tokenId;
            if _mapping {
                assert(
                    tokenId >= MIN_USD_STABLE_TOKEN_ID && tokenId <= MAX_USD_STABLE_TOKEN_ID, 'e5'
                );
                targetTokenId = USD_TOKEN_ID;
            }

            // Effects
            // Priority Queue request
            let op = Deposit {
                chainId: CHAIN_ID,
                subAccountId: _subAccountId,
                tokenId: tokenId,
                targetTokenId: targetTokenId,
                amount: _amount,
                owner: _zkLinkAddress,
                accountId: 0, // unknown at this point
            };

            let pubData = op.writeForPriorityQueue();
            self.addPriorityRequest(OpType::Deposit(()), pubData, DEPOSIT_CHECK_BYTES);
        }

        // Saves priority request in storage
        // Calculates expiration block for request, store this request and emit NewPriorityRequest event
        // Parameters:
        //  _opType Rollup operation type
        //  _pubData Operation pubdata
        fn addPriorityRequest(
            ref self: ContractState, _opType: OpType, _pubData: Bytes, _hashInputSize: usize
        ) {
            // Expiration block is: current block number + priority expiration delta
            let expirationBlock = get_block_number() + PRIORITY_EXPIRATION;
            let toprs = self.totalOpenPriorityRequests.read();
            let nextPriorityRequestId = self.firstPriorityRequestId.read() + toprs;
            let hashedPubData = _pubData.keccak_for_check(_hashInputSize);
            let priorityRequest = PriorityOperation {
                hashedPubData: hashedPubData, expirationBlock: expirationBlock, opType: _opType
            };

            self.priorityRequests.write(nextPriorityRequestId, priorityRequest);

            self
                .emit(
                    Event::NewPriorityRequest(
                        NewPriorityRequest {
                            sender: get_caller_address(),
                            serialId: nextPriorityRequestId,
                            opType: _opType,
                            pubData: _pubData,
                            expirationBlock: expirationBlock
                        }
                    )
                );
            self.totalOpenPriorityRequests.write(toprs + 1);
        }

        // Process one block commit using previous block StoredBlockInfo,
        // Parameters:
        //  _previousBlock
        //  _newBlock
        //  _compressed
        // Returns:
        //  new block StoredBlockInfo
        // NOTE: Does not change storage (except events, so we can't mark it view)
        fn commitOneCompressedBlock(
            ref self: ContractState, _previousBlock: @StoredBlockInfo, _newBlock: @CommitBlockInfo
        ) -> StoredBlockInfo {
            assert(*_newBlock.blockNumber > *_previousBlock.blockNumber, 'g0');

            // Check onchain operations
            let (pendingOnchainOpsHash, priorityReqCommitted, onchainOperationPubdataHash) = self
                .collectOnchainOpsOfCompressedBlock(_newBlock);

            // Create synchronization hash for cross chain block verify
            let syncHash = createSlaverChainSyncHash(
                *_previousBlock.syncHash,
                *_newBlock.blockNumber,
                *_newBlock.newStateHash,
                onchainOperationPubdataHash
            );

            StoredBlockInfo {
                blockNumber: *_newBlock.blockNumber,
                blockSequence: *_previousBlock.blockSequence + 1,
                priorityOperations: priorityReqCommitted,
                pendingOnchainOperationsHash: pendingOnchainOpsHash,
                syncHash: syncHash
            }
        }

        // Gets operations packed in bytes array. Unpacks it and stores onchain operations.
        // Priority operations must be committed in the same order as they are in the priority queue.
        // NOTE: does not change storage! (only emits events)
        // Parameters:
        //  _newBlockData
        // Returns:
        //  processableOperationsHash - hash of the all operations of the current chain that needs to be executed  (Withdraws, ForcedExits, FullExits)
        //  priorityOperationsProcessed - number of priority operations processed of the current chain in this block (Deposits, FullExits)
        //  currentOnchainOpPubdataHash - current chain onchain operation (Deposits, ChangePubKeys, Withdraws, ForcedExits, FullExits) pubdatas group by chain id (used in cross chain block verify)
        fn collectOnchainOpsOfCompressedBlock(
            self: @ContractState, _newBlockData: @CommitBlockInfo
        ) -> (u256, u64, u256) {
            let pubData = _newBlockData.publicData;
            // pubdata length must be a multiple of CHUNK_BYTES
            assert(pubData.size() % CHUNK_BYTES == 0, 'h0');

            let uncommittedPriorityRequestsOffset = self.firstPriorityRequestId.read()
                + self.totalCommittedPriorityRequests.read();
            let mut priorityOperationsProcessed: u64 = 0;
            let mut onchainOperationPubdataHash: u256 = EMPTY_STRING_KECCAK;
            let mut processableOperationsHash: u256 = EMPTY_STRING_KECCAK;

            let mut i = 0;
            loop {
                if i == _newBlockData.onchainOperations.len() {
                    break;
                }
                let onchainOpData: @OnchainOperationData = _newBlockData.onchainOperations[i];
                let pubdataOffset: usize = *onchainOpData.publicDataOffset;

                assert(pubdataOffset + 1 < pubData.size(), 'h1');
                assert(pubdataOffset % CHUNK_BYTES == 0, 'h2');

                let (_, opType) = ReadBytes::<OpType>::read(pubData, pubdataOffset);

                let nextPriorityOpIndex: u64 = uncommittedPriorityRequestsOffset
                    + priorityOperationsProcessed;

                let (newPriorityProceeded, opPubData, opPubDataProcessable) = self
                    .checkOnchainOpOfCompressedBlock(
                        opType, pubData, pubdataOffset, nextPriorityOpIndex
                    );

                priorityOperationsProcessed += newPriorityProceeded;
                // group onchain operations pubdata hash by chain id
                onchainOperationPubdataHash = concatHash(onchainOperationPubdataHash, @opPubData);

                if opPubDataProcessable {
                    processableOperationsHash = concatHash(processableOperationsHash, @opPubData);
                }

                i += 1;
            };

            (processableOperationsHash, priorityOperationsProcessed, onchainOperationPubdataHash)
        }


        fn checkOnchainOpOfCompressedBlock(
            self: @ContractState,
            _opType: OpType,
            _pubData: @Bytes,
            _pubdataOffset: usize,
            _nextPriorityOpIdx: u64
        ) -> (u64, Bytes, bool) {
            let mut priorityOperationsProcessed: u64 = 0;
            let mut opPubDataProcessable: bool = false;
            let mut opPubData: Bytes = BytesTrait::new();
            // ignore check if ops are not part of the current chain
            if _opType == OpType::Deposit(()) {
                opPubData = _pubData.read_bytes(_pubdataOffset, DEPOSIT_BYTES);
                checkPriorityOperation(
                    @opPubData, @self.priorityRequests.read(_nextPriorityOpIdx), DEPOSIT_CHECK_BYTES
                );
                priorityOperationsProcessed = 1;
            } else if _opType == OpType::ChangePubKey(()) {
                opPubData = _pubData.read_bytes(_pubdataOffset, CHANGE_PUBKEY_BYTES);
                let mut offset = CHANGE_PUBKEY_CHECK_OFFSET;
                let (offset, pubKeyHash) = opPubData.read_felt252_packed(offset, PUBKEY_HASH_BYTES);
                let (offset, owner) = opPubData.read_address(offset);
                let (offset, nonce) = opPubData.read_u32(offset);
                // Now, starknet only support on-chain change pubkey
                let valid: bool = self.authFacts.read((owner, nonce)) == pubKeyHash(pubKeyHash);
                assert(valid, 'k1');
            } else {
                if _opType == OpType::Withdraw(()) {
                    opPubData = _pubData.read_bytes(_pubdataOffset, WITHDRAW_BYTES);
                } else if _opType == OpType::ForcedExit(()) {
                    opPubData = _pubData.read_bytes(_pubdataOffset, FORCED_EXIT_BYTES);
                } else if _opType == OpType::FullExit(()) {
                    opPubData = _pubData.read_bytes(_pubdataOffset, FULL_EXIT_BYTES);
                    checkPriorityOperation(
                        @opPubData,
                        @self.priorityRequests.read(_nextPriorityOpIdx),
                        FULL_EXIT_CHECK_BYTES
                    );
                    priorityOperationsProcessed = 1;
                } else {
                    // revert("k2")
                    panic_with_felt252('k2');
                }

                opPubDataProcessable = true;
            }

            (priorityOperationsProcessed, opPubData, opPubDataProcessable)
        }

        // Executes one block
        // 1. Processes all pending operations (Send Exits, Complete priority requests)
        // 2. Finalizes block on Ethereum
        fn executeOneBlock(
            ref self: ContractState, _blockExecuteData: @ExecuteBlockInfo, _executedBlockIdx: u64
        ) {
            // Ensure block was committed
            assert(
                hashStoredBlockInfo(*_blockExecuteData.storedBlock) == self
                    .storedBlockHashes
                    .read(_executedBlockIdx),
                'm0'
            );

            let mut pendingOnchainOpsHash: u256 = EMPTY_STRING_KECCAK;
            let mut i: usize = 0;
            loop {
                if i == _blockExecuteData.pendingOnchainOpsPubdata.len() {
                    break;
                }

                let pubData: @Bytes = _blockExecuteData.pendingOnchainOpsPubdata[i];

                let (_, opType) = OpTypeReadBytes::read(pubData, 0);

                // `pendingOnchainOpsPubdata` only contains ops of the current chain
                // no need to check chain id

                if opType == OpType::Withdraw(()) {
                    let op = WithdrawReadOperation::readFromPubdata(pubData);
                    // account request fast withdraw and sub account supply nonce
                    self
                        ._executeWithdraw(
                            op.accountId,
                            op.subAccountId,
                            op.nonce,
                            op.owner,
                            op.tokenId,
                            op.amount,
                            op.fastWithdrawFeeRate,
                            op.withdrawToL1
                        );
                } else if opType == OpType::ForcedExit(()) {
                    let op = ForcedExitReadOperation::readFromPubdata(pubData);
                    // request forced exit for target account but initiator sub account supply nonce
                    // forced exit require fast withdraw default and take no fee for fast withdraw
                    self
                        ._executeWithdraw(
                            op.initiatorAccountId,
                            op.initiatorSubAccountId,
                            op.initiatorNonce,
                            op.target,
                            op.tokenId,
                            op.amount,
                            0,
                            op.withdrawToL1
                        );
                } else if opType == OpType::FullExit(()) {
                    let op = FullExitReadOperation::readFromPubdata(pubData);
                    self.increasePendingBalance(op.tokenId, op.owner, op.amount);
                } else {
                    panic_with_felt252('m2');
                }

                pendingOnchainOpsHash = concatHash(pendingOnchainOpsHash, pubData);

                i += 1;
            };

            assert(
                pendingOnchainOpsHash == *_blockExecuteData
                    .storedBlock
                    .pendingOnchainOperationsHash,
                'm3'
            );
        }

        // The circuit will check whether there is dust in the amount
        fn _executeWithdraw(
            ref self: ContractState,
            _accountIdOfNonce: u32,
            _subAccountIdOfNonce: u8,
            _nonce: u32,
            _owner: ContractAddress,
            _tokenId: u16,
            _amount: u128,
            _fastWithdrawFeeRate: u16,
            _withdrawToL1: u8
        ) {
            // token MUST be registered
            let rt: RegisteredToken = self.tokens.read(_tokenId);
            assert(rt.registered, 'o0');

            // recover withdraw amount
            let recoverAmount = recoveryDecimals(_amount, rt.decimals);
            let withdrawHash = getWithdrawHash(
                _accountIdOfNonce,
                _subAccountIdOfNonce,
                _nonce,
                _owner,
                rt.tokenAddress,
                recoverAmount,
                _fastWithdrawFeeRate
            );

            if _withdrawToL1 == 1 {
                // store L1 withdraw data hash to wait relayer consuming it
                // (accountIdOfNonce, subAccountIdOfNonce, nonce) ensures the uniqueness of withdraw hash
                self.pendingL1Withdraws.write(withdrawHash, true);
                self
                    .emit(
                        Event::WithdrawalPendingL1(
                            WithdrawalPendingL1 { withdrawHash: withdrawHash }
                        )
                    )
            } else {
                let acceptor: ContractAddress = self.accepts.read(withdrawHash);
                if acceptor == Zeroable::zero() {
                    // receiver act as a acceptor
                    self.accepts.write(withdrawHash, _owner);
                    self.increasePendingBalance(_tokenId, _owner, _amount);
                } else {
                    self.increasePendingBalance(_tokenId, acceptor, _amount);
                }
            }
        }

        // Increase `_recipient` balance to withdraw
        // Parameters:
        //  _tokenId
        //  _recipient
        //  _amount amount that need to recovery decimals when withdraw
        fn increasePendingBalance(
            ref self: ContractState, _tokenId: u16, _recipient: ContractAddress, _amount: u128
        ) {
            let recipient: u256 = extendAddress(_recipient);
            self.increaseBalanceToWithdraw(recipient, _tokenId, _amount);
            self
                .emit(
                    Event::WithdrawalPending(
                        WithdrawalPending {
                            tokenId: _tokenId, recepient: recipient, amount: _amount
                        }
                    )
                );
        }

        fn increaseBalanceToWithdraw(
            ref self: ContractState, _address: u256, _tokenId: u16, _amount: u128
        ) {
            let balance: u128 = self.pendingBalances.read((_address, _tokenId));
            // overflow should not happen here
            // (2^128 / 10^18 = 3.4 * 10^20) is enough to meet the really token balance of L2 account
            self.pendingBalances.write((_address, _tokenId), balance + _amount);
        }

        fn _checkAccept(
            ref self: ContractState,
            _acceptor: ContractAddress,
            _receiver: ContractAddress,
            _token: ContractAddress,
            _amount: u128,
            _fastWithdrawFeeRate: u16,
            _accountIdOfNonce: u32,
            _subAccountIdOfNonce: u8,
            _nonce: u32
        ) -> u128 {
            self.active();
            // acceptor and receiver MUST be set and MUST not be the same
            assert(_receiver.is_non_zero(), 'H1');
            assert(_acceptor != _receiver, 'H2');

            // feeRate MUST be valid and MUST not be 100%
            assert(_fastWithdrawFeeRate < MAX_ACCEPT_FEE_RATE, 'H3');
            let amountReceive: u128 = _amount
                * (MAX_ACCEPT_FEE_RATE - _fastWithdrawFeeRate).into()
                / MAX_ACCEPT_FEE_RATE.into();

            // accept tx may be later than block exec tx(with user withdraw op)
            let hash = getWithdrawHash(
                _accountIdOfNonce,
                _subAccountIdOfNonce,
                _nonce,
                _receiver,
                _token,
                _amount,
                _fastWithdrawFeeRate
            );
            assert(self.accepts.read(hash).is_zero(), 'H4');

            // ===Effects===
            self.accepts.write(hash, _acceptor);

            amountReceive
        }
    }

    // =========================utils functions=========================
    // improve decimals when deposit, for example, user deposit 2 USDC in ui, and the decimals of USDC is 6
    // the `_amount` params when call contract will be 2 * 10^6
    // because all token decimals defined in layer two is 18
    // so the `_amount` in deposit pubdata should be 2 * 10^6 * 10^(18 - 6) = 2 * 10^18
    #[inline(always)]
    fn improveDecimals(_amount: u128, _decimals: u8) -> u128 {
        _amount * fast_power10((TOKEN_DECIMALS_OF_LAYER2 - _decimals).into())
    }

    // recover decimals when withdraw, this is the opposite of improve decimals
    #[inline(always)]
    fn recoveryDecimals(_amount: u128, _decimals: u8) -> u128 {
        _amount / fast_power10((TOKEN_DECIMALS_OF_LAYER2 - _decimals).into())
    }

    // Return accept record hash for fast withdraw
    // (accountIdOfNonce, subAccountIdOfNonce, nonce) ensures the uniqueness of withdraw hash
    fn getWithdrawHash(
        _accountIdOfNonce: u32,
        _subAccountIdOfNonce: u8,
        _nonce: u32,
        _owner: ContractAddress,
        _token: ContractAddress,
        _amount: u128,
        _fastWithdrawFeeRate: u16
    ) -> u256 {
        let mut bytes: Bytes = BytesTrait::new();
        bytes.append_u32(_accountIdOfNonce);
        bytes.append_u8(_subAccountIdOfNonce);
        bytes.append_u32(_nonce);
        bytes.append_address(_owner);
        bytes.append_address(_token);
        bytes.append_u128(_amount);
        bytes.append_u16(_fastWithdrawFeeRate);

        bytes.keccak()
    }

    // Returns the keccak hash of the ABI-encoded StoredBlockInfo
    #[inline(always)]
    fn hashStoredBlockInfo(_storedBlockInfo: StoredBlockInfo) -> u256 {
        let bytes: Bytes = _storedBlockInfo.into();
        bytes.keccak()
    }

    // Checks the peration is same as operation in priority queue
    #[inline(always)]
    fn checkPriorityOperation(
        op: @Bytes, _priorityOperation: @PriorityOperation, _checkSize: usize
    ) {
        assert(
            op.keccak_for_check(_checkSize) == *_priorityOperation.hashedPubData,
            'OP: invalid op hash'
        );
    }

    // Create synchronization hash for cross chain block verify
    fn createSlaverChainSyncHash(
        _preBlockSyncHash: u256,
        _newBlockNumber: u64,
        _newBlockStateHash: u256,
        _newBlockOnchainOperationPubdataHash: u256
    ) -> u256 {
        let mut bytes: Bytes = BytesTrait::new();
        bytes.append_u256(_preBlockSyncHash);
        bytes.append_u32(_newBlockNumber.try_into().unwrap()); // convert block number to u32
        bytes.append_u256(_newBlockStateHash);
        bytes.append_u256(_newBlockOnchainOperationPubdataHash);

        bytes.keccak()
    }

    #[inline(always)]
    fn extendAddress(_address: ContractAddress) -> u256 {
        let address: felt252 = _address.into();
        address.into()
    }
}
