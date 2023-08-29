#[starknet::interface]
trait IVerifierMock<TContractState> {
    fn setVerifyResult(ref self: TContractState, r: bool);
}

#[starknet::contract]
mod VerifierMock {
    use zklink::contracts::verifier::IVerifier;

    #[storage]
    struct Storage {
        verifyResult: bool
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.verifyResult.write(true);
    }

    #[external(v0)]
    impl IVerifierMockImpl of super::IVerifierMock<ContractState> {
        fn setVerifyResult(ref self: ContractState, r: bool) {
            self.verifyResult.write(r);
        }
    }

    #[external(v0)]
    impl IVerifierImpl of IVerifier<ContractState> {
        fn verifyAggregatedBlockProof(
            ref self: ContractState,
            _recursiveInput: Array<u256>,
            _proof: Array<u256>,
            _vkIndexes: Array<u8>,
            _individualVksInputs: Array<u256>,
            _subProofsLimbs: Array<u256>
        ) -> bool {
            self.verifyResult.read()
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
            self.verifyResult.read()
        }
    }
}
