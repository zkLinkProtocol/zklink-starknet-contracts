use starknet::ContractAddress;
use zklink::utils::data_structures::DataStructures::{
    StoredBlockInfo, CommitBlockInfo, ProofInput, Token,
    CompressedBlockExtraInfo, ExecuteBlockInfo};
use zklink::utils::bytes::Bytes;

#[starknet::interface]
trait IZklink<TContractState> {
    fn depositERC20(ref self: TContractState, _token: ContractAddress, _amount: u128, _zkLinkAddress: ContractAddress, _subAccountId: u8, _mapping: bool);
    fn transferERC20(ref self: TContractState, _token: ContractAddress, _to: ContractAddress, _amount: u128, _maxAmount: u128, _isStandard: bool) -> u128;
    fn acceptERC20(ref self: TContractState, _accepter: ContractAddress, _accountId: u32, _receiver: ContractAddress, _tokenId: u16, _amount: u128, _withdrawFeeRate: u16, _nonce: u32, _amountTransfer: u128);
    fn requestFullExit(ref self: TContractState, _accountId: u32, _subAccountId: u8, _tokenId: u16, _mapping: bool);
    fn activateExodusMode(ref self: TContractState);
    fn performExodus(ref self: TContractState, _storedBlockInfo: StoredBlockInfo, _owner: ContractAddress, _accountId: u32, _subAccountId: u8, _withdrawTokenId: u16, _deductTokenId: u16, _amount: u128, _proof: Array<u256>);
    fn cancelOutstandingDepositsForExodusMode(ref self: TContractState, _n: u64, _depositsPubdata: Array<Bytes>);
    fn setAuthPubkeyHash(ref self: TContractState, _pubkeyHash: felt252, _nonce: u32);
    fn withdrawPendingBalance(ref self: TContractState, _owner: ContractAddress, _tokenId: u16, _amount: u128) -> u128;
    fn commitBlocks(ref self: TContractState, _lastCommittedBlockData: StoredBlockInfo, _newBlocksData: Array<CommitBlockInfo>);
    fn commitCompressedBlocks(ref self: TContractState, _lastCommittedBlockData: StoredBlockInfo, _newBlocksData: Array<CommitBlockInfo>, _newBlocksExtraData: Array<CompressedBlockExtraInfo>);
    fn executeBlocks(ref self: TContractState, _blocksData: Array<ExecuteBlockInfo>);
    fn proveBlocks(ref self: TContractState, _committedBlocks: Array<StoredBlockInfo>, _proof: ProofInput);
    fn revertBlocks(ref self: TContractState, _blocksToRevert: Array<StoredBlockInfo>);
    fn receiveSynchronizationProgress(ref self: TContractState, _syncHash: u256, _progress: u256);
    fn syncBlocks(ref self: TContractState, _block: StoredBlockInfo);
    fn brokerApprove(ref self: TContractState, _tokenId: u16, _broker: ContractAddress, _amount: u128) -> bool;
    fn changeGovernor(ref self: TContractState, _newGovernor: ContractAddress);
    fn addToken(ref self: TContractState, _tokenId: u16, _tokenAddress: ContractAddress, _decimals: u8, _standard: bool);
    fn addTokens(ref self: TContractState, _tokenList: Array<Token>);
    fn setTokenPaused(ref self: TContractState, _tokenId: u16, _tokenPaused: bool);
    fn setValidator(ref self: TContractState, _validator: ContractAddress, _active: bool);
    fn addBridge(ref self: TContractState, _bridge: ContractAddress) -> usize;
    fn updateBridge(ref self: TContractState, _index: usize, _enableBridgeTo: bool, _enableBridgeFrom: bool);
    fn getSynchronizedProgress(self: @TContractState, _block: StoredBlockInfo) -> u256;
    fn brokerAllowance(self: @TContractState, _tokenId: u16, _accepter: ContractAddress, _broker: ContractAddress) -> u128;
    fn getPendingBalance(self: @TContractState, _address: ContractAddress, _tokenId: u16) -> u128;
    fn isBridgeToEnabled(self: @TContractState, _bridge: ContractAddress) -> bool;
    fn isBridgeFromEnabled(self: @TContractState, _bridge: ContractAddress) -> bool;

    fn StoredBlockInfoTest(self: @TContractState, _blocksData: Array<StoredBlockInfo>, i: usize) -> u64;
    fn CommitBlockInfoTest(self: @TContractState, _blocksData: Array<CommitBlockInfo>, i: usize, j: usize) -> usize;
    fn CompressedBlockExtraInfoTest(self: @TContractState, _blocksExtraData: Array<CompressedBlockExtraInfo>, i: usize, j: usize) -> u256;
    fn ExecuteBlockInfoTest(self: @TContractState, _blocksData: Array<ExecuteBlockInfo>, i: usize, j: usize, _opType: u8) -> u8;
    fn u256Test(self: @TContractState, _u256: u256) -> (u128, u128);
    fn u256sTest(self: @TContractState, _u256s: Array<u256>, i: usize) -> (u128, u128);
    fn u8sTest1(self: @TContractState, _u8s: Array<u8>) -> usize;
    fn u8sTest2(self: @TContractState, _u8s: Array<u8>) -> Array<u8>;
}

#[starknet::contract]
mod Zklink {
    use zeroable::Zeroable;
    use traits::{
        Into,
        TryInto,
        Index,
        Default
    };
    use option::OptionTrait;
    use array::{ArrayTrait, SpanTrait};
    use dict::Felt252DictTrait;
    use dict::Felt252DictEntryTrait;
    use box::BoxTrait;
    use clone::Clone;
    use starknet::{
        ContractAddress,
        contract_address_const,
        Felt252TryIntoContractAddress,
        get_contract_address,
        get_caller_address,
        get_block_info,
        get_block_timestamp
    };
    // TODO: corelib import error
    use core::starknet::info::get_block_number;

    use super::IZklinkDispatcher;
    use super::IZklinkDispatcherTrait;
    use zklink::libraries::IVerifier::IVerifierDispatcher;
    use zklink::libraries::IVerifier::IVerifierDispatcherTrait;
    use zklink::libraries::IERC20::IERC20Dispatcher;
    use zklink::libraries::IERC20::IERC20DispatcherTrait;
    // use zklink::libraries::reentrancyguard::ReentrancyGuard;

    use zklink::utils::bytes::{
        Bytes,
        BytesTrait,
        ReadBytes
    };
    use zklink::utils::operations::Operations::{
        OpType,
        OpTypeIntoU8,
        OpTypeReadBytes,
        U8TryIntoOpType,
        PriorityOperation,
        OperationTrait,
        Deposit,
        DepositOperation,
        FullExit,
        FullExitOperation,
        ForcedExit,
        ForcedExitOperatoin,
        Withdraw,
        WithdrawOperation,
        ChangePubKey,
        ChangePubKeyOperation
    };
    use zklink::utils::data_structures::DataStructures::{
        RegisteredToken,
        BridgeInfo,
        StoredBlockInfo,
        StoredBlockInfoIntoBytes,
        CommitBlockInfo,
        CompressedBlockExtraInfo,
        ExecuteBlockInfo,
        OnchainOperationData,
        Token,
        ProofInput,
        ChangePubkeyType,
        ChangePubkeyTypeReadBytes
    };
    use zklink::utils::math::{
        u128_pow,
        felt252_fast_pow2,
        u256_pow2,
        u256_to_u160,
        u32_min,
        u64_min,
        u128_min,
    };
    use zklink::utils::utils::{
        concatHash,
        pubKeyHash,
        concatTwoHash
    };
    use zklink::utils::constants::{
        EMPTY_STRING_KECCAK, MAX_AMOUNT_OF_REGISTERED_TOKENS, MAX_ACCOUNT_ID, MAX_SUB_ACCOUNT_ID,
        CHUNK_BYTES, DEPOSIT_BYTES, CHANGE_PUBKEY_BYTES, WITHDRAW_BYTES, FORCED_EXIT_BYTES, FULL_EXIT_BYTES,
        PRIORITY_EXPIRATION,
        MAX_DEPOSIT_AMOUNT,
        MAX_PROOF_COMMITMENT, INPUT_MASK,
        AUTH_FACT_RESET_TIMELOCK,
        CHAIN_ID, MIN_CHAIN_ID, MAX_CHAIN_ID, ALL_CHAINS, CHAIN_INDEX,
        ENABLE_COMMIT_COMPRESSED_BLOCK, MAX_ACCEPT_FEE_RATE,
        TOKEN_DECIMALS_OF_LAYER2,
        GLOBAL_ASSET_ACCOUNT_ID, GLOBAL_ASSET_ACCOUNT_ADDRESS,
        USD_TOKEN_ID, MIN_USD_STABLE_TOKEN_ID, MAX_USD_STABLE_TOKEN_ID,
    };
    
    /// Storage
    #[storage]
    struct Storage {
        entered: bool,

        // public
        // Verifier contract. Used to verify block proof and exit proof
        verifier: ContractAddress,

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
        // Root-chain balances to withdraw, (owner, tokenId) => amount
        // the amount of pending balance need to recovery decimals when withdraw
        pendingBalances: LegacyMap::<(ContractAddress, u16), u128>,

        // public
        // Flag indicates that a user has exited a certain token balance in the exodus mode
        // The struct of this map is (accountId ,subAccountId, withdrawTokenId, deductTokenId) => performed
        // withdrawTokenId is the token that withdraw to user in l1
        // deductTokenId is the token that deducted from user in l2
        performedExodus: LegacyMap::<(u32, u8, u16, u16), bool>,

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

