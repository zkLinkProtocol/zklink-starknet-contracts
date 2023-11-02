use clone::Clone;
use array::ArrayTrait;
use traits::Into;
use traits::TryInto;
use traits::DivRem;
use option::OptionTrait;
use starknet::{ContractAddress, Felt252TryIntoContractAddress};
use zklink::utils::math::{u128_fast_shift, u128_join, u128_split, read_sub_u128};
use zklink::utils::utils::{u128_array_slice, u8_array_to_u256};
use zklink::utils::keccak::keccak_u128s_be;
use alexandria_math::sha256::sha256;

// You can impl this trait for your own type.
// To make it able to read type T from Bytes.
// Call: ReadBytes::<T>::read(@bytes, offset);
trait ReadBytes<T> {
    fn read(bytes: @Bytes, offset: usize) -> (usize, T);
}

// Bytes is a dynamic array of u128, where each element contains 16 bytes.
const BYTES_PER_ELEMENT: usize = 16;

/// Note that:   In Bytes, there are many variables about size and length.
///              We use size to represent the number of bytes in Bytes.
///              We use length to represent the number of elements in Bytes.

/// Bytes is a cairo implementation of solidity Bytes in Big-endian.
/// It is a dynamic array of u128, where each element contains 16 bytes.

/// Bytes is a dynamic array of u128, where each element contains 16 bytes.
///  - size: the number of bytes in the Bytes
///  - data: the data of the Bytes
#[derive(Drop, Clone, PartialEq, Serde)]
struct Bytes {
    data: Array<u128>,
    pending_data: u128,
    pending_data_size: usize
}

trait BytesTrait {
    /// Create a empty Bytes
    fn new() -> Bytes;
    /// Create a Bytes with size bytes 0
    fn zero(size: usize) -> Bytes;
    /// Locate offset in Bytes
    fn locate(offset: usize) -> (usize, usize);
    /// Get Bytes size
    fn size(self: @Bytes) -> usize;
    /// update specific value (1 bytes) at specific offset
    fn update_at(ref self: Bytes, offset: usize, value: u8);
    /// Read value with size bytes from Bytes, and packed into u128
    fn read_u128_packed(self: @Bytes, offset: usize, size: usize) -> (usize, u128);
    /// Read value with element_size bytes from Bytes, and packed into u128 array
    fn read_u128_array_packed(
        self: @Bytes, offset: usize, array_length: usize, element_size: usize
    ) -> (usize, Array<u128>);
    /// Read value with size bytes from Bytes, and packed into felt252
    fn read_felt252_packed(self: @Bytes, offset: usize, size: usize) -> (usize, felt252);
    /// Read a u8 from Bytes
    fn read_u8(self: @Bytes, offset: usize) -> (usize, u8);
    /// Read a u16 from Bytes
    fn read_u16(self: @Bytes, offset: usize) -> (usize, u16);
    /// Read a u32 from Bytes
    fn read_u32(self: @Bytes, offset: usize) -> (usize, u32);
    /// Read a usize from Bytes
    fn read_usize(self: @Bytes, offset: usize) -> (usize, usize);
    /// Read a u64 from Bytes
    fn read_u64(self: @Bytes, offset: usize) -> (usize, u64);
    /// Read a u128 from Bytes
    fn read_u128(self: @Bytes, offset: usize) -> (usize, u128);
    /// Read a u256 from Bytes
    fn read_u256(self: @Bytes, offset: usize) -> (usize, u256);
    /// Read a u256 array from Bytes
    fn read_u256_array(self: @Bytes, offset: usize, array_length: usize) -> (usize, Array<u256>);
    /// Read sub Bytes with size bytes from Bytes
    fn read_bytes(self: @Bytes, offset: usize, size: usize) -> (usize, Bytes);
    /// Read felt252 from Bytes, which stored as u256
    fn read_felt252(self: @Bytes, offset: usize) -> (usize, felt252);
    /// Read a ContractAddress from Bytes
    fn read_address(self: @Bytes, offset: usize) -> (usize, ContractAddress);
    /// Write value with size bytes into Bytes, value is packed into u128
    fn append_u128_packed(ref self: Bytes, value: u128, size: usize);
    /// Write u8 into Bytes
    fn append_u8(ref self: Bytes, value: u8);
    /// Write u16 into Bytes
    fn append_u16(ref self: Bytes, value: u16);
    /// Write u32 into Bytes
    fn append_u32(ref self: Bytes, value: u32);
    /// Write usize into Bytes
    fn append_usize(ref self: Bytes, value: usize);
    /// Write u64 into Bytes
    fn append_u64(ref self: Bytes, value: u64);
    /// Write u128 into Bytes
    fn append_u128(ref self: Bytes, value: u128);
    /// Write u256 into Bytes
    fn append_u256(ref self: Bytes, value: u256);
    /// Write felt252 into Bytes, which stored as u256
    fn append_felt252(ref self: Bytes, value: felt252);
    /// Write address into Bytes
    fn append_address(ref self: Bytes, value: ContractAddress);
    /// concat with other Bytes
    fn concat(ref self: Bytes, other: @Bytes);
    /// keccak hash
    fn keccak(self: @Bytes) -> u256;
    /// sha256 hash
    fn sha256(self: @Bytes) -> u256;
    /// append pending data
    fn append_pending_data(ref self: Bytes, value: u128, size: usize);
    /// read value from data
    fn read_data(self: @Bytes, offset: usize, size: usize) -> u128;
    /// read value from pending_data
    fn read_pending_data(self: @Bytes, offset: usize, size: usize) -> u128;
}

