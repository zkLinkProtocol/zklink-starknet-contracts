// use starknet::{
//     ContractAddress,
//     secp256k1::{
//         recover_public_key, recover_public_key_u32, secp256k1_ec_get_coordinates_syscall,
//         verify_eth_signature
//     },
//     SyscallResultTrait
// };
// use option::OptionTrait;
// use traits::{Into, TryInto};

// /// Converts a public key point to the corresponding Ethereum address.
// fn public_key_point_to_address(public_key_point: Secp256K1EcPoint) -> felt252 {
//     let (x, y) = secp256k1_ec_get_coordinates_syscall(public_key_point).unwrap_syscall();

//     let mut keccak_input = Default::default();
//     keccak_input.append(x);
//     keccak_input.append(y);
//     // Keccak output is little endian.
//     let point_hash_le = keccak_u256s_be_inputs(keccak_input.span());
//     let point_hash = u256 {
//         low: integer::u128_byte_reverse(point_hash_le.high),
//         high: integer::u128_byte_reverse(point_hash_le.low)
//     };

//     point_hash.try_into().unwrap()
// }

// #[test]
// #[available_gas(100000000)]
// fn test_secp256k1_recover_public_key() {
//     let y_parity = true;
//     let msg_hash: u256 = 0x99d947a00c319038bdf644dc9bf28676b3a75819407458e1120c80f1699c39;
//     let r: u256 = 0x27366cf4812d3abc3f2c185a8b65691b6758b7eff45bb6b4e6a5e0f43bdf455;
//     let s : u256 = 0x6bebc15369d88f0cd27c7c365dbb3852afd2f97392672b30626db2dba2e401c;
//     let public_key = recover_public_key(msg_hash, r, s, y_parity).unwrap();
    
//     assert(public_key_point_to_address(public_key) == 0x025ec026985a3bf9d0cc1fe17326b245dfdc3ff89b8fde106542a3ea56c5a918, 'invalid');
// }