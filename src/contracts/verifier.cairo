use starknet::ContractAddress;

#[starknet::interface]
trait IVerifier<TContractState> {
    fn verifyAggregatedBlockProof(
        ref self: TContractState,
        _recursiveInput: Array<u256>,
        _proof: Array<u256>,
        _vkIndexes: Array<u8>,
        _individualVksInputs: Array<u256>,
        _subProofsLimbs: Array<u256>
    ) -> bool;

    fn verifyExitProof(
        ref self: TContractState,
        _rootHash: u256,
        _chainId: u8,
        _accountId: u32,
        _subAccountId: u8,
        _owner: u256,
        _tokenId: u16,
        _srcTokenId: u16,
        _amount: u128,
        _proof: Array<u256>
    ) -> bool;
}

#[starknet::contract]
mod Verifier {
    #[storage]
    struct Storage {}

    #[external(v0)]
    impl VerifierImpl of super::IVerifier<ContractState> {
        fn verifyAggregatedBlockProof(
            ref self: ContractState,
            _recursiveInput: Array<u256>,
            _proof: Array<u256>,
            _vkIndexes: Array<u8>,
            _individualVksInputs: Array<u256>,
            _subProofsLimbs: Array<u256>
        ) -> bool {
            false
        }

        fn verifyExitProof(
            ref self: ContractState,
            _rootHash: u256,
            _chainId: u8,
            _accountId: u32,
            _subAccountId: u8,
            _owner: u256,
            _tokenId: u16,
            _srcTokenId: u16,
            _amount: u128,
            _proof: Array<u256>
        ) -> bool {
            false
        }
    }
}
