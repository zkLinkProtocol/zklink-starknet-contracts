use core::option::OptionTrait;
use core::traits::{TryInto, Into, DivRem};
use zklink::utils::math::{
    u128_fast_shift, u128_join, u128_split, read_sub_u128, uint_min, fast_power10, u256_fast_pow2
};

#[test]
#[available_gas(20000000000)]
fn test_min() {
    let left: u8 = 1;
    let right: u8 = 2;
    assert(uint_min(left, right) == left, 'u8 min');

    let left: u16 = 1;
    let right: u16 = 0;
    assert(uint_min(left, right) == right, 'u16 min');

    let left: u32 = 1;
    let right: u32 = 1;
    assert(uint_min(left, right) == left, 'u32 min');

    let left: u64 = 1;
    let right: u64 = 2;
    assert(uint_min(left, right) == left, 'u64 min');

    let left: u128 = 1;
    let right: u128 = 2;
    assert(uint_min(left, right) == left, 'u128 min');

    let left: u256 = 1;
    let right: u256 = 2;
    assert(uint_min(left, right) == left, 'u256 min');
}

// #[test]
// #[available_gas(20000000000)]
// #[should_panic(expected: ('invalid exp',))]
// fn test_u128_fast_pow2() {
//     let mut i = 0;
//     let max_exp = 127;
//     loop {
//         if i > max_exp {
//             break;
//         }
//         assert(u128_fast_pow2(i).into() == common_pow(2, i), 'invalid result');
//         i = i + 1;
//     };

//     assert(u128_fast_pow2(i).into() == common_pow(2, i), 'panic');
// }

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('invalid exp',))]
fn test_u256_fast_pow2() {
    let mut i = 0;
    let max_exp = 255;
    loop {
        if i > max_exp {
            break;
        }
        assert(u256_fast_pow2(i) == common_pow(2, i), 'invalid result');
        i = i + 1;
    };

    assert(u256_fast_pow2(i) == common_pow(2, i), 'panic');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('invalid exp',))]
fn test_fast_power10() {
    let mut i = 0;
    let max_exp = 18;
    loop {
        if i > max_exp {
            break;
        }
        assert(fast_power10(i).into() == common_pow(10, i), 'invalid result');
        i = i + 1;
    };

    assert(fast_power10(i).into() == common_pow(10, i), 'panic');
}

// return base^exp
fn common_pow(base: u256, exp: usize) -> u256 {
    let mut res = 1;
    let mut count = 0;
    loop {
        if count == exp {
            break;
        } else {
            res = base * res;
        }
        count = count + 1;
    };
    res
}

#[test]
fn test_u128_div_rem() {
    let value = 10349_u128;
    let div = 7_u128;
    let (q, r) = DivRem::div_rem(value, div.try_into().unwrap());
    assert(q == 1478, 'invalid result');
    assert(r == 3, 'invalid result');
}

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
fn test_read_sub_u128_full() {
    let value = 0x01020304050607080102030405060708;
    let value_size = 16;

    // 1. offset=0, size=4
    let sub = read_sub_u128(value, value_size, 0, 4);
    assert(sub == 0x01020304, '1 invalid result');

    // 2. offset=0, size=value_size
    let sub = read_sub_u128(value, value_size, 0, value_size);
    assert(sub == value, '2 invalid result');

    // 3. offset=1, size=value_size-1
    let sub = read_sub_u128(value, value_size, 1, value_size - 1);
    assert(sub == 0x020304050607080102030405060708, '3 invalid result');

    // 4. offset=3, size=11
    let sub = read_sub_u128(value, value_size, 3, 11);
    assert(sub == 0x405060708010203040506, '4 invalid result');
}

#[test]
fn test_read_sub_u128_common() {
    let value = 0x010203040506070801;
    let value_size = 9;

    // 1. offset=0, size=4
    let sub = read_sub_u128(value, value_size, 0, 4);
    assert(sub == 0x01020304, '1 invalid result');

    // 2. offset=0, size=value_size
    let sub = read_sub_u128(value, value_size, 0, value_size);
    assert(sub == value, '2 invalid result');

    // 3. offset=1, size=value_size-1
    let sub = read_sub_u128(value, value_size, 1, value_size - 1);
    assert(sub == 0x0203040506070801, '3 invalid result');

    // 4. offset=3, size=11
    let sub = read_sub_u128(value, value_size, 3, 4);
    assert(sub == 0x4050607, '4 invalid result');
}

#[test]
fn test_u128_join() {
    let left = 0x0102;
    let right = 0x0304;
    assert(u128_join(left, right, 2) == 0x01020304, 'invalid result');
}
