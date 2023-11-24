use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use starknet::testing::{set_contract_address, set_block_number};

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
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::utils::data_structures::DataStructures::StoredBlockInfo;

fn getStoredBlockTemplate() -> StoredBlockInfo {
    StoredBlockInfo {
        blockNumber: 5,
        preCommittedBlockNumber: 4,
        priorityOperations: 7,
        pendingOnchainOperationsHash: 0xcf2ef9f8da5935a514cc25835ea39be68777a2674197105ca904600f26547ad2,
        syncHash: 0xab04d07f7c285404dc58dd0b37894b20c4193a231499a20e4056d119fc2c1184
    }
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_cancelOutstandingDepositsForExodusMode_when_active() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    let owner = defaultSender;
    let accountId = 245;
    let subAccountId = 2;
    let tokenId = 58;
    let amount = 1560000000000000000; // 1.56 Ether
    let proof = array![3, 0, 9, 5];
    let storedBlock = getStoredBlockTemplate();

    set_contract_address(defaultSender);
    zklink_dispatcher.cancelOutstandingDepositsForExodusMode(3, array![]);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_activateExodusMode_twice() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let alice = *addrs[utils::ADDR_ALICE];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    let to = alice;
    let subAccountId = 0;
    let amount: u128 = 1000000000000000000; // 1 Ether

    // expire block is zero in unit test environment
    // cairo-test defualt block number is 0
    set_block_number(5);
    set_contract_address(defaultSender);
    eth_dispatcher.mint(amount.into() * 10);
    eth_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    utils::drop_event(zklink);

    zklink_dispatcher.activateExodusMode();
    utils::assert_event_ExodusMode(zklink, true);

    // active agian should failed
    zklink_dispatcher.activateExodusMode();
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('A0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_cancelOutstandingDepositsForExodusMode_no_priority_request() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let alice = *addrs[utils::ADDR_ALICE];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let eth_dispatcher = IStandardTokenDispatcher { contract_address: eth.tokenAddress };

    // active exodus mode
    let to = alice;
    let subAccountId = 0;
    let amount: u128 = 1000000000000000000; // 1 Ether
    set_block_number(6);
    set_contract_address(defaultSender);
    eth_dispatcher.mint(amount.into() * 10);
    eth_dispatcher.approve(zklink, amount.into());
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    utils::drop_event(zklink);
    zklink_dispatcher.activateExodusMode();
    utils::drop_event(zklink);

    // there should be priority requests exist
    zklink_dispatcher.setTotalOpenPriorityRequests(0);
    zklink_dispatcher.cancelOutstandingDepositsForExodusMode(3, array![]);
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
fn test_zklink_cancelOutstandingDepositsForExodusMode_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let alice = *addrs[utils::ADDR_ALICE];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    set_contract_address(defaultSender);
    token2_dispatcher.mint(1000000000000000000000); // 1000 Ether
    token2_dispatcher.approve(zklink, 1000000000000000000000); // 1000 Ether
    let amount0 = 4000000000000000000; // 4 Ether
    let amount1 = 10000000000000000000; // 10 Ether
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, amount0, utils::extendAddress(defaultSender), 0, false);

    set_contract_address(alice);
    zklink_dispatcher.requestFullExit(14, 2, token2.tokenId, false);

    set_contract_address(defaultSender);
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, amount1, utils::extendAddress(alice), 1, false);

    // active exodus mode
    zklink_dispatcher.setExodus(true);

    // encode_format = ["uint8","uint8","uint8","uint16","uint16","uint128","uint256","uint32"]
    // example = [1, 1, 0, 34, 34, 4000000000000000000, 0x64656661756c7453656e646572, 0]
    //
    // data = [1334420303166101594918487461189386295, 173935750826965364298396591252748369920, 110386672137580]
    // pending_data = 140629222569120991627182080
    // pending_data_size = 11
    let pubdata0 = Bytes {
        data: array![
            1334420303166101594918487461189386295,
            173935750826965364298396591252748369920,
            110386672137580
        ],
        pending_data: 140629222569120991627182080,
        pending_data_size: 11
    };

    // encode_format = ["uint8","uint8","uint8","uint16","uint16","uint128","uint256","uint32"]
    // example = [1, 1, 1, 34, 34, 10000000000000000000, 0x616c696365, 0]
    //
    // data = [1334440585575705246588911408440672394, 264698193606944179014304174415986819072, 0]
    // pending_data = 1797146059463920189440
    // pending_data_size = 11
    let pubdata1 = Bytes {
        data: array![
            1334440585575705246588911408440672394, 264698193606944179014304174415986819072, 0
        ],
        pending_data: 1797146059463920189440,
        pending_data_size: 11
    };

    zklink_dispatcher.cancelOutstandingDepositsForExodusMode(3, array![pubdata0, pubdata1]);
    let balance0 = zklink_dispatcher
        .getPendingBalance(utils::extendAddress(defaultSender), token2.tokenId);
    let balance1 = zklink_dispatcher.getPendingBalance(utils::extendAddress(alice), token2.tokenId);

    assert(balance0 == amount0, 'getPendingBalance0');
    assert(balance1 == amount1, 'getPendingBalance1');
}
