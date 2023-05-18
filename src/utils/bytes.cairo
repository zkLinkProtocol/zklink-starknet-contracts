use array::ArrayTrait;
use core::traits::Into;
use core::traits::TryInto;
use core::option::OptionTrait;
use starknet::{
    ContractAddress,
    Felt252TryIntoContractAddress
};
use zklink::utils::math::{
    felt252_fast_pow2,
    u128_fast_pow2,
    u128_div_rem,
    u128_join,
    u128_split,
    u128_sub_value,
    usize_div_rem
};

// Bytes is a dynamic array of u128, where each element contains 16 bytes.
const BYTES_PER_ELEMENT: usize = 16;

// Note that:   In Bytes, there are many variables about size and length.
//              We use size to represent the number of bytes in Bytes.
//              We use length to represent the number of elements in Bytes.

// Bytes is a cairo implementation of solidity Bytes.
// It is a dynamic array of u128, where each element contains 16 bytes.
// To save cost, the last element MUST be filled fully.
// That's means that every element should and MUST contains 16 bytes.
// For example, if we have a Bytes with 33 bytes, we will have 3 elements.
// Theroetically, the bytes looks like this:
//      first element:  [16 bytes]
//      second element: [16 bytes]
//      third element:  [1 byte]
// But in zkLink Bytes, the last element should be padded with zero to make
// it 16 bytes. So the zkLink bytes looks like this:
//      first element:  [16 bytes]
//      second element: [16 bytes]
//      third element:  [1 byte] + [15 bytes zero padding]

// Bytes is a dynamic array of u128, where each element contains 16 bytes.
//  - size: the number of bytes in the Bytes
//  - data: the data of the Bytes
#[derive(Drop)]
struct Bytes {
    size: usize,
    data: Array<u128>
}

trait BytesTrait {
    // Create a Bytes from an array of u128
    fn new(size: usize, data: Array::<u128>) -> Bytes;
    // Create an empty Bytes
    fn new_empty() -> Bytes;
    // Locate offset in Bytes
    fn locate(offset: usize) -> (usize, usize);
    // Read value with size bytes from Bytes, and packed into u128
    fn read_u128(self: @Bytes, offset: usize, size: usize) -> (usize, u128);
    // Read value with element_size bytes from Bytes, and packed into u128 array
    fn read_u128_array(self: @Bytes, offset: usize, array_length: usize, element_size: usize) -> (usize, Array<u128>);
    // Read a u256 from Bytes
    fn read_u256(self: @Bytes, offset: usize) -> (usize, u256);
    // Read a u256 array from Bytes
    fn read_u256_array(self: @Bytes, offset: usize, array_length: usize) -> (usize, Array<u256>);
    // Read sub Bytes with size bytes from Bytes
    fn read_bytes(self: @Bytes, offset: usize, size: usize) -> (usize, Bytes);
    // Read a ContractAddress from Bytes
    fn read_address(self: @Bytes, offset: usize) -> (usize, ContractAddress);
}

impl BytesImpl of BytesTrait {
    fn new(size: usize, data: Array::<u128>) -> Bytes {
        Bytes {
            size,
            data
        }
    }

    fn new_empty() -> Bytes {
        let mut data = ArrayTrait::<u128>::new();
        Bytes {
            size: 0_usize,
            data: data
        }
    }

    // Locat offset in Bytes
    // Arguments:
    //  - offset: the offset in Bytes
    // Returns:
    //  - element_index: the index of the element in Bytes
    //  - element_offset: the offset in the element
    fn locate(offset: usize) -> (usize, usize) {
        usize_div_rem(offset, BYTES_PER_ELEMENT)
    }

