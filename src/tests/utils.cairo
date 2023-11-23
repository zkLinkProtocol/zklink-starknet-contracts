use core::traits::Destruct;
use array::ArrayTrait;
use array::SpanTrait;
use core::result::ResultTrait;
use option::OptionTrait;
use clone::Clone;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::{ContractAddress, contract_address_const};
use starknet::SyscallResultTrait;
use traits::{TryInto, Into};
use starknet::testing;
use test::test_utils::assert_eq;
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::utils::constants::CHUNK_BYTES;
use zklink::utils::math::u128_join;
use zklink::contracts::zklink::Zklink;
use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::tests::mocks::standard_token::StandardToken;
use zklink::tests::mocks::camel_standard_token::CamelStandardToken;
use zklink::tests::mocks::standard_decimals_token::StandardDecimalsToken;
use zklink::tests::mocks::verifier_test::VerifierMock;

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
const OP_FORCE_EXIT_SIZE: usize = 69;
const OP_ORDER_MATCHING_SIZE: usize = 77;
const BYTES_PER_ELEMENT: usize = 16;
const GENESIS_ROOT: u256 = 0x209d742ecb062db488d20e7f8968a40673d718b24900ede8035e05a78351d956;
const EMPTY_STRING_KECCAK: u256 =
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
const MAX_SUB_ACCOUNT_ID: u8 = 31;
const MAX_ACCOUNT_ID: u32 = 16777215;
const MAX_ACCEPT_FEE_RATE: u16 = 10000;


fn deploy(contract_class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        contract_class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap_syscall();
    address
}

fn pop_log<T, impl TDrop: Drop<T>, impl TEvent: starknet::Event<T>>(
    address: ContractAddress
) -> Option<T> {
    let (mut keys, mut data) = testing::pop_log_raw(address)?;

    // Remove the event ID from the keys
    keys.pop_front();

    let ret = starknet::Event::deserialize(ref keys, ref data);
    assert(data.is_empty(), 'Event has extra data');
    assert(keys.is_empty(), 'Event has extra keys');
    ret
}

fn assert_no_events_left(address: ContractAddress) {
    assert(testing::pop_log_raw(address).is_none(), 'Events remaining on queue');
}

fn drop_event(address: ContractAddress) {
    testing::pop_log_raw(address);
}

fn assert_event_Accept(
    zklink: ContractAddress,
    _acceptor: ContractAddress,
    _receiver: ContractAddress,
    _tokenId: u16,
    _amount: u128,
    _withdrawFeeRate: u16,
    _accountIdOfNonce: u32,
    _subAccountIdOfNonce: u8,
    _nonce: u32,
    _amountReceive: u128
) {
    let event = pop_log::<Zklink::Accept>(zklink).unwrap();
    assert(event.acceptor == _acceptor, 'acceptor');
    assert(event.receiver == _receiver, 'receiver');
    assert(event.tokenId == _tokenId, 'tokenId');
    assert(event.amount == _amount, 'amount');
    assert(event.withdrawFeeRate == _withdrawFeeRate, 'withdrawFeeRate');
    assert(event.accountIdOfNonce == _accountIdOfNonce, 'accountIdOfNonce');
    assert(event.subAccountIdOfNonce == _subAccountIdOfNonce, 'subAccountIdOfNonce');
    assert(event.nonce == _nonce, 'nonce');
    assert(event.amountReceive == _amountReceive, 'amountReceive');
    assert_no_events_left(zklink);
}

fn assert_event_ExodusMode(zklink: ContractAddress, exodusMode: bool) {
    let event = pop_log::<Zklink::ExodusMode>(zklink).unwrap();
    assert(event.exodusMode == exodusMode, 'ExodusMode Emit');
    assert_no_events_left(zklink);
}

fn assert_event_WithdrawalPending(
    zklink: ContractAddress, _tokenId: u16, _recepient: u256, _amount: u128
) {
    let event = pop_log::<Zklink::WithdrawalPending>(zklink).unwrap();
    assert(event.tokenId == _tokenId, 'tokenId');
    assert(event.recepient == _recepient, 'recepient');
    assert(event.amount == _amount, 'amount');
}

