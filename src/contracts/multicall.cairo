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
    fn multiStaticCall(self: @TContractState, _targets: Array<Call>) -> Array<MulticallResult>;
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
    use core::traits::TryInto;
    use core::traits::Into;
    use contract_starknet::multicall::IMulticall;
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
        fn multiStaticCall(self: @ContractState, _targets: Array<Call>) -> Array<MulticallResult> {
            let mut results: Array<MulticallResult> = array![];
            let mut _targets = _targets;
            loop {
                match _targets.pop_front() {
                    Option::Some(Call{address,
                    selector,
                    calldata }) => {
                        let returnData = starknet::call_contract_syscall(
                            address, selector, calldata.span()
                        )
                            .unwrap_syscall();

                        // TODO: when Sierra has the ability to catch a revert to resume execution
                        // we should add false to the result to indicate a failure
                        results.append(MulticallResult { success: true, returnData: returnData });
                    },
                    Option::None => { break; }
                }
            };
            results
        }

        fn multicall(ref self: ContractState, _targets: Array<Call>) -> Array<MulticallResult> {
            self.multiStaticCall(_targets)
        }

        fn batchWithdrawToL1(
            ref self: ContractState,
            _zklink: ContractAddress,
            _withdrawDatas: Array<WithdrawToL1Info>
        ) {
            let mut _withdrawDatas = _withdrawDatas;
            loop {
                match _withdrawDatas.pop_front() {
                    Option::Some(withdrawToL1Info) => {
                        let mut calldata: Array<felt252> = array![];
                        Serde::serialize(@withdrawToL1Info.owner, ref calldata);
                        Serde::serialize(@withdrawToL1Info.token, ref calldata);
                        Serde::serialize(@withdrawToL1Info.amount, ref calldata);
                        Serde::serialize(@withdrawToL1Info.fastWithdrawFeeRate, ref calldata);
                        Serde::serialize(@withdrawToL1Info.accountIdOfNonce, ref calldata);
                        Serde::serialize(@withdrawToL1Info.subAccountIdOfNonce, ref calldata);
                        Serde::serialize(@withdrawToL1Info.nonce, ref calldata);

                        starknet::call_contract_syscall(
                            address: _zklink,
                            entry_point_selector: selector!("withdrawToL1"),
                            calldata: calldata.span()
                        )
                            .unwrap_syscall();
                    },
                    Option::None => { break; }
                }
            }
        }

        fn batchWithdrawPendingBalance(
            ref self: ContractState,
            _zklink: ContractAddress,
            _withdrawDatas: Array<WithdrawPendingBalanceInfo>
        ) {
            let mut _withdrawDatas = _withdrawDatas;
            loop {
                match _withdrawDatas.pop_front() {
                    Option::Some(withdrawPendingBalanceInfo) => {
                        let mut calldata: Array<felt252> = array![];
                        Serde::serialize(@withdrawPendingBalanceInfo.owner, ref calldata);
                        Serde::serialize(@withdrawPendingBalanceInfo.tokenId, ref calldata);
                        Serde::serialize(@withdrawPendingBalanceInfo.amount, ref calldata);

                        starknet::call_contract_syscall(
                            address: _zklink,
                            entry_point_selector: selector!("withdrawPendingBalance"),
                            calldata: calldata.span()
                        )
                            .unwrap_syscall();
                    },
                    Option::None => { break; }
                }
            }
        }
    }
}
