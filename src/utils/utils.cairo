use traits::Into;
use array::ArrayTrait;
use traits::TryInto;
use option::OptionTrait;
use zklink::utils::math::{
    u128_split,
    u128_join,
    felt252_fast_pow2
};
use zklink::utils::bytes::{
    Bytes,
    BytesTrait
};
use zklink::utils::keccak::keccak_u128s_be;
use alexandria_data_structures::array_ext::ArrayTraitExt;


fn u8_array_to_u256(arr: Span<u8>) -> u256 {
    let mut i = 0;
    let mut high: u128 = 0;
    let mut low: u128 = 0;
    // process high
    loop {
        if i == 16 {
            break();
        }
        high = u128_join(high, (*arr[i]).into(), 1);
        i += 1;
    };
    // process low
    loop {
        if i == 16 {
            break();
        }
        low = u128_join(low, (*arr[i]).into(), 1);
        i += 1;
    };

    u256{low, high}
}

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

// new_hash = hash(old_hash + bytes)
fn concatHash(_hash: u256, _bytes: @Bytes) -> u256 {
    let mut hash_data: Array<u128> = ArrayTrait::new();

    // append _hash
    hash_data.append(_hash.high);
    hash_data.append(_hash.low);

    // process _bytes
    let (last_data_index, last_element_size) = BytesTrait::locate(_bytes.size());
    let mut bytes_data = u128_array_slice(_bytes.data, 0, last_data_index);
    // To cumpute hash, we should remove 0 padded
    let (last_element_value, _) = u128_split(*_bytes.data[last_data_index], 16, last_element_size);
    
    // append _bytes
    hash_data.append_all(ref bytes_data);
    hash_data.append(last_element_value);
    keccak_u128s_be(hash_data.span())
}

// Returns new_hash = hash(a + b)
fn concatTwoHash(a: u256, b: u256) -> u256 {
    let mut hash_data: Array<u128> = ArrayTrait::new();

    // append a
    hash_data.append(a.high);
    hash_data.append(a.low);

    // append b
    hash_data.append(b.high);
    hash_data.append(b.low);

    keccak_u128s_be(hash_data.span())
}

// hash ChangePubKey.pubKeyHash(u160, 20 bytes, packed into felt252)
fn pubKeyHash(_pubKeyHash: felt252) -> u256 {
    let mut hash_data: Array<u128> = ArrayTrait::new();
    let _pubKeyHash: u256 = _pubKeyHash.into();
    let (l, r) = u128_split(_pubKeyHash.low, 16, 12);
    let high = u128_join(_pubKeyHash.high, l, 12);

    hash_data.append(high);
    hash_data.append(r);

    keccak_u128s_be(hash_data.span())
}