use zklink::utils::math::{
    felt252_fast_pow2,
    u128_fast_pow2,
    usize_div_rem,
    u128_div_rem,
    u128_join,
    u128_split,
    u128_sub_value,
    u256_to_u160
};
use debug::PrintTrait;


#[test]
fn test_u256_to_u160() {
    let hash = u256{
        low: 0xaf2186e7afa85296f106336e376669f7,
        high: 0x387a8233c96e1fc0ad5e284353276177
    };

    let value = u256_to_u160(hash);
    assert(value == 0x53276177af2186e7afa85296f106336e376669f7, 'invalid value');
}

#[test]
fn test_felt252_fast_pow2() {
    assert(felt252_fast_pow2(0) == 1, 'felt pow(2, 0)');
    assert(felt252_fast_pow2(250) == 1809251394333065553493296640760748560207343510400633813116524750123642650624, 'felt pow(2, 250)');
    assert(felt252_fast_pow2(251) == 0, 'felt pow(2, 251)');
}

#[test]
fn test_u128_fast_pow2() {
    assert(u128_fast_pow2(0) == 1, 'invalid result');
    assert(u128_fast_pow2(127) == 170141183460469231731687303715884105728, 'invalid result');
    assert(u128_fast_pow2(128) == 0, 'invalid result');
}

#[test]
fn test_usize_div_rem() {
    let value = 10349;
    let div = 7;
    let (q, r) = usize_div_rem(value, div);
    assert(q == value / div, 'invalid result');
    assert(r == value % div, 'invalid result');
}

#[test]
fn test_u128_div_rem() {
    let value = 10349;
    let div = 7;
    let (q, r) = u128_div_rem(value, div);
    assert(q == value / div, 'invalid result');
    assert(r == value % div, 'invalid result');
}

// TODO: protostar do not support should_panic Now.
// #[test]
// #[should_panic(expected:('value_size can not be gt 16', ))]
// fn test_u128_split_panic_1() {
//     let value = 0x01020304050607080102030405060708;
//     let value_size = 17;
//     u128_split(value, value_size, 1);
// }

#[test]
fn test_u128_split_full() {
    let value = 0x01020304050607080102030405060708;
    let value_size = 16;

    // 1. left is 0x0
    let (left, rifht) = u128_split(value, value_size, 0);
    assert(left == 0, '1 invalid result');
    assert(rifht == value, '1 invalid result');

    // 2. left is 0x01020304
    let (left, rifht) = u128_split(value, value_size, 4);
    assert(left == 0x01020304, '2 invalid result');
    assert(rifht == 0x050607080102030405060708, '2 invalid result');

    // 3. left is 0x0102030405060708
    let (left, rifht) = u128_split(value, value_size, 8);
    assert(left == 0x0102030405060708, '3 invalid result');
    assert(rifht == 0x0102030405060708, '3 invalid result');

    // 4. left is 0x010203040506070801
    let (left, rifht) = u128_split(value, value_size, 9);
    assert(left == 0x010203040506070801, '4 invalid result');
    assert(rifht == 0x02030405060708, '4 invalid result');

    // 5. left is value
    let (left, rifht) = u128_split(value, value_size, value_size);
    assert(left == value, '5 invalid result');
    assert(rifht == 0, '5 invalid result');
}

#[test]
fn test_u128_split_common() {
    let value = 0x0102030405060708010203;
    let value_size = 11;

    // 1. left is 0x0
    let (left, rifht) = u128_split(value, value_size, 0);
    assert(left == 0, '1 invalid result');
    assert(rifht == value, '1 invalid result');

    // 2. left is 0x01020304
    let (left, rifht) = u128_split(value, value_size, 4);
    assert(left == 0x01020304, '2 invalid result');
    assert(rifht == 0x05060708010203, '2 invalid result');

    // 3. left is 0x0102030405060708
    let (left, rifht) = u128_split(value, value_size, 6);
    assert(left == 0x010203040506, '3 invalid result');
    assert(rifht == 0x0708010203, '3 invalid result');

    // 5. left is value
    let (left, rifht) = u128_split(value, value_size, value_size);
    assert(left == value, '4 invalid result');
    assert(rifht == 0, '4 invalid result');
}

#[test]
fn test_u128_sub_value_full() {
    let value = 0x01020304050607080102030405060708;
    let value_size = 16;

    // 1. offset=0, size=4
    let sub = u128_sub_value(value, value_size, 0, 4);
    assert(sub == 0x01020304, '1 invalid result');

    // 2. offset=0, size=value_size
    let sub = u128_sub_value(value, value_size, 0, value_size);
    assert(sub == value, '2 invalid result');

    // 3. offset=1, size=value_size-1
    let sub = u128_sub_value(value, value_size, 1, value_size - 1);
    assert(sub == 0x020304050607080102030405060708, '3 invalid result');

    // 4. offset=3, size=11
    let sub = u128_sub_value(value, value_size, 3, 11);
    assert(sub == 0x405060708010203040506, '4 invalid result');
}

#[test]
fn test_u128_sub_value_common() {
    let value = 0x010203040506070801;
    let value_size = 9;

    // 1. offset=0, size=4
    let sub = u128_sub_value(value, value_size, 0, 4);
    assert(sub == 0x01020304, '1 invalid result');

    // 2. offset=0, size=value_size
    let sub = u128_sub_value(value, value_size, 0, value_size);
    assert(sub == value, '2 invalid result');

    // 3. offset=1, size=value_size-1
    let sub = u128_sub_value(value, value_size, 1, value_size - 1);
    assert(sub == 0x0203040506070801, '3 invalid result');

    // 4. offset=3, size=11
    let sub = u128_sub_value(value, value_size, 3, 4);
    assert(sub == 0x4050607, '4 invalid result');
}

#[test]
fn test_u128_join() {
    let left = 0x0102;
    let right = 0x0304;
    assert(u128_join(left, right, 2) == 0x01020304, 'invalid result');
}