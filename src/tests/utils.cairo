use array::ArrayTrait;
use array::SpanTrait;
use core::result::ResultTrait;
use option::OptionTrait;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::ContractAddress;
use starknet::testing;
use starknet::SyscallResultTrait;
use traits::TryInto;
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::utils::constants::CHUNK_BYTES;
use zklink::utils::math::{u128_join, u256_pow2};

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

fn deploy(contract_class_hash: felt252, calldata: Array<felt252>) -> ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        contract_class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap_syscall();
    address
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

fn createOffsetCommitment(ref offsetsCommitment: u256, pubdataOffset: usize, is_onchainOp: bool) {
    if !is_onchainOp {
        return;
    }
    let chunkId = pubdataOffset / CHUNK_BYTES;
    let chunkIdCommitment = u256_pow2(chunkId);
    offsetsCommitment = offsetsCommitment | chunkIdCommitment;
}
