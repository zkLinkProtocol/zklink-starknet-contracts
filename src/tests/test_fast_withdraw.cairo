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
use zklink::utils::operations::Operations::Withdraw;

#[test]
#[available_gas(20000000000)]
fn test_zklink_normal_withdraw_erc20_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

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

    let b0 = token2_dispatcher.balanceOf(owner);
    zklink_dispatcher.testExecuteWithdraw(op);
    zklink_dispatcher.withdrawPendingBalance(owner, tokenId, amount);
    let b1 = token2_dispatcher.balanceOf(owner);
    assert(b1 - b0 == amount.into(), 'balance');
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
fn test_zklink_fast_withdraw_and_not_accept_success() {
    // fast withdraw but accept not finish, token should be sent to owner as normal
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token2: Token = *tokens[utils::TOKEN_T2];
    let token2_dispatcher = IStandardTokenDispatcher { contract_address: token2.tokenAddress };

    let chainId: u8 = 1;
    let accountId: u32 = 1;
    let subAccountId: u8 = 1;
    let tokenId: u16 = token2.tokenId;
    let amount: u128 = 10000000000000000000; // 10 Ether
    let owner: ContractAddress = alice;
    let nonce: u32 = 2;
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

    let b0 = token2_dispatcher.balanceOf(owner);
    zklink_dispatcher.testExecuteWithdraw(op);
    zklink_dispatcher.withdrawPendingBalance(owner, tokenId, amount);
    let b1 = token2_dispatcher.balanceOf(owner);
    assert(b1 - b0 == amount.into(), 'balance');

    // encode_format = ["uint32","uint8","uint32", "uint256","uint256","uint128","uint16"]
    // example = [1, 1, 2, 0x616c696365, 0x4, 10000000000000000000, 50]
    //
    // data = [79537647524229797850344587264, 0, 30151107623175033224995799040, 0, 288230376151711744]
    // pending_data = 655360000000000000000050
    // pending_data_size = 11
    let pubdata = Bytes {
        data: array![
            79537647524229797850344587264, 0, 30151107623175033224995799040, 0, 288230376151711744
        ],
        pending_data: 655360000000000000000050,
        pending_data_size: 11
    };
    let hash = pubdata.keccak();
    let address = zklink_dispatcher.getAcceptor(hash);
    assert(address == owner, 'acceptor');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_fast_withdraw_and_accept_success() {
    let (addrs, tokens) = utils::prepare_test_deploy();
    let alice = *addrs[utils::ADDR_ALICE];
    let bob = *addrs[utils::ADDR_BOB];
    let zklink = *addrs[utils::ADDR_ZKLINK];
    let zklink_dispatcher = IZklinkMockDispatcher { contract_address: zklink };
    let token5: Token = *tokens[utils::TOKEN_T5];
    let token5_dispatcher = IStandardDecimalsTokenDispatcher {
        contract_address: token5.tokenAddress
    };

    let chainId: u8 = 1;
    let accountId: u32 = 1;
    let subAccountId: u8 = 1;
    let l1Amount: u128 = 10000000; // 10 Ether
    let l2Amount: u128 = 10000000000000000000; // 10 Ether
    let owner: ContractAddress = alice;
    let nonce: u32 = 1;
    let fastWithdrawFeeRate: u16 = 50;
    let withdrawToL1: u8 = 0;

    let bobBalance0 = token5_dispatcher.balanceOf(bob);
    let bobPendingBalance0 = zklink_dispatcher
        .getPendingBalance(utils::extendAddress(bob), token5.tokenId);
    let aliceBalance0 = token5_dispatcher.balanceOf(alice);

    token5_dispatcher.mintTo(bob, l1Amount.into());
    let amountTransfer = l1Amount
        * (utils::MAX_ACCEPT_FEE_RATE - fastWithdrawFeeRate).into()
        / utils::MAX_ACCEPT_FEE_RATE.into();
    set_contract_address(bob);
    token5_dispatcher.approve(zklink, amountTransfer.into());
    zklink_dispatcher
        .acceptERC20(
            owner,
            token5.tokenAddress,
            l1Amount,
            fastWithdrawFeeRate,
            accountId,
            subAccountId,
            nonce
        );

    let op = Withdraw {
        chainId,
        accountId,
        subAccountId,
        tokenId: token5.tokenId,
        amount: l2Amount,
        owner,
        nonce,
        fastWithdrawFeeRate,
        withdrawToL1
    };
    zklink_dispatcher.testExecuteWithdraw(op);

    let aliceBalance1 = token5_dispatcher.balanceOf(alice);
    let bobBalance1 = token5_dispatcher.balanceOf(bob);
    let bobPendingBalance1 = zklink_dispatcher
        .getPendingBalance(utils::extendAddress(bob), token5.tokenId);

    assert(
        aliceBalance1 - aliceBalance0 == amountTransfer.into(), 'alice balance'
    ); // owner receive amountTransfer = l1Amount - fee
    assert(
        bobBalance1 - bobBalance0 == (l1Amount - amountTransfer).into(), 'bob balance'
    ); // l1Amount - amountTransfer is the profit of acceptor
    assert(
        bobPendingBalance1 - bobPendingBalance0 == l2Amount.into(), 'bob pending balance'
    ); // acceptor pending balance increase
}
