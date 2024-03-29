use zklink_starknet_utils::bytes::Bytes;
use zklink::utils::operations::Operations::{Deposit, Withdraw, FullExit, ForcedExit, ChangePubKey};

#[starknet::interface]
trait IOperationsMock<TContractState> {
    fn testDepositPubdata(self: @TContractState, _example: Deposit, _pubData: Bytes);
    fn testWriteDepositPubdata(self: @TContractState, _example: Deposit);
    fn testWithdrawPubdata(self: @TContractState, _example: Withdraw, _pubData: Bytes);
    fn testFullExitPubdata(self: @TContractState, _example: FullExit, _pubData: Bytes);
    fn testWriteFullExitPubdata(self: @TContractState, _example: FullExit);
    fn testForcedExitPubdata(self: @TContractState, _example: ForcedExit, _pubData: Bytes);
    fn testChangePubkeyPubdata(self: @TContractState, _example: ChangePubKey, _pubData: Bytes);
}

#[starknet::contract]
mod OperationsMock {
    use zklink::utils::operations::Operations::{
        OperationReadTrait, OperationWriteTrait, Deposit, DepositReadOperation, Withdraw,
        WithdrawReadOperation, FullExit, FullExitReadOperation, ForcedExit, ForcedExitReadOperation,
        ChangePubKey, ChangePubKeyReadOperation
    };
    use zklink_starknet_utils::bytes::Bytes;
    use debug::PrintTrait;

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl OperationsImpl of super::IOperationsMock<ContractState> {
        fn testDepositPubdata(self: @ContractState, _example: Deposit, _pubData: Bytes) {
            let parsed = DepositReadOperation::readFromPubdata(@_pubData);
            assert(_example.chainId == parsed.chainId, 'cok');
            assert(_example.subAccountId == parsed.subAccountId, 'sok');
            assert(_example.tokenId == parsed.tokenId, 'tok');
            assert(_example.targetTokenId == parsed.targetTokenId, 't1ok');
            assert(_example.amount == parsed.amount, 'amn');
            assert(_example.owner == parsed.owner, 'own');
            assert(_example.accountId == parsed.accountId, 'aok');
        }

        fn testWriteDepositPubdata(self: @ContractState, _example: Deposit) {
            let pubdata: Bytes = _example.writeForPriorityQueue();
            let parsed = DepositReadOperation::readFromPubdata(@pubdata);
            assert(0 == parsed.accountId, 'acc');
            assert(_example.chainId == parsed.chainId, 'cok');
            assert(_example.subAccountId == parsed.subAccountId, 'sok');
            assert(_example.tokenId == parsed.tokenId, 'tok');
            assert(_example.targetTokenId == parsed.targetTokenId, 't1ok');
            assert(_example.amount == parsed.amount, 'amn');
            assert(_example.owner == parsed.owner, 'own');
        }

        fn testWithdrawPubdata(self: @ContractState, _example: Withdraw, _pubData: Bytes) {
            let parsed = WithdrawReadOperation::readFromPubdata(@_pubData);
            assert(_example.chainId == parsed.chainId, 'cok');
            assert(_example.accountId == parsed.accountId, 'aok');
            assert(_example.subAccountId == parsed.subAccountId, 'saok');
            assert(_example.tokenId == parsed.tokenId, 'tok');
            assert(_example.amount == parsed.amount, 'amn');
            assert(_example.owner == parsed.owner, 'own');
            assert(_example.nonce == parsed.nonce, 'nonce');
            assert(_example.fastWithdrawFeeRate == parsed.fastWithdrawFeeRate, 'fr');
            assert(_example.withdrawToL1 == parsed.withdrawToL1, 'l1');
        }

        fn testFullExitPubdata(self: @ContractState, _example: FullExit, _pubData: Bytes) {
            let parsed = FullExitReadOperation::readFromPubdata(@_pubData);
            assert(_example.chainId == parsed.chainId, 'cid');
            assert(_example.accountId == parsed.accountId, 'acc');
            assert(_example.subAccountId == parsed.subAccountId, 'scc');
            assert(_example.owner == parsed.owner, 'own');
            assert(_example.tokenId == parsed.tokenId, 'tok');
            assert(_example.amount == parsed.amount, 'amn');
        }

        fn testWriteFullExitPubdata(self: @ContractState, _example: FullExit) {
            let pubdata = _example.writeForPriorityQueue();
            let parsed = FullExitReadOperation::readFromPubdata(@pubdata);
            assert(_example.chainId == parsed.chainId, 'cid');
            assert(_example.accountId == parsed.accountId, 'acc');
            assert(_example.subAccountId == parsed.subAccountId, 'scc');
            assert(_example.tokenId == parsed.tokenId, 'tok');
            assert(0 == parsed.amount, 'amn');
            assert(_example.owner == parsed.owner, 'own');
        }

        fn testForcedExitPubdata(self: @ContractState, _example: ForcedExit, _pubData: Bytes) {
            let parsed = ForcedExitReadOperation::readFromPubdata(@_pubData);
            assert(_example.chainId == parsed.chainId, 'cid');
            assert(_example.initiatorAccountId == parsed.initiatorAccountId, 'iaid');
            assert(_example.initiatorSubAccountId == parsed.initiatorSubAccountId, 'isaid');
            assert(_example.initiatorNonce == parsed.initiatorNonce, 'in');
            assert(_example.targetAccountId == parsed.targetAccountId, 'taid');
            assert(_example.tokenId == parsed.tokenId, 'tcc');
            assert(_example.amount == parsed.amount, 'amn');
            assert(_example.withdrawToL1 == parsed.withdrawToL1, 'l1');
            assert(_example.target == parsed.target, 'tar');
        }

        fn testChangePubkeyPubdata(self: @ContractState, _example: ChangePubKey, _pubData: Bytes) {
            let parsed = ChangePubKeyReadOperation::readFromPubdata(@_pubData);
            assert(_example.accountId == parsed.accountId, 'acc');
            assert(_example.pubKeyHash == parsed.pubKeyHash, 'pkh');
            assert(_example.owner == parsed.owner, 'own');
            assert(_example.nonce == parsed.nonce, 'nnc');
        }
    }
}
