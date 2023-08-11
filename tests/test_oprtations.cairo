use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use cheatcodes::PreparedContract;
use forge_print::PrintTrait;

use zklink::mocks::operations::IOperationsSafeDispatcher;
use zklink::mocks::operations::IOperationsSafeDispatcherTrait;
use zklink::mocks::operations::IOperationsDispatcher;
use zklink::mocks::operations::IOperationsDispatcherTrait;

use zklink::utils::operations::Operations::{
    OperationTrait, Deposit, Withdraw, FullExit, ForcedExit, ChangePubKey
};
use zklink::utils::bytes::{Bytes, BytesTrait};

fn deploy_contract(name: felt252) -> ContractAddress {
    let class_hash = declare(name);
    let prepared = PreparedContract {
        class_hash, constructor_calldata: @ArrayTrait::new()
    };
    deploy(prepared).unwrap()
}

// calculate pubData from Python
// from eth_abi.packed import encode_abi_packed
// data = encode_abi_packed(encode_format, example)
// size = len(data)
// data += b'\x00' * (16 - size % 16)
// data = [int.from_bytes(x, 'big') for x in [data[i:i+16] for i in range(0, len(data), 16)]]


#[test]
fn test_zklink_read_deposit_pubdata() {
    let contract_address = deploy_contract('Operations');
    let dispatcher = IOperationsDispatcher { contract_address };
    let owner: felt252 = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d;

    let _example: Deposit = Deposit {
        chainId:1,
        accountId:13,
        subAccountId:0,
        tokenId:25,
        targetTokenId:23,
        amount:100,
        owner: owner
    };

    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 13, 0, 25, 23, 100, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 59
    // data = [1334420292659166737988792875596382208, 109982469853070, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]

    let mut _pubData: Bytes = BytesTrait::new_empty();
    _pubData.size = 59;
    _pubData.data = array![1334420292659166737988792875596382208, 109982469853070, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000];

    dispatcher.testDepositPubdata(_example, _pubData);
}

#[test]
fn test_zklink_write_deposit_pubdata() {
    let contract_address = deploy_contract('Operations');
    let dispatcher = IOperationsDispatcher { contract_address };
    let owner: felt252 = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d;

    let _example: Deposit = Deposit {
        chainId:1,
        accountId:13,
        subAccountId:0,
        tokenId:25,
        targetTokenId:23,
        amount:100,
        owner: owner
    };

    dispatcher.testWriteDepositPubdata(_example);
}

#[test]
fn test_zklink_read_withdraw_pubdata() {
    let contract_address = deploy_contract('Operations');
    let dispatcher = IOperationsDispatcher { contract_address };
    let owner: ContractAddress = 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d.try_into().unwrap();

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
    _pubData.size = 59;
    _pubData.data = array![3992876284251986964483546870026600448, 35184607447564, 20678471039984701855585286363423409824, 149216281713636543258803496807561166848, 59816172597981541120104732932467326976];

    dispatcher.testWithdrawPubdata(_example, _pubData);
}