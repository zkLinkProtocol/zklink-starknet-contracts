use core::traits::Into;
use core::array::ArrayTrait;
use starknet::{ContractAddress, ContractAddressIntoFelt252};
use zklink::utils::bytes::{
    Bytes,
    BytesTrait
};
use debug::PrintTrait;

#[test]
#[available_gas(20000000)]
fn test_bytes() {
    let mut array = ArrayTrait::<u128>::new();
    array.append(0x01020304050607080910111213141516);
    array.append(0x01020304050607080910111213141516);
    array.append(0x01020304050607080910000000000000);

    let bytes = BytesTrait::new(42, array);

    // read_u128
    // TODO: over size
    let (new_offset, value) = bytes.read_u128_packed(0, 1);
    assert(new_offset == 1, 'read_u128_1_offset');
    assert(value == 0x01, 'read_u128_1_value');

    let (new_offset, value) = bytes.read_u128_packed(new_offset, 14);
    assert(new_offset == 15, 'read_u128_2_offset');
    assert(value == 0x0203040506070809101112131415, 'read_u128_2_value');

    let (new_offset, value) = bytes.read_u128_packed(new_offset, 15);
    assert(new_offset == 30, 'read_u128_3_offset');
    assert(value == 0x160102030405060708091011121314, 'read_u128_3_value');

    let (new_offset, value) = bytes.read_u128_packed(new_offset, 8);
    assert(new_offset == 38, 'read_u128_3_offset');
    assert(value == 0x1516010203040506, 'read_u128_3_value');

    let (new_offset, value) = bytes.read_u128_packed(new_offset, 4);
    assert(new_offset == 42, 'read_u128_3_offset');
    assert(value == 0x07080910, 'read_u128_3_value');
    
    // read_u128_array
    let (new_offset, new_array) = bytes.read_u128_array_packed(0, 3, 3);
    assert(new_offset == 9, 'read_u128_array_1_offset');
    assert(*new_array[0] == 0x010203, 'read_u128_array_1_value_1');
    assert(*new_array[1] == 0x040506, 'read_u128_array_1_value_2');
    assert(*new_array[2] == 0x070809, 'read_u128_array_1_value_3');

    let (new_offset, new_array) = bytes.read_u128_array_packed(9, 3, 7);
    assert(new_offset == 30, 'read_u128_array_2_offset');
    assert(*new_array[0] == 0x10111213141516, 'read_u128_array_2_value_1');
    assert(*new_array[1] == 0x01020304050607, 'read_u128_array_2_value_2');
    assert(*new_array[2] == 0x08091011121314, 'read_u128_array_2_value_3');

    // read_u256
    let (new_offset, value) = bytes.read_u256(4);
    assert(new_offset == 36, 'read_u256_1_offset');
    assert(value.high == 0x05060708091011121314151601020304, 'read_u256_1_value_high');
    assert(value.low == 0x05060708091011121314151601020304, 'read_u256_1_value_low');
    
    // read_u256_array
    let mut array = ArrayTrait::<u128>::new();
    array.append(0x01020304050607080910111213141516);
    array.append(0x16151413121110090807060504030201);
    array.append(0x16151413121110090807060504030201);
    array.append(0x01020304050607080910111213141516);
    array.append(0x01020304050607080910111213141516);
    array.append(0x16151413121110090000000000000000);

    let bytes = BytesTrait::new(88, array);

    let (new_offset, new_array) = bytes.read_u256_array(7, 2);
    assert(new_offset == 71, 'read_u256_array_offset');
    assert(*new_array[0].high == 0x08091011121314151616151413121110, 'read_256_array_value_1_high');
    assert(*new_array[0].low ==  0x09080706050403020116151413121110, 'read_256_array_value_1_low');
    assert(*new_array[1].high == 0x09080706050403020101020304050607, 'read_256_array_value_2_high');
    assert(*new_array[1].low ==  0x08091011121314151601020304050607, 'read_256_array_value_2_low');

    // read_address
    let mut array = ArrayTrait::<u128>::new();
    array.append(0x01020304050607080910111213140154);
    array.append(0x01855d7796176b05d160196ff92381eb);
    array.append(0x7910f5446c2e0e04e13db2194a4f0000);

    let bytes = BytesTrait::new(46, array);
    let address = 0x015401855d7796176b05d160196ff92381eb7910f5446c2e0e04e13db2194a4f;

    let (new_offset, value) = bytes.read_address(14);
    assert(new_offset == 46, 'read_address_offset');
    assert(value.into() == address, 'read_address_value');

    // read_bytes
    let (new_offset, sub_bytes) = bytes.read_bytes(4, 37);
    let sub_bytes_data = @sub_bytes.data;
    assert(new_offset == 41, 'read_bytes_offset');
    assert(*sub_bytes_data[0] == 0x05060708091011121314015401855d77, 'read_bytes_value_1');
    assert(*sub_bytes_data[1] == 0x96176b05d160196ff92381eb7910f544, 'read_bytes_value_2');
    assert(*sub_bytes_data[2] == 0x6c2e0e04e10000000000000000000000, 'read_bytes_value_3');

    // append_u128_packed
    let mut array = ArrayTrait::<u128>::new();
    array.append(0x01020304050607080900000000000000);
    let mut bytes = BytesTrait::new(9, array);

    bytes.append_u128_packed(0x101112131415161718, 9);
    let Bytes{size, mut data} = bytes;
    assert(size == 18, 'append_u128_packed_size_1');
    assert(*data[0] == 0x01020304050607080910111213141516, 'append_u128_packed_1_value_1');
    assert(*data[1] == 0x17180000000000000000000000000000, 'append_u128_packed_1_value_2');

    let mut bytes = BytesTrait::new_empty();

    bytes.append_u128_packed(0x101112131415161718, 9);
    let Bytes{size, mut data} = bytes;
    assert(size == 9, 'append_u128_packed_2_size');
    assert(*data[0] == 0x10111213141516171800000000000000, 'append_u128_packed_2_value_1');
}