use core::array::ArrayTrait;
use core::traits::TryInto;
use option::OptionTrait;
use zklink::utils::math::{
    u128_split,
    felt252_fast_pow2
};


// https://github.com/keep-starknet-strange/alexandria/blob/main/alexandria/data_structures/src/data_structures.cairo
/// Returns the slice of an array.
/// * `arr` - The array to slice.
/// * `begin` - The index to start the slice at.
/// * `end` - The index to end the slice at (not included).
/// # Returns
/// * `Array<u128>` - The slice of the array.
fn u128_array_slice(src: @Array<u128>, mut begin: usize, end: usize) -> Array<u128> {
    let mut slice = ArrayTrait::new();
    let len = begin + end;
    loop {
        if begin >= len {
            break ();
        }
        if begin >= src.len() {
            break ();
        }

        slice.append(*src[begin]);
        begin += 1;
    };
    slice
}

const U256_TO_U160_MASK: u256 = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
// Take the 20-byte(u160) low-order bits of u256 and store them into felt252.
fn u256_to_u160(src: u256) -> felt252 {
    (src & U256_TO_U160_MASK).try_into().unwrap()
}