    // Read value with size bytes from Bytes, and packed into u128
    // Arguments:
    //  - offset: the offset in Bytes
    //  - size: the number of bytes to read
    // Returns:
    //  - new_offset: next value offset in Bytes
    //  - value: the value packed into u128
    fn read_u128(self: @Bytes, offset: usize, size: usize) -> (usize, u128) {
        // check
        assert(offset + size <= *self.size, 'out of bound');
        assert(size * 8 <= 128, 'too large');

        // check value in one element or two
        // if value in one element, just read it
        // if value in two elements, read them and join them
        let (element_index, element_offset) = BytesTrait::locate(offset);
        let value_in_one_element = element_offset + size <= BYTES_PER_ELEMENT;

        if value_in_one_element {
            let value = u128_sub_value(*self.data[element_index], BYTES_PER_ELEMENT, element_offset, size);
            return (offset + size, value);
        } else {
            let (_, end_element_offset) = BytesTrait::locate(offset + size);
            let left = u128_sub_value(*self.data[element_index], BYTES_PER_ELEMENT, element_offset, BYTES_PER_ELEMENT - element_offset);
            let right = u128_sub_value(*self.data[element_index + 1], BYTES_PER_ELEMENT, 0, end_element_offset);
            let value = u128_join(left, right, end_element_offset);
            return (offset + size, value);
        }
    }

    fn read_u128_array(self: @Bytes, offset: usize, array_length: usize, element_size: usize) -> (usize, Array<u128>) {
        assert(offset + array_length * element_size <= *self.size, 'out of bound');
        let mut array = ArrayTrait::<u128>::new();

        if array_length == 0 {
            return (offset, array);
        }
        let mut offset = offset;
        let mut i = array_length;
        loop {
            let (new_offset, value) = self.read_u128(offset, element_size);
            array.append(value);
            offset = new_offset;
            i -= 1;
            if i == 0 {
                break();
            };
        };
        (offset, array)
    }

    // read a u256 from Bytes
    fn read_u256(self: @Bytes, offset: usize) -> (usize, u256) {
        // check
        assert(offset + 32 <= *self.size, 'out of bound');

        let (element_index, element_offset) = BytesTrait::locate(offset);
        let (new_offset, high) = self.read_u128(offset, 16);
        let (new_offset, low) = self.read_u128(new_offset, 16);

        (new_offset, u256 { low, high })
    }

    // read a u256 array from Bytes
    fn read_u256_array(self: @Bytes, offset: usize, array_length: usize) -> (usize, Array<u256>) {
        assert(offset + array_length * 32 <= *self.size, 'out of bound');
        let mut array = ArrayTrait::<u256>::new();
        
        if array_length == 0 {
            return (offset, array);
        }

        let mut offset = offset;
        let mut i = array_length;
        loop {
            let (new_offset, value) = self.read_u256(offset);
            array.append(value);
            offset = new_offset;
            i -= 1;
            if i == 0 {
                break();
            };
        };
        (offset, array)
    }

    // read sub Bytes from Bytes
    fn read_bytes(self: @Bytes, offset: usize, size: usize) -> (usize, Bytes) {
        // check
        assert(offset + size <= *self.size, 'out of bound');
        let mut array = ArrayTrait::<u128>::new();
        if size == 0 {
            return (offset, BytesTrait::new(0, array));
        }

        // read full array element for sub_bytes
        let mut new_offset = offset;
        let mut sub_bytes_full_array_len = size / BYTES_PER_ELEMENT;
        loop {
            let (new_offset, value) = self.read_u128(new_offset, BYTES_PER_ELEMENT);
            array.append(value);
            sub_bytes_full_array_len -= 1;
            if sub_bytes_full_array_len == 0 {
                break();
            };
        };

        // process last array element for sub_bytes
        // 1. read last element real value;
        // 2. make last element full with padding 0;
        let sub_bytes_last_element_size = size % BYTES_PER_ELEMENT;
        if sub_bytes_last_element_size > 0 {
            let (new_offset, value) = self.read_u128(new_offset, sub_bytes_last_element_size);
            let padding = BYTES_PER_ELEMENT - sub_bytes_last_element_size;
            let value = u128_join(value, 0, padding);
            array.append(value);
        }

        return (new_offset, BytesTrait::new(size, array));
    }

    // read address from Bytes
    fn read_address(self: @Bytes, offset: usize) -> (usize, ContractAddress) {
        let (new_offset, value) = self.read_u256(offset);
        let address: felt252 = value.high.into() * felt252_fast_pow2(128) + value.low.into();
        (new_offset, address.try_into().unwrap())
    }
}