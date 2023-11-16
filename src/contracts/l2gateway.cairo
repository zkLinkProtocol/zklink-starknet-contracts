use starknet::{EthAddress, ContractAddress};

#[starknet::interface]
trait IL2Gateway<TContractState> {
    fn depositERC20(
        ref self: TContractState,
        _token: ContractAddress,
        _amount: u128,
        _zkLinkAddress: u256,
        _subAccountId: u8,
        _mapping: bool
    );
    fn withdrawERC20(
        ref self: TContractState,
        _owner: EthAddress,
        _token: ContractAddress,
        _amount: u128,
        _accountIdOfNonce: u32,
        _subAccountIdOfNonce: u8,
        _nonce: u32,
        _fastWithdrawFeeRate: u16
    ) -> u128;
}
