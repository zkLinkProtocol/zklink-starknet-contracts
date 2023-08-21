use core::traits::Into;
use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;

use zklink::tests::mocks::operations_test::OperationsMock;
use zklink::tests::mocks::operations_test::IOperationsMockDispatcher;
use zklink::tests::mocks::operations_test::IOperationsMockDispatcherTrait;
use zklink::utils::operations::Operations::{
    OperationReadTrait, Deposit, Withdraw, FullExit, ForcedExit, ChangePubKey
};
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::tests::utils;

fn deploy_contract() -> IOperationsMockDispatcher {
    let calldata = array![];
    let address = utils::deploy(OperationsMock::TEST_CLASS_HASH, calldata);
    IOperationsMockDispatcher { contract_address: address }
}

// calculate pubData from Python
// from eth_abi.packed import encode_abi_packed
// data = encode_abi_packed(encode_format, example)
// size = len(data)
// data += b'\x00' * (16 - size % 16)
// data = [int.from_bytes(x, 'big') for x in [data[i:i+16] for i in range(0, len(data), 16)]]

#[test]
#[available_gas(20000000000)]
fn test_zklink_read_deposit_pubdata() {
    let dispatcher = deploy_contract();
    let owner: felt252 = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d;

    let _example: Deposit = Deposit {
        chainId: 1,
        accountId: 13,
        subAccountId: 0,
        tokenId: 25,
        targetTokenId: 23,
        amount: 100,
        owner: owner.into()
    };

    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 13, 0, 25, 23, 100, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 59
    // data = [1334420292659166737988792875596382208, 109982469853070, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]

    let mut _pubData: Bytes = BytesTrait::new_empty();
    _pubData.size = 59;
    _pubData
        .data =
            array![
                1334420292659166737988792875596382208,
                109982469853070,
                179892997260459296479640320015568236610,
                3577810954935998486498406173769728000
            ];

    dispatcher.testDepositPubdata(_example, _pubData);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_write_deposit_pubdata() {
    let dispatcher = deploy_contract();
    let owner: felt252 = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d;

    let _example: Deposit = Deposit {
        chainId: 1,
        accountId: 13,
        subAccountId: 0,
        tokenId: 25,
        targetTokenId: 23,
        amount: 100,
        owner: owner.into()
    };

    dispatcher.testWriteDepositPubdata(_example);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_read_withdraw_pubdata() {
    let dispatcher = deploy_contract();
    let owner: ContractAddress = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d
        .try_into()
        .unwrap();

    let _example: Withdraw = Withdraw {
        chainId: 1,
        accountId: 32,
        subAccountId: 4,
        tokenId: 34,
        amount: 32,
        owner: owner,
        nonce: 45,
        fastWithdrawFeeRate: 45,
        fastWithdraw: 1
    };

    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8"]
    // example = [3, 1, 32, 4, 34, 34, 32, 14, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d, 45, 45, 1]
    //
    // size = 68
    // data = [3992876284251986964483546870026600448, 35184607447564, 20678471039984701855585286363423409824, 149216281713636543258803496807561166848, 59816172597981541120104732932467326976]

    let mut _pubData: Bytes = BytesTrait::new_empty();
    _pubData.size = 68;
    _pubData
        .data =
            array![
                3992876284251986964483546870026600448,
                35184607447564,
                20678471039984701855585286363423409824,
                149216281713636543258803496807561166848,
                59816172597981541120104732932467326976
            ];

    dispatcher.testWithdrawPubdata(_example, _pubData);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_read_fullexit_pubdata() {
    let dispatcher = deploy_contract();
    let owner: ContractAddress = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d
        .try_into()
        .unwrap();

    let _example: FullExit = FullExit {
        chainId: 1,
        accountId: 34,
        subAccountId: 23,
        owner: owner,
        tokenId: 2,
        srcTokenId: 1,
        amount: 15
    };

    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 34, 23, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d, 2, 1, 15]
    //
    // size = 59
    // data = [6651332275824326418906434470835265930, 200395919779929312501285245198324010931, 6100388676413382880207601728340623360, 16492674416640]

    let mut _pubData: Bytes = BytesTrait::new_empty();
    _pubData.size = 59;
    _pubData
        .data =
            array![
                6651332275824326418906434470835265930,
                200395919779929312501285245198324010931,
                6100388676413382880207601728340623360,
                16492674416640
            ];

    dispatcher.testFullExitPubdata(_example, _pubData);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_write_fullexit_pubdata() {
    let dispatcher = deploy_contract();
    let owner: ContractAddress = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d
        .try_into()
        .unwrap();

    let _example: FullExit = FullExit {
        chainId: 1,
        accountId: 34,
        subAccountId: 23,
        owner: owner,
        tokenId: 2,
        srcTokenId: 1,
        amount: 15
    };

    dispatcher.testWriteFullExitPubdata(_example);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_read_forceexit_pubdata() {
    let dispatcher = deploy_contract();
    let target: ContractAddress = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d
        .try_into()
        .unwrap();

    let _example: ForcedExit = ForcedExit {
        chainId: 1,
        initiatorAccountId: 2,
        initiatorSubAccountId: 1,
        initiatorNonce: 5,
        targetAccountId: 3,
        tokenId: 5,
        amount: 6,
        target: target
    };

    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [7, 1, 2, 1, 5, 3, 4, 5, 5, 6, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 68
    // data = [9309788267355368511960897543844397828, 25961880433486709464340449365852160, 477624887620356151319952016089, 227142569737839188506614686513323349732, 130444596926336721081525902839130357760]

    let mut _pubData: Bytes = BytesTrait::new_empty();
    _pubData.size = 68;
    _pubData
        .data =
            array![
                9309788267355368511960897543844397828,
                25961880433486709464340449365852160,
                477624887620356151319952016089,
                227142569737839188506614686513323349732,
                130444596926336721081525902839130357760
            ];

    dispatcher.testForcedExitPubdata(_example, _pubData);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_read_changepubkey_pubdata() {
    let dispatcher = deploy_contract();
    let pubKeyHash: felt252 = 0x823B747710C5bC9b8A47243f2c3d1805F1aA00c5;
    let owner: ContractAddress = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d
        .try_into()
        .unwrap();

    let _example: ChangePubKey = ChangePubKey {
        chainId: 1, accountId: 2, pubKeyHash: pubKeyHash, owner: owner, nonce: 3
    };

    // encode_format = ["uint8","uint8","uint32","uint8","uint160","uint256","uint32","uint16","uint16"]
    // example = [6, 1, 2, 3, 0x823B747710C5bC9b8A47243f2c3d1805F1aA00c5, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d, 3, 4, 5]
    //
    // size = 67
    // data = [7980560271570464486150960366994889610, 94563391684388089342185505966699319182, 179892997260459296479640320015568236610, 3577810954935998486498406173769728768, 5317013395187681749967347977377808384]

    let mut _pubData: Bytes = BytesTrait::new_empty();
    _pubData.size = 67;
    _pubData
        .data =
            array![
                7980560271570464486150960366994889610,
                94563391684388089342185505966699319182,
                179892997260459296479640320015568236610,
                3577810954935998486498406173769728768,
                5317013395187681749967347977377808384
            ];

    dispatcher.testChangePubkeyPubdata(_example, _pubData);
}