impl BytesImpl of BytesTrait {
    #[inline(always)]
    fn new() -> Bytes {
        Bytes { data: ArrayTrait::<u128>::new(), pending_data: 0_u128, pending_data_size: 0_usize }
    }

    fn zero(size: usize) -> Bytes {
        let mut data = ArrayTrait::<u128>::new();

        let (mut data_len, pending_data_size) = DivRem::div_rem(
            size, BYTES_PER_ELEMENT.try_into().expect('Division by 0')
        );

        loop {
            if data_len == 0 {
                break;
            };
            data.append(0_u128);
            data_len -= 1;
        };

        Bytes { data, pending_data: 0_u128, pending_data_size }
    }

    /// Locate offset in Bytes
    /// Arguments:
    ///  - offset: the offset in Bytes
    /// Returns:
    ///  - element_index: the index of the element in Bytes
    ///  - element_offset: the offset in the element
    #[inline(always)]
    fn locate(offset: usize) -> (usize, usize) {
        DivRem::div_rem(offset, BYTES_PER_ELEMENT.try_into().expect('Division by 0'))
    }

    /// Get Bytes size
    #[inline(always)]
    fn size(self: @Bytes) -> usize {
        self.data.len() * BYTES_PER_ELEMENT + *self.pending_data_size
    }

    /// update specific value (1 bytes) at specific offset
    fn update_at(ref self: Bytes, offset: usize, value: u8) {
        assert(offset < self.size(), 'update out of bound');
        let mut new_bytes = BytesTrait::new();

        // if update first bytes, ignore
        if offset > 0 {
            let (_, left) = self.read_bytes(0, offset);
            new_bytes.concat(@left);
        }
        new_bytes.append_u8(value);

        // if update last bytes, ignore
        if offset < self.size() - 1 {
            let (_, right) = self.read_bytes(offset + 1, self.size() - offset - 1);
            new_bytes.concat(@right);
        }
        self = new_bytes;
    }

