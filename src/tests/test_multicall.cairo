use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::{TryInto, Into};
use clone::Clone;
use debug::PrintTrait;
use serde::Serde;
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
use zklink::contracts::multicall::Multicall;
use zklink::contracts::multicall::IMulticallDispatcher;
use zklink::contracts::multicall::IMulticallDispatcherTrait;
use zklink::contracts::multicall::{Call, MulticallResult};
use zklink::tests::utils;
use zklink::tests::utils::Token;
use zklink::utils::data_structures::DataStructures::StoredBlockInfo;
use zklink::utils::operations::Operations::Withdraw;


#[test]
#[available_gas(20000000000)]
fn test_zklink_multicall_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };
    let multicall = utils::deploy(Multicall::TEST_CLASS_HASH, array![]);

    let chainId: u8 = 1;
    let accountId: u32 = 1;
    let subAccountId: u8 = 1;
    let tokenId: u16 = token2.tokenId;
    let amount: u128 = 10000000000000000000; // 10 Ether
    let owner: ContractAddress = bob;
    let nonce: u32 = 0;
    let fastWithdrawFeeRate: u16 = 50;
    let withdrawToL1: u8 = 0;
    let op = Withdraw {
        chainId,
        accountId,
        subAccountId,
        tokenId,
        amount,
        owner,
        nonce,
        fastWithdrawFeeRate,
        withdrawToL1
    };

    token2_dispatcher.mintTo(zklink, amount.into());

    zklink_dispatcher.testExecuteWithdraw(op);

    let mut i = 10;
    let mut targets: Array<ContractAddress> = array![];
    let mut calls: Array<Call> = array![];
    loop {
        if i == 0 {
            break;
        }
        targets.append(zklink);

        let mut calldata: Array<felt252> = array![];
        let address: u256 = utils::extendAddress(owner);
        Serde::serialize(@address.low, ref calldata);
        Serde::serialize(@address.high, ref calldata);
        Serde::serialize(@tokenId, ref calldata);
        calls.append(Call { selector: selector!("getPendingBalance"), calldata });
        i -= 1;
    };

    let mut res = IMulticallDispatcher { contract_address: multicall }.multicall(targets, calls);
    loop {
        match res.pop_front() {
            Option::Some(result) => {
                let MulticallResult{success, returnData } = result;
                assert(success == true, 'invalid bool');
                assert(returnData.len() == 1, 'invalid return data length');
                assert(*returnData[0] == amount.into(), 'invalid return data');
            },
            Option::None(_) => { break; }
        }
    }
}
