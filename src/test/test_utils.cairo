use array::ArrayTrait;
use zklink::utils::utils::{
    u8_array_to_u256,
    u128_array_slice,
    u64_array_slice,
    concatHash,
    concatTwoHash,
    pubKeyHash
};
use zklink::utils::bytes::{Bytes, BytesTrait};
use debug::PrintTrait;

#[test]
#[available_gas(20000000000)]
fn test_u8_array_to_u256() {
    let mut array = ArrayTrait::<u8>::new();
    let mut i = 0;
    loop {
        if i == 32 {
            break();
        }
        array.append(i % 8);
        i += 1;
    };

    let res: u256 = u8_array_to_u256(array.span());
    assert(res == 0x0001020304050607000102030405060700010203040506070001020304050607, 'invalid u256');
}

#[test]
#[available_gas(20000000000)]
fn test_u128_array_slice() {
    let mut array = ArrayTrait::<u128>::new();
    array.append(1);
    array.append(2);
    array.append(3);

    let res = u128_array_slice(@array, 0, 2);
    assert(res.len() == 2, 'invalid length 1');
    assert(*res[0] == 1, 'invalid value 1');
    assert(*res[1] == 2, 'invalid value 2');

    let res = u128_array_slice(@array, 1, 3);
    assert(res.len() == 2, 'invalid length 2');
    assert(*res[0] == 2, 'invalid value 1');
    assert(*res[1] == 3, 'invalid value 2');
}

#[test]
#[available_gas(20000000000)]
fn test_u64_array_slice() {
    let mut array = ArrayTrait::<u64>::new();
    array.append(1);
    array.append(2);
    array.append(3);

    let res = u64_array_slice(@array, 0, 2);
    assert(res.len() == 2, 'invalid length 1');
    assert(*res[0] == 1, 'invalid value 1');
    assert(*res[1] == 2, 'invalid value 2');

    let res = u64_array_slice(@array, 1, 3);
    assert(res.len() == 2, 'invalid length 2');
    assert(*res[0] == 2, 'invalid value 1');
    assert(*res[1] == 3, 'invalid value 2');
}

#[test]
#[available_gas(20000000000)]
fn test_concatHash() {
    let hash: u256 = 0xcb1bcb5098bb2f588b82ea341e3b1148b7d1eeea2552d624b30f4240b5b85995;
    let mut array = ArrayTrait::<u128>::new();
    array.append(0x10111213141516171810111213141516);
    array.append(0x17180101020102030400000001000003);
    array.append(0x04050607080000000000000010111213);
    array.append(0x14151617180000000000000001020304);
    array.append(0x05060708090000000000000000000102);
    array.append(0x0304050607015401855d7796176b05d1);
    array.append(0x60196ff92381eb7910f5446c2e0e04e1);
    array.append(0x3db2194a4f0000000000000000000000);

    let bytes: Bytes = BytesTrait::new(117, array);

    let res = concatHash(hash, @bytes);
    assert(res == 0x03f334207a3bf13253da30866be22b0df83fa8257e9eac68969278fe4bc1f5d0, 'invalid hash');
}

#[test]
#[available_gas(20000000000)]
fn test_concatTwoHash() {
    let hash1: u256 = 0xcb1bcb5098bb2f588b82ea341e3b1148b7d1eeea2552d624b30f4240b5b85995;
    let hash2: u256 = 0x03f334207a3bf13253da30866be22b0df83fa8257e9eac68969278fe4bc1f5d0;

    let res = concatTwoHash(hash1, hash2);
    assert(res == 0x8edd237e38318c42a3387e350bd0c3de4581c1e6477f00a0df0a6ded12e70989, 'invalid hash');
}

#[test]
#[available_gas(20000000000)]
fn test_pubKeyHash() {
    let pubKeyHash: felt252 = 0x0bd0c3de4581c1e6477f00a0df0a6ded12e70989;

    let res = pubKeyHash(pubKeyHash);
    assert(res == 0xbf0ce4dca350adf44df47b8833c5f84b87c8208b4323944d3a07311939a1d15f, 'invalid hash');
}