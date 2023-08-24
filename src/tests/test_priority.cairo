use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
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
use zklink::utils::bytes::{Bytes, BytesTrait};


#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_eth_exodus() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];

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

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('e3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_deposit_token_unregisted() {
    let (addrs, _) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token_address: ContractAddress = utils::deploy(
        StandardToken::TEST_CLASS_HASH, array!['Token not registered', 'TNR']
    );
    let token_dispatcher = IStandardTokenDispatcher { contract_address: token_address };
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
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
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
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
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
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
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
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
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
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
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let eth: Token = *tokens[0];
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
    let subAccountId: u8 = utils::MAX_SUB_ACCOUNT_ID + 1;
    let amount: u128 = 1000000000000000000;

    set_contract_address(defaultSender);
    zklink_dispatcher
        .depositERC20(eth.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
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
fn test_zklink_deposit_standard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[1];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
    let subAccountId: u8 = 0;
    let amount: u128 = 30;

    set_contract_address(defaultSender);
    token2_dispatcher.mint(10000);
    let senderBalance = token2_dispatcher.balance_of(defaultSender);
    let contractBalance = token2_dispatcher.balance_of(zklink);
    token2_dispatcher.approve(zklink, 100);
    zklink_dispatcher
        .depositERC20(token2.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    assert(
        token2_dispatcher.balance_of(zklink) == contractBalance + amount.into(),
        'invalid contract balance'
    );
    assert(
        token2_dispatcher.balance_of(defaultSender) == senderBalance - amount.into(),
        'invalid sender balance'
    );

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 34, 34, 30, 0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0]
    //
    // size 59
    // data = [1334420292643450702982333137294458880, 32985348833280, 2112475483491437590759, 179721859689502125521965815952033447936]
    let pubData: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643450702982333137294458880,
            32985348833280,
            2112475483491437590759,
            179721859689502125521965815952033447936
        ]
    );
    assert(hashedPubdata == pubData.keccak(), 'invalid pubdata hash');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_deposit_nonstandard_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token3: Token = *tokens[2];
    let token3_dispatcher = IStandardTokenDispatcher { contract_address: token3.tokenAddress };
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
    let subAccountId: u8 = 0;
    let amount: u128 = 30;
    let senderFee = 3; // 30 * 0.1
    let receiverFee = 6; // 30 * 0.2

    set_contract_address(defaultSender);
    token3_dispatcher.mint(10000);
    let senderBalance = token3_dispatcher.balance_of(defaultSender);
    let contractBalance = token3_dispatcher.balance_of(zklink);
    token3_dispatcher.approve(zklink, 100);
    zklink_dispatcher
        .depositERC20(token3.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    assert(
        token3_dispatcher.balance_of(zklink) == contractBalance
            + (amount.into() - receiverFee.into()),
        'invalid contract balance'
    );
    assert(
        token3_dispatcher.balance_of(defaultSender) == senderBalance
            - (amount.into() + senderFee.into()),
        'invalid sender balance'
    );

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 35, 35, 24, 0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0]
    //
    // size 59
    // data = [1334420292643450703054391830844014592, 26388279066624, 2112475483491437590759, 179721859689502125521965815952033447936]
    let pubData: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643450703054391830844014592,
            26388279066624,
            2112475483491437590759,
            179721859689502125521965815952033447936
        ]
    );
    assert(hashedPubdata == pubData.keccak(), 'invalid pubdata hash');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_deposit_erc20_mapping_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token4: Token = *tokens[3];
    let token4_dispatcher = IStandardTokenDispatcher { contract_address: token4.tokenAddress };
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
    let subAccountId: u8 = 0;
    let amount: u128 = 30;

    set_contract_address(defaultSender);
    token4_dispatcher.mint(10000);
    let senderBalance = token4_dispatcher.balance_of(defaultSender);
    let contractBalance = token4_dispatcher.balance_of(zklink);
    token4_dispatcher.approve(zklink, 100);
    zklink_dispatcher
        .depositERC20(token4.tokenAddress, amount, utils::extendAddress(to), subAccountId, true);
    assert(
        token4_dispatcher.balance_of(zklink) == contractBalance + amount.into(),
        'invalid contract balance'
    );
    assert(
        token4_dispatcher.balance_of(defaultSender) == senderBalance - amount.into(),
        'invalid sender balance'
    );

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 17, 1, 30, 0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0]
    //
    // size 59
    // data = [1334420292643450701757317754765967360, 32985348833280, 2112475483491437590759, 179721859689502125521965815952033447936]
    let pubData: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643450701757317754765967360,
            32985348833280,
            2112475483491437590759,
            179721859689502125521965815952033447936
        ]
    );
    assert(hashedPubdata == pubData.keccak(), 'invalid pubdata hash');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_deposit_standard_decimals_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let defaultSender = *addrs[0];
    let zklink = *addrs[6];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token5: Token = *tokens[4];
    let token5_dispatcher = IStandardTokenDispatcher { contract_address: token5.tokenAddress };
    let to: ContractAddress =
        contract_address_const::<0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0>();
    let subAccountId: u8 = 0;
    let amount: u128 = 30000000; // 30 * 10^6

    set_contract_address(defaultSender);
    token5_dispatcher.mint(10000000000); // 10000 * 10^6
    let senderBalance = token5_dispatcher.balance_of(defaultSender);
    let contractBalance = token5_dispatcher.balance_of(zklink);
    token5_dispatcher.approve(zklink, 100000000); // 100 * 10^6
    zklink_dispatcher
        .depositERC20(token5.tokenAddress, amount, utils::extendAddress(to), subAccountId, false);
    assert(
        token5_dispatcher.balance_of(zklink) == contractBalance + amount.into(),
        'invalid contract balance'
    );
    assert(
        token5_dispatcher.balance_of(defaultSender) == senderBalance - amount.into(),
        'invalid sender balance'
    );

    let hashedPubdata = zklink_dispatcher.getPriorityHash(0);
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 36, 36, 30000000000000000000, 0x72847C8Bdc54b338E787352bceC33ba90cD7aFe0]
    //
    // size 59
    // data = [1334420292643450703126450524393570304, 32985348833280000000000000000000, 2112475483491437590759, 179721859689502125521965815952033447936]
    let pubData: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643450703126450524393570304,
            32985348833280000000000000000000,
            2112475483491437590759,
            179721859689502125521965815952033447936
        ]
    );
    assert(hashedPubdata == pubData.keccak(), 'invalid pubdata hash');
}