    /// read value from data
    #[inline(always)]
    fn read_data(self: @Bytes, offset: usize, size: usize) -> u128 {
        // check value in one element or two
        // if value in one element, just read it
        // if value in two elements, read them and join them
        let mut value = 0;
        let (element_index, element_offset) = BytesTrait::locate(offset);
        let value_in_one_element = element_offset + size <= BYTES_PER_ELEMENT;
        if value_in_one_element {
            value =
                read_sub_u128(*self.data[element_index], BYTES_PER_ELEMENT, element_offset, size);
        } else {
            let (_, end_element_offset) = BytesTrait::locate(offset + size);
            let left = read_sub_u128(
                *self.data[element_index],
                BYTES_PER_ELEMENT,
                element_offset,
                BYTES_PER_ELEMENT - element_offset
            );
            let right = read_sub_u128(
                *self.data[element_index + 1], BYTES_PER_ELEMENT, 0, end_element_offset
            );
            value = u128_join(left, right, end_element_offset);
        }
        value
    }
    /// read value from pending_data
    #[inline(always)]
    fn read_pending_data(self: @Bytes, offset: usize, size: usize) -> u128 {
        read_sub_u128(*self.pending_data, *self.pending_data_size, offset, size)
    }

    /// Read value with size bytes from Bytes, and packed into u128
    /// Arguments:
    ///  - offset: the offset in Bytes
    ///  - size: the number of bytes to read
    /// Returns:
    ///  - new_offset: next value offset in Bytes
    ///  - value: the value packed into u128
    fn read_u128_packed(self: @Bytes, offset: usize, size: usize) -> (usize, u128) {
        // check
        assert(offset + size <= self.size(), 'out of bound');
        assert(size <= 16, 'too large');

        // There are three cases:
        // 1. value all in pending_data
        // 2. value all in data
        // 3. value in pending_data and data

        // value all in pending_data
        if offset >= self.data.len() * BYTES_PER_ELEMENT {
            let (_, pending_data_offset) = BytesTrait::locate(offset);
            return (offset + size, self.read_pending_data(pending_data_offset, size));
        }

        // value all in data
        if offset + size < self.data.len() * BYTES_PER_ELEMENT {
            return (offset + size, self.read_data(offset, size));
        }

        let left_size = self.data.len() * BYTES_PER_ELEMENT - offset;
        let left = self.read_data(offset, left_size);
        let right = self.read_pending_data(0, size - left_size);
        let value = u128_join(left, right, size - left_size);
        (offset + size, value)
    }

    fn read_u128_array_packed(
        self: @Bytes, offset: usize, array_length: usize, element_size: usize
    ) -> (usize, Array<u128>) {
        assert(offset + array_length * element_size <= self.size(), 'out of bound');
        let mut array = ArrayTrait::<u128>::new();

        if array_length == 0 {
            return (offset, array);
        }
        let mut offset = offset;
        let mut i = array_length;
        loop {
            let (new_offset, value) = self.read_u128_packed(offset, element_size);
            array.append(value);
            offset = new_offset;
            i -= 1;
            if i == 0 {
                break;
            };
        };
        (offset, array)
    }

    /// Read value with size bytes from Bytes, and packed into felt252
    fn read_felt252_packed(self: @Bytes, offset: usize, size: usize) -> (usize, felt252) {
        // check
        assert(offset + size <= self.size(), 'out of bound');
        // Bytes unit is one byte
        // felt252 can hold 31 bytes max
        assert(size <= 31, 'too large');

        if size <= 16 {
            let (new_offset, value) = self.read_u128_packed(offset, size);
            return (new_offset, value.into());
        } else {
            let (new_offset, high) = self.read_u128_packed(offset, size - 16);
            let (new_offset, low) = self.read_u128_packed(new_offset, 16);
            return (new_offset, u256 { low, high }.try_into().unwrap());
        }
    }

    /// Read a u8 from Bytes
    #[inline(always)]
    fn read_u8(self: @Bytes, offset: usize) -> (usize, u8) {
        let (new_offset, value) = self.read_u128_packed(offset, 1);
        (new_offset, value.try_into().unwrap())
    }
    /// Read a u16 from Bytes
    #[inline(always)]
    fn read_u16(self: @Bytes, offset: usize) -> (usize, u16) {
        let (new_offset, value) = self.read_u128_packed(offset, 2);
        (new_offset, value.try_into().unwrap())
    }
    /// Read a u32 from Bytes
    #[inline(always)]
    fn read_u32(self: @Bytes, offset: usize) -> (usize, u32) {
        let (new_offset, value) = self.read_u128_packed(offset, 4);
        (new_offset, value.try_into().unwrap())
    }
    /// Read a usize from Bytes
    #[inline(always)]
    fn read_usize(self: @Bytes, offset: usize) -> (usize, usize) {
        let (new_offset, value) = self.read_u128_packed(offset, 4);
        (new_offset, value.try_into().unwrap())
    }
    /// Read a u64 from Bytes
    #[inline(always)]
    fn read_u64(self: @Bytes, offset: usize) -> (usize, u64) {
        let (new_offset, value) = self.read_u128_packed(offset, 8);
        (new_offset, value.try_into().unwrap())
    }

