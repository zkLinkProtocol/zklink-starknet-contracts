use traits::Into;
use array::{ArrayTrait, SpanTrait};
use traits::TryInto;
use option::OptionTrait;
use zklink_starknet_utils::utils::{u128_split, u128_join};
use zklink_starknet_utils::bytes::{Bytes, BytesTrait};
use zklink_starknet_utils::keccak::keccak_u128s_be;
use alexandria_data_structures::array_ext::ArrayTraitExt;

// new_hash = hash(old_hash + bytes)
fn concatHash(_hash: u256, _bytes: @Bytes) -> u256 {
    let mut hash_data: Array<u128> = ArrayTrait::new();

    // append _hash
    hash_data.append(_hash.high);
    hash_data.append(_hash.low);

    // process _bytes
    let mut bytes_data = _bytes.data.clone();
    hash_data.append_all(ref bytes_data);
    hash_data.append(*_bytes.pending_data);
    keccak_u128s_be(hash_data.span(), 32 + _bytes.size())
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

    keccak_u128s_be(hash_data.span(), 64)
}

// hash ChangePubKey.pubKeyHash(u160, 20 bytes, packed into felt252)
fn pubKeyHash(_pubKeyHash: felt252) -> u256 {
    let mut hash_data: Array<u128> = ArrayTrait::new();
    let _pubKeyHash: u256 = _pubKeyHash.into();
    let (l, r) = u128_split(_pubKeyHash.low, 16, 12);
    let high = u128_join(_pubKeyHash.high, l, 12);

    hash_data.append(high);
    hash_data.append(r);

    keccak_u128s_be(hash_data.span(), 20)
}
