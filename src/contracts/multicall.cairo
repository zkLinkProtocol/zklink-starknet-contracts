use starknet::{ContractAddress, EthAddress};

#[derive(Drop, Serde, Clone)]
struct Call {
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
    fn multicall(
        self: @TContractState, _targets: Array<ContractAddress>, _calls: Array<Call>
    ) -> Array<MulticallResult>;
    fn batchWithdrawToL1(
        self: @TContractState, _zklink: ContractAddress, _withdrawDatas: Array<WithdrawToL1Info>
    );
    fn batchWithdrawPendingBalance(
        self: @TContractState,
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
        fn multicall(
            self: @ContractState, _targets: Array<ContractAddress>, _calls: Array<Call>
        ) -> Array<MulticallResult> {
            assert(_targets.len() == _calls.len(), 'Invalid input length');

            let mut results: Array<MulticallResult> = array![];
            let mut i = 0;

            loop {
                if i == _targets.len() {
                    break;
                }

                let target = *_targets[i];
                let Call{selector, calldata } = _calls[i].clone();

                let returnData = starknet::call_contract_syscall(
                    address: target, entry_point_selector: selector, calldata: calldata.span(),
                )
                    .unwrap_syscall();

                results.append(MulticallResult { success: true, returnData: returnData });
                i += 1;
            };

            results
        }

        fn batchWithdrawToL1(
            self: @ContractState, _zklink: ContractAddress, _withdrawDatas: Array<WithdrawToL1Info>
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
                );

                i += 1;
            }
        }

        fn batchWithdrawPendingBalance(
            self: @ContractState,
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
                );

                i += 1;
            }
        }
    }
}
