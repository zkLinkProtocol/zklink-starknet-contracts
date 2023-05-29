use array::{Span, ArrayTrait, SpanTrait, ArrayDrop};
use integer::u128_byte_reverse;
use traits::TryInto;
use option::OptionTrait;
use starknet::SyscallResultTrait;
use keccak::{
    u128_to_u64,
    u128_split,
    add_padding
};

fn u256_reverse_endian(input: u256) -> u256 {
    let low = u128_byte_reverse(input.high);
    let high = u128_byte_reverse(input.low);
    u256 { low, high }
}

// Computes the keccak256 of multiple uint128 values.
// The values are interpreted as big-endian.
// https://github.com/starkware-libs/cairo/blob/main/corelib/src/keccak.cairo
fn keccak_u128s_be(mut input: Span<u128>) -> u256 {
    let mut keccak_input: Array::<u64> = ArrayTrait::new();

    loop {
        match input.pop_front() {
            Option::Some(v) => {
                keccak_add_uint128_be(ref keccak_input, *v);
            },
            Option::None(_) => {
                break ();
            },
        };
    };

    add_padding(ref keccak_input);
    u256_reverse_endian(starknet::syscalls::keccak_syscall(keccak_input.span()).unwrap_syscall())
}

fn keccak_add_uint128_be(ref keccak_input: Array::<u64>, value: u128) {
    let (high, low) = u128_split(u128_byte_reverse(value));
    keccak_input.append(low);
    keccak_input.append(high);
}