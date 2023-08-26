use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use starknet::testing::{set_caller_address, set_contract_address, pop_log};
use test::test_utils::assert_eq;

use zklink::contracts::zklink::Zklink;
use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::tests::mocks::standard_token::StandardToken;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcher;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcherTrait;
use zklink::tests::mocks::non_standard_token::NonStandardToken;
use zklink::tests::mocks::non_standard_token::INonStandardTokenDispatcher;
use zklink::tests::mocks::non_standard_token::INonStandardTokenDispatcherTrait;
use zklink::tests::mocks::standard_decimals_token::StandardDecimalsToken;
use zklink::tests::mocks::standard_decimals_token::IStandardDecimalsTokenDispatcher;
use zklink::tests::mocks::standard_decimals_token::IStandardDecimalsTokenDispatcherTrait;
use zklink::tests::utils;
use zklink::tests::utils::Token;
use zklink::utils::bytes::{Bytes, BytesTrait};

fn assert_event_BrokerApprove(
    zklink: ContractAddress,
    _tokenId: u16,
    _owner: ContractAddress,
    _spender: ContractAddress,
    _amount: u128
) {
    assert_eq(
        @pop_log(zklink).unwrap(),
        @Zklink::Event::BrokerApprove(
            Zklink::BrokerApprove {
                tokenId: _tokenId, owner: _owner, spender: _spender, amount: _amount
            }
        ),
        'BrokerApprove Emit'
    );
}

fn assert_event_Accept(
    zklink: ContractAddress,
    _acceptor: ContractAddress,
    _accountId: u32,
    _receiver: ContractAddress,
    _tokenId: u16,
    _amount: u128,
    _withdrawFeeRate: u16,
    _accountIdOfNonce: u32,
    _subAccountIdOfNonce: u8,
    _nonce: u32,
    _amountSent: u128,
    _amountReceive: u128
) {
    assert_eq(
        @pop_log(zklink).unwrap(),
        @Zklink::Event::Accept(
            Zklink::Accept {
                acceptor: _acceptor,
                accountId: _accountId,
                receiver: _receiver,
                tokenId: _tokenId,
                amount: _amount,
                withdrawFeeRate: _withdrawFeeRate,
                accountIdOfNonce: _accountIdOfNonce,
                subAccountIdOfNonce: _subAccountIdOfNonce,
                nonce: _nonce,
                amountSent: _amountSent,
                amountReceive: _amountReceive
            }
        ),
        'Accept Emit'
    )
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_broker_approve_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[1];

    set_contract_address(alice);
    zklink_dispatcher.brokerApprove(token2.tokenId, bob, 100);
    assert_event_BrokerApprove(zklink, token2.tokenId, alice, bob, 100);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_acceptor_zero() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];

    let ZERO: ContractAddress = contract_address_const::<0>();
    let fwAId = 1;
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(ZERO, fwAId, bob, eth.tokenId, 100, 20, 10, 0, 1, 100);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_receiver_zero() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];

    let ZERO: ContractAddress = contract_address_const::<0>();
    let fwAId = 1;
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(alice, fwAId, ZERO, eth.tokenId, 100, 20, 10, 0, 1, 100);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_same_acceptor_receiver() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];

    let ZERO: ContractAddress = contract_address_const::<0>();
    let fwAId = 1;
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(alice, fwAId, alice, eth.tokenId, 100, 20, 10, 0, 1, 100);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_token_unregisted() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let ZERO: ContractAddress = contract_address_const::<0>();
    let fwAId = 1;
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(alice, fwAId, bob, 10000, 100, 20, 10, 0, 1, 100);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H4', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_feerate_too_large() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];

    let ZERO: ContractAddress = contract_address_const::<0>();
    let fwAId = 1;
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(alice, fwAId, bob, eth.tokenId, 100, 10000, 10, 0, 1, 100);
}

