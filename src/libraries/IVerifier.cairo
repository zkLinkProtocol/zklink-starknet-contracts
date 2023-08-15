use starknet::ContractAddress;

#[starknet::interface]
trait IVerifier<TContractState> {
    #[external]
    fn verifyAggregatedBlockProof(
        ref self: TContractState,
        _recursiveInput: Array<u256>,
        _proof: Array<u256>,
        _vkIndexes: Array<u8>,
        _individualVksInputs: Array<u256>,
        _subProofsLimbs: Array<u256>
    ) -> bool;

    #[external]
    fn verifyExitProof(
        ref self: TContractState,
        _rootHash: u256,
        _chainId: u8,
        _accountId: u8,
        _subAccountId: u8,
        _owner: ContractAddress,
        _tokenId: u16,
        _srcTokenId: u16,
        _amount: u128,
        _proof: Array<u256>
    ) -> bool;
}
