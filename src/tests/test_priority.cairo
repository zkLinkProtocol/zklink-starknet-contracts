use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
use starknet::{ContractAddress, contract_address_const};
use starknet::Felt252TryIntoContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};

use zklink_starknet_utils::bytes::{Bytes, BytesTrait};

use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::tests::mocks::standard_token::StandardToken;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcher;
use zklink::tests::mocks::standard_token::IStandardTokenDispatcherTrait;
use zklink::tests::mocks::standard_decimals_token::StandardDecimalsToken;
use zklink::tests::mocks::standard_decimals_token::IStandardDecimalsTokenDispatcher;
use zklink::tests::mocks::standard_decimals_token::IStandardDecimalsTokenDispatcherTrait;
use zklink::tests::mocks::camel_standard_token::CamelStandardToken;
use zklink::tests::mocks::camel_standard_token::ICamelStandardTokenDispatcher;
use zklink::tests::mocks::camel_standard_token::ICamelStandardTokenDispatcherTrait;
use zklink::tests::utils;
use zklink::tests::utils::Token;
use zklink::utils::constants::{DEPOSIT_CHECK_BYTES, FULL_EXIT_CHECK_BYTES};


#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_eth_exodus() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];

    // exodus
    zklink_dispatcher.setExodus(true);
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
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
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    // exodus
    zklink_dispatcher.setExodus(true);
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;
    let amount: u128 = 1000000000000000000;
    set_contract_address(defaultSender);
    token2_dispatcher.mint(10000);
    token2_dispatcher.approve(zklink, 100);
    // deposit Token2
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, 30, utils::extendAddress(to), subAccountId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('e3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_token_unregistered() {
    let (addrs, _) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token_address: ContractAddress = utils::deploy(
        StandardToken::TEST_CLASS_HASH, array!['Token not registered', 'TNR']
    );
    let token_dispatcher = IStandardTokenDispatcher { contract_address: token_address };
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;

    set_contract_address(defaultSender);
    token_dispatcher.mint(10000);
    token_dispatcher.approve(zklink, 100);
    zklink_dispatcher
        .depositERC20(token_address, 30, utils::extendAddress(to), subAccountId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('e4', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_token_paused() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;
    let amount: u128 = 1000000000000000000;

    set_contract_address(defaultSender);
    token2_dispatcher.mint(10000);
    token2_dispatcher.approve(zklink, 100);
    zklink_dispatcher.setTokenPaused(token2.tokenId, true);
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, 30, utils::extendAddress(to), subAccountId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('e5', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_token_unspupported_mapping() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;
    let amount: u128 = 1000000000000000000;

    set_contract_address(defaultSender);
    token2_dispatcher.mint(10000);
    token2_dispatcher.approve(zklink, 100);
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, 30, utils::extendAddress(to), subAccountId, true);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('e0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_zero_amount() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;
    let amount: u128 = 0;

    set_contract_address(defaultSender);
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('e1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_zero_to_address() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let to: ContractAddress = contract_address_const::<0>();
    let subAccountId: u8 = 0;
    let amount: u128 = 1000000000000000000;

    set_contract_address(defaultSender);
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('e2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_subaccountid_too_large() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = utils::MAX_SUB_ACCOUNT_ID + 1;
    let amount: u128 = 1000000000000000000;

    set_contract_address(defaultSender);
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
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
fn test_zklink_deposit_standard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;
    let amount: u128 = 30;

    set_contract_address(defaultSender);
    token2_dispatcher.mint(10000);
    let senderBalance = token2_dispatcher.balanceOf(defaultSender);
    let contractBalance = token2_dispatcher.balanceOf(zklink);
    token2_dispatcher.approve(zklink, 100);
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    assert(
        token2_dispatcher.balanceOf(zklink) == contractBalance + amount.into(),
        'invalid contract balance'
    );
    assert(
        token2_dispatcher.balanceOf(defaultSender) == senderBalance - amount.into(),
        'invalid sender balance'
    );

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint8","uint16","uint16","uint128","uint256","uint32"]
    // example = [1, 1, 0, 34, 34, 30, 0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0, 0]
    //
    // data = [1334420303166101594918487461189386240, 141670994486089356410880, 9073013115197512348337205226446]
    // pending_data = 236022272872492080104996864
    // pending_data_size = 11
    let pubData = Bytes {
        data: array![
            1334420303166101594918487461189386240,
            141670994486089356410880,
            9073013115197512348337205226446
        ],
        pending_data: 236022272872492080104996864,
        pending_data_size: 11
    };
    assert(hashedPubdata == pubData.keccak_for_check(DEPOSIT_CHECK_BYTES), 'invalid pubdata hash');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_deposit_camel_standard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token6: Token = *tokens[utils::TOKEN_T6];
    let token6_dispatcher = ICamelStandardTokenDispatcher { contract_address: token6.tokenAddress };
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;
    let amount: u128 = 30;

    set_contract_address(defaultSender);
    token6_dispatcher.mint(10000);
    let senderBalance = token6_dispatcher.balanceOf(defaultSender);
    let contractBalance = token6_dispatcher.balanceOf(zklink);
    token6_dispatcher.approve(zklink, 100);
    zklink_dispatcher
        .depositERC20(token6.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    assert(
        token6_dispatcher.balanceOf(zklink) == contractBalance + amount.into(),
        'invalid contract balance'
    );
    assert(
        token6_dispatcher.balanceOf(defaultSender) == senderBalance - amount.into(),
        'invalid sender balance'
    );

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint8","uint16","uint16","uint128","uint256","uint32"]
    // example = [1, 1, 0, 37, 37, 30, 0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0, 0]
    //
    // data = [1334420304094570791481971276299370496, 141670994486089356410880, 9073013115197512348337205226446]
    // pending_data = 236022272872492080104996864
    // pending_data_size = 11
    let pubData = Bytes {
        data: array![
            1334420304094570791481971276299370496,
            141670994486089356410880,
            9073013115197512348337205226446
        ],
        pending_data: 236022272872492080104996864,
        pending_data_size: 11
    };
    assert(hashedPubdata == pubData.keccak_for_check(DEPOSIT_CHECK_BYTES), 'invalid pubdata hash');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_deposit_erc20_mapping_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token4: Token = *tokens[utils::TOKEN_T4];
    let token4_dispatcher = IStandardTokenDispatcher { contract_address: token4.tokenAddress };
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;
    let amount: u128 = 30;

    set_contract_address(defaultSender);
    token4_dispatcher.mint(10000);
    let senderBalance = token4_dispatcher.balanceOf(defaultSender);
    let contractBalance = token4_dispatcher.balanceOf(zklink);
    token4_dispatcher.approve(zklink, 100);
    zklink_dispatcher
        .depositERC20(token4.tokenAddress, amount, utils::extendAddress(to), subAccountId, true);
    assert(
        token4_dispatcher.balanceOf(zklink) == contractBalance + amount.into(),
        'invalid contract balance'
    );
    assert(
        token4_dispatcher.balanceOf(defaultSender) == senderBalance - amount.into(),
        'invalid sender balance'
    );

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint8","uint16","uint16","uint128","uint256","uint32"]
    // example = [1, 1, 0, 17, 1, 30, 0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0, 0]
    //
    // data = [1334420297904700589861686594576056320, 141670994486089356410880, 9073013115197512348337205226446]
    // pending_data = 236022272872492080104996864
    // pending_data_size = 11
    let pubData = Bytes {
        data: array![
            1334420297904700589861686594576056320,
            141670994486089356410880,
            9073013115197512348337205226446
        ],
        pending_data: 236022272872492080104996864,
        pending_data_size: 11
    };
    assert(hashedPubdata == pubData.keccak_for_check(DEPOSIT_CHECK_BYTES), 'invalid pubdata hash');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_deposit_standard_decimals_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token5: Token = *tokens[utils::TOKEN_T5];
    let token5_dispatcher = IStandardDecimalsTokenDispatcher {
        contract_address: token5.tokenAddress
    };
    let to: ContractAddress = contract_address_const::<
        0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0
    >();
    let subAccountId: u8 = 0;
    let amount: u128 = 30000000; // 30 * 10^6

    set_contract_address(defaultSender);
    token5_dispatcher.mint(10000000000); // 10000 * 10^6
    let senderBalance = token5_dispatcher.balanceOf(defaultSender);
    let contractBalance = token5_dispatcher.balanceOf(zklink);
    token5_dispatcher.approve(zklink, 100000000); // 100 * 10^6
    zklink_dispatcher
        .depositERC20(token5.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    assert(
        token5_dispatcher.balanceOf(zklink) == contractBalance + amount.into(),
        'invalid contract balance'
    );
    assert(
        token5_dispatcher.balanceOf(defaultSender) == senderBalance - amount.into(),
        'invalid sender balance'
    );

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint8","uint16","uint16","uint128","uint256","uint32"]
    // example = [1, 1, 0, 36, 36, 30000000000000000000, 0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0, 0]
    //
    // data = [1334420303785081059294143337929376160, 113529846978955610116163308384424034304, 9073013115197512348337205226446]
    // pending_data = 236022272872492080104996864
    // pending_data_size = 11
    let pubData = Bytes {
        data: array![
            1334420303785081059294143337929376160,
            113529846978955610116163308384424034304,
            9073013115197512348337205226446
        ],
        pending_data: 236022272872492080104996864,
        pending_data_size: 11
    };
    assert(hashedPubdata == pubData.keccak_for_check(DEPOSIT_CHECK_BYTES), 'invalid pubdata hash');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_fullexit_exodus() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let accountId = 13;
    let subAccountId: u8 = 0;
    // exodus
    set_contract_address(defaultSender);
    zklink_dispatcher.setExodus(true);
    zklink_dispatcher.requestFullExit(accountId, subAccountId, eth.tokenId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('a0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_fullexit_accountid_too_large() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let accountId = utils::MAX_ACCOUNT_ID + 1;
    let subAccountId: u8 = 0;

    set_contract_address(defaultSender);
    zklink_dispatcher.requestFullExit(accountId, subAccountId, eth.tokenId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('a1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_fullexit_subaccountid_too_large() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let accountId = 13;
    let subAccountId: u8 = utils::MAX_SUB_ACCOUNT_ID + 1;

    set_contract_address(defaultSender);
    zklink_dispatcher.requestFullExit(accountId, subAccountId, eth.tokenId, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('a2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_fullexit_token_unregistered() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let accountId = 13;
    let subAccountId: u8 = 0;

    set_contract_address(defaultSender);
    zklink_dispatcher.requestFullExit(accountId, subAccountId, 10000, false);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('a3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_fullexit_token_unsupported_mapping() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let accountId = 13;
    let subAccountId: u8 = 0;

    set_contract_address(defaultSender);
    zklink_dispatcher.requestFullExit(accountId, subAccountId, eth.tokenId, true);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_fullexit_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[utils::TOKEN_ETH];
    let accountId = 13;
    let subAccountId: u8 = 0;

    set_contract_address(defaultSender);
    zklink_dispatcher.requestFullExit(accountId, subAccountId, eth.tokenId, false);

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 13, 0, 0x64656661756c7453656e646572, 33, 33, 0]
    //
    // data = [6651332275798830227802555977002123264, 110386672137580, 154623465419847618179872172595872792576]
    // pending_data = 0
    // pending_data_size = 11
    let pubData = Bytes {
        data: array![
            6651332275798830227802555977002123264,
            110386672137580,
            154623465419847618179872172595872792576
        ],
        pending_data: 0,
        pending_data_size: 11
    };
    assert(
        hashedPubdata == pubData.keccak_for_check(FULL_EXIT_CHECK_BYTES), 'invalid pubdata hash'
    );
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_fullexit_mapping_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[utils::ADDR_DEFAULT];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token4: Token = *tokens[utils::TOKEN_T4];
    let accountId = 13;
    let subAccountId: u8 = 0;

    set_contract_address(defaultSender);
    zklink_dispatcher.requestFullExit(accountId, subAccountId, token4.tokenId, true);

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 13, 0, 0x64656661756c7453656e646572, 17, 1, 0]
    //
    // data = [6651332275798830227802555977002123264, 110386672137580, 154623465419847618178719215906893856768]
    // pending_data = 0
    // pending_data_size = 11
    let pubData = Bytes {
        data: array![
            6651332275798830227802555977002123264,
            110386672137580,
            154623465419847618178719215906893856768
        ],
        pending_data: 0,
        pending_data_size: 11
    };
    assert(
        hashedPubdata == pubData.keccak_for_check(FULL_EXIT_CHECK_BYTES), 'invalid pubdata hash'
    );
}
