use array::ArrayTrait;

use zklink_starknet_utils::bytes::{Bytes, BytesTrait};

use zklink::utils::utils::{concatHash, concatTwoHash, pubKeyHash};


#[test]
#[available_gas(20000000000)]
fn test_concatHash() {
    let hash: u256 = 0xcb1bcb5098bb2f588b82ea341e3b1148b7d1eeea2552d624b30f4240b5b85995;
    let mut bytes = BytesTrait::new();
    bytes.append_u128(0x10111213141516171810111213141516);
    bytes.append_u128(0x17180101020102030400000001000003);
    bytes.append_u128(0x04050607080000000000000010111213);
    bytes.append_u128(0x14151617180000000000000001020304);
    bytes.append_u128(0x05060708090000000000000000000102);
    bytes.append_u128(0x0304050607015401855d7796176b05d1);
    bytes.append_u128(0x60196ff92381eb7910f5446c2e0e04e1);
    bytes.append_u128_packed(0x3db2194a4f, 5);

    let res = concatHash(hash, @bytes);
    assert(
        res == 0x03f334207a3bf13253da30866be22b0df83fa8257e9eac68969278fe4bc1f5d0, 'invalid hash'
    );
}

#[test]
#[available_gas(20000000000)]
fn test_concatTwoHash() {
    let hash1: u256 = 0xcb1bcb5098bb2f588b82ea341e3b1148b7d1eeea2552d624b30f4240b5b85995;
    let hash2: u256 = 0x03f334207a3bf13253da30866be22b0df83fa8257e9eac68969278fe4bc1f5d0;

    let res = concatTwoHash(hash1, hash2);
    assert(
        res == 0x8edd237e38318c42a3387e350bd0c3de4581c1e6477f00a0df0a6ded12e70989, 'invalid hash'
    );
}

#[test]
#[available_gas(20000000000)]
fn test_pubKeyHash() {
    let pubKeyHash: felt252 = 0x0bd0c3de4581c1e6477f00a0df0a6ded12e70989;

    let res = pubKeyHash(pubKeyHash);
    assert(
        res == 0xbf0ce4dca350adf44df47b8833c5f84b87c8208b4323944d3a07311939a1d15f, 'invalid hash'
    );
}
