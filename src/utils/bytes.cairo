use array::ArrayTrait;
use option::OptionTrait;
use zklink::utils::pow2::fast_pow2;

const BYTES_PER_FILT: usize = 16;

#[derive(Drop)]
struct Bytes {
    size: usize,
    data: Array<felt252>
}

trait BytesTrait {
    fn new(size: usize, data: Array::<felt252>) -> Bytes;
    fn new_empty() -> Bytes;
}

impl BytesImpl of BytesTrait {
    fn new(size: usize, data: Array::<felt252>) -> Bytes {
        Bytes {
            size,
            data
        }
    }

    fn new_empty() -> Bytes {
        bytes_new()
    }
}

fn bytes_new() -> Bytes {
    let mut data = ArrayTrait::<felt252>::new();
    Bytes {
        size: 0_usize,
        data: data
    }
}