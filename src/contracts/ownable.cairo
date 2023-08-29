use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IOwnable<TContractState> {
    fn getMaster(self: @TContractState) -> ContractAddress;
    fn transferMastership(ref self: TContractState, _newMaster: ContractAddress);
}
