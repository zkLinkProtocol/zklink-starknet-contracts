use core::array::ArrayTrait;
use serde::Serde;
use debug::PrintTrait;

// Learn cairo by write unittest

// #[test]
// fn test_pow() {
//     assert(2 * 3 == 6, '2 * 3');
//     // assert(pow(2, 3) == 8, 'pow(2, 3)');
// }

// fn foo(offset: felt252) -> (felt252, felt252) {
//     (offset + 1, 0)
// }

// #[test]
// fn test_var() {
//     let (offset, a) = foo(0);
//     let (offset, b) = foo(offset);
//     let (offset, c) = foo(offset);

//     assert(offset == 3, 'offset');
// }

// #[test]
// #[available_gas(200000)]
// fn test_serialize() {
//     let mut original = ArrayTrait::<felt252>::new();
//     let mut output = ArrayTrait::<felt252>::new();
//     original.append(1);
//     original.append(2);
//     original.serialize(ref output);
//     original.print()
// }

// #[test]
// fn test_bitwise() {
//     let a = u256{low: 0, high: 0};
//     let b = u256{low: 0xaf2186e7afa85296f106336e376669f7,
//         high: 0x387a8233c96e1fc0ad5e284353276177};
//     let c = a & b;
//     c.print();
// }