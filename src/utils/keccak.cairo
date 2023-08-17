use array::{Span, ArrayTrait, SpanTrait, ArrayDrop};
use integer::u128_byte_reverse;
use traits::TryInto;
use option::OptionTrait;
use starknet::SyscallResultTrait;
use keccak::{u128_to_u64, u128_split as u128_split_to_u64, cairo_keccak};
use zklink::utils::math::{u32_min, u128_split, u128_div_rem, u128_fast_pow2, u128_join};
use zklink::utils::utils::u64_array_slice;

const KECCAK_FULL_RATE_IN_U64S: usize = 17;

fn u256_reverse_endian(input: u256) -> u256 {
    let low = u128_byte_reverse(input.high);
    let high = u128_byte_reverse(input.low);
    u256 { low, high }
}

// Computes the keccak256 of multiple uint128 values.
// The values are interpreted as big-endian.
// https://github.com/starkware-libs/cairo/blob/main/corelib/src/keccak.cairo
fn keccak_u128s_be(mut input: Span<u128>, n_bytes: usize) -> u256 {
    let mut keccak_input: Array::<u64> = ArrayTrait::new();
    let mut size = n_bytes;
    loop {
        match input.pop_front() {
            Option::Some(v) => {
                let value_size = u32_min(size, 16);
                keccak_add_uint128_be(ref keccak_input, *v, value_size);
                size -= value_size;
            },
            Option::None(_) => {
                break ();
            },
        };
    };

    let aligned = n_bytes % 8 == 0;
    if aligned {
        u256_reverse_endian(cairo_keccak(ref keccak_input, 0, 0))
    } else {
        let last_input_num_bytes = n_bytes % 8;
        let last_input_word = *keccak_input[keccak_input.len() - 1];
        let mut inputs = u64_array_slice(@keccak_input, 0, keccak_input.len() - 1);
        u256_reverse_endian(cairo_keccak(ref inputs, last_input_word, last_input_num_bytes))
    }
}

fn keccak_add_uint128_be(ref keccak_input: Array::<u64>, value: u128, value_size: usize) {
    if value_size == 16 {
        let (high, low) = u128_split_to_u64(u128_byte_reverse(value));
        keccak_input.append(low);
        keccak_input.append(high);
    } else {
        let reversed_value = u128_byte_reverse(value);
        let (reversed_value, _) = u128_split(reversed_value, 16, value_size);
        if value_size <= 8 {
            keccak_input.append(u128_to_u64(reversed_value));
        } else {
            let (high, low) = u128_div_rem(reversed_value, u128_fast_pow2(64));
            keccak_input.append(u128_to_u64(low));
            keccak_input.append(u128_to_u64(high));
        }
    }
}
