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

use zklink_starknet_utils::bytes::{Bytes, BytesTrait};

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
use zklink::tests::mocks::verifier_test::IVerifierMock;
use zklink::tests::mocks::verifier_test::IVerifierMockDispatcher;
use zklink::tests::mocks::verifier_test::IVerifierMockDispatcherTrait;
use zklink::tests::utils;
use zklink::tests::utils::Token;
use zklink::utils::data_structures::DataStructures::StoredBlockInfo;

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('b0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_withdrawPendingBalance_token_unregisted() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let amount = 1000000000000000000; // 1 Ether
    zklink_dispatcher.withdrawPendingBalance(defaultSender, 100, amount);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('b1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_withdrawPendingBalance_zero_amount() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let amount = 0; // 0 Ether
    zklink_dispatcher.withdrawPendingBalance(defaultSender, eth.tokenId, amount);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('b1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_withdrawPendingBalance_no_pending_balance() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let amount = 1000000000000000000; // 0 Ether
    zklink_dispatcher.withdrawPendingBalance(defaultSender, eth.tokenId, amount);
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
fn test_zklink_withdrawPendingBalance_standard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let alice = *addrs[utils::ADDR_ALICE];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    // prepare
    let depositAmount: u128 = 1000000000000000000; // 1 Ether
    set_contract_address(defaultSender);
    token2_dispatcher.mint(depositAmount.into());
    token2_dispatcher.approve(zklink, depositAmount.into());
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, depositAmount, utils::extendAddress(alice), 0, false);
    utils::drop_event(zklink);

    // encode_format = ["uint8","uint8","uint8","uint16","uint16","uint128","uint256","uint32"]
    // example = [1, 1, 0, 34, 34, 1000000000000000000, 0x616c696365, 0]
    //
    // data = [1334420303166101594918487461189386253, 298695712897445188672130103387013251072, 0]
    // pending_data = 1797146059463920189440
    // pending_data_size = 11
    let pubdata = Bytes {
        data: array![
            1334420303166101594918487461189386253, 298695712897445188672130103387013251072, 0
        ],
        pending_data: 1797146059463920189440,
        pending_data_size: 11
    };

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
