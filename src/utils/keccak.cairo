use array::{Span, ArrayTrait, SpanTrait, ArrayDrop};
use integer::u128_byte_reverse;
use traits::TryInto;
use option::OptionTrait;
use starknet::SyscallResultTrait;
use keccak::{u128_to_u64, u128_split as u128_split_to_u64};
use zklink::utils::math::{u32_min, u128_split, u128_div_rem, u128_fast_pow2, u64_pow, u128_join};
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
    add_padding(ref keccak_input, n_bytes);
    u256_reverse_endian(starknet::syscalls::keccak_syscall(keccak_input.span()).unwrap_syscall())
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

// The padding in keccak256 is 10*1;
fn add_padding(ref input: Array<u64>, n_bytes: usize) {
    let aligned = n_bytes % 8 == 0;
    let divisor = integer::u32_try_as_non_zero(KECCAK_FULL_RATE_IN_U64S).unwrap();
    let (q, r) = integer::u32_safe_divmod(input.len(), divisor);
    let padding_len = KECCAK_FULL_RATE_IN_U64S - r;
    // padding_len is in the range [1, KECCAK_FULL_RATE_IN_U64S].
    // padding_len >= 2;
    if aligned {
        if padding_len == 1 {
            input.append(0x8000000000000001);
            return ();
        }
        input.append(1);
        finalize_padding(ref input, padding_len - 1);
    } else {
        let mut last: u64 = *input[input.len() - 1];
        last = u64_pow(2, (n_bytes % 8) * 8) + last;
        input = u64_array_slice(@input, 0, input.len() - 1);
        input.append(last);
        finalize_padding(ref input, padding_len);
    }
}

// Finalize the padding by appending 0*1.
fn finalize_padding(ref input: Array<u64>, padding_len: u32) {
    if (padding_len == 1) {
        input.append(0x8000000000000000);
        return ();
    }

    input.append(0);
    finalize_padding(ref input, padding_len - 1);
}