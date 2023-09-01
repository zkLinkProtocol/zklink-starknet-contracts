use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use starknet::testing::{set_contract_address, set_block_number, pop_log};
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
use zklink::tests::mocks::verifier_test::IVerifierMock;
use zklink::tests::mocks::verifier_test::IVerifierMockDispatcher;
use zklink::tests::mocks::verifier_test::IVerifierMockDispatcherTrait;
use zklink::tests::utils;
use zklink::tests::utils::Token;
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::utils::data_structures::DataStructures::StoredBlockInfo;

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('b0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_withdrawPendingBalance_token_unregisted() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let amount = 1000000000000000000; // 1 Ether
    zklink_dispatcher.withdrawPendingBalance(defaultSender, 100, amount);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('b1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_withdrawPendingBalance_zero_amount() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let amount = 0; // 0 Ether
    zklink_dispatcher.withdrawPendingBalance(defaultSender, eth.tokenId, amount);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('b1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_withdrawPendingBalance_no_pending_balance() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let amount = 1000000000000000000; // 0 Ether
    zklink_dispatcher.withdrawPendingBalance(defaultSender, eth.tokenId, amount);
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
fn test_zklink_withdrawPendingBalance_standard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    // prepare
    let depositAmount: u128 = 1000000000000000000; // 1 Ether
    set_contract_address(defaultSender);
    token2_dispatcher.mint(depositAmount.into());
    token2_dispatcher.approve(zklink, depositAmount.into());
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, depositAmount, utils::extendAddress(alice), 0, false);
    utils::drop_event(zklink);

    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 34, 34, 1000000000000000000, 0x616c696365]
    //
    // size 59
    // data = [1334420292643450702982333137294458880, 1099511627776000000000000000000, 0, 460069391222763568496640]
    let pubdata: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643450702982333137294458880,
            1099511627776000000000000000000,
            0,
            460069391222763568496640
        ]
    );

    // action1
    zklink_dispatcher.setExodus(true);
    zklink_dispatcher.cancelOutstandingDepositsForExodusMode(1, array![pubdata]);
    zklink_dispatcher.setExodus(false);

    // check1
    let balance = zklink_dispatcher.getPendingBalance(utils::extendAddress(alice), token2.tokenId);
    assert(balance == depositAmount, 'balance1');

    // action2
    let b0 = token2_dispatcher.balanceOf(alice);
    let amount0: u128 = 500000000000000000; // 0.5 Ether
    zklink_dispatcher.withdrawPendingBalance(alice, token2.tokenId, amount0);

    // check2
    utils::assert_event_Withdrawal(zklink, token2.tokenId, amount0);
    let balance = token2_dispatcher.balanceOf(alice);
    assert(balance == b0 + amount0.into(), 'balance2');
    let balance = zklink_dispatcher.getPendingBalance(utils::extendAddress(alice), token2.tokenId);
    assert(balance == depositAmount - amount0, 'balance3');

    // action3
    let leftAmount = depositAmount - amount0;
    let amount1 = 600000000000000000; // 0.6 Ether
    zklink_dispatcher.withdrawPendingBalance(alice, token2.tokenId, amount1);

    // check3
    utils::assert_event_Withdrawal(zklink, token2.tokenId, leftAmount);
    let balance = token2_dispatcher.balanceOf(alice);
    assert(balance == b0 + depositAmount.into(), 'balance4');
    let balance = zklink_dispatcher.getPendingBalance(utils::extendAddress(alice), token2.tokenId);
    assert(balance == 0, 'balance5');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_withdrawPendingBalance_nonstandard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let alice = *addrs[4];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token3: Token = *tokens[2];
    let token3_dispatcher = INonStandardTokenDispatcher { contract_address: token3.tokenAddress };

    // prepare
    let depositAmount: u128 = 1000000000000000000; // 1 Ether
    set_contract_address(defaultSender);
    token3_dispatcher.mint(2000000000000000000); // 2 Ether
    token3_dispatcher.approve(zklink, depositAmount.into());
    zklink_dispatcher
        .depositERC20(token3.tokenAddress, depositAmount, utils::extendAddress(alice), 0, false);
    utils::drop_event(zklink);
    let reallyDepositAmount: u128 = 800000000000000000; // 0.8 Ether, take 20% fee

    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 35, 35, 800000000000000000, 0x616c696365]
    //
    // size 59
    // data = [1334420292643450703054391830844014592, 879609302220800000000000000000, 0, 460069391222763568496640]
    let pubdata: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643450703054391830844014592,
            879609302220800000000000000000,
            0,
            460069391222763568496640
        ]
    );

    // action1
    zklink_dispatcher.setExodus(true);
    zklink_dispatcher.cancelOutstandingDepositsForExodusMode(1, array![pubdata]);
    zklink_dispatcher.setExodus(false);

    // check1
    let balance = zklink_dispatcher.getPendingBalance(utils::extendAddress(alice), token3.tokenId);
    assert(balance == reallyDepositAmount, 'balance1');

    // action2
    let b0 = token3_dispatcher.balanceOf(alice);
    let amount0: u128 = 500000000000000000; // 0.5 Ether
    let reallyAmount0: u128 = 550000000000000000; // 0.55 Ether, 0.5 * 1.1
    let reallyReceive0: u128 = 400000000000000000; // 0.4 Ether, 0.5 * 0.8
    zklink_dispatcher.withdrawPendingBalance(alice, token3.tokenId, amount0);

    // check2
    utils::assert_event_Withdrawal(zklink, token3.tokenId, reallyAmount0);
    let balance = token3_dispatcher.balanceOf(alice);
    assert(balance == b0 + reallyReceive0.into(), 'balance2');
    let balance = zklink_dispatcher.getPendingBalance(utils::extendAddress(alice), token3.tokenId);
    assert(balance == reallyDepositAmount - reallyAmount0, 'balance3');
}
