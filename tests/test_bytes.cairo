use core::array::ArrayTrait;
use zklink::utils::bytes::{
    Bytes,
    BytesTrait
};
use debug::PrintTrait;

#[test]
#[available_gas(200000000)]
fn test_bytes() {
    let mut array = ArrayTrait::<u128>::new();
    array.append(0x01020304050607080910111213141516);
    array.append(0x01020304050607080910111213141516);
    array.append(0x01020304050607080910000000000000);

    let bytes = BytesTrait::new(42, array);

    // read_u128
    // TODO: over size
    let (new_offset, value) = bytes.read_u128(0, 1);
    assert(new_offset == 1, 'read_u128_1_offset');
    assert(value == 0x01, 'read_u128_1_value');

    let (new_offset, value) = bytes.read_u128(new_offset, 14);
    assert(new_offset == 15, 'read_u128_2_offset');
    assert(value == 0x0203040506070809101112131415, 'read_u128_2_value');

    let (new_offset, value) = bytes.read_u128(new_offset, 15);
    assert(new_offset == 30, 'read_u128_3_offset');
    assert(value == 0x160102030405060708091011121314, 'read_u128_3_value');

    let (new_offset, value) = bytes.read_u128(new_offset, 8);
    assert(new_offset == 38, 'read_u128_3_offset');
    assert(value == 0x1516010203040506, 'read_u128_3_value');

    let (new_offset, value) = bytes.read_u128(new_offset, 4);
    assert(new_offset == 42, 'read_u128_3_offset');
    assert(value == 0x07080910, 'read_u128_3_value');
    
    // read_u128_array
    let (new_offset, new_array) = bytes.read_u128_array(0, 3, 3);
    assert(new_offset == 9, 'read_u128_array_1_offset');
    assert(*new_array[0] == 0x010203, 'read_u128_array_1_value');
    // assert(*new_array[1] == 0x040506, 'read_u128_array_1_value');
    // assert(*new_array[2] == 0x070809, 'read_u128_array_1_value');

    // read_u256

    // read_u256_array

    // read_address

    // read_bytes
}