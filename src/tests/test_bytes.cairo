use traits::Into;
use array::ArrayTrait;
use starknet::{ContractAddress, ContractAddressIntoFelt252, contract_address_const};
use zklink::utils::bytes::{Bytes, BytesTrait};
use debug::PrintTrait;

#[test]
#[available_gas(20000000)]
fn test_bytes_zero() {
    let bytes = BytesTrait::zero(1);
    assert(bytes.size() == 1, 'invalid size1');
    assert(bytes.data.len() == 0, 'invalid value1_1');
    assert(bytes.pending_data == 0, 'invalid value1_2');
    assert(bytes.pending_data_size == 1, 'invalid value1_3');

    let bytes = BytesTrait::zero(17);
    assert(bytes.size() == 17, 'invalid size2');
    assert(bytes.data.len() == 1, 'invalid value2_1');
    assert(bytes.pending_data == 0, 'invalid value2_2');
    assert(bytes.pending_data_size == 1, 'invalid value2_3');
    let (_, value) = bytes.read_u8(15);
    assert(value == 0, 'invalid value3');
    let (_, value) = bytes.read_u8(0);
    assert(value == 0, 'invalid value4');
    let (_, value) = bytes.read_u8(16);
    assert(value == 0, 'invalid value5');
}

#[test]
#[available_gas(200000000)]
#[should_panic(expected: ('update out of bound',))]
fn test_bytes_update_panic() {
    let mut bytes = BytesTrait::new();
    bytes.update_at(0, 0x01);
}

#[test]
#[available_gas(200000000)]
fn test_bytes_update() {
    let mut bytes = BytesTrait::new();
    bytes.append_u128_packed(0x0102030405, 5);

    bytes.update_at(0, 0x05);
    assert(bytes.size() == 5, 'update_size1');
    assert(bytes.pending_data == 0x0502030405, 'update_value_1');

    bytes.update_at(1, 0x06);
    assert(bytes.size() == 5, 'update_size2');
    assert(bytes.pending_data == 0x0506030405, 'update_value_2');

    bytes.update_at(2, 0x07);
    assert(bytes.size() == 5, 'update_size3');
    assert(bytes.pending_data == 0x0506070405, 'update_value_3');

    bytes.update_at(3, 0x08);
    assert(bytes.size() == 5, 'update_size4');
    assert(bytes.pending_data == 0x0506070805, 'update_value_4');

    bytes.update_at(4, 0x09);
    assert(bytes.size() == 5, 'update_size5');
    assert(bytes.pending_data == 0x0506070809, 'update_value_5');

    let mut bytes = BytesTrait::new();
    bytes.append_u128(0x01020304050607080910111213141516);
    bytes.append_u128(0x01020304050607080910111213141516);
    bytes.append_u128_packed(0x01020304050607080910, 10);

    bytes.update_at(16, 0x16);
    assert(bytes.size() == 42, 'update_size6');
    assert(*bytes.data[0] == 0x01020304050607080910111213141516, 'update_value_6');
    assert(*bytes.data[1] == 0x16020304050607080910111213141516, 'update_value_7');
    assert(bytes.pending_data == 0x01020304050607080910, 'update_value_8');

    bytes.update_at(15, 0x01);
    assert(bytes.size() == 42, 'update_size7');
    assert(*bytes.data[0] == 0x01020304050607080910111213141501, 'update_value_9');
    assert(*bytes.data[1] == 0x16020304050607080910111213141516, 'update_value_10');
    assert(bytes.pending_data == 0x01020304050607080910, 'update_value_11');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u128_packed() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u128_packed(0, 1);
    assert(new_offset == 1, 'read_u128_packed_1_offset');
    assert(value == 0x01, 'read_u128_packed_1_value');

    let (new_offset, value) = bytes.read_u128_packed(new_offset, 14);
    assert(new_offset == 15, 'read_u128_packed_2_offset');
    assert(value == 0x0203040506070809101112131415, 'read_u128_packed_2_value');

    let (new_offset, value) = bytes.read_u128_packed(new_offset, 15);
    assert(new_offset == 30, 'read_u128_packed_3_offset');
    assert(value == 0x160102030405060708091011121314, 'read_u128_packed_3_value');

    let (new_offset, value) = bytes.read_u128_packed(new_offset, 8);
    assert(new_offset == 38, 'read_u128_packed_4_offset');
    assert(value == 0x1516010203040506, 'read_u128_packed_4_value');

    let (new_offset, value) = bytes.read_u128_packed(new_offset, 4);
    assert(new_offset == 42, 'read_u128_packed_5_offset');
    assert(value == 0x07080910, 'read_u128_packed_5_value');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('out of bound',))]
