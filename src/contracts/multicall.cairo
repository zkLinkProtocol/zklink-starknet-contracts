use starknet::{ContractAddress, EthAddress};

#[derive(Drop, Serde, Clone)]
struct Call {
    address: ContractAddress,
    selector: felt252,
    calldata: Array<felt252>
}

#[derive(Drop, Serde)]
struct MulticallResult {
    success: bool,
    returnData: Span<felt252>
}

#[derive(Drop, Serde)]
struct WithdrawToL1Info {
    owner: EthAddress,
    token: ContractAddress,
    amount: u128,
    fastWithdrawFeeRate: u16,
    accountIdOfNonce: u32,
    subAccountIdOfNonce: u8,
    nonce: u32,
    value: u256
}

#[derive(Drop, Serde)]
struct WithdrawPendingBalanceInfo {
    owner: ContractAddress,
    tokenId: u16,
    amount: u128
}

#[derive(Drop, Serde)]
struct AcceptInfo {
    receiver: ContractAddress,
    token: ContractAddress,
    amount: u128,
    withdrawFeeRate: u16,
    accountIdOfNonce: u32,
    subAccountIdOfNonce: u8,
    nonce: u32,
}

#[starknet::interface]
trait IMulticall<TContractState> {
    fn multicall(ref self: TContractState, _targets: Array<Call>) -> Array<MulticallResult>;
    fn batchWithdrawToL1(
        ref self: TContractState, _zklink: ContractAddress, _withdrawDatas: Array<WithdrawToL1Info>
    );
    fn batchWithdrawPendingBalance(
        ref self: TContractState,
        _zklink: ContractAddress,
        _withdrawDatas: Array<WithdrawPendingBalanceInfo>
    );
}

#[starknet::contract]
mod Multicall {
    use core::array::ArrayTrait;
    use super::IMulticallDispatcher;
    use super::IMulticallDispatcherTrait;
    use super::{Call, MulticallResult, WithdrawToL1Info, WithdrawPendingBalanceInfo, AcceptInfo};

    use starknet::{ContractAddress, EthAddress, SyscallResultTrait};
    use serde::Serde;

    #[storage]
    struct Storage {}

    #[external(v0)]
    impl Multicall of super::IMulticall<ContractState> {
        fn multicall(ref self: ContractState, _targets: Array<Call>) -> Array<MulticallResult> {
            let mut results: Array<MulticallResult> = array![];
            let mut i = 0;

            loop {
                if i == _targets.len() {
                    break;
                }
                let Call{address, selector, calldata } = _targets[i].clone();
                let returnData = starknet::call_contract_syscall(
                    address: address, entry_point_selector: selector, calldata: calldata.span(),
                )
                    .unwrap_syscall();

                // TODO: when Sierra has the ability to catch a revert to resume execution
                // we should add false to the result to indicate a failure
                results.append(MulticallResult { success: true, returnData: returnData });
                i += 1;
            };

            results
        }

        fn batchWithdrawToL1(
            ref self: ContractState,
            _zklink: ContractAddress,
            _withdrawDatas: Array<WithdrawToL1Info>
        ) {
            let mut i = 0;
            loop {
                if i == _withdrawDatas.len() {
                    break;
                }

                let withdrawToL1Info: @WithdrawToL1Info = _withdrawDatas[i];
                let mut calldata: Array<felt252> = array![];

                Serde::serialize(withdrawToL1Info.owner, ref calldata);
                Serde::serialize(withdrawToL1Info.token, ref calldata);
                Serde::serialize(withdrawToL1Info.amount, ref calldata);
                Serde::serialize(withdrawToL1Info.fastWithdrawFeeRate, ref calldata);
                Serde::serialize(withdrawToL1Info.accountIdOfNonce, ref calldata);
                Serde::serialize(withdrawToL1Info.subAccountIdOfNonce, ref calldata);
                Serde::serialize(withdrawToL1Info.nonce, ref calldata);

                starknet::call_contract_syscall(
                    address: _zklink,
                    entry_point_selector: selector!("withdrawToL1"),
                    calldata: calldata.span()
                )
                    .unwrap_syscall();

                i += 1;
            }
        }

        fn batchWithdrawPendingBalance(
            ref self: ContractState,
            _zklink: ContractAddress,
            _withdrawDatas: Array<WithdrawPendingBalanceInfo>
        ) {
            let mut i = 0;
            loop {
                if i == _withdrawDatas.len() {
                    break;
                }

                let withdrawPendingBalanceInfo: @WithdrawPendingBalanceInfo = _withdrawDatas[i];
                let mut calldata: Array<felt252> = array![];

                Serde::serialize(withdrawPendingBalanceInfo.owner, ref calldata);
                Serde::serialize(withdrawPendingBalanceInfo.tokenId, ref calldata);
                Serde::serialize(withdrawPendingBalanceInfo.amount, ref calldata);

                starknet::call_contract_syscall(
                    address: _zklink,
                    entry_point_selector: selector!("withdrawPendingBalance"),
                    calldata: calldata.span()
                )
                    .unwrap_syscall();

                i += 1;
            }
        }
    }
}
