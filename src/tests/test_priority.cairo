use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use clone::Clone;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};

use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::tests::mocks::standard_token::StandardToken;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcher;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcherTrait;
use zklink::tests::utils;
use zklink::tests::utils::Token;


#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_eth_exodus() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    // exodus
    zklink_dispatcher.setExodus(true);
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
    let subAccountId: u8 = 0;
    let amount: u128 = 1000000000000000000;
    set_contract_address(defaultSender);
    // deposit ETH
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_erc20_exodus() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    // exodus
    zklink_dispatcher.setExodus(true);
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
    let subAccountId: u8 = 0;
    let amount: u128 = 1000000000000000000;
    set_contract_address(defaultSender);
    token2_dispatcher.mint(10000);
    token2_dispatcher.approve(zklink, 100);
    // deposit Token2
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, 30, utils::extendAddress(to), subAccountId, false);
}