fn test_bytes_read_u128_packed_out_of_bound() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u128_packed(0, 43);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('too large',))]
fn test_bytes_read_u128_packed_too_large() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u128_packed(0, 17);
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u128_array_packed() {
    let bytes = test_bytes_42();

    let (new_offset, new_array) = bytes.read_u128_array_packed(0, 3, 3);
    assert(new_offset == 9, 'read_u128_array_1_offset');
    assert(*new_array[0] == 0x010203, 'read_u128_array_1_value_1');
    assert(*new_array[1] == 0x040506, 'read_u128_array_1_value_2');
    assert(*new_array[2] == 0x070809, 'read_u128_array_1_value_3');

    let (new_offset, new_array) = bytes.read_u128_array_packed(9, 4, 7);
    assert(new_offset == 37, 'read_u128_array_2_offset');
    assert(*new_array[0] == 0x10111213141516, 'read_u128_array_2_value_1');
    assert(*new_array[1] == 0x01020304050607, 'read_u128_array_2_value_2');
    assert(*new_array[2] == 0x08091011121314, 'read_u128_array_2_value_3');
    assert(*new_array[3] == 0x15160102030405, 'read_u128_array_2_value_4');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('out of bound',))]
fn test_bytes_read_u128_array_packed_out_of_bound() {
    let bytes = test_bytes_42();

    let (new_offset, new_array) = bytes.read_u128_array_packed(0, 11, 4);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('too large',))]
fn test_bytes_read_u128_array_packed_too_large() {
    let bytes = test_bytes_42();

    let (new_offset, new_array) = bytes.read_u128_array_packed(0, 2, 17);
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_felt252_packed() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_felt252_packed(13, 20);
    assert(new_offset == 33, 'read_felt252_1_offset');
    assert(value == 0x1415160102030405060708091011121314151601, 'read_felt252_1_value');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('out of bound',))]
fn test_bytes_read_felt252_packed_out_of_bound() {
    let bytes = test_bytes_42();

    let (new_offset, new_array) = bytes.read_felt252_packed(0, 43);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('too large',))]
