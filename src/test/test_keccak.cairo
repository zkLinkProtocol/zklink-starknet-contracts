use array::ArrayTrait;
use zklink::utils::keccak::keccak_u128s_be;
use debug::PrintTrait;


#[test]
#[available_gas(2000000)]
fn test_keccak_u128s_be() {
    let mut array: Array<u128> = ArrayTrait::<u128>::new();
    let res: u256 = keccak_u128s_be(array.span());
    let hash: u256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assert(res == hash, 'keccak_0_wrong');

    array.append(0);
    array.append(1);

    // 0x0000000000000000000000000000000000000000000000000000000000000001
    let res: u256 = keccak_u128s_be(array.span());
    let hash: u256 = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;

    assert(res == hash, 'keccak_1_wrong');

    array.append(0);
    array.append(2);
    array.append(0);
    array.append(3);
    array.append(0);
    array.append(4);

    // 0x0000000000000000000000000000000000000000000000000000000000000001
    // 0x0000000000000000000000000000000000000000000000000000000000000002
    // 0x0000000000000000000000000000000000000000000000000000000000000003
    // 0x0000000000000000000000000000000000000000000000000000000000000004
    let res: u256 = keccak_u128s_be(array.span());
    let hash: u256 = 0x392791df626408017a264f53fde61065d5a93a32b60171df9d8a46afdf82992d;
    assert(res == hash, 'keccak_2_wrong');

    // 0x10111213141516171810111213141516
    // 0x17180101020102030400000001000003
    // 0x04050607080000000000000010111213
    // 0x14151617180000000000000001020304
    // 0x05060708090000000000000000000102
    // 0x0304050607015401855d7796176b05d1
    // 0x60196ff92381eb7910f5446c2e0e04e1
    // 0x3db2194a4f
    let mut array: Array<u128> = ArrayTrait::<u128>::new();
    array.append(0x10111213141516171810111213141516);
    array.append(0x17180101020102030400000001000003);
    array.append(0x04050607080000000000000010111213);
    array.append(0x14151617180000000000000001020304);
    array.append(0x05060708090000000000000000000102);
    array.append(0x0304050607015401855d7796176b05d1);
    array.append(0x60196ff92381eb7910f5446c2e0e04e1);
    array.append(0x3db2194a4f);

    let res: u256 = keccak_u128s_be(array.span());
    let hash: u256 = 0xcb1bcb5098bb2f588b82ea341e3b1148b7d1eeea2552d624b30f4240b5b85995;
    assert(res == hash, 'keccak_3_wrong');
}