        // internal
        // if (`synchronizedChains` | CHAIN_INDEX) == `ALL_CHAINS` defined in `constants.cairo` then blocks at `blockHeight` and before it can be executed
        // the key is the `syncHash` of `StoredBlockInfo`
        // the value is the `synchronizedChains` of `syncHash` collected from all other chains
        synchronizedChains: LegacyMap::<u256, u256>,

        // public
        // Accept infos of fast withdraw of account
        // (accountId, keccak256(receiver, tokenId, amount, withdrawFeeRate, nonce)) => accepter address
        accepts: LegacyMap::<(u32, u256), ContractAddress>,

        // internal
        // Broker allowance used in accept, accepter can authorize broker to do accept
        // Similar to the allowance of transfer in ERC20
        // (tokenId, accepter, broker) => allowance
        brokerAllowances: LegacyMap::<(u16, ContractAddress, ContractAddress), u128>,

        // public
        // A set of permitted validators
        validators: LegacyMap::<ContractAddress, bool>,

        // public
        // A map of registered token infos
        tokens: LegacyMap::<u16, RegisteredToken>,

        // public
        // A map of registered token infos
        tokenIds: LegacyMap::<ContractAddress, u16>,

        // public
        // using map instead of array, index => BridgeInfo
        // bridgeIndex[bridgeAddress] - 1 => BridgeInfo
        bridges: LegacyMap::<usize, BridgeInfo>,

        // public
        // bridges length
        bridgesLength: usize,

        // public
        // 0 is reversed for non-exist bridge, existing bridges are indexed from 1
        bridgeIndex: LegacyMap::<ContractAddress, usize>,
    }

    /// Events
    // Event emitted when a block is committed
    #[derive(Drop, starknet::Event)]
    struct BlockCommit {
        blockNumber: u64
    }

    // Event emitted when a block is proven
    #[derive(Drop, starknet::Event)]
    struct BlockProven {
        blockNumber: u64
    }

    // Event emitted when a block is executed
    #[derive(Drop, starknet::Event)]
    struct BlockExecuted {
        blockNumber: u64
    }
    
    // Event emitted when user funds are withdrawn from the zkLink state and contract
    #[derive(Drop, starknet::Event)]
    struct Withdrawal {
        tokenId: u16,
        amount: u128
    }

    // Event emitted when user funds are withdrawn from the zkLink state but not from contract
    #[derive(Drop, starknet::Event)]
    struct WithdrawalPending {
        tokenId: u16,
        recepient: ContractAddress,
        amount: u128
    }

    // Event emitted when user sends a authentication fact (e.g. pub-key hash)
    #[derive(Drop, starknet::Event)]
    struct FactAuth {
        sender: ContractAddress,
        nonce: u32,
        fact: felt252
    }

    // Event emitted when authentication fact reset clock start
    #[derive(Drop, starknet::Event)]
    struct FactAuthResetTime {
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
    struct ExodusMode {}

    // New priority request event. Emitted when a request is placed into mapping
    #[derive(Drop, starknet::Event)]
    struct NewPriorityRequest {
        sender: ContractAddress,
        serialId: u64,
        opType: OpType,
        pubData: Bytes,
        expirationBlock: u64
    }

    // Event emitted when accepter accept a fast withdraw
    #[derive(Drop, starknet::Event)]
    struct Accept {
        accepter: ContractAddress,
        accountId: u32,
        receiver: ContractAddress,
        tokenId: u16,
        amountSent: u128,
        amountReceive: u128
    }

    // Event emitted when set broker allowance
    #[derive(Drop, starknet::Event)]
    struct BrokerApprove {
        tokenId: u16,
        owner: ContractAddress,
        spender: ContractAddress,
        amount: u128
    }

    // Token added to ZkLink net
    #[derive(Drop, starknet::Event)]
    struct NewToken {
        tokenId: u16,
        token: ContractAddress
    }

    // Governor changed
    #[derive(Drop, starknet::Event)]
    struct NewGovernor {
        governor: ContractAddress
    }

    // Validator's status updated
    #[derive(Drop, starknet::Event)]
    struct ValidatorStatusUpdate {
        validatorAddress: ContractAddress,
        isActive: bool
    }

    // Token pause status update
    #[derive(Drop, starknet::Event)]
    struct TokenPausedUpdate {
        tokenId: u16,
        paused: bool
    }

    // New bridge added
    #[derive(Drop, starknet::Event)]
    struct AddBridge {
        bridge: ContractAddress,
        bridgeIndex: usize
    }

    // Bridge update
    #[derive(Drop, starknet::Event)]
    struct UpdateBridge {
        bridgeIndex: usize,
        enableBridgeTo: bool,
        enableBridgeFrom: bool
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BlockCommit: BlockCommit,
        BlockProven: BlockProven,
        BlockExecuted: BlockExecuted,
        Withdrawal: Withdrawal,
        WithdrawalPending: WithdrawalPending,
        FactAuth: FactAuth,
        FactAuthResetTime: FactAuthResetTime,
        BlocksRevert: BlocksRevert,
        ExodusMode: ExodusMode,
        NewPriorityRequest: NewPriorityRequest,
        Accept: Accept,
        BrokerApprove: BrokerApprove,
        NewToken: NewToken,
        NewGovernor: NewGovernor,
        ValidatorStatusUpdate: ValidatorStatusUpdate,
        TokenPausedUpdate: TokenPausedUpdate,
        AddBridge: AddBridge,
        UpdateBridge: UpdateBridge
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
        assert(_verifierAddress.is_non_zero(), 'i0');
        assert(_networkGovernor.is_non_zero(), 'i1');

        self.verifier.write(_verifierAddress);
        self.networkGovernor.write(_networkGovernor);

        let storedBlockZero = StoredBlockInfo {
            blockNumber: _blockNumber,
            priorityOperations: 0,
            pendingOnchainOperationsHash: EMPTY_STRING_KECCAK,
            timestamp: _timestamp,
            stateHash: _stateHash,
            commitment: _commitment,
            syncHash: _syncHash
        };

        // TODO: uncomment this assert when cairo fix the `Difference in FunctionId` bug.
        // https://github.com/starkware-libs/cairo/pull/3230
        // storedBlockHashes::write(_blockNumber, hashStoredBlockInfo(storedBlockZero));
        self.totalBlocksCommitted.write(_blockNumber);
        self.totalBlocksProven.write(_blockNumber);
        self.totalBlocksSynchronized.write(_blockNumber);
        self.totalBlocksExecuted.write(_blockNumber);
    }

    #[external(v0)]
    impl Zklink of super::IZklink<ContractState> {
        // TODO: upgrade interface


        // Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
        // it MUST be ok to call other external functions within from this function
        // when the token(eg. erc777) is not a pure erc20 token
        // Parameters:
        //  _token Token address
        //  _amount Token amount
        //  _zkLinkAddress The receiver Layer 2 address
        //  _subAccountId The receiver sub account
        //  _mapping If true and token has a mapping token, user will receive mapping token at l2
        fn depositERC20(ref self: ContractState, _token: ContractAddress, _amount: u128, _zkLinkAddress: ContractAddress, _subAccountId: u8, _mapping: bool) {
            self.start();
            self.deposit(_token, _amount, _zkLinkAddress, _subAccountId, _mapping);
            self.end();
        }

        // Sends tokens
        // NOTE: will revert if transfer call fails or rollup balance difference (before and after transfer) is bigger than _maxAmount
        // This function is used to allow tokens to spend zkLink contract balance up to amount that is requested
        // Parameters:
        //  _token Token address
        //  _to Address of recipient
        //  _amount Amount of tokens to transfer
        //  _maxAmount Maximum possible amount of tokens to transfer to this account
        //  _isStandard If token is a standard erc20
        //  withdrawnAmount The really amount than will be debited from user
        fn transferERC20(ref self: ContractState, _token: ContractAddress, _to: ContractAddress, _amount: u128, _maxAmount: u128, _isStandard: bool) -> u128 {
            let sender = get_caller_address();
            let contract_address = get_contract_address();
            assert(sender == contract_address, 'n0');

            // most tokens are standard, fewer query token balance can save gas
            if _isStandard {
                IERC20Dispatcher {contract_address: _token}.transfer(_to, _amount.into());
                return _amount;
            } else {
                let balanceBefore = IERC20Dispatcher {contract_address: _token}.balance_of(contract_address);
                IERC20Dispatcher {contract_address: _token}.transfer(_to, _amount.into());
                let balanceAfter = IERC20Dispatcher {contract_address: _token}.balance_of(contract_address);
                let balanceDiff: u128 = (balanceBefore - balanceAfter).try_into().unwrap();
                assert(balanceDiff > 0, 'n1'); // transfer is considered successful only if the balance of the contract decreased after transfer
                assert(balanceDiff <= _maxAmount, 'n2'); // rollup balance difference (before and after transfer) is bigger than `_maxAmount`
                return balanceDiff;
            }
        }

