use array::ArrayTrait;
use array::SpanTrait;
use core::result::ResultTrait;
use option::OptionTrait;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::ContractAddress;
use starknet::testing;
use starknet::SyscallResultTrait;
use traits::TryInto;


fn deploy(contract_class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        contract_class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap_syscall();
    address
}