#[contract]
mod Zklink {
    use zeroable::Zeroable;
    use core::traits::Into;
    use core::traits::TryInto;
    use core::option::OptionTrait;
    use core::array::ArrayTrait;
    use box::BoxTrait;
    use starknet::{
        ContractAddress,
        get_contract_address,
        get_caller_address,
        // TODO: import get_block_number
        // get_block_number,
        get_block_info,
        // TODO: import get_block_timestamp
        // get_block_timestamp
    };

    use zklink::libraries::IERC20::IERC20Dispatcher;
    use zklink::libraries::IERC20::IERC20DispatcherTrait;
    use zklink::libraries::reentrancyguard::ReentrancyGuard;

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
        ForcedExit,
        Withdraw,
        ChangePubKey,
    };
    use zklink::utils::data_structures::DataStructures::{
        RegisteredToken,
        BridgeInfo,
        StoredBlockInfo,
        StoredBlockInfoIntoBytes,
        CommitBlockInfo,
        CompressedBlockExtraInfo,
        ExecuteBlockInfo,
        Token,
        ProofInput
    };
    use zklink::utils::math::{
        U128IntoU256,
        U256TryIntoU128,
        u128_pow,
        felt252_fast_pow2,
        u256_pow2,
        u256_to_u160
    };
    use zklink::utils::utils::{
        concatHash,
    };
    use zklink::utils::constants::{
        EMPTY_STRING_KECCAK,
        CHUNK_BYTES,
        MAX_ACCOUNT_ID,
        MAX_SUB_ACCOUNT_ID,
        PRIORITY_EXPIRATION,
        MAX_DEPOSIT_AMOUNT,
        CHAIN_ID,
        MIN_CHAIN_ID,
        MAX_CHAIN_ID,
        ALL_CHAINS,
        ENABLE_COMMIT_COMPRESSED_BLOCK,
        GLOBAL_ASSET_ACCOUNT_ID,
        GLOBAL_ASSET_ACCOUNT_ADDRESS,
        USD_TOKEN_ID,
        MIN_USD_STABLE_TOKEN_ID,
        MAX_USD_STABLE_TOKEN_ID,
        TOKEN_DECIMALS_OF_LAYER2,
    };
    
    /// Storage
    struct Storage {
        // public
        // Verifier contract. Used to verify block proof and exit proof
        verifier: ContractAddress,

        // public
        // Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
        totalBlocksExecuted: u32,

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
        totalBlocksProven: u32,

        // public
        // Total number of committed requests.
        // Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
        totalCommittedPriorityRequests: u64,

        // public
        // Latest synchronized block height
        totalBlocksSynchronized: u32,

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
        bridges: LegacyMap::<usize, BridgeInfo>,

        // public
        // 0 is reversed for non-exist bridge, existing bridges are indexed from 1
        bridgeIndex: LegacyMap::<ContractAddress, usize>,
    }

    /// Events
    // Event emitted when a block is committed
    #[event]
    fn BlockCommit(blockNumber: u64){}

    // Event emitted when a block is proven
    #[event]
    fn BlockProven(blockNumber: u64){}

    // Event emitted when a block is executed
    #[event]
    fn BlockExecuted(blockNumber: u64){}

    // Event emitted when user funds are withdrawn from the zkLink state and contract
    #[event]
    fn Withdrawal(tokenId: u16, amount: u128){}

    // Event emitted when user funds are withdrawn from the zkLink state but not from contract
    #[event]
    fn WithdrawalPending(tokenId: u16, recepient: ContractAddress, amount: u128){}

    // Event emitted when user sends a authentication fact (e.g. pub-key hash)
    #[event]
    fn FactAuth(sender: ContractAddress, nonce: u32, fact: felt252){}

    // Event emitted when authentication fact reset clock start
    #[event]
    fn FactAuthResetTime(sender: ContractAddress, nonce: u32, time: u64){}

    // Event emitted when blocks are reverted
    #[event]
    fn BlocksRevert(totalBlocksVerified: u32, totalBlocksCommitted: u64){}

    // Exodus mode entered event
    #[event]
    fn ExodusMode(){}

    // New priority request event. Emitted when a request is placed into mapping
    #[event]
    fn NewPriorityRequest(sender: ContractAddress, serialId: u64, opType: OpType, pubData: Bytes, expirationBlock: u64){}

    // Event emitted when accepter accept a fast withdraw
    #[event]
    fn Accept(accepter: ContractAddress, accountId: u32, receiver: ContractAddress, tokenId: u16, amountSent: u128, amountReceive: u128){}

    // Event emitted when set broker allowance
    #[event]
    fn BrokerApprove(tokenId: u16, owner: ContractAddress, spender: ContractAddress, amount: u128){}

    // Token added to ZkLink net
    #[event]
    fn NewToken(tokenId: u16, token: ContractAddress){}

    // Governor changed
    #[event]
    fn NewGovernor(governor: ContractAddress){}

    // Validator's status updated
    #[event]
    fn ValidatorStatusUpdate(validatorAddress: ContractAddress, isActive: bool){}

    // Token pause status update
    #[event]
    fn TokenPausedUpdate(tokenId: u16, paused: bool){}

    // New bridge added
    #[event]
    fn AddBridge(bridge: ContractAddress, bridgeIndex: usize){}

    // Bridge update
    #[event]
    fn UpdateBridge(bridgeIndex: usize, enableBridgeTo: bool, enableBridgeFrom: bool){}

    // =================modifier functions=================

    // Checks that current state not is exodus mode
    #[inline(always)]
    fn active() {
        assert(!exodusMode::read(), '0');
    }

    // Checks that current state is exodus mode
    #[inline(always)]
    fn notActive() {
        assert(exodusMode::read(), '1');
    }

    // Set logic contract must be called through proxy
    #[inline(always)]
    fn onlyDelegateCall() {
        // TODO
    }
    
    // Check if msg sender is a governor
    #[inline(always)]
    fn onlyGovernor() {
        assert(get_caller_address() == networkGovernor::read(), '3');
    }

    // Check if msg sender is a validator
    #[inline(always)]
    fn onlyValidator() {
        assert(validators::read(get_caller_address()), '4');
    }

    // =================Upgrade interface=================
    // TODO

    // =================User interface=================

    // Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
    // it MUST be ok to call other external functions within from this function
    // when the token(eg. erc777) is not a pure erc20 token
    // Parameters:
    //  _token Token address
    //  _amount Token amount
    //  _zkLinkAddress The receiver Layer 2 address
    //  _subAccountId The receiver sub account
    //  _mapping If true and token has a mapping token, user will receive mapping token at l2
    #[external]
    fn depositERC20(_token: ContractAddress, _amount: u128, _zkLinkAddress: ContractAddress, _subAccountId: u8, _mapping: bool) {
        ReentrancyGuard::start();
        deposit(_token, _amount, _zkLinkAddress, _subAccountId, _mapping);
        ReentrancyGuard::end();
    }

    // Register full exit request - pack pubdata, add priority request
    // Parameters:
    //  _accountId Numerical id of the account
    //  _subAccountId The exit sub account
    //  _tokenId Token id
    //  _mapping If true and token has a mapping token, user's mapping token balance will be decreased at l2
    #[external]
    fn requestFullExit(_accountId: u32, _subAccountId: u8, _tokenId: u16, _mapping: bool) {
        ReentrancyGuard::start();
        active();
        // Checks
        // accountId and subAccountId MUST be valid
        assert(_accountId <= MAX_ACCOUNT_ID & _accountId != GLOBAL_ASSET_ACCOUNT_ID, 'a0');
        assert(_subAccountId <= MAX_SUB_ACCOUNT_ID, 'a1');
        // token MUST be registered to ZkLink
        let rt = tokens::read(_tokenId);
        assert(rt.registered, 'a2');
        // when full exit stable tokens (e.g. USDC, BUSD) with mapping, USD will be deducted from account
        // and stable token will be transfer from zkLink contract to account address
        // all other tokens don't support mapping
        let mut srcTokenId = _tokenId;
        if _mapping {
            assert(_tokenId >= MIN_USD_STABLE_TOKEN_ID & _tokenId <= MAX_USD_STABLE_TOKEN_ID, 'a3');
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
        addPriorityRequest(OpType::FullExit(()), pubData);

        ReentrancyGuard::end();
    }

    // Checks if Exodus mode must be entered. If true - enters exodus mode and emits ExodusMode event.
    // Exodus mode must be entered in case of current ethereum block number is higher than the oldest
    // of existed priority requests expiration block number.
    #[external]
    fn activateExodusMode() {
        ReentrancyGuard::start();
        active();

        ReentrancyGuard::end();
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
    #[external]
    fn performExodus(_storedBlockInfo: StoredBlockInfo, _owner: ContractAddress, _accountId: u32, _subAccountId: u8, _withdrawTokenId: u16, _deductTokenId: u16, _amount: u128, _proof: Array<u256>) {
        ReentrancyGuard::start();
        notActive();

        ReentrancyGuard::end();
    }

    // Accrues users balances from deposit priority requests in Exodus mode
    // WARNING: Only for Exodus mode
    // Canceling may take several separate transactions to be completed
    // Parameters:
    //  _n number of requests to process
    //  _depositsPubdataSize deposit pubData size in bytes
    //  _depositsPubdata deposit details
    fn cancelOutstandingDepositsForExodusMode(_n: u64, _depositsPubdata: Bytes) {
        ReentrancyGuard::start();
        notActive();

        ReentrancyGuard::end();
    }

    // Set data for changing pubkey hash using onchain authorization.
    // Transaction author (msg.sender) should be L2 account address.
    // New pubkey hash can be reset, to do that user should send two transactions:
    //  1. First `setAuthPubkeyHash` transaction for already used `_nonce` will set timer.
    //  2. After `AUTH_FACT_RESET_TIMELOCK` time is passed second `setAuthPubkeyHash` transaction will reset pubkey hash for `_nonce`.
    // Parameters:
    //  _pubkeyHash New pubkey hash
    //  _nonce Nonce of the change pubkey L2 transaction
    #[external]
    fn setAuthPubkeyHash(_pubkeyHash: felt252, _nonce: u32) {
        ReentrancyGuard::start();
        active();

        ReentrancyGuard::end();
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
    #[external]
    fn withdrawPendingBalance(_owner: ContractAddress, _tokenId: u16, _amount: u128) -> u128 {
        let amount = 0;
        ReentrancyGuard::start();
        

        ReentrancyGuard::end();
        amount
    }

    // Returns amount of tokens that can be withdrawn by `address` from zkLink contract
    // Parameters:
    //  _address Address of the tokens owner
    //  _tokenId Token id
    // Returns:
    //  The pending balance(without recovery decimals) can be withdrawn
    #[view]
    fn getPendingBalance(_address: ContractAddress, _tokenId: u16) -> u128 {
        pendingBalances::read((_address, _tokenId))
    }   

    // =================Validator interface=================

    // Commit block
    // 1. Checks onchain operations of all chains, timestamp.
    // 2. Store block commitments, sync hash.
    #[external]
    fn commitBlocks(_lastCommittedBlockData: StoredBlockInfo, _newBlocksData: Array<CommitBlockInfo>) {
        let mut _newBlocksExtraData: Array<CompressedBlockExtraInfo> = ArrayTrait::new();
        _commitBlocks(_lastCommittedBlockData, _newBlocksData, false, _newBlocksExtraData);
    }

    // Commit compressed block
    // 1. Checks onchain operations of current chain, timestamp.
    // 2. Store block commitments, sync hash.
    #[external]
    fn commitCompressedBlocks(_lastCommittedBlockData: StoredBlockInfo, _newBlocksData: Array<CommitBlockInfo>, _newBlocksExtraData: Array<CompressedBlockExtraInfo>) {

    }

    // Execute blocks, completing priority operations and processing withdrawals.
    // 1. Processes all pending operations (Send Exits, Complete priority requests)
    // 2. Finalizes block on Ethereum
    #[external]
    fn executeBlocks(_blocksData: Array<ExecuteBlockInfo>) {
        ReentrancyGuard::start();
        active();
        onlyValidator();

        ReentrancyGuard::end();
    }

    // =================Block interface====================

    // Blocks commitment verification.
    // Only verifies block commitments without any other processing
    #[external]
    fn proveBlocks(_committedBlocks: Array<StoredBlockInfo>, _proof: ProofInput) {
        ReentrancyGuard::start();

        ReentrancyGuard::end();
    }

    // Reverts unExecuted blocks
    #[external]
    fn revertBlocks(_blocksToRevert: Array<StoredBlockInfo>) {
        ReentrancyGuard::start();
        onlyValidator();

        ReentrancyGuard::end();
    }

    // =================Cross chain block synchronization===============

    // Combine the `progress` of the other chains of a `syncHash` with self
    #[external]
    fn receiveSynchronizationProgress(_syncHash: u256, _progress: u256) {

    }

    // Get synchronized progress of current chain known
    #[view]
    fn getSynchronizedProgress(_block: StoredBlockInfo) -> u256 {
        u256{low: 0, high: 0}
    }

    // Check if received all syncHash from other chains at the block height
    #[external]
    fn syncBlocks(_block: StoredBlockInfo) {
        ReentrancyGuard::start();

        ReentrancyGuard::end();
    }

    // =================Fast withdraw and Accept===============

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
    #[external]
    fn acceptERC20(_accepter: ContractAddress, _accountId: u32, _receiver: ContractAddress, _tokenId: u16, _amount: u128, _withdrawFeeRate: u16, _nonce: u32, _amountTransfer: u128) {
        ReentrancyGuard::start();

        ReentrancyGuard::end();
    }

    // Return the accept allowance of broker
    #[view]
    fn brokerAllowance(_tokenId: u16, _accepter: ContractAddress, _broker: ContractAddress) -> u128 {
        brokerAllowances::read((_tokenId, _accepter, _broker))
    }

    // Give allowance to broker to call accept
    // Parameters:
    //  tokenId token that transfer to the receiver of accept request from accepter or broker
    //  broker who are allowed to do accept by accepter(the msg.sender)
    //  amount the accept allowance of broker
    #[external]
    fn brokerApprove(_tokenId: u16, _broker: ContractAddress, _amount: u128) -> bool {
        true
    }

    fn _checkAccept(_accepter: ContractAddress, _accountId: u32, _receiver: ContractAddress, _tokenId: u16, _amount: u128, _withdrawFeeRate: u16, _nonce: u32) -> (u128, u256, ContractAddress){
        (0, u256{low: 0, high: 0}, Zeroable::zero())
    }

    // =================Governance interface===============

    // Change current governor
    // Parameters:
    //  _newGovernor Address of the new governor
    #[external]
    fn changeGovernor(_newGovernor: ContractAddress) {
        ReentrancyGuard::start();
        onlyGovernor();

        ReentrancyGuard::end();
    }

    // Add token to the list of networks tokens
    // Parameters:
    //  _tokenId Token id
    //  _tokenAddress Address of the token
    //  _decimals Token decimals of layer one
    //  _standard If token is a standard erc20
    #[external]
    fn addToken(_tokenId: u16, _tokenAddress: ContractAddress, _decimals: u8, _standard: bool) {
        onlyGovernor();
    }

    // Add tokens to the list of networks tokens
    // Parameters:
    //  _tokenList Token list
    #[external]
    fn addTokens(_tokenList: Array<Token>) {

    }

    // Pause token deposits for the given token
    // Parameters:
    //  _tokenId Token id
    //  _tokenPaused Token paused status
    #[external]
    fn setTokenPaused(_tokenId: u16, _tokenPaused: bool) {
        onlyGovernor();
    }

    // Change validator status (active or not active)
    // Parameters:
    //  _validator Validator address
    //  _active Active flag
    #[external]
    fn setValidator(_validator: ContractAddress, _active: bool) {
        onlyGovernor();
    }

    // Add a new bridge
    // Parameters:
    //  bridge the bridge contract
    // Returns:
    //  the index of new bridge
    #[external]
    fn addBridge(_bridge: ContractAddress) -> usize {
        onlyGovernor();
        0
    }

    // Update bridge info
    // If we want to remove a bridge(not compromised), we should firstly set `enableBridgeTo` to false
    // and wait all messages received from this bridge and then set `enableBridgeFrom` to false.
    // But when a bridge is compromised, we must set both `enableBridgeTo` and `enableBridgeFrom` to false immediately
    // Parameters:
    //  _index the bridge info index
    //  _enableBridgeTo if set to false, bridge to will be disabled
    //  _enableBridgeFrom if set to false, bridge from will be disabled
    #[external]
    fn updateBridge(_index: usize, _enableBridgeTo: bool, _enableBridgeFrom: bool) {
        onlyGovernor();
    }

    // Get enableBridgeTo status
    #[view]
    fn isBridgeToEnabled(_bridge: ContractAddress) -> bool {
        let index = bridgeIndex::read(_bridge) - 1;
        bridges::read(index).enableBridgeTo
    }

    // Get enableBridgeFrom status
    #[view]
    fn isBridgeFromEnabled(_bridge: ContractAddress) -> bool {
        let index = bridgeIndex::read(_bridge) - 1;
        bridges::read(index).enableBridgeFrom
    }

    // =================Internal functions=================

    // Deposit ERC20 token internal function
    // Parameters:
    //  _token Token address
    //  _amount Token amount
    //  _zkLinkAddress The receiver Layer 2 address
    //  _subAccountId The receiver sub account
    //  _mapping If true and token has a mapping token, user will receive mapping token at l2
    fn deposit(_tokenAddress: ContractAddress, _amount: u128, _zkLinkAddress: ContractAddress, _subAccountId: u8, _mapping: bool) {
        active();
        // checks
        // disable deposit to zero address or global asset account
        assert(_zkLinkAddress != Zeroable::zero() & _zkLinkAddress != GLOBAL_ASSET_ACCOUNT_ADDRESS, 'e1');
        // subAccountId MUST be valid
        assert(_subAccountId <= MAX_SUB_ACCOUNT_ID, 'e2');
        // token MUST be registered to ZkLink and deposit MUST be enabled
        let tokenId = tokenIds::read(_tokenAddress);
        // 0 is a invalid token and MUST NOT register to zkLink contract
        assert(tokenId != 0, 'e3');
        let rt = tokens::read(tokenId);
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
        assert(_amount > 0 & _amount <= MAX_DEPOSIT_AMOUNT, 'e0');

        // only stable tokens(e.g. USDC, BUSD) support mapping to USD when deposit
        let mut targetTokenId = tokenId;
        if _mapping {
            assert(tokenId >= MIN_USD_STABLE_TOKEN_ID & tokenId <= MAX_USD_STABLE_TOKEN_ID, 'e5');
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
        addPriorityRequest(OpType::Deposit(()), pubData);
    }

    // Saves priority request in storage
    // Calculates expiration block for request, store this request and emit NewPriorityRequest event
    // Parameters:
    //  _opType Rollup operation type
    //  _pubData Operation pubdata
    fn addPriorityRequest(_opType: OpType, _pubData: Bytes) {
        // Expiration block is: current block number + priority expiration delta
        // TODO: use get_block_number
        let expirationBlock = get_block_info().unbox().block_number + PRIORITY_EXPIRATION;
        let toprs = totalOpenPriorityRequests::read();
        let nextPriorityRequestId = firstPriorityRequestId::read() + toprs;
        let hashedPubData = u256_to_u160(_pubData.keccak());

        let priorityRequest = PriorityOperation {
            hashedPubData: hashedPubData,
            expirationBlock: expirationBlock,
            opType: _opType
        };
        priorityRequests::write(nextPriorityRequestId, priorityRequest);

        let sender = get_caller_address();
        NewPriorityRequest(sender, nextPriorityRequestId, _opType, _pubData, expirationBlock);

        totalOpenPriorityRequests::write(toprs + 1);
    }

    // CommitBlocks internal function
    // Parameters:
    //  _lastCommittedBlockData
    //  _newBlocksData
    //  _compressed
    //  _newBlocksExtraData
    fn _commitBlocks(_lastCommittedBlockData: StoredBlockInfo, _newBlocksData: Array<CommitBlockInfo>, _compressed: bool, _newBlocksExtraData: Array<CompressedBlockExtraInfo>) {
        ReentrancyGuard::start();
        active();
        onlyValidator();
        // Checks
        assert(_newBlocksData.len() > 0, 'f0');
        assert(storedBlockHashes::read(totalBlocksCommitted::read()) == hashStoredBlockInfo(_lastCommittedBlockData), 'f1');

        // Effects
        let mut i = 0;
        let mut _lastCommittedBlockData = _lastCommittedBlockData;
        loop {
            if i == _newBlocksData.len() {
                break();
            }
            _lastCommittedBlockData = commitOneBlock(_lastCommittedBlockData, _newBlocksData[i], _compressed, _newBlocksExtraData[i]);

            i += 1;
        };
        ReentrancyGuard::end();
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
    fn commitOneBlock(_previousBlock: StoredBlockInfo, _newBlock: @CommitBlockInfo, _compressed: bool, _newBlockExtra: @CompressedBlockExtraInfo) -> StoredBlockInfo {
        assert(*_newBlock.blockNumber == _previousBlock.blockNumber + 1, 'g0');
        assert(!_compressed | ENABLE_COMMIT_COMPRESSED_BLOCK, 'g1');
        // Check timestamp of the new block
        assert(*_newBlock.timestamp >= _previousBlock.timestamp, 'g2');

        // Check onchain operations
        let (
            pendingOnchainOperationsHash,
            priorityReqCommitted,
            onchainOpsOffsetCommitment,
            onchainOperationPubdataHashs
        ) = collectOnchainOps(_newBlock);



        StoredBlockInfo{
            blockNumber: 0,
            priorityOperations: 0,
            pendingOnchainOperationsHash: u256{low: 0, high: 0},
            timestamp: 0,
            stateHash: u256{low: 0, high: 0},
            commitment: u256{low: 0, high: 0},
            syncHash: u256{low: 0, high: 0}
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
    fn collectOnchainOps(_newBlockData: @CommitBlockInfo) -> (u256, u64, u256, Array<u256>) {
        let pubData = _newBlockData.publicData;
        // pubdata length must be a multiple of CHUNK_BYTES
        assert(*pubData.size % CHUNK_BYTES == 0, 'h0');
        
        // Init return values
        // TODO: change to 0_256
        let mut offsetsCommitment: u256 = u256{low: 0, high: 0}; // use a u256 instead of Bytes to save gas
        let mut priorityOperationsProcessed: u64 = 0;
        let mut onchainOperationPubdataHashs: Array<u256> = initOnchainOperationPubdataHashs();
        let mut processableOperationsHash: u256 = EMPTY_STRING_KECCAK;

        let uncommittedPriorityRequestsOffset = firstPriorityRequestId::read() + totalCommittedPriorityRequests::read();

        let mut i = 0;
        loop {
            if i == _newBlockData.onchainOperations.len() {
                break();
            }
            let onchainOpData = _newBlockData.onchainOperations[i];
            let pubdataOffset = *onchainOpData.publicDataOffset;
            
            assert(pubdataOffset + 1 < *pubData.size, 'h1');
            assert(pubdataOffset % CHUNK_BYTES == 0, 'h2');

            {
                let chunkId: u32 = pubdataOffset / CHUNK_BYTES;
                let chunkIdCommitment = u256_pow2(chunkId);
                // offset commitment should be empty
                // TODO: change to 0_256
                assert((offsetsCommitment & chunkIdCommitment) == u256{low: 0, high: 0}, 'h3');
                offsetsCommitment = offsetsCommitment | chunkIdCommitment;
            }

            // chainIdOffset = pubdataOffset + 1
            let (_, chainId) = pubData.read_u8(pubdataOffset + 1);
            checkChainId(chainId);

            let (_, opType) = ReadBytes::<OpType>::read(pubData, pubdataOffset);

            let nextPriorityOpIndex: u64 = uncommittedPriorityRequestsOffset + priorityOperationsProcessed;
            
            let (newPriorityProceeded, opPubData, processablePubData) = checkOnchainOp(
                opType,
                chainId,
                pubData,
                pubdataOffset,
                nextPriorityOpIndex,
                onchainOpData.ethWitness);

            priorityOperationsProcessed += newPriorityProceeded;
            i += 1;
        };
        
        
        (
            processableOperationsHash,
            priorityOperationsProcessed,
            offsetsCommitment,
            onchainOperationPubdataHashs
        )
    }

    fn initOnchainOperationPubdataHashs() -> Array<u256> {
        // overflow is impossible, max(MAX_CHAIN_ID + 1) = 256
        // use index of onchainOperationPubdataHashs as chain id
        // index start from [0, MIN_CHAIN_ID - 1] left unused
        let mut onchainOperationPubdataHashs: Array<u256> = ArrayTrait::new();
        let mut i = MIN_CHAIN_ID;
        loop {
            if i > MAX_CHAIN_ID {
                break();
            }
            let chainIndex: u256 = felt252_fast_pow2(i.into() - 1).into();
            if (chainIndex & ALL_CHAINS) == chainIndex {
                onchainOperationPubdataHashs.append(EMPTY_STRING_KECCAK);
            } else {
                onchainOperationPubdataHashs.append(u256{low: 0, high: 0});
            }
            i += 1;
        };

        onchainOperationPubdataHashs
    }

    fn checkChainId(_chainId: u8) {
        assert(_chainId >= MIN_CHAIN_ID & _chainId <= MAX_CHAIN_ID, 'i1');
        // revert if invalid chain id exist
        // for example, when `ALL_CHAINS` = 13(1 << 0 | 1 << 2 | 1 << 3), it means 2(1 << 2 - 1) is a invalid chainId
        let chainIndex: u256 = u256_pow2(_chainId.into() - 1);
        assert((chainIndex & ALL_CHAINS) == chainIndex, 'i2');
    }

    fn checkOnchainOp(_opType: OpType, _chainId: u8, _pubData: @Bytes, _pubdataOffset: usize, _nextPriorityOpIdx: u64, _ethWitness: @Bytes) -> (u64, Bytes, Bytes) {
        (0, BytesTrait::new_empty(), BytesTrait::new_empty())
    }

    // Create synchronization hash for cross chain block verify
    fn createSyncHash(_preBlockSyncHash: u256, _commitment: u256, _onchainOperationPubdataHashs: Array<u256>) -> u256 {
        u256{low: 0, high: 0}
    }

    // Creates block commitment from its data
    // _offsetCommitment - hash of the array where 1 is stored in chunk where onchainOperation begins and 0 for other chunks
    fn createBlockCommitment(_previousBlock: StoredBlockInfo, _newBlockData: CommitBlockInfo, _compressed: bool, _newBlockExtraData: CompressedBlockExtraInfo, _offsetsCommitment: Bytes) -> u256 {
        u256{low: 0, high: 0}
    }

    // Checks that change operation is correct
    fn verifyChangePubkey(_ethWitness: Bytes, _changePk: ChangePubKey) -> bool {
        false
    }

    // Checks that signature is valid for pubkey change message
    fn verifyChangePubkeyECRECOVER(_ethWitness: Bytes, _changePk: ChangePubKey) -> bool {
        false
    }

    // Checks that signature is valid for pubkey change message
    fn verifyChangePubkeyCREATE2(_ethWitness: Bytes, _changePk: ChangePubKey) -> bool {
        false
    }

    // Executes one block
    // 1. Processes all pending operations (Send Exits, Complete priority requests)
    // 2. Finalizes block on Ethereum
    fn executeOneBlock(_blockExecuteData: ExecuteBlockInfo, _executedBlockIdx: usize) {

    }

    // Execute withdraw operation
    fn executeWithdraw(op: Withdraw) {

    }

    // Execute force exit operation
    fn executeForceExit(op: ForcedExit) {

    }

    // Execute full exit operation
    fn executeFullExit(op: FullExit) {

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
    fn withdrawOrStore(_tokenId: u16, _tokenAddress: ContractAddress, _isTokenStandard: bool, _decimals: u8, _recipient: ContractAddress, _amount: u128) {

    }

    // Increase `_recipient` balance to withdraw
    // Parameters:
    //  _tokenId
    //  _recipient
    //  _amount amount that need to recovery decimals when withdraw
    fn increasePendingBalance(_tokenId: u16, _recipient: ContractAddress, _amount: u128) {

    }

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
}