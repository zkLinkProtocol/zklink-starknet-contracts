use starknet::{ContractAddress, ClassHash};

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
    fn getMaster(self: @TContractState) -> ContractAddress;
    fn transferMastership(ref self: TContractState, _newMaster: ContractAddress);
    fn upgrade(ref self: TContractState, impl_hash: ClassHash);
}

#[starknet::contract]
mod Verifier {
    use starknet::{ContractAddress, ClassHash, get_caller_address};
    use openzeppelin::upgrades::interface::IUpgradeable;

    #[storage]
    struct Storage {
        // public, master address, which can call upgrade functions
        master: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.master.write(get_caller_address());
    }

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
}