fn test_bytes_read_felt252_packed_too_large() {
    let bytes = test_bytes_42();

    let (new_offset, new_array) = bytes.read_felt252_packed(0, 32);
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u8() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u8(15);
    assert(new_offset == 16, 'read_u8_offset');
    assert(value == 0x16, 'read_u8_value');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u16() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u16(15);
    assert(new_offset == 17, 'read_u16_offset');
    assert(value == 0x1601, 'read_u16_value');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u32() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u32(15);
    assert(new_offset == 19, 'read_u32_offset');
    assert(value == 0x16010203, 'read_u32_value');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_usize() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_usize(15);
    assert(new_offset == 19, 'read_usize_offset');
    assert(value == 0x16010203, 'read_usize_value');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u64() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u64(15);
    assert(new_offset == 23, 'read_u64_offset');
    assert(value == 0x1601020304050607, 'read_u64_value');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u128() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u128(15);
    assert(new_offset == 31, 'read_u128_offset');
    assert(value == 0x16010203040506070809101112131415, 'read_u128_value');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u256() {
    let bytes = test_bytes_42();

    let (new_offset, value) = bytes.read_u256(4);
    assert(new_offset == 36, 'read_u256_1_offset');
    assert(value.high == 0x05060708091011121314151601020304, 'read_u256_1_value_high');
    assert(value.low == 0x05060708091011121314151601020304, 'read_u256_1_value_low');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_u256_array() {
    let mut bytes = BytesTrait::new();
    bytes.append_u128(0x01020304050607080910111213141516);
    bytes.append_u128(0x16151413121110090807060504030201);
    bytes.append_u128(0x16151413121110090807060504030201);
    bytes.append_u128(0x01020304050607080910111213141516);
    bytes.append_u128(0x01020304050607080910111213141516);
    bytes.append_u128_packed(0x1615141312111009, 8);

    let (new_offset, new_array) = bytes.read_u256_array(7, 2);
    assert(new_offset == 71, 'read_u256_array_offset');
    let result: u256 = *new_array[0];
    assert(result.high == 0x08091011121314151616151413121110, 'read_256_array_value_1_high');
    assert(result.low == 0x09080706050403020116151413121110, 'read_256_array_value_1_low');
    let result: u256 = *new_array[1];
    assert(result.high == 0x09080706050403020101020304050607, 'read_256_array_value_2_high');
    assert(result.low == 0x08091011121314151601020304050607, 'read_256_array_value_2_low');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_address() {
    let mut bytes = BytesTrait::new();
    bytes.append_u128(0x01020304050607080910111213140154);
    bytes.append_u128(0x01855d7796176b05d160196ff92381eb);
    bytes.append_u128_packed(0x7910f5446c2e0e04e13db2194a4f, 14);

    let address = 0x015401855d7796176b05d160196ff92381eb7910f5446c2e0e04e13db2194a4f;

    let (new_offset, value) = bytes.read_address(14);
    assert(new_offset == 46, 'read_address_offset');
    assert(value.into() == address, 'read_address_value');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_read_bytes() {
    let mut bytes = BytesTrait::new();
    bytes.append_u128(0x01020304050607080910111213140154);
    bytes.append_u128(0x01855d7796176b05d160196ff92381eb);
    bytes.append_u128_packed(0x7910f5446c2e0e04e13db2194a4f, 14);

    let sub_bytes = bytes.read_bytes(4, 37);
    let sub_bytes_data = @sub_bytes.data;
    // assert(new_offset == 41, 'read_bytes_offset');
    assert(sub_bytes.size() == 37, 'read_bytes_size');
    assert(*sub_bytes_data[0] == 0x05060708091011121314015401855d77, 'read_bytes_value_1');
    assert(*sub_bytes_data[1] == 0x96176b05d160196ff92381eb7910f544, 'read_bytes_value_2');
    assert(sub_bytes.pending_data == 0x6c2e0e04e1, 'read_bytes_value_3');

    let sub_bytes = bytes.read_bytes(0, 14);
    let sub_bytes_data = @sub_bytes.data;
    // assert(new_offset == 14, 'read_bytes_offset');
    assert(sub_bytes.size() == 14, 'read_bytes_size');
    assert(sub_bytes.pending_data == 0x0102030405060708091011121314, 'read_bytes_value_4');

    // read first byte
    let sub_bytes = bytes.read_bytes(0, 1);
    let sub_bytes_data = @sub_bytes.data;
    // assert(new_offset == 1, 'read_bytes_offset');
    assert(sub_bytes.size() == 1, 'read_bytes_size');
    assert(sub_bytes.pending_data == 0x01, 'read_bytes_value_5');

    // read last byte
    let sub_bytes = bytes.read_bytes(45, 1);
    let sub_bytes_data = @sub_bytes.data;
    // assert(new_offset == 46, 'read_bytes_offset');
    assert(sub_bytes.size() == 1, 'read_bytes_size');
    assert(sub_bytes.pending_data == 0x4f, 'read_bytes_value_6');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_append() {
    let mut bytes = BytesTrait::new();

    // append_u128_packed
    bytes.append_u128_packed(0x101112131415161718, 9);

    assert(bytes.size() == 9, 'append_u128_packed_1_size_1');
    assert(bytes.pending_data_size == 9, 'append_u128_packed_1_size_2');
    assert(bytes.data.len() == 0, 'append_u128_packed_1_len');
    assert(bytes.pending_data == 0x101112131415161718, 'append_u128_packed_1_value_1');

    bytes.append_u128_packed(0x101112131415161718, 9);
    assert(bytes.size() == 18, 'append_u128_packed_2_size_1');
    assert(bytes.pending_data_size == 2, 'append_u128_packed_1_size_2');
    assert(bytes.data.len() == 1, 'append_u128_packed_2_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_u128_packed_2_value_1');
    assert(bytes.pending_data == 0x1718, 'append_u128_packed_2_value_2');

    // append_u8
    bytes.append_u8(0x01);
    assert(bytes.size() == 19, 'append_u8_size_1');
    assert(bytes.pending_data_size == 3, 'append_u8_size_2');
    assert(bytes.data.len() == 1, 'append_u8_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_u8_value_1');
    assert(bytes.pending_data == 0x171801, 'append_u8_value_2');

    // append_u16
    bytes.append_u16(0x0102);
    assert(bytes.size() == 21, 'append_u16_size_1');
    assert(bytes.pending_data_size == 5, 'append_u16_size_2');
    assert(bytes.data.len() == 1, 'append_u16_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_u16_value_1');
    assert(bytes.pending_data == 0x1718010102, 'append_u16_value_2');

    // append_u32
    bytes.append_u32(0x01020304);
    assert(bytes.size() == 25, 'append_u32_size_1');
    assert(bytes.pending_data_size == 9, 'append_u32_size_2');
    assert(bytes.data.len() == 1, 'append_u32_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_u32_value_1');
    assert(bytes.pending_data == 0x171801010201020304, 'append_u32_value_2');

    // append_usize
    bytes.append_usize(0x01);
    assert(bytes.size() == 29, 'append_usize_size_1');
    assert(bytes.pending_data_size == 13, 'append_usize_size_2');
    assert(bytes.data.len() == 1, 'append_usize_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_usize_value_1');
    assert(bytes.pending_data == 0x17180101020102030400000001, 'append_usize_value_2');

    // append_u64
    bytes.append_u64(0x030405060708);
    assert(bytes.size() == 37, 'append_u64_size_1');
    assert(bytes.pending_data_size == 5, 'append_u64_size_2');
    assert(bytes.data.len() == 2, 'append_u64_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_u64_value_1');
    assert(*bytes.data[1] == 0x17180101020102030400000001000003, 'append_u64_value_2');
    assert(bytes.pending_data == 0x0405060708, 'append_u64_value_3');

    // append_u128
    bytes.append_u128(0x101112131415161718);
    assert(bytes.size() == 53, 'append_u128_size_1');
    assert(bytes.pending_data_size == 5, 'append_u128_size_2');
    assert(bytes.data.len() == 3, 'append_u128_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_u128_value_1');
    assert(*bytes.data[1] == 0x17180101020102030400000001000003, 'append_u128_value_2');
    assert(*bytes.data[2] == 0x04050607080000000000000010111213, 'append_u128_value_3');
    assert(bytes.pending_data == 0x1415161718, 'append_u128_value_4');

    // append_u256
    bytes.append_u256(u256 { low: 0x01020304050607, high: 0x010203040506070809 });
    assert(bytes.size() == 85, 'append_u256_size_1');
    assert(bytes.pending_data_size == 5, 'append_u256_size_2');
    assert(bytes.data.len() == 5, 'append_256_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_u256_value_1');
    assert(*bytes.data[1] == 0x17180101020102030400000001000003, 'append_u256_value_2');
    assert(*bytes.data[2] == 0x04050607080000000000000010111213, 'append_u256_value_3');
    assert(*bytes.data[3] == 0x14151617180000000000000001020304, 'append_u256_value_4');
    assert(*bytes.data[4] == 0x05060708090000000000000000000102, 'append_u256_value_5');
    assert(bytes.pending_data == 0x0304050607, 'append_u256_value_6');

    // append_address
    let address = contract_address_const::<
        0x015401855d7796176b05d160196ff92381eb7910f5446c2e0e04e13db2194a4f
    >();
    bytes.append_address(address);
    assert(bytes.size() == 117, 'append_address_size_1');
    assert(bytes.pending_data_size == 5, 'append_address_size_2');
    assert(bytes.data.len() == 7, 'append_address_len');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'append_address_value_1');
    assert(*bytes.data[1] == 0x17180101020102030400000001000003, 'append_address_value_2');
    assert(*bytes.data[2] == 0x04050607080000000000000010111213, 'append_address_value_3');
    assert(*bytes.data[3] == 0x14151617180000000000000001020304, 'append_address_value_4');
    assert(*bytes.data[4] == 0x05060708090000000000000000000102, 'append_address_value_5');
    assert(*bytes.data[5] == 0x0304050607015401855d7796176b05d1, 'append_address_value_6');
    assert(*bytes.data[6] == 0x60196ff92381eb7910f5446c2e0e04e1, 'append_address_value_7');
    assert(bytes.pending_data == 0x3db2194a4f, 'append_address_value_8');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_concat() {
    let mut bytes = Bytes {
        data: array![
            0x10111213141516171810111213141516,
            0x17180101020102030400000001000003,
            0x04050607080000000000000010111213,
            0x14151617180000000000000001020304,
            0x05060708090000000000000000000102,
            0x0304050607015401855d7796176b05d1,
            0x60196ff92381eb7910f5446c2e0e04e1
        ],
        pending_data: 0x3db2194a4f,
        pending_data_size: 5,
    };

    let other = Bytes {
        data: array![0x01020304050607080910111213140154, 0x01855d7796176b05d160196ff92381eb],
        pending_data: 0x7910f5446c2e0e04e13db2194a4f,
        pending_data_size: 14,
    };

    bytes.concat(@other);
    assert(bytes.size() == 163, 'concat_size');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'concat_value_1');
    assert(*bytes.data[1] == 0x17180101020102030400000001000003, 'concat_value_2');
    assert(*bytes.data[2] == 0x04050607080000000000000010111213, 'concat_value_3');
    assert(*bytes.data[3] == 0x14151617180000000000000001020304, 'concat_value_4');
    assert(*bytes.data[4] == 0x05060708090000000000000000000102, 'concat_value_5');
    assert(*bytes.data[5] == 0x0304050607015401855d7796176b05d1, 'concat_value_6');
    assert(*bytes.data[6] == 0x60196ff92381eb7910f5446c2e0e04e1, 'concat_value_7');
    assert(*bytes.data[7] == 0x3db2194a4f0102030405060708091011, 'concat_value_8');
    assert(*bytes.data[8] == 0x121314015401855d7796176b05d16019, 'concat_value_9');
    assert(*bytes.data[9] == 0x6ff92381eb7910f5446c2e0e04e13db2, 'concat_value_10');
    assert(bytes.pending_data == 0x194a4f, 'concat_value_11');

    // empty bytes concat
    let mut empty_bytes = BytesTrait::new();
    empty_bytes.concat(@bytes);

    assert(empty_bytes.size() == 163, 'concat_size');
    assert(*empty_bytes.data[0] == 0x10111213141516171810111213141516, 'concat_value_1');
    assert(*empty_bytes.data[1] == 0x17180101020102030400000001000003, 'concat_value_2');
    assert(*empty_bytes.data[2] == 0x04050607080000000000000010111213, 'concat_value_3');
    assert(*empty_bytes.data[3] == 0x14151617180000000000000001020304, 'concat_value_4');
    assert(*empty_bytes.data[4] == 0x05060708090000000000000000000102, 'concat_value_5');
    assert(*empty_bytes.data[5] == 0x0304050607015401855d7796176b05d1, 'concat_value_6');
    assert(*empty_bytes.data[6] == 0x60196ff92381eb7910f5446c2e0e04e1, 'concat_value_7');
    assert(*empty_bytes.data[7] == 0x3db2194a4f0102030405060708091011, 'concat_value_8');
    assert(*empty_bytes.data[8] == 0x121314015401855d7796176b05d16019, 'concat_value_9');
    assert(*empty_bytes.data[9] == 0x6ff92381eb7910f5446c2e0e04e13db2, 'concat_value_10');
    assert(empty_bytes.pending_data == 0x194a4f, 'concat_value_11');

    // concat empty_bytes
    let empty_bytes = BytesTrait::new();
    bytes.concat(@empty_bytes);

    assert(bytes.size() == 163, 'concat_size');
    assert(*bytes.data[0] == 0x10111213141516171810111213141516, 'concat_value_1');
    assert(*bytes.data[1] == 0x17180101020102030400000001000003, 'concat_value_2');
    assert(*bytes.data[2] == 0x04050607080000000000000010111213, 'concat_value_3');
    assert(*bytes.data[3] == 0x14151617180000000000000001020304, 'concat_value_4');
    assert(*bytes.data[4] == 0x05060708090000000000000000000102, 'concat_value_5');
    assert(*bytes.data[5] == 0x0304050607015401855d7796176b05d1, 'concat_value_6');
    assert(*bytes.data[6] == 0x60196ff92381eb7910f5446c2e0e04e1, 'concat_value_7');
    assert(*bytes.data[7] == 0x3db2194a4f0102030405060708091011, 'concat_value_8');
    assert(*bytes.data[8] == 0x121314015401855d7796176b05d16019, 'concat_value_9');
    assert(*bytes.data[9] == 0x6ff92381eb7910f5446c2e0e04e13db2, 'concat_value_10');
    assert(bytes.pending_data == 0x194a4f, 'concat_value_11');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_keccak() {
    // Calculating keccak by Python
    // from Crypto.Hash import keccak
    // k = keccak.new(digest_bits=256)
    // k.update(bytes.fromhex(''))
    // print(k.hexdigest())

    // empty
    let bytes = BytesTrait::new();
    let hash: u256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    let res = bytes.keccak();
    assert(res == hash, 'bytes_keccak_0');

    // u256{low: 1, high: 0}
    let bytes: Bytes = Bytes { data: array![0, 1], pending_data: 0, pending_data_size: 0, };
    let res = bytes.keccak();
    let hash: u256 = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;
    assert(res == hash, 'bytes_keccak_1');

    // test_bytes_append bytes
    let mut bytes: Bytes = BytesTrait::new();
    bytes.append_u128(0x10111213141516171810111213141516);
    bytes.append_u128(0x17180101020102030400000001000003);
    bytes.append_u128(0x04050607080000000000000010111213);
    bytes.append_u128(0x14151617180000000000000001020304);
    bytes.append_u128(0x05060708090000000000000000000102);
    bytes.append_u128(0x0304050607015401855d7796176b05d1);
    bytes.append_u128(0x60196ff92381eb7910f5446c2e0e04e1);
    bytes.append_u128_packed(0x3db2194a4f, 5);

    let hash: u256 = 0xcb1bcb5098bb2f588b82ea341e3b1148b7d1eeea2552d624b30f4240b5b85995;
    let res = bytes.keccak();
    assert(res == hash, 'bytes_keccak_2');
}

#[test]
#[available_gas(20000000)]
fn test_bytes_keccak_for_check() {
    // Calculating keccak by Python
    // from Crypto.Hash import keccak
    // k = keccak.new(digest_bits=256)
    // k.update(bytes.fromhex(''))
    // print(k.hexdigest())

    let mut bytes: Bytes = BytesTrait::new();
    bytes.append_u128(0x10111213141516171810111213141516);
    bytes.append_u128(0x17180101020102030400000001000003);
    bytes.append_u128(0x04050607080000000000000010111213);
    bytes.append_u128(0x14151617180000000000000001020304);
    bytes.append_u128(0x05060708090000000000000000000102);
    bytes.append_u128(0x0304050607015401855d7796176b05d1);
    bytes.append_u128(0x60196ff92381eb7910f5446c2e0e04e1);
    bytes.append_u128_packed(0x3db2194a4f, 5);

    let hash: u256 = 0xd031c7dd0f07337fb416a8f7d13d2414f8d5e3191135835622329a0aecd72cd5;
    let res = bytes.keccak_for_check(112);
    assert(res == hash, 'bytes_keccak_for_check_1');
    let hash: u256 = 0xcb1bcb5098bb2f588b82ea341e3b1148b7d1eeea2552d624b30f4240b5b85995;
    let res = bytes.keccak_for_check(117);
    assert(res == hash, 'bytes_keccak_for_check_2');
}

#[test]
#[available_gas(20000000000)]
fn test_bytes_sha256() {
    // empty
    let bytes = BytesTrait::new();
    let hash: u256 = 0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;
    let res = bytes.sha256();
    assert(res == hash, 'bytes_sha256_0');

    // u256{low: 1, high: 0}
    // 0x0000000000000000000000000000000000000000000000000000000000000001
    let bytes: Bytes = Bytes { data: array![0, 1], pending_data: 0, pending_data_size: 0, };
    let res = bytes.sha256();
    let hash: u256 = 0xec4916dd28fc4c10d78e287ca5d9cc51ee1ae73cbfde08c6b37324cbfaac8bc5;
    assert(res == hash, 'bytes_sha256_1');

    // test_bytes_append bytes
    let mut bytes: Bytes = BytesTrait::new();
    bytes.append_u128(0x10111213141516171810111213141516);
    bytes.append_u128(0x17180101020102030400000001000003);
    bytes.append_u128(0x04050607080000000000000010111213);
    bytes.append_u128(0x14151617180000000000000001020304);
    bytes.append_u128(0x05060708090000000000000000000102);
    bytes.append_u128(0x0304050607015401855d7796176b05d1);
    bytes.append_u128(0x60196ff92381eb7910f5446c2e0e04e1);
    bytes.append_u128_packed(0x3db2194a4f, 5);

    let hash: u256 = 0xc3ab2c0ce2c246454f265f531ab14f210215ce72b91c23338405c273dc14ce1d;
    let res = bytes.sha256();
    assert(res == hash, 'bytes_sha256_2');
}

#[test]
#[available_gas(1000000)]
fn test_append_byte() {
    let mut ba = Default::default();
    let mut c = 1_u8;
    loop {
        if c == 34 {
            break;
        }
        ba.append_byte(c);
        c += 1;
    };
}


// call append_word 6 times
#[test]
#[available_gas(10000000)]
fn test_append_word() {
    let mut ba = BytesTrait::new();

    ba.append_u128_packed(0x0102030405060708091a0b0c0d0e0f, 15);

    ba.append_u128_packed(0x1f2021, 3);

    ba.append_u128_packed(0x2223, 2);

    // Length is 0, so nothing is actually appended.
    ba.append_u128_packed(0xffee, 0);

    ba.append_u128_packed(0x2425262728292a2b2c2d2e2f, 12);

    ba.append_u128_packed(0x3f, 1);
}

#[test]
#[available_gas(10000000)]
fn test_append() {
    let mut ba1 = test_byte_array_17();
    let ba2 = test_byte_array_17();

    ba1.concat(@ba2);
}

fn test_byte_array_17() -> Bytes {
    let mut ba1 = BytesTrait::new();
    ba1.append_u128(0x0102030405060708091a0b0c0d0e0f10);
    ba1.append_u128_packed(0x20, 1);
    ba1
}

fn test_bytes_42() -> Bytes {
    let mut bytes = BytesTrait::new();
    bytes.append_u128(0x01020304050607080910111213141516);
    bytes.append_u128(0x01020304050607080910111213141516);
    bytes.append_u128_packed(0x01020304050607080910, 10);
    bytes
}
