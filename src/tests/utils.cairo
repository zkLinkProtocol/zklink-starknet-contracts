use array::ArrayTrait;
use array::SpanTrait;
use core::result::ResultTrait;
use option::OptionTrait;
use clone::Clone;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::{ContractAddress, contract_address_const};
use starknet::SyscallResultTrait;
use traits::{TryInto, Into};
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::utils::constants::CHUNK_BYTES;
use zklink::utils::math::u128_join;

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

const OP_NOOP: u8 = 0;
const OP_DEPOSIT: u8 = 1;
const OP_TRANSFER_TO_NEW: u8 = 2;
const OP_WITHDRAW: u8 = 3;
const OP_TRANSFER: u8 = 4;
const OP_FULL_EXIT: u8 = 5;
const OP_CHANGE_PUBKEY: u8 = 6;
const OP_FORCE_EXIT: u8 = 7;
const OP_ORDER_MATCHING: u8 = 11;
const OP_NOOP_CHUNKS: usize = 1;
const OP_DEPOSIT_CHUNKS: usize = 3;
const OP_TRANSFER_TO_NEW_CHUNKS: usize = 3;
const OP_WITHDRAW_CHUNKS: usize = 3;
const OP_TRANSFER_CHUNKS: usize = 2;
const OP_FULL_EXIT_CHUNKS: usize = 3;
const OP_CHANGE_PUBKEY_CHUNKS: usize = 3;
const OP_FORCE_EXIT_CHUNKS: usize = 3;
const OP_ORDER_MATCHING_CHUNKS: usize = 4;
const OP_DEPOSIT_SIZE: usize = 59;
const OP_TRANSFER_TO_NEW_SIZE: usize = 52;
const OP_WITHDRAW_SIZE: usize = 68;
const OP_TRANSFER_SIZE: usize = 20;
const OP_FULL_EXIT_SIZE: usize = 59;
const OP_CHANGE_PUBKEY_SIZE: usize = 67;
const OP_FORCE_EXIT_SIZE: usize = 68;
const OP_ORDER_MATCHING_SIZE: usize = 77;
const BYTES_PER_ELEMENT: usize = 16;
const GENESIS_ROOT: u256 = 0x209d742ecb062db488d20e7f8968a40673d718b24900ede8035e05a78351d956;
const EMPTY_STRING_KECCAK: u256 =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;


fn deploy(contract_class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        contract_class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap_syscall();
    address
}

#[derive(Clone, Copy, Serde, Drop)]
struct Token {
    tokenId: u16,
    tokenAddress: ContractAddress
}

fn prepare_test_deploy() -> (Array<ContractAddress>, Array<Token>) {
    // users
    let defaultSender: ContractAddress = contract_address_const::<1>();
    let governor: ContractAddress = contract_address_const::<2>();
    let validator: ContractAddress = contract_address_const::<3>();
    let feeAccount: ContractAddress = contract_address_const::<4>();
    let alice: ContractAddress = contract_address_const::<5>();
    let bob: ContractAddress = contract_address_const::<6>();

    // zklink
    let calldata = array![
        7, // verifier
        2, // governor
        0, // blockNumber
        0, // timestamp
        GENESIS_ROOT.low.into(), // stateHash low
        GENESIS_ROOT.high.into(), // stateHash high
        0, // commitment low
        0, // commitment high
        EMPTY_STRING_KECCAK.low.into(), // syncHash low
        EMPTY_STRING_KECCAK.high.into(), // syncHash high
    ];
    let zklink: ContractAddress = deploy(ZklinkMock::TEST_CLASS_HASH, calldata);
    let dispatcher = IZklinkMockDispatcher { contract_address: zklink };

    // tokens
    let eth = Token {
        tokenId: 33,
        tokenAddress: contract_address_const::<0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7>()
    };
    dispatcher.addToken(eth.tokenId, eth.tokenAddress, 18, true);

    let token2 = Token {
        tokenId: 34, tokenAddress: deploy(StandardToken::TEST_CLASS_HASH, array!['Token2', 'T2'])
    };
    dispatcher.addToken(token2.tokenId, token2.tokenAddress, 18, true);

    let token3 = Token {
        tokenId: 35, tokenAddress: deploy(NonStandardToken::TEST_CLASS_HASH, array!['Token3', 'T3'])
    };
    dispatcher.addToken(token3.tokenId, token3.tokenAddress, 18, false);

    let token4 = Token {
        tokenId: 17, tokenAddress: deploy(StandardToken::TEST_CLASS_HASH, array!['Token4', 'T4'])
    };
    dispatcher.addToken(token4.tokenId, token4.tokenAddress, 18, true);

    let token5 = Token {
        tokenId: 36,
        tokenAddress: deploy(StandardDecimalsToken::TEST_CLASS_HASH, array!['Token5', 'T5', 6])
    };
    dispatcher.addToken(token5.tokenId, token5.tokenAddress, 6, true);

    let address: Array<ContractAddress> = array![
        defaultSender, governor, validator, feeAccount, alice, bob, zklink
    ];

    let tokens: Array<Token> = array![eth, token2, token3, token4, token5];

    (address, tokens)
}

fn paddingChunk(ref pubdata: Bytes, chunks: usize) {
    let mut zeroPadding = CHUNK_BYTES * chunks - pubdata.size;
    loop {
        if zeroPadding == 0 {
            break;
        }
        pubdata.append_u8(0);
        zeroPadding -= 1;
    }
}

fn createOffsetCommitment(ref offsetsCommitment: Bytes, opPadding: @Bytes, is_onchainOp: bool) {
    let chunk_size = opPadding.size() / CHUNK_BYTES;
    let mut commitment: u128 = if is_onchainOp {
        0x01
    } else {
        0x00
    };

    let mut i = 1;
    loop {
        if i == chunk_size {
            break;
        }
        commitment = u128_join(commitment, 0x00, 1);
        i += 1;
    };

    offsetsCommitment.append_u128_packed(commitment, chunk_size);
}

fn extendAddress(_address: ContractAddress) -> u256 {
    let address: felt252 = _address.into();
    address.into()
}