// calculate pubData from Python
// from eth_abi.packed import encode_abi_packed
// def cal():
//     data = encode_abi_packed(encode_format, example)
//     size = len(data)
//     data += b'\x00' * (16 - size % 16)
//     data = [int.from_bytes(x, 'big') for x in [data[i:i+16] for i in range(0, len(data), 16)]]
//     print(size)
//     print(data)

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('H6', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_has_acceptor() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];

    // encode_format = ["uint32","uint8","uint32", "uint256","uint16","uint128","uint16"]
    // example = [10, 0, 1, 0x626f62, 33, 100, 100]
    //
    // size 61
    // data = [792281625142715433529477431296, 0, 464846565593906591825920, 109952840499200]
    let pubData: Bytes = BytesTrait::new(
        61, array![792281625142715433529477431296, 0, 464846565593906591825920, 109952840499200]
    );
    let hash = pubData.keccak();
    let fwAId = 1;
    zklink_dispatcher.setAcceptor(fwAId, hash, alice);
    set_contract_address(alice);
    zklink_dispatcher.acceptERC20(alice, fwAId, bob, eth.tokenId, 100, 100, 10, 0, 1, 100);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_exodus() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];

    let fwAId = 1;
    set_contract_address(alice);
    zklink_dispatcher.setExodus(true);
    zklink_dispatcher.acceptERC20(alice, fwAId, bob, eth.tokenId, 10000, 100, 10, 0, 1, 10000);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_accept_standard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    let fwAId = 1;
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
            bob,
            fwAId,
            alice,
            token2.tokenId,
            amount,
            feeRate,
            accountIdOfNonce,
            subAccountIdOfNonce,
            nonce,
            amountReceive
        );
    assert_event_Accept(
        zklink,
        bob,
        fwAId,
        alice,
        token2.tokenId,
        amount,
        feeRate,
        accountIdOfNonce,
        subAccountIdOfNonce,
        nonce,
        amountReceive,
        amountReceive
    );

    // encode_format = ["uint32","uint8","uint32", "uint256","uint16","uint128","uint16"]
    // example = [15, 3, 1, 0x616c696365, 34, 1000000000000000000, 100]
    //
    // size 61
    // data = [1189350892743501156703371526144, 0, 30151107623175070608391143424, 1099511627776000000001677721600]
    let pubData: Bytes = BytesTrait::new(
        61,
        array![
            1189350892743501156703371526144,
            0,
            30151107623175070608391143424,
            1099511627776000000001677721600
        ]
    );
    let hash = pubData.keccak();

    let address = zklink_dispatcher.getAcceptor(fwAId, hash);
    assert(address == bob, 'acceptor');

    let balance = token2_dispatcher.balance_of(alice);
    assert(balance == amountReceive.into(), 'balance');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('F0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_erc20_approve_not_enough() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    let fwAId = 1;
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
            bob,
            fwAId,
            alice,
            token2.tokenId,
            amount,
            feeRate,
            accountIdOfNonce,
            subAccountIdOfNonce,
            nonce,
            amountReceive
        );
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_accept_sender_not_acceptor() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    let fwAId = 1;
    let amount: u128 = 1000000000000000000; // 1 Ether
    let feeRate = 100; // 1%
    let accountIdOfNonce = 15;
    let subAccountIdOfNonce = 3;
    let nonce = 3;
    let amountReceive: u128 = 990000000000000000; // 0.99 Ether

    set_contract_address(bob);
    token2_dispatcher.mint(100000000000000000000); // 100 Ether
    token2_dispatcher.approve(zklink, 2000000000000000000); // 2 Ether
    zklink_dispatcher
        .brokerApprove(token2.tokenId, defaultSender, 1500000000000000000); // 1.5 Ether
    utils::drop_event(zklink);

    // change sender to defaultSender
    set_contract_address(defaultSender);
    zklink_dispatcher
        .acceptERC20(
            bob,
            fwAId,
            alice,
            token2.tokenId,
            amount,
            feeRate,
            accountIdOfNonce,
            subAccountIdOfNonce,
            nonce,
            amountReceive
        );
    assert_event_Accept(
        zklink,
        bob,
        fwAId,
        alice,
        token2.tokenId,
        amount,
        feeRate,
        accountIdOfNonce,
        subAccountIdOfNonce,
        nonce,
        amountReceive,
        amountReceive
    );

    let broker_allowance = zklink_dispatcher
        .brokerAllowance(token2.tokenId, bob, defaultSender); // 0.51 Ether
    assert(broker_allowance == 510000000000000000, 'broker_allowance');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('F1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_accept_broker_allowance_not_enough() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let bob = *addrs[5];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    let fwAId = 1;
    let amount: u128 = 1000000000000000000; // 1 Ether
    let feeRate = 100; // 1%
    let accountIdOfNonce = 15;
    let subAccountIdOfNonce = 3;
    let mut nonce = 3;
    let amountReceive: u128 = 990000000000000000; // 0.99 Ether

    set_contract_address(bob);
    token2_dispatcher.mint(100000000000000000000); // 100 Ether
    token2_dispatcher.approve(zklink, 2000000000000000000); // 2 Ether
    zklink_dispatcher
        .brokerApprove(token2.tokenId, defaultSender, 1500000000000000000); // 1.5 Ether
    utils::drop_event(zklink);

    // change sender to defaultSender
    set_contract_address(defaultSender);
    zklink_dispatcher
        .acceptERC20(
            bob,
            fwAId,
            alice,
            token2.tokenId,
            amount,
            feeRate,
            accountIdOfNonce,
            subAccountIdOfNonce,
            nonce,
            amountReceive
        );

    // broker allowance is 0.51 Ether
    // accept again
    nonce = 4;
    zklink_dispatcher
        .acceptERC20(
            bob,
            fwAId,
            alice,
            token2.tokenId,
            amount,
            feeRate,
            accountIdOfNonce,
            subAccountIdOfNonce,
            nonce,
            amountReceive
        );
}