    /// read a u128 from Bytes
    #[inline(always)]
    fn read_u128(self: @Bytes, offset: usize) -> (usize, u128) {
        self.read_u128_packed(offset, 16)
    }

    /// read a u256 from Bytes
    #[inline(always)]
    fn read_u256(self: @Bytes, offset: usize) -> (usize, u256) {
        // check
        assert(offset + 32 <= self.size(), 'out of bound');

        let (new_offset, high) = self.read_u128(offset);
        let (new_offset, low) = self.read_u128(new_offset);

        (new_offset, u256 { low, high })
    }

    /// read a u256 array from Bytes
    fn read_u256_array(self: @Bytes, offset: usize, array_length: usize) -> (usize, Array<u256>) {
        assert(offset + array_length * 32 <= self.size(), 'out of bound');
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
                break;
            };
        };
        (offset, array)
    }

    /// read sub Bytes from Bytes
    fn read_bytes(self: @Bytes, offset: usize, size: usize) -> (usize, Bytes) {
        // check
        assert(offset + size <= self.size(), 'out of bound');

        if size == 0 {
            return (offset, BytesTrait::new());
        }

        let mut sub_bytes = BytesTrait::new();

        // read full array element for sub_bytes
        let mut offset = offset;
        let mut sub_bytes_full_array_len = size / BYTES_PER_ELEMENT;
        loop {
            if sub_bytes_full_array_len == 0 {
                break;
            };
            let (new_offset, value) = self.read_u128(offset);
            sub_bytes.data.append(value);
            offset = new_offset;
            sub_bytes_full_array_len -= 1;
        };

        // process last array element for sub_bytes
        // 1. read last element real value;
        // 2. make last element full with padding 0;
        let sub_bytes_last_element_size = size % BYTES_PER_ELEMENT;
        if sub_bytes_last_element_size > 0 {
            let (new_offset, value) = self.read_u128_packed(offset, sub_bytes_last_element_size);
            sub_bytes.pending_data = value;
            sub_bytes.pending_data_size = sub_bytes_last_element_size;
            offset = new_offset;
        }

        return (offset, sub_bytes);
    }

    /// read felt252 from Bytes
    /// felt252 stores as u256 in Bytes
    #[inline(always)]
    fn read_felt252(self: @Bytes, offset: usize) -> (usize, felt252) {
        let (new_offset, value) = self.read_u256(offset);
        (new_offset, value.try_into().expect('Couldn\'t convert to felt252'))
    }

    /// read Contract Address from Bytes
    #[inline(always)]
    fn read_address(self: @Bytes, offset: usize) -> (usize, ContractAddress) {
        let (new_offset, value) = self.read_u256(offset);
        let address: felt252 = value.try_into().expect('Couldn\'t convert to felt252');
        (new_offset, address.try_into().expect('Couldn\'t convert to address'))
    }

    /// Write value with size bytes into Bytes, value is packed into u128
    fn append_u128_packed(ref self: Bytes, value: u128, size: usize) {
        assert(size <= 16, 'size must be less than 16');

        if (size == 0) {
            return;
        }

        let total_pending_bytes = self.pending_data_size + size;

        if total_pending_bytes < BYTES_PER_ELEMENT {
            self.append_pending_data(value, size);
            return;
        }

        if total_pending_bytes == BYTES_PER_ELEMENT {
            if (self.pending_data_size == 0) {
                self.data.append(value);
                return;
            }

            self.data.append(self.pending_data * u128_fast_shift(size) + value);
            self.pending_data = 0;
            self.pending_data_size = 0;
            return;
        }

        let left_size = BYTES_PER_ELEMENT - self.pending_data_size;
        let (left, right) = u128_split(value, size, left_size);
        self.data.append(self.pending_data * u128_fast_shift(left_size) + left);
        self.pending_data = right;
        self.pending_data_size = size - left_size;
    }


    /// append pending data
    #[inline(always)]
    fn append_pending_data(ref self: Bytes, value: u128, size: usize) {
        if self.pending_data_size == 0 {
            self.pending_data = value;
            self.pending_data_size = size;
            return;
        }
        
        self.pending_data = u128_join(self.pending_data, value, size);
        self.pending_data_size += size;
    }

    /// Write u8 into Bytes
    #[inline(always)]
    fn append_u8(ref self: Bytes, value: u8) {
        self.append_u128_packed(value.into(), 1)
    }

    /// Write u16 into Bytes
    #[inline(always)]
    fn append_u16(ref self: Bytes, value: u16) {
        self.append_u128_packed(value.into(), 2)
    }

    /// Write u32 into Bytes
    #[inline(always)]
    fn append_u32(ref self: Bytes, value: u32) {
        self.append_u128_packed(value.into(), 4)
    }

    /// Write usize into Bytes
    #[inline(always)]
    fn append_usize(ref self: Bytes, value: usize) {
        self.append_u128_packed(value.into(), 4)
    }

    /// Write u64 into Bytes
    #[inline(always)]
    fn append_u64(ref self: Bytes, value: u64) {
        self.append_u128_packed(value.into(), 8)
    }

    /// Write u128 into Bytes
    #[inline(always)]
    fn append_u128(ref self: Bytes, value: u128) {
        self.append_u128_packed(value, 16)
    }

    /// Write u256 into Bytes
    #[inline(always)]
    fn append_u256(ref self: Bytes, value: u256) {
        self.append_u128(value.high);
        self.append_u128(value.low);
    }

    /// Write felt252 into Bytes, which stored as u256
    #[inline(always)]
    fn append_felt252(ref self: Bytes, value: felt252) {
        let value: u256 = value.into();
        self.append_u256(value)
    }

    /// Write address into Bytes
    #[inline(always)]
    fn append_address(ref self: Bytes, value: ContractAddress) {
        let address_felt256: felt252 = value.into();
        let address_u256: u256 = address_felt256.into();
        self.append_u256(address_u256)
    }

    /// concat with other Bytes
    fn concat(ref self: Bytes, other: @Bytes) {
        // read full array element for other
        let mut offset = 0;
        let mut sub_bytes_full_array_len = other.size() / BYTES_PER_ELEMENT;
        loop {
            if sub_bytes_full_array_len == 0 {
                break;
            };
            let (new_offset, value) = other.read_u128(offset);
            self.append_u128(value);
            offset = new_offset;
            sub_bytes_full_array_len -= 1;
        };

        // process last array element for right
        let sub_bytes_last_element_size = other.size() % BYTES_PER_ELEMENT;
        if sub_bytes_last_element_size > 0 {
            let (new_offset, value) = other.read_u128_packed(offset, sub_bytes_last_element_size);
            self.append_u128_packed(value, sub_bytes_last_element_size);
        }
    }

    /// keccak hash
    fn keccak(self: @Bytes) -> u256 {
        if *self.pending_data_size == 0 {
            return keccak_u128s_be(self.data.span(), self.size());
        } else {
            let mut hash_data = self.data.clone();
            hash_data.append(*self.pending_data);
            return keccak_u128s_be(hash_data.span(), self.size());
        }
    }

    /// sha256 hash
    fn sha256(self: @Bytes) -> u256 {
        let mut hash_data: Array<u8> = ArrayTrait::new();
        let mut i: usize = 0;
        let mut offset: usize = 0;
        loop {
            if i == self.size() {
                break;
            }
            let (new_offset, hash_data_item) = self.read_u8(offset);
            hash_data.append(hash_data_item);
            offset = new_offset;
            i += 1;
        };

        let output: Array<u8> = sha256(hash_data);
        u8_array_to_u256(output.span())
    }
}