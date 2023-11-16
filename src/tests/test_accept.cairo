use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};

use zklink::contracts::zklink::Zklink;
use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::tests::mocks::standard_token::StandardToken;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcher;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcherTrait;
use zklink::tests::mocks::standard_decimals_token::StandardDecimalsToken;
use zklink::tests::mocks::standard_decimals_token::IStandardDecimalsTokenDispatcher;
use zklink::tests::mocks::standard_decimals_token::IStandardDecimalsTokenDispatcherTrait;
use zklink::tests::utils;
use zklink::tests::utils::Token;
use zklink::utils::bytes::{Bytes, BytesTrait};


#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_receiver_zero() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];

    let ZERO: ContractAddress = contract_address_const::<0>();
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(ZERO, eth.tokenId, 100, 20, 10, 0, 1);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_same_acceptor_receiver() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];

    let ZERO: ContractAddress = contract_address_const::<0>();
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(alice, eth.tokenId, 100, 20, 10, 0, 1);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_token_unregisted() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let ZERO: ContractAddress = contract_address_const::<0>();
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(bob, 10000, 100, 20, 10, 0, 1);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H4', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_feerate_too_large() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];

    let ZERO: ContractAddress = contract_address_const::<0>();
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(bob, eth.tokenId, 100, 10000, 10, 0, 1);
}

// calculate pubData from Python
// from eth_abi.packed import encode_packed
// def cal():
//     data = encode_packed(encode_format, example)
//     size = len(data)
//     data = [int.from_bytes(x, 'big') for x in [data[i:i+16] for i in range(0, len(data), 16)]]
//     print(data[:-1])
//     print(data[-1])
//     print(size % 16)

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H6', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_has_acceptor() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];

    // encode_format = ["uint32","uint8","uint32", "uint256","uint16","uint128","uint16"]
    // example = [10, 0, 1, 0x626f62, 33, 100, 100]
    //
    // data = [792281625142715433529477431296, 0, 464846565593906591825920]
    // pending_data = 6553700
    // pending_data_size = 13
    let pubData = Bytes {
        data: array![792281625142715433529477431296, 0, 464846565593906591825920],
        pending_data: 6553700,
        pending_data_size: 13
    };
    let hash = pubData.keccak();
    zklink_dispatcher.setAcceptor(hash, alice);
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(bob, eth.tokenId, 100, 100, 10, 0, 1);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_exodus() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];

    set_contract_address(alice);
    zklink_dispatcher.setExodus(true);
    zklink_dispatcher.acceptERC20(bob, eth.tokenId, 10000, 100, 10, 0, 1);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_accept_standard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    let amount: u128 = 1000000000000000000; // 1 Ether
    let feeRate = 100; // 1%
    let accountIdOfNonce = 15;
    let subAccountIdOfNonce = 3;
    let mut nonce = 1;
    let amountReceive = 990000000000000000; // 0.99 Ether

    set_contract_address(bob);
    token2_dispatcher.mint(100000000000000000000); // 100 Ether
    token2_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .acceptERC20(
            alice, token2.tokenId, amount, feeRate, accountIdOfNonce, subAccountIdOfNonce, nonce
        );
    utils::assert_event_Accept(
        zklink,
        bob,
        alice,
        token2.tokenId,
        amount,
        feeRate,
        accountIdOfNonce,
        subAccountIdOfNonce,
        nonce,
        amountReceive
    );

    // encode_format = ["uint32","uint8","uint32", "uint256","uint16","uint128","uint16"]
    // example = [15, 3, 1, 0x616c696365, 34, 1000000000000000000, 100]
    //
    // data = [1189350892743501156703371526144, 0, 30151107623175070608391143424]
    // pending_data = 65536000000000000000100
    // pending_data_size = 13
    let pubData = Bytes {
        data: array![1189350892743501156703371526144, 0, 30151107623175070608391143424],
        pending_data: 65536000000000000000100,
        pending_data_size: 13
    };
    let hash = pubData.keccak();

    let address = zklink_dispatcher.getAcceptor(hash);
    assert(address == bob, 'acceptor');

    let balance = token2_dispatcher.balanceOf(alice);
    assert(balance == amountReceive.into(), 'balance');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('u256_sub Overflow', 'ENTRYPOINT_FAILED', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_erc20_approve_not_enough() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    let amount: u128 = 1000000000000000000; // 1 Ether
    let feeRate = 100; // 1%
    let accountIdOfNonce = 15;
    let subAccountIdOfNonce = 3;
    let nonce = 2;
    let amountReceive: u128 = 980000000000000000; // 0.98 Ether

    set_contract_address(bob);
    // approve value not enough
    token2_dispatcher.mint(100000000000000000000); // 100 Ether
    token2_dispatcher.approve(zklink, amountReceive.into()); // 0.98 Ether
    zklink_dispatcher
        .acceptERC20(
            alice, token2.tokenId, amount, feeRate, accountIdOfNonce, subAccountIdOfNonce, nonce
        );
}