        // Accepter accept a erc20 token fast withdraw, accepter will get a fee for profit
        // Parameters:
        //  accepter Accepter who accept a fast withdraw
        //  accountId Account that request fast withdraw
        //  receiver User receive token from accepter (the owner of withdraw operation)
        //  tokenId Token id
        //  amount The amount of withdraw operation
        //  withdrawFeeRate Fast withdraw fee rate taken by accepter
        //  nonce Account nonce, used to produce unique accept info
        //  amountTransfer Amount that transfer from accepter to receiver
        // may be a litter larger than the amount receiver received
        fn acceptERC20(ref self: ContractState, _accepter: ContractAddress, _accountId: u32, _receiver: ContractAddress, _tokenId: u16, _amount: u128, _withdrawFeeRate: u16, _nonce: u32, _amountTransfer: u128) {
            self.start();

            // Checks
            let (mut amountReceive, hash, tokenAddress) = self._checkAccept(_accepter, _accountId, _receiver, _tokenId, _amount, _withdrawFeeRate, _nonce);

            // Effects
             self.accepts.write((_accountId, hash), _accepter);

            // Interactions
            let receiverBalanceBefore: u256 = IERC20Dispatcher {contract_address: tokenAddress}.balance_of(_receiver);
            let accepterBalanceBefore: u256 = IERC20Dispatcher {contract_address: tokenAddress}.balance_of(_accepter);
            let success: bool = IERC20Dispatcher {contract_address: tokenAddress}.transfer_from(_accepter, _receiver, _amountTransfer.into());
            // TODO: need check?
            assert(success, 'H7');
            let receiverBalanceAfter: u256 = IERC20Dispatcher {contract_address: tokenAddress}.balance_of(_receiver);
            let accepterBalanceAfter: u256 = IERC20Dispatcher {contract_address: tokenAddress}.balance_of(_accepter);
            let receiverBalanceDiff: u128 = (receiverBalanceAfter - receiverBalanceBefore).try_into().unwrap();
            assert(receiverBalanceDiff >= amountReceive, 'F0');
            amountReceive = receiverBalanceDiff;
            let amountSent: u128 = (accepterBalanceBefore - accepterBalanceAfter).try_into().unwrap();

            let sender = get_caller_address();
            if sender != _accepter {
                assert(Zklink::brokerAllowance(@self, _tokenId, _accepter, sender) >= amountSent, 'F1');
                 self.brokerAllowances.write((_tokenId, _accepter, sender),  self.brokerAllowances.read((_tokenId, _accepter, sender)) - amountSent);
            }

            self.emit(
                Accept {
                    accepter: _accepter,
                    accountId: _accountId,
                    receiver: _receiver,
                    tokenId: _tokenId,
                    amountSent: amountSent,
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
        fn requestFullExit(ref self: ContractState, _accountId: u32, _subAccountId: u8, _tokenId: u16, _mapping: bool) {
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
                assert(_tokenId >= MIN_USD_STABLE_TOKEN_ID && _tokenId <= MAX_USD_STABLE_TOKEN_ID, 'a3');
                srcTokenId = USD_TOKEN_ID;
            }

            // Effects
            let sender = get_caller_address();
            let op = FullExit {
                chainId: CHAIN_ID,
                accountId: _accountId,
                subAccountId: _subAccountId,
                owner: sender,              // Only the owner of account can fullExit for them self
                tokenId: _tokenId,
                srcTokenId: srcTokenId,
                amount: 0,                  // unknown at this point
            };

            let pubData = op.writeForPriorityQueue();
            self.addPriorityRequest(OpType::FullExit(()), pubData);

            self.end();
        }

        // Checks if Exodus mode must be entered. If true - enters exodus mode and emits ExodusMode event.
        // Exodus mode must be entered in case of current ethereum block number is higher than the oldest
        // of existed priority requests expiration block number.
        fn activateExodusMode(ref self: ContractState) {
            self.start();
            self.active();
            let blockNumber = get_block_number();
            let expirationBlock = self.priorityRequests.read(self.firstPriorityRequestId.read()).expirationBlock;
            let trigger: bool = ((blockNumber >= expirationBlock) & (expirationBlock != 0));

            if trigger {
                self.exodusMode.write(true);
                self.emit(
                    Event::ExodusMode(
                        ExodusMode {}
                    )
                );
            }

            self.end();
        }

        // Withdraws token from ZkLink to root chain in case of exodus mode. User must provide proof that he owns funds
        // Parameters:
        //  _storedBlockInfo Last verified block
        //  _owner Owner of the account
        //  _accountId Id of the account in the tree
        //  _subAccountId Id of the subAccount in the tree
        //  _proof Proof
        //  _withdrawTokenId The token want to withdraw in l1
        //  _deductTokenId The token deducted in l2
        //  _amount Amount for owner (must be total amount, not part of it) in l2
        fn performExodus(ref self: ContractState, _storedBlockInfo: StoredBlockInfo, _owner: ContractAddress, _accountId: u32, _subAccountId: u8, _withdrawTokenId: u16, _deductTokenId: u16, _amount: u128, _proof: Array<u256>) {
            self.start();
            self.notActive();

            // checks
            // performed exodus MUST not be already exited
            assert(!self.performedExodus.read((_accountId, _subAccountId, _withdrawTokenId, _deductTokenId)), 'y0');
            // incorrect stored block info
            assert(self.storedBlockHashes.read(self.totalBlocksExecuted.read()) == hashStoredBlockInfo(_storedBlockInfo), 'y1');
            // exit proof MUST be correct
            // TODO: impl fake verifier proof contract
            let proofCorrect: bool = true;
            assert(proofCorrect, 'y2');

            // Effects
            self.performedExodus.write((_accountId, _subAccountId, _withdrawTokenId, _deductTokenId), true);

            self.increaseBalanceToWithdraw(_withdrawTokenId, _owner, _amount);
            self.emit(
                Event::WithdrawalPending(
                    WithdrawalPending {
                        tokenId: _withdrawTokenId,
                        recepient: _owner,
                        amount: _amount
                    }
                )
            );

            self.end();
        }

        // Accrues users balances from deposit priority requests in Exodus mode
        // WARNING: Only for Exodus mode
        // Canceling may take several separate transactions to be completed
        // Parameters:
        //  _n number of requests to process
        //  _depositsPubdataSize deposit pubData size in bytes
        //  _depositsPubdata deposit details
        fn cancelOutstandingDepositsForExodusMode(ref self: ContractState, _n: u64, _depositsPubdata: Array<Bytes>) {
            self.start();
            self.notActive();
            // Checks
            let toProcess: u64 = u64_min(self.totalOpenPriorityRequests.read(), _n);
            assert(toProcess > 0, 'A0');

            // Effects
            let mut currentDepositIdx: usize = 0;
            // overflow is impossible, firstPriorityRequestId >= 0 and toProcess > 0
            let mut lastPriorityRequestId: u64 = self.firstPriorityRequestId.read() + toProcess - 1;
            let mut id: u64 = self.firstPriorityRequestId.read();
            loop {
                if id > lastPriorityRequestId {
                    break ();
                }

                let pr: PriorityOperation = self.priorityRequests.read(id);
                if pr.opType == OpType::Deposit(()) {
                    let depositPubdata = _depositsPubdata[currentDepositIdx];
                    let depositPubdataHash: felt252 = u256_to_u160(depositPubdata.keccak());
                    assert(depositPubdataHash == pr.hashedPubData, 'A1');
                    currentDepositIdx += 1;

                    let (_, op) = DepositOperation::readFromPubdata(depositPubdata);
                    self.increaseBalanceToWithdraw(op.tokenId, op.owner, op.amount);
                }

                // TODO: delete priority request
                // after return back deposited token to user, delete the priorityRequest to avoid redundant cancel
                // other priority requests(ie. FullExit) are also be deleted because they are no used anymore
                // and we can get gas reward for free these slots
                // delete priorityRequests[id];

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
                self.emit(
                    Event::FactAuth (
                        FactAuth {
                            sender: sender,
                            nonce: _nonce,
                            fact: _pubkeyHash
                        }
                    )
                );
            } else {
                let currentResetTimer: u64 = self.authFactsResetTimer.read((sender, _nonce));
                let timestamp = get_block_timestamp();
                if currentResetTimer == 0 {
                    self.authFactsResetTimer.write((sender, _nonce), timestamp);
                    self.emit(
                        Event::FactAuthResetTime (
                            FactAuthResetTime {
                                sender: sender,
                                nonce: _nonce,
                                time: timestamp
                            }
                        )
                    );
                } else {
                    assert((timestamp - currentResetTimer) >= AUTH_FACT_RESET_TIMELOCK, 'B1');
                    self.authFactsResetTimer.write((sender, _nonce), 0);
                    self.authFacts.write((sender, _nonce), pubKeyHash(_pubkeyHash));
                    self.emit(
                        Event::FactAuth (
                            FactAuth {
                                sender: sender,
                                nonce: _nonce,
                                fact: _pubkeyHash
                            }
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
        fn withdrawPendingBalance(ref self: ContractState, _owner: ContractAddress, _tokenId: u16, _amount: u128) -> u128 {
            self.start();

            // Checks
            let rt: RegisteredToken = self.tokens.read(_tokenId);
            assert(rt.registered, 'b0');

            // Set the available amount to withdraw
            let balance: u128 = self.pendingBalances.read((_owner, _tokenId));
            let withdrawBalance = recoveryDecimals(balance, rt.decimals);
            let mut amount = u128_min(_amount, withdrawBalance);
            assert(amount > 0, 'b1');

            // Interactions
            let tokenAddress: ContractAddress = rt.tokenAddress;
            let contract_address = get_contract_address();
            amount = IZklinkDispatcher {contract_address}.transferERC20(tokenAddress, _owner, amount, withdrawBalance, rt.standard);
            
            self.pendingBalances.write((_owner, _tokenId), balance - improveDecimals(amount, rt.decimals));
            self.emit(
                Event::Withdrawal (
                    Withdrawal {
                        tokenId: _tokenId,
                        amount: amount
                    }
                )
            );

            self.end();
            amount
        }

        // Commit block
        // 1. Checks onchain operations of all chains, timestamp.
        // 2. Store block commitments, sync hash.
        fn commitBlocks(ref self: ContractState, _lastCommittedBlockData: StoredBlockInfo, _newBlocksData: Array<CommitBlockInfo>) {
            let mut _newBlocksExtraData: Array<CompressedBlockExtraInfo> = ArrayTrait::new();
            self._commitBlocks(_lastCommittedBlockData, _newBlocksData, false, _newBlocksExtraData);
        }

        // Commit compressed block
        // 1. Checks onchain operations of current chain, timestamp.
        // 2. Store block commitments, sync hash.
        fn commitCompressedBlocks(ref self: ContractState, _lastCommittedBlockData: StoredBlockInfo, _newBlocksData: Array<CommitBlockInfo>, _newBlocksExtraData: Array<CompressedBlockExtraInfo>) {
            self._commitBlocks(_lastCommittedBlockData, _newBlocksData, true, _newBlocksExtraData);
        }

        // Execute blocks, completing priority operations and processing withdrawals.
        // 1. Processes all pending operations (Send Exits, Complete priority requests)
        // 2. Finalizes block on Ethereum
        fn executeBlocks(ref self: ContractState, _blocksData: Array<ExecuteBlockInfo>) {
            self.start();
            self.active();
            self.onlyValidator();

            let _blocksData = _blocksData.span();
            let nBlocks: u64 = _blocksData.len().into();
            assert(nBlocks > 0, 'd0');

            assert(self.totalBlocksExecuted.read() + nBlocks <= self.totalBlocksSynchronized.read(), 'd1');

            let mut priorityRequestsExecuted = 0;
            let mut i: usize = 0;
            loop {
                if i.into() == nBlocks {
                    break();
                }
                let blockData: @ExecuteBlockInfo = _blocksData[i];
                self.executeOneBlock(blockData, i);
                priorityRequestsExecuted += *blockData.storedBlock.priorityOperations;
                i += 1;
            };

            self.firstPriorityRequestId.write(self.firstPriorityRequestId.read() + priorityRequestsExecuted);
            self.totalCommittedPriorityRequests.write(self.totalCommittedPriorityRequests.read() - priorityRequestsExecuted);
            self.totalOpenPriorityRequests.write(self.totalOpenPriorityRequests.read() - priorityRequestsExecuted);

            self.totalBlocksExecuted.write(self.totalBlocksExecuted.read() + nBlocks);
            let lastBlockData: @ExecuteBlockInfo = _blocksData[(nBlocks - 1).try_into().unwrap()];
            self.emit(
                Event::BlockExecuted (
                    BlockExecuted {
                        blockNumber: *lastBlockData.storedBlock.blockNumber
                    }
                )
            );

            self.end();
        }

        // Blocks commitment verification.
        // Only verifies block commitments without any other processing
        fn proveBlocks(ref self: ContractState, _committedBlocks: Array<StoredBlockInfo>, _proof: ProofInput) {
            self.start();
            // Checks
            let ProofInput {
                recursiveInput,
                proof,
                vkIndexes,
                commitments,
                subproofsLimbs
            } = _proof;
            let mut currentTotalBlocksProven: u64 = self.totalBlocksProven.read();
            let mut i: usize = 0;
            let commitments_span = commitments.span();
            loop {
                if i == _committedBlocks.len() {
                    break ();
                }
                let commitBlock: @StoredBlockInfo = _committedBlocks[i];
                currentTotalBlocksProven += 1;
                assert(hashStoredBlockInfo(*commitBlock) == self.storedBlockHashes.read(currentTotalBlocksProven), 'x0');

                // commitment of proof produced by zk has only 253 significant bits
                // 'commitment & INPUT_MASK' is used to set the highest 3 bits to 0 and leave the rest unchanged
                assert(*commitments_span[i] <= MAX_PROOF_COMMITMENT, 'x1');
                assert(*commitments_span[i] == (*commitBlock.commitment & INPUT_MASK), 'x1');

                i += 1;
            };

            // Effects
            assert(currentTotalBlocksProven <= self.totalBlocksCommitted.read(), 'x2');
            self.totalBlocksProven.write(currentTotalBlocksProven);

            // Interactions
            let contract_address: ContractAddress = self.verifier.read();
            let success: bool = IVerifierDispatcher {contract_address}.verifyAggregatedBlockProof(
                recursiveInput,
                proof,
                vkIndexes,
                commitments,
                subproofsLimbs,
            );
            assert(success, 'x3');

            self.emit(
                Event::BlockProven (
                    BlockProven {
                        blockNumber: currentTotalBlocksProven
                    }
                )
            );

            self.end();
        }

        // Reverts unExecuted blocks
        fn revertBlocks(ref self: ContractState, _blocksToRevert: Array<StoredBlockInfo>) {
            self.start();
            self.onlyValidator();

            let mut blocksCommitted: u64 = self.totalBlocksCommitted.read();
            let blocksToRevert: u32 = u32_min(_blocksToRevert.len(), (blocksCommitted - self.totalBlocksExecuted.read()).try_into().unwrap());
            let mut revertedPriorityRequests: u64 = 0;
            let mut i: usize = 0;

            loop {
                if i == blocksToRevert {
                    break ();
                }

                let storedBlockInfo: StoredBlockInfo = *_blocksToRevert[i];
                assert(self.storedBlockHashes.read(blocksCommitted) == hashStoredBlockInfo(storedBlockInfo), 'c');

                // TODO: delete storedBlockHashes[blocksCommitted];
                // delete storedBlockHashes[blocksCommitted];

                blocksCommitted -= 1;
                revertedPriorityRequests += storedBlockInfo.priorityOperations;

                i += 1;
            };

            self.totalBlocksCommitted.write(blocksCommitted);
            self.totalCommittedPriorityRequests.write(self.totalCommittedPriorityRequests.read() - revertedPriorityRequests);

            if (self.totalBlocksCommitted.read() < self.totalBlocksProven.read()) {
                self.totalBlocksProven.write(self.totalBlocksCommitted.read());
            }
            if (self.totalBlocksProven.read() < self.totalBlocksSynchronized.read()) {
                self.totalBlocksSynchronized.write(self.totalBlocksProven.read());
            }

            self.emit(
                Event::BlocksRevert (
                    BlocksRevert {
                        totalBlocksVerified: self.totalBlocksExecuted.read(),
                        totalBlocksCommitted: blocksCommitted
                    }
                )
            );

            self.end();
        }

        // Combine the `progress` of the other chains of a `syncHash` with self
        fn receiveSynchronizationProgress(ref self: ContractState, _syncHash: u256, _progress: u256) {
            let sender = get_caller_address();
            assert(Zklink::isBridgeFromEnabled(@self, sender), 'C');

            self.synchronizedChains.write(_syncHash, self.synchronizedChains.read(_syncHash) | _progress);
        }

        // Check if received all syncHash from other chains at the block height
        fn syncBlocks(ref self: ContractState, _block: StoredBlockInfo) {
            self.start();

            let progress = Zklink::getSynchronizedProgress(@self, _block);

            assert(progress == ALL_CHAINS, 'D0');
            assert(_block.blockNumber > self.totalBlocksSynchronized.read(), 'D1');

            self.totalBlocksSynchronized.write(_block.blockNumber);

            self.end();
        }

        // Give allowance to broker to call accept
        // Parameters:
        //  tokenId token that transfer to the receiver of accept request from accepter or broker
        //  broker who are allowed to do accept by accepter(the msg.sender)
        //  amount the accept allowance of broker
        fn brokerApprove(ref self: ContractState, _tokenId: u16, _broker: ContractAddress, _amount: u128) -> bool {
            assert(_broker != Zeroable::zero(), 'G');
            let sender = get_caller_address();
            self.brokerAllowances.write((_tokenId, sender, _broker), _amount);
            self.emit(
                Event::BrokerApprove (
                    BrokerApprove {
                        tokenId: _tokenId,
                        owner: sender,
                        spender: _broker,
                        amount: _amount
                    }
                )
            );
            true
        }

        // Change current governor
        // Parameters:
        //  _newGovernor Address of the new governor
        fn changeGovernor(ref self: ContractState, _newGovernor: ContractAddress) {
            self.start();
            self.onlyGovernor();

            assert(_newGovernor != Zeroable::zero(), 'H');
            if _newGovernor != self.networkGovernor.read() {
                self.networkGovernor.write(_newGovernor);
                self.emit(
                    Event::NewGovernor (
                        NewGovernor {
                            governor: _newGovernor
                        }
                    )
                );
            }

            self.end();
        }

        // Add token to the list of networks tokens
        // Parameters:
        //  _tokenId Token id
        //  _tokenAddress Address of the token
        //  _decimals Token decimals of layer one
        //  _standard If token is a standard erc20
        fn addToken(ref self: ContractState, _tokenId: u16, _tokenAddress: ContractAddress, _decimals: u8, _standard: bool) {
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
            rt.standard = _standard;
            self.tokens.write(_tokenId, rt);
            self.tokenIds.write(_tokenAddress, _tokenId);
            self.emit(
                Event::NewToken (
                    NewToken {
                        tokenId: _tokenId,
                        token: _tokenAddress
                    }
                )
            );
        }

        // Add tokens to the list of networks tokens
        // Parameters:
        //  _tokenList Token list
        fn addTokens(ref self: ContractState, _tokenList: Array<Token>) {
            let mut i: usize = 0;
            loop {
                if i == _tokenList.len() {
                    break ();
                }
                let _token: Token = *_tokenList[i];
                Zklink::addToken(ref self, _token.tokenId, _token.tokenAddress, _token.decimals, _token.standard);
                i += 1;
            };
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
                self.emit(
                    Event::TokenPausedUpdate (
                        TokenPausedUpdate {
                            tokenId: _tokenId,
                            paused: _tokenPaused
                        }
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
                self.emit(
                    Event::ValidatorStatusUpdate (
                        ValidatorStatusUpdate {
                            validatorAddress: _validator,
                            isActive: _active
                        }
                    )
                );
            }
        }

        // Add a new bridge
        // Parameters:
        //  bridge the bridge contract
        // Returns:
        //  the index of new bridge
        fn addBridge(ref self: ContractState, _bridge: ContractAddress) -> usize {
            self.onlyGovernor();
            
            assert(_bridge != Zeroable::zero(), 'L0');
            // the index of non-exist bridge is zero
            assert(self.bridgeIndex.read(_bridge) == 0, 'L1');

            let info: BridgeInfo = BridgeInfo {
                bridge: _bridge,
                enableBridgeTo: true,
                enableBridgeFrom: true,
            };

            let mut length = self.bridgesLength.read();
            length += 1;
            self.bridgesLength.write(length);
            self.bridges.write(length, info);
            self.bridgeIndex.write(_bridge, length);

            self.emit(
                Event::AddBridge (
                    AddBridge {
                        bridge: _bridge,
                        bridgeIndex: length
                    }
                )
            );

            length
        }

        // Update bridge info
        // If we want to remove a bridge(not compromised), we should firstly set `enableBridgeTo` to false
        // and wait all messages received from this bridge and then set `enableBridgeFrom` to false.
        // But when a bridge is compromised, we must set both `enableBridgeTo` and `enableBridgeFrom` to false immediately
        // Parameters:
        //  _index the bridge info index
        //  _enableBridgeTo if set to false, bridge to will be disabled
        //  _enableBridgeFrom if set to false, bridge from will be disabled
        fn updateBridge(ref self: ContractState, _index: usize, _enableBridgeTo: bool, _enableBridgeFrom: bool) {
            self.onlyGovernor();

            assert(_index < self.bridgesLength.read(), 'M');
            let mut info: BridgeInfo = self.bridges.read(_index);
            info.enableBridgeTo = _enableBridgeTo;
            info.enableBridgeFrom = _enableBridgeFrom;
            self.bridges.write(_index, info);

            self.emit(
                Event::UpdateBridge (
                    UpdateBridge {
                        bridgeIndex: _index,
                        enableBridgeTo: _enableBridgeTo,
                        enableBridgeFrom: _enableBridgeFrom
                    }
                )
            );
        }

        // =============view functions=============
        // Get synchronized progress of current chain known
        fn getSynchronizedProgress(self: @ContractState, _block: StoredBlockInfo) -> u256 {
            // `ALL_CHAINS` will be upgraded when we add a new chain
            // and all blocks that confirm synchronized will return the latest progress flag
            let mut progress: u256 = 0;
            if _block.blockNumber <= self.totalBlocksSynchronized.read() {
                progress = ALL_CHAINS;
            } else {
                progress = self.synchronizedChains.read(_block.syncHash);
                // combine the current chain if it has proven this block
                if (_block.blockNumber <= self.totalBlocksProven.read()) & (hashStoredBlockInfo(_block) == self.storedBlockHashes.read(_block.blockNumber)) {
                    progress = progress | CHAIN_INDEX;
                } else {
                    progress = progress & ~CHAIN_INDEX;
                }
            }
            progress
        }

        // Return the accept allowance of broker
        fn brokerAllowance(self: @ContractState, _tokenId: u16, _accepter: ContractAddress, _broker: ContractAddress) -> u128 {
            self.brokerAllowances.read((_tokenId, _accepter, _broker))
        }

        // Returns amount of tokens that can be withdrawn by `address` from zkLink contract
        // Parameters:
        //  _address Address of the tokens owner
        //  _tokenId Token id
        // Returns:
        //  The pending balance(without recovery decimals) can be withdrawn
        fn getPendingBalance(self: @ContractState, _address: ContractAddress, _tokenId: u16) -> u128 {
            self.pendingBalances.read((_address, _tokenId))
        }

        // Get enableBridgeTo status
        fn isBridgeToEnabled(self: @ContractState, _bridge: ContractAddress) -> bool {
            let index = self.bridgeIndex.read(_bridge) - 1;
            self.bridges.read(index).enableBridgeTo
        }

        // Get enableBridgeFrom status
        fn isBridgeFromEnabled(self: @ContractState, _bridge: ContractAddress) -> bool {
            let index = self.bridgeIndex.read(_bridge) - 1;
            self.bridges.read(index).enableBridgeFrom
        }

        // =============Test Interface=============
        // TODO: delete after test
        fn StoredBlockInfoTest(self: @ContractState, _blocksData: Array<StoredBlockInfo>, i: usize) -> u64 {
            let blockData: @StoredBlockInfo = _blocksData[i];
            *blockData.timestamp
        }

        fn CommitBlockInfoTest(self: @ContractState, _blocksData: Array<CommitBlockInfo>, i: usize, j: usize) -> usize {
            let blockData: @CommitBlockInfo = _blocksData[i];
            let onchainOperation : @OnchainOperationData = blockData.onchainOperations[j];
            *onchainOperation.publicDataOffset
        }

        fn CompressedBlockExtraInfoTest(self: @ContractState, _blocksExtraData: Array<CompressedBlockExtraInfo>, i: usize, j: usize) -> u256 {
            let blockExtraData: @CompressedBlockExtraInfo = _blocksExtraData[i];
            *blockExtraData.onchainOperationPubdataHashs[j]
        }

        fn ExecuteBlockInfoTest(self: @ContractState, _blocksData: Array<ExecuteBlockInfo>, i: usize, j: usize, _opType: u8) -> u8 {
            let blockData: @ExecuteBlockInfo = _blocksData[i];
            let bytes: @Bytes = blockData.pendingOnchainOpsPubdata[j];
            let opType: OpType = _opType.try_into().unwrap();

            if opType == OpType::Deposit(()) {
                let (_, op) = DepositOperation::readFromPubdata(bytes);
                return op.chainId;
            } else if opType == OpType::FullExit(()) {
                let (_, op) = FullExitOperation::readFromPubdata(bytes);
                return op.chainId;
            } else if opType == OpType::Withdraw(()) {
                let (_, op) = WithdrawOperation::readFromPubdata(bytes);
                return op.chainId;
            } else if opType == OpType::ForcedExit(()) {
                let (_, op) = ForcedExitOperatoin::readFromPubdata(bytes);
                return op.chainId;
            } else if opType == OpType::ChangePubKey(()) {
                let (_, op) = ChangePubKeyOperation::readFromPubdata(bytes);
                return op.chainId;
            } else {
                return 0;
            }
        }

        fn u256Test(self: @ContractState, _u256: u256) -> (u128, u128) {
            (_u256.low, _u256.high)
        }

        fn u256sTest(self: @ContractState, _u256s: Array<u256>, i: usize) -> (u128, u128) {
            let _u256s = _u256s.span();
            let _u256: u256 = *_u256s[i];
            (_u256.low, _u256.high)
        }

        fn u8sTest1(self: @ContractState, _u8s: Array<u8>) -> usize {
            _u8s.len()
        }

        fn u8sTest2(self: @ContractState, _u8s: Array<u8>) -> Array<u8> {
            _u8s
        }
    }

    #[generate_trait]
    impl InternalFunctions of InternalFunctionsTrait {
        // =================modifier functions=================
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

        // Set logic contract must be called through proxy
        #[inline(always)]
        fn onlyDelegateCall(self: @ContractState) {
            // TODO
        }
        
        // Check if msg sender is a governor
        #[inline(always)]
        fn onlyGovernor(self: @ContractState) {
            assert(get_caller_address() == self.networkGovernor.read(), '3');
        }

        // Check if msg sender is a validator
        #[inline(always)]
        fn onlyValidator(self: @ContractState) {
            assert(self.validators.read(get_caller_address()), '4');
        }

        // =================Internal functions=================
        // Deposit ERC20 token internal function
        // Parameters:
        //  _token Token address
        //  _amount Token amount
        //  _zkLinkAddress The receiver Layer 2 address
        //  _subAccountId The receiver sub account
        //  _mapping If true and token has a mapping token, user will receive mapping token at l2
        fn deposit(ref self: ContractState, _tokenAddress: ContractAddress, _amount: u128, _zkLinkAddress: ContractAddress, _subAccountId: u8, _mapping: bool) {
            self.active();
            // checks
            // disable deposit to zero address or global asset account
            assert(_zkLinkAddress != contract_address_const::<0>(), 'e1');
            assert(_zkLinkAddress != GLOBAL_ASSET_ACCOUNT_ADDRESS.try_into().unwrap(), 'e1');
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
            let sender = get_caller_address();
            let this = get_contract_address();
            let mut _amount = _amount;
            if rt.standard {
                IERC20Dispatcher {contract_address: _tokenAddress}.transfer_from(sender, this, _amount.into());
            } else {
                // support non-standard tokens
                let balanceBefore = IERC20Dispatcher {contract_address: _tokenAddress}.balance_of(this);
                // NOTE, the balance of this contract will be increased
                // if the token is not a pure erc20 token, it could do anything within the transferFrom
                // we MUST NOT use `token.balanceOf(address(this))` in any control structures
                IERC20Dispatcher {contract_address: _tokenAddress}.transfer_from(sender, this, _amount.into());
                let balanceAfter = IERC20Dispatcher {contract_address: _tokenAddress}.balance_of(this);
                _amount = (balanceAfter - balanceBefore).try_into().unwrap();
            }

            // improve decimals before send to layer two
            _amount = improveDecimals(_amount, rt.decimals);
            // disable deposit with zero amount
            assert(_amount > 0 && _amount <= MAX_DEPOSIT_AMOUNT, 'e0');

            // only stable tokens(e.g. USDC, BUSD) support mapping to USD when deposit
            let mut targetTokenId = tokenId;
            if _mapping {
                assert(tokenId >= MIN_USD_STABLE_TOKEN_ID && tokenId <= MAX_USD_STABLE_TOKEN_ID, 'e5');
                targetTokenId = USD_TOKEN_ID;
            }

            // Effects
            // Priority Queue request
            let op = Deposit {
                chainId: CHAIN_ID,
                accountId: 0,   // unknown at this point
                subAccountId: _subAccountId,
                tokenId: tokenId,
                targetTokenId: targetTokenId,
                amount: _amount,
                owner: _zkLinkAddress
            };

            let pubData = op.writeForPriorityQueue();
            self.addPriorityRequest(OpType::Deposit(()), pubData);
        }
        
        // Saves priority request in storage
        // Calculates expiration block for request, store this request and emit NewPriorityRequest event
        // Parameters:
        //  _opType Rollup operation type
        //  _pubData Operation pubdata
        fn addPriorityRequest(ref self: ContractState, _opType: OpType, _pubData: Bytes) {
            // Expiration block is: current block number + priority expiration delta
            let expirationBlock = get_block_number() + PRIORITY_EXPIRATION;
            let toprs = self.totalOpenPriorityRequests.read();
            let nextPriorityRequestId = self.firstPriorityRequestId.read() + toprs;
            let hashedPubData = u256_to_u160(_pubData.keccak());

            let priorityRequest = PriorityOperation {
                hashedPubData: hashedPubData,
                expirationBlock: expirationBlock,
                opType: _opType
            };
            // TODO: uncomment it when impl real priorityRequests StorageAccess
            // priorityRequests::write(nextPriorityRequestId, priorityRequest);

            let sender = get_caller_address();
            self.emit(
                Event::NewPriorityRequest(
                    NewPriorityRequest {
                        sender: sender,
                        serialId: nextPriorityRequestId,
                        opType: _opType,
                        pubData: _pubData,
                        expirationBlock: expirationBlock
                    }
                )
            );
            self.totalOpenPriorityRequests.write(toprs + 1);
        }

        // CommitBlocks internal function
        // Parameters:
        //  _lastCommittedBlockData
        //  _newBlocksData
        //  _compressed
        //  _newBlocksExtraData
        fn _commitBlocks(ref self: ContractState, _lastCommittedBlockData: StoredBlockInfo, _newBlocksData: Array<CommitBlockInfo>, _compressed: bool, _newBlocksExtraData: Array<CompressedBlockExtraInfo>) {
            self.start();
            self.active();
            self.onlyValidator();
            // Checks
            let _newBlocksData = _newBlocksData.span();
            assert(_newBlocksData.len() > 0, 'f0');
            assert(self.storedBlockHashes.read(self.totalBlocksCommitted.read()) == hashStoredBlockInfo(_lastCommittedBlockData), 'f1');

            // Effects
            let mut i = 0;
            let mut _lastCommittedBlockData = _lastCommittedBlockData;
            loop {
                if i == _newBlocksData.len() {
                    break();
                }
                _lastCommittedBlockData = self.commitOneBlock(@_lastCommittedBlockData, _newBlocksData[i], _compressed, _newBlocksExtraData[i]);

                // forward `totalCommittedPriorityRequests` because it's will be reused in the next `commitOneBlock`
                self.totalCommittedPriorityRequests.write(self.totalCommittedPriorityRequests.read() + _lastCommittedBlockData.priorityOperations);
                self.storedBlockHashes.write(_lastCommittedBlockData.blockNumber, hashStoredBlockInfo(_lastCommittedBlockData));
                i += 1;
            };
            assert(self.totalCommittedPriorityRequests.read() <= self.totalOpenPriorityRequests.read(), 'f2');

            self.totalBlocksCommitted.write(self.totalBlocksCommitted.read() + _newBlocksData.len().into());

            // If enable compressed commit then we can ignore prove and ensure that block is correct by sync
            if (_compressed & (ENABLE_COMMIT_COMPRESSED_BLOCK == 1)) {
                self.totalBlocksProven.write(self.totalBlocksCommitted.read());
            }

            self.emit(
                Event::BlockCommit(
                    BlockCommit {
                        blockNumber: _lastCommittedBlockData.blockNumber
                    }
                )
            );

            self.end();
        }

        // Process one block commit using previous block StoredBlockInfo,
        // Parameters:
        //  _previousBlock
        //  _newBlock
        //  _compressed
        //  _newBlockExtra
        // Returns:
        //  new block StoredBlockInfo
        // NOTE: Does not change storage (except events, so we can't mark it view)
        fn commitOneBlock(ref self: ContractState, _previousBlock: @StoredBlockInfo, _newBlock: @CommitBlockInfo, _compressed: bool, _newBlockExtra: @CompressedBlockExtraInfo) -> StoredBlockInfo {
            assert(*_newBlock.blockNumber == *_previousBlock.blockNumber + 1, 'g0');
            // There is not bool <=> felt252 in Cairo, so we define ENABLE_COMMIT_COMPRESSED_BLOCK in felt252
            // if true is 1, else is 0.
            // So we can get commit compressed block enabled by `ENABLE_COMMIT_COMPRESSED_BLOCK == 1`
            assert(!_compressed | (ENABLE_COMMIT_COMPRESSED_BLOCK == 1), 'g1');
            // Check timestamp of the new block
            assert(*_newBlock.timestamp >= *_previousBlock.timestamp, 'g2');

            // Check onchain operations
            let (
                pendingOnchainOpsHash,
                priorityReqCommitted,
                onchainOpsOffsetCommitment,
                mut onchainOpPubdataHashsHigh,
                mut onchainOpPubdataHashsLow
            ) = self.collectOnchainOps(_newBlock);

            // Create block commitment for verification proof
            let commitment: u256 = createBlockCommitment(_previousBlock, _newBlock, _compressed, _newBlockExtra, onchainOpsOffsetCommitment);

            // Create synchronization hash for cross chain block verify
            if _compressed {
                let mut i = MIN_CHAIN_ID;
                loop {
                    if i > MAX_CHAIN_ID {
                        break();
                    }

                    if i != CHAIN_ID {
                        let (high_entry, _) = onchainOpPubdataHashsHigh.entry(i.into());
                        let (low_entry, _) = onchainOpPubdataHashsLow.entry(i.into());
                        let hash: u256 = *_newBlockExtra.onchainOperationPubdataHashs[i.into()];
                        onchainOpPubdataHashsHigh = high_entry.finalize(hash.high);
                        onchainOpPubdataHashsLow = low_entry.finalize(hash.low);
                    }
                    i += 1;
                };
            }

            let syncHash = createSyncHash(*_previousBlock.syncHash, commitment, ref onchainOpPubdataHashsHigh, ref onchainOpPubdataHashsLow);

            StoredBlockInfo {
                blockNumber: *_newBlock.blockNumber,
                priorityOperations: priorityReqCommitted,
                pendingOnchainOperationsHash: pendingOnchainOpsHash,
                timestamp: *_newBlock.timestamp,
                stateHash: *_newBlock.newStateHash,
                commitment: commitment,
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
        //  offsetsCommitment - array where 1 is stored in chunk where onchainOperation begins and other are 0 (used in commitments)
        //  onchainOperationPubdatas - onchain operation (Deposits, ChangePubKeys, Withdraws, ForcedExits, FullExits) pubdatas group by chain id (used in cross chain block verify)
        fn collectOnchainOps(self: @ContractState, _newBlockData: @CommitBlockInfo) -> (u256, u64, u256, Felt252Dict<u128>, Felt252Dict<u128>) {
            let pubData = _newBlockData.publicData;
            // pubdata length must be a multiple of CHUNK_BYTES
            assert(pubData.size() % CHUNK_BYTES == 0, 'h0');
            
            // Init return values
            let mut offsetsCommitment: u256 = 0; // use a u256 instead of Bytes to save gas
            let mut priorityOperationsProcessed: u64 = 0;
            let (mut onchainOpPubdataHashsHigh, mut onchainOpPubdataHashsLow) = initOnchainOperationPubdataHashs();
            let mut processableOperationsHash: u256 = EMPTY_STRING_KECCAK;

            let uncommittedPriorityRequestsOffset = self.firstPriorityRequestId.read() + self.totalCommittedPriorityRequests.read();

            let mut i = 0;
            loop {
                if i == _newBlockData.onchainOperations.len() {
                    break();
                }
                let onchainOpData: @OnchainOperationData = _newBlockData.onchainOperations[i];
                let pubdataOffset: usize = *onchainOpData.publicDataOffset;
                
                assert(pubdataOffset + 1 < pubData.size(), 'h1');
                assert(pubdataOffset % CHUNK_BYTES == 0, 'h2');

                {
                    let chunkId: u32 = pubdataOffset / CHUNK_BYTES;
                    let chunkIdCommitment = u256_pow2(chunkId);
                    // offset commitment should be empty
                    assert((offsetsCommitment & chunkIdCommitment) == 0, 'h3');
                    offsetsCommitment = offsetsCommitment | chunkIdCommitment;
                }

                // chainIdOffset = pubdataOffset + 1
                let (_, chainId) = pubData.read_u8(pubdataOffset + 1);
                checkChainId(chainId);

                let (_, opType) = ReadBytes::<OpType>::read(pubData, pubdataOffset);

                let nextPriorityOpIndex: u64 = uncommittedPriorityRequestsOffset + priorityOperationsProcessed;
                
                let (newPriorityProceeded, opPubData, processablePubData) = self.checkOnchainOp(
                    opType,
                    chainId,
                    pubData,
                    pubdataOffset,
                    nextPriorityOpIndex,
                    onchainOpData.ethWitness);

                priorityOperationsProcessed += newPriorityProceeded;
                // group onchain operations pubdata hash by chain id
                updateOnchainOperationPubdataHashs(chainId, ref onchainOpPubdataHashsHigh, ref onchainOpPubdataHashsLow, @opPubData);

                if processablePubData.size() > 0 {
                    processableOperationsHash = concatHash(processableOperationsHash, @processablePubData);
                }

                i += 1;
            };
            
            (
                processableOperationsHash,
                priorityOperationsProcessed,
                offsetsCommitment,
                onchainOpPubdataHashsHigh,
                onchainOpPubdataHashsLow
            )
        }

        

        fn checkOnchainOp(self: @ContractState, _opType: OpType, _chainId: u8, _pubData: @Bytes, _pubdataOffset: usize, _nextPriorityOpIdx: u64, _ethWitness: @Bytes) -> (u64, Bytes, Bytes) {
            let mut priorityOperationsProcessed: u64 = 0;
            let mut processablePubData: Bytes = BytesTrait::new_empty();
            let mut opPubData: Bytes = BytesTrait::new_empty();
            // ignore check if ops are not part of the current chain
            if _opType == OpType::Deposit(()) {
                let (_, opPubData_internal) = _pubData.read_bytes(_pubdataOffset, DEPOSIT_BYTES);
                if _chainId == CHAIN_ID {
                    let (_, op) = DepositOperation::readFromPubdata(@opPubData_internal);
                    op.checkPriorityOperation(@self.priorityRequests.read(_nextPriorityOpIdx));
                    priorityOperationsProcessed = 1;
                }
                opPubData = opPubData_internal;
            } else if _opType == OpType::ChangePubKey(()) {
                let (_, opPubData_internal) = _pubData.read_bytes(_pubdataOffset, CHANGE_PUBKEY_BYTES);
                if _chainId == CHAIN_ID {
                    let (_, op) = ChangePubKeyOperation::readFromPubdata(@opPubData_internal);
                    if _ethWitness.size() != 0 {
                        let valid: bool = self.verifyChangePubkey(_ethWitness, @op);
                        assert(valid, 'k0');
                    } else {
                        let valid: bool = self.authFacts.read((op.owner, op.nonce)) == pubKeyHash(op.pubKeyHash);
                        assert(valid, 'k1');
                    }
                }
                opPubData = opPubData_internal;
            } else {
                if _opType == OpType::Withdraw(()) {
                    let (_, opPubData_internal) = _pubData.read_bytes(_pubdataOffset, WITHDRAW_BYTES);
                    opPubData = opPubData_internal;
                } else if _opType == OpType::ForcedExit(()) {
                    let (_, opPubData_internal) = _pubData.read_bytes(_pubdataOffset, FORCED_EXIT_BYTES);
                    opPubData = opPubData_internal;
                } else if _opType == OpType::FullExit(()) {
                    let (_, opPubData_internal) = _pubData.read_bytes(_pubdataOffset, FULL_EXIT_BYTES);
                    if _chainId == CHAIN_ID {
                        let (_, op) = FullExitOperation::readFromPubdata(@opPubData_internal);
                        op.checkPriorityOperation(@self.priorityRequests.read(_nextPriorityOpIdx));
                        priorityOperationsProcessed = 1;
                    }
                    opPubData = opPubData_internal;
                } else {
                    // revert("k2")
                    panic_with_felt252('k2');
                }

                if (_chainId == CHAIN_ID) {
                    // clone opPubData here instead of return its reference
                    // because opPubData and processablePubData will be consumed in later concatHash
                    processablePubData = opPubData.clone();
                }
            }
            
            (priorityOperationsProcessed, opPubData, processablePubData)
        }

        


        // Checks that change operation is correct
        fn verifyChangePubkey(self: @ContractState, _ethWitness: @Bytes, _changePk: @ChangePubKey) -> bool {
            let (_, changePkType) = ChangePubkeyTypeReadBytes::read(_ethWitness, 0);
            if changePkType == ChangePubkeyType::ECRECOVER(()) {
                return self.verifyChangePubkeyECRECOVER(_ethWitness, _changePk);
            } else {
                return false;
            }
        }

        // Checks that signature is valid for pubkey change message
        fn verifyChangePubkeyECRECOVER(self: @ContractState, _ethWitness: @Bytes, _changePk: @ChangePubKey) -> bool {
            // TODO: add impl when cairo secp256k1 added
            // https://github.com/starkware-libs/cairo/blob/main/corelib/src/starknet/secp256k1.cairo
            true
        }

        // Executes one block
        // 1. Processes all pending operations (Send Exits, Complete priority requests)
        // 2. Finalizes block on Ethereum
        fn executeOneBlock(ref self: ContractState, _blockExecuteData: @ExecuteBlockInfo, _executedBlockIdx: usize) {
            // Ensure block was committed
            // TODO: uncomment this assert when cairo fix the `Difference in FunctionId` bug.
            // https://github.com/starkware-libs/cairo/pull/3230
            // assert(
            //     hashStoredBlockInfo(*_blockExecuteData.storedBlock) ==
            //     storedBlockHashes::read(*_blockExecuteData.storedBlock.blockNumber),
            //     'm0');
            assert(*_blockExecuteData.storedBlock.blockNumber == self.totalBlocksExecuted.read() + _executedBlockIdx.into() + 1, 'm1');

            let mut pendingOnchainOpsHash: u256 = EMPTY_STRING_KECCAK;
            let mut i: usize = 0;
            loop {
                if i == _blockExecuteData.pendingOnchainOpsPubdata.len() {
                    break ();
                }

                let pubData: @Bytes = _blockExecuteData.pendingOnchainOpsPubdata[i];

                let (_, opType) = OpTypeReadBytes::read(pubData, 0);

                // `pendingOnchainOpsPubdata` only contains ops of the current chain
                // no need to check chain id

                if opType == OpType::Withdraw(()) {
                    let (_, op) = WithdrawOperation::readFromPubdata(pubData);
                    self.executeWithdraw(op);
                } else if opType == OpType::ForcedExit(()) {
                    let (_, op) = ForcedExitOperatoin::readFromPubdata(pubData);
                    self.executeForceExit(op);
                } else if opType == OpType::FullExit(()) {
                    let (_, op) = FullExitOperation::readFromPubdata(pubData);
                    self.executeFullExit(op);
                } else {
                    panic_with_felt252('m2');
                }

                pendingOnchainOpsHash = concatHash(pendingOnchainOpsHash, pubData);

                i += 1;
            };

            assert(pendingOnchainOpsHash == *_blockExecuteData.storedBlock.pendingOnchainOperationsHash, 'm3');
        }

        // Execute withdraw operation
        fn executeWithdraw(ref self: ContractState, op: Withdraw) {
            // token MUST be registered
            let rt: RegisteredToken = self.tokens.read(op.tokenId);
            assert(rt.registered, 'o0');

            // nonce > 0 means fast withdraw
            if op.nonce > 0 {
                // recover withdraw amount
                let acceptAmount: u128 = recoveryDecimals(op.amount, rt.decimals);
                let dustAmount: u128 = op.amount - improveDecimals(acceptAmount, rt.decimals);
                let mut fwBytes: Bytes = BytesTrait::new_empty();
                fwBytes.append_address(op.owner);
                fwBytes.append_u16(op.tokenId);
                fwBytes.append_u128(acceptAmount);
                fwBytes.append_u16(op.fastWithdrawFeeRate);
                fwBytes.append_u32(op.nonce);
                let fwHash = fwBytes.keccak();
                let accepter: ContractAddress = self.accepts.read((op.accountId, fwHash));

                if accepter == Zeroable::zero() {
                    // receiver act as a accepter
                    self.accepts.write((op.accountId, fwHash), op.owner);
                    self.withdrawOrStore(op.tokenId, rt.tokenAddress, rt.standard, rt.decimals, op.owner, op.amount);
                } else {
                    // just increase the pending balance of accepter
                    self.increasePendingBalance(op.tokenId, accepter, op.amount);
                    // add dust to owner
                    if dustAmount > 0 {
                        self.increasePendingBalance(op.tokenId, op.owner, dustAmount);
                    }
                }
            } else {
                self.withdrawOrStore(op.tokenId, rt.tokenAddress, rt.standard, rt.decimals, op.owner, op.amount);
            }
        }

        // Execute force exit operation
        fn executeForceExit(ref self: ContractState, op: ForcedExit) {
            // token MUST be registered
            let rt: RegisteredToken = self.tokens.read(op.tokenId);
            assert(rt.registered, 'p0');

            self.withdrawOrStore(op.tokenId, rt.tokenAddress, rt.standard, rt.decimals, op.target, op.amount);
        }

        // Execute full exit operation
        fn executeFullExit(ref self: ContractState, op: FullExit) {
            // token MUST be registered
            let rt: RegisteredToken = self.tokens.read(op.tokenId);
            assert(rt.registered, 'r0');

            self.withdrawOrStore(op.tokenId, rt.tokenAddress, rt.standard, rt.decimals, op.owner, op.amount);
        }

        // Try execute withdraw, if it fails - store withdraw to pendingBalances
        // 1. Try to send token to _recipients
        // 2. On failure: Increment _recipients balance to withdraw.
        // Parameters:
        //  _tokenId
        //  _tokenAddress
        //  _isTokenStandard
        //  _decimals
        //  _recipient
        //  _amount
        fn withdrawOrStore(ref self: ContractState, _tokenId: u16, _tokenAddress: ContractAddress, _isTokenStandard: bool, _decimals: u8, _recipient: ContractAddress, _amount: u128) {
            if _amount == 0 {
                return ();
            }

            // recover withdraw amount and add dust to pending balance
            let withdrawAmount: u128 = recoveryDecimals(_amount, _decimals);
            let dustAmount: u128 = _amount - improveDecimals(withdrawAmount, _decimals);
            let mut sent = false;
            let contract_address = get_contract_address();

            IZklinkDispatcher {contract_address}.transferERC20(_tokenAddress, _recipient, withdrawAmount, withdrawAmount, _isTokenStandard);
            sent = true;

            if sent {
                self.emit(
                    Event::Withdrawal(
                        Withdrawal {
                            tokenId: _tokenId,
                            amount: withdrawAmount
                        }
                    )
                );
                if dustAmount > 0 {
                    self.increasePendingBalance(_tokenId, _recipient, dustAmount);
                }
            } else {
                self.increasePendingBalance(_tokenId, _recipient, _amount);
            }
        }

        // Increase `_recipient` balance to withdraw
        // Parameters:
        //  _tokenId
        //  _recipient
        //  _amount amount that need to recovery decimals when withdraw
        fn increasePendingBalance(ref self: ContractState, _tokenId: u16, _recipient: ContractAddress, _amount: u128) {
            self.increaseBalanceToWithdraw(_tokenId, _recipient, _amount);
            self.emit(
                Event::WithdrawalPending(
                    WithdrawalPending {
                        tokenId: _tokenId,
                        recepient: _recipient,
                        amount: _amount
                    }
                )
            );
        }

        fn increaseBalanceToWithdraw(ref self: ContractState, _tokenId: u16, _recipient: ContractAddress, _amount: u128) {
            let balance: u128 = self.pendingBalances.read((_recipient, _tokenId));
            self.pendingBalances.write((_recipient, _tokenId), balance + _amount);
        }

        fn _checkAccept(self: @ContractState, _accepter: ContractAddress, _accountId: u32, _receiver: ContractAddress, _tokenId: u16, _amount: u128, _withdrawFeeRate: u16, _nonce: u32) -> (u128, u256, ContractAddress) {
            // accepter and receiver MUST be set and MUST not be the same
            assert(_accepter != Zeroable::zero(), 'H0');
            assert(_receiver != Zeroable::zero(), 'H1');
            assert(_accepter != _receiver, 'H2');

            // token MUST be registered to ZkLink
            let rt: RegisteredToken = self.tokens.read(_tokenId);
            assert(rt.registered, 'H3');

            let tokenAddress = rt.tokenAddress;

            // feeRate MUST be valid and MUST not be 100%
            assert(_withdrawFeeRate <= MAX_ACCEPT_FEE_RATE, 'H4');
            let amountReceive: u128 = _amount * ((MAX_ACCEPT_FEE_RATE - _withdrawFeeRate) / MAX_ACCEPT_FEE_RATE).into();

            // nonce MUST not be zero
            assert(_nonce > 0, 'H5');

            // accept tx may be later than block exec tx(with user withdraw op)
            let mut acceptBytes: Bytes = BytesTrait::new_empty();
            acceptBytes.append_address(_receiver);
            acceptBytes.append_u16(_tokenId);
            acceptBytes.append_u128(_amount);
            acceptBytes.append_u16(_withdrawFeeRate);
            acceptBytes.append_u32(_nonce);

            let hash = acceptBytes.keccak();

            assert(self.accepts.read((_accountId, hash)) == Zeroable::zero(), 'H6');

            (amountReceive, hash, tokenAddress)
        }
    }

    // =========================utils functions=========================
    // improve decimals when deposit, for example, user deposit 2 USDC in ui, and the decimals of USDC is 6
    // the `_amount` params when call contract will be 2 * 10^6
    // because all token decimals defined in layer two is 18
    // so the `_amount` in deposit pubdata should be 2 * 10^6 * 10^(18 - 6) = 2 * 10^18
    fn improveDecimals(_amount: u128, _decimals: u8) -> u128 {
        _amount * u128_pow(10, (TOKEN_DECIMALS_OF_LAYER2 - _decimals).into())
    }

    // recover decimals when withdraw, this is the opposite of improve decimals
    fn recoveryDecimals(_amount: u128, _decimals: u8) -> u128 {
        _amount / u128_pow(10, (TOKEN_DECIMALS_OF_LAYER2 - _decimals).into())
    }

    // Returns the keccak hash of the ABI-encoded StoredBlockInfo
    fn hashStoredBlockInfo(_storedBlockInfo: StoredBlockInfo) -> u256 {
        let bytes: Bytes = _storedBlockInfo.into();
        bytes.keccak()
    }

    fn initOnchainOperationPubdataHashs() -> (Felt252Dict<u128>, Felt252Dict<u128>) {
        // overflow is impossible, max(MAX_CHAIN_ID + 1) = 256
        // use index of onchainOperationPubdataHashs as chain id
        // index start from [0, MIN_CHAIN_ID - 1] left unused

        // Becauseof cairo array element can not update,
        // We use dict instead to store onchainOperationPubdataHashs
        // And now dict in cairo do not support u256, we should use two dict
        // TODO: use one dict when cairo support u256 dict
        let mut onchainOpPubdataHashsHigh: Felt252Dict<u128> = Default::default();
        let mut onchainOpPubdataHashsLow: Felt252Dict<u128> = Default::default();
        let mut i = MIN_CHAIN_ID;
        loop {
            if i > MAX_CHAIN_ID {
                break();
            }
            let chainIndex: u256 = u256_pow2(i.into() - 1);
            if (chainIndex & ALL_CHAINS) == chainIndex {
                onchainOpPubdataHashsHigh.insert(i.into(), EMPTY_STRING_KECCAK.high);
                onchainOpPubdataHashsLow.insert(i.into(), EMPTY_STRING_KECCAK.low);
            }
            i += 1;
        };
        (onchainOpPubdataHashsHigh, onchainOpPubdataHashsLow)
    }

    fn checkChainId(_chainId: u8) {
        assert(_chainId >= MIN_CHAIN_ID && _chainId <= MAX_CHAIN_ID, 'i1');
        // revert if invalid chain id exist
        // for example, when `ALL_CHAINS` = 13(1 << 0 | 1 << 2 | 1 << 3), it means 2(1 << 2 - 1) is a invalid chainId
        let chainIndex: u256 = u256_pow2(_chainId.into() - 1);
        assert((chainIndex & ALL_CHAINS) == chainIndex, 'i2');
    }

    fn updateOnchainOperationPubdataHashs(_chainId: u8, ref _onchainOpPubdataHashsHigh: Felt252Dict<u128>, ref _onchainOpPubdataHashsLow: Felt252Dict<u128>, _opPubData: @Bytes) {
        let (high_entry, high_value) = _onchainOpPubdataHashsHigh.entry(_chainId.into());
        let (low_entry, low_value) = _onchainOpPubdataHashsLow.entry(_chainId.into());
        let old_hash = u256{high: high_value, low: low_value};
        let newHash = concatHash(old_hash, _opPubData);

        _onchainOpPubdataHashsHigh = high_entry.finalize(newHash.high);
        _onchainOpPubdataHashsLow = low_entry.finalize(newHash.low);
    }

    // Creates block commitment from its data
    // _offsetCommitment - hash of the array where 1 is stored in chunk where onchainOperation begins and 0 for other chunks
    fn createBlockCommitment(_previousBlock: @StoredBlockInfo, _newBlockData: @CommitBlockInfo, _compressed: bool, _newBlockExtraData: @CompressedBlockExtraInfo, _offsetsCommitment: u256) -> u256 {
        let offsetsCommitmentHash = if !_compressed {
            let mut offsetsCommitmentBytes = BytesTrait::new_empty();
            offsetsCommitmentBytes.append_u256(_offsetsCommitment);
            offsetsCommitmentBytes.sha256()
        } else {
            *(_newBlockExtraData.offsetCommitmentHash)
        };

        let newBlockPubDataHash = if !_compressed {
            _newBlockData.publicData.sha256()
        } else {
            *(_newBlockExtraData.publicDataHash)
        };
        let mut BlockCommitmentBytes = BytesTrait::new_empty();
        BlockCommitmentBytes.append_u256((*_newBlockData.blockNumber).into());
        BlockCommitmentBytes.append_u256((*_newBlockData.feeAccount).into());
        BlockCommitmentBytes.append_u256((*_previousBlock.stateHash));
        BlockCommitmentBytes.append_u256((*_newBlockData.newStateHash));
        BlockCommitmentBytes.append_u256((*_newBlockData.timestamp).into());
        BlockCommitmentBytes.append_u256(newBlockPubDataHash);
        BlockCommitmentBytes.append_u256(offsetsCommitmentHash);

        BlockCommitmentBytes.sha256()
    }

    // Create synchronization hash for cross chain block verify
    fn createSyncHash(_preBlockSyncHash: u256, _commitment: u256, ref _onchainOpPubdataHashsHigh: Felt252Dict<u128>, ref _onchainOpPubdataHashsLow: Felt252Dict<u128>) -> u256 {
        let mut syncHash = concatTwoHash(_preBlockSyncHash, _commitment);
        let mut i = MIN_CHAIN_ID;
        loop {
            if i > MAX_CHAIN_ID {
                break();
            }
            let chainIndex: u256 = u256_pow2(i.into() - 1);
            if (chainIndex & ALL_CHAINS) == chainIndex {
                let onchainOperationPubdataHash = u256{
                    low: _onchainOpPubdataHashsLow.get(i.into()),
                    high: _onchainOpPubdataHashsHigh.get(i.into())
                };
                syncHash = concatTwoHash(syncHash, onchainOperationPubdataHash);
            }
            i += 1;
        };
        syncHash
    }
}