fn assert_event_Withdrawal(zklink: ContractAddress, _tokenId: u16, _amount: u128) {
    let event = pop_log::<Zklink::Withdrawal>(zklink).unwrap();
    assert(event.tokenId == _tokenId, 'tokenId');
    assert(event.amount == _amount, 'amount');
    assert_no_events_left(zklink);
}

#[derive(Clone, Copy, Serde, Drop)]
struct Token {
    tokenId: u16,
    tokenAddress: ContractAddress
}

const TOKEN_ETH: usize = 0;
const TOKEN_T2: usize = 1;
const TOKEN_T4: usize = 2;
const TOKEN_T5: usize = 3;
const TOKEN_T6: usize = 4;

const ADDR_DEFAULT: usize = 0;
const ADDR_GOVERNOR: usize = 1;
const ADDR_VALIDATOR: usize = 2;
const ADDR_FEE_ACCOUNT: usize = 3;
const ADDR_ALICE: usize = 4;
const ADDR_BOB: usize = 5;
const ADDR_ZKLINK: usize = 6;
const ADDR_VERIFIER: usize = 7;

fn prepare_test_deploy() -> (Array<ContractAddress>, Array<Token>) {
    // cairo test will auto generate contract address
    // The first deployed contact address is 0x1, and the second is 0x2, and so on.
    // So, we need to set the account address manually.

    // users, address equals var name hex value
    // string = 'governor'
    // hex_value = hex(int.from_bytes(string.encode(), 'big'))
    let defaultSender: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();
    let governor: ContractAddress = contract_address_const::<0x676f7665726e6f72>();
    let validator: ContractAddress = contract_address_const::<0x76616c696461746f72>();
    let feeAccount: ContractAddress = contract_address_const::<0x6665654163636f756e74>();
    let alice: ContractAddress = contract_address_const::<0x616c696365>();
    let bob: ContractAddress = contract_address_const::<0x626f62>();

    // verifier
    let verifier: ContractAddress = deploy(VerifierMock::TEST_CLASS_HASH, array![]);
    // zklink
    let calldata = array![
        defaultSender.into(), // master
        verifier.into(), // verifier
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
        tokenId: 33, tokenAddress: deploy(StandardToken::TEST_CLASS_HASH, array!['Ether', 'ETH'])
    };
    dispatcher.addToken(eth.tokenId, eth.tokenAddress, 18);
    drop_event(zklink);

    let token2 = Token {
        tokenId: 34, tokenAddress: deploy(StandardToken::TEST_CLASS_HASH, array!['Token2', 'T2'])
    };
    dispatcher.addToken(token2.tokenId, token2.tokenAddress, 18);
    drop_event(zklink);

    let token4 = Token {
        tokenId: 17, tokenAddress: deploy(StandardToken::TEST_CLASS_HASH, array!['Token4', 'T4'])
    };
    dispatcher.addToken(token4.tokenId, token4.tokenAddress, 18);
    drop_event(zklink);

    let token5 = Token {
        tokenId: 36,
        tokenAddress: deploy(StandardDecimalsToken::TEST_CLASS_HASH, array!['Token5', 'T5', 6])
    };
    dispatcher.addToken(token5.tokenId, token5.tokenAddress, 6);
    drop_event(zklink);

    let token6 = Token {
        tokenId: 37,
        tokenAddress: deploy(CamelStandardToken::TEST_CLASS_HASH, array!['Token6', 'T6'])
    };
    dispatcher.addToken(token6.tokenId, token6.tokenAddress, 18);
    drop_event(zklink);

    let address: Array<ContractAddress> = array![
        defaultSender, governor, validator, feeAccount, alice, bob, zklink, verifier
    ];

    let tokens: Array<Token> = array![eth, token2, token4, token5, token6];

    (address, tokens)
}

fn paddingChunk(ref pubdata: Bytes, chunks: usize) {
    let mut zeroPadding = CHUNK_BYTES * chunks - pubdata.size();
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
