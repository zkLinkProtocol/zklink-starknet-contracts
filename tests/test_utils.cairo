use zklink::utils::utils::u256_to_u160;
use debug::PrintTrait;
#[test]
fn test_u256_to_u160() {
    let hash = u256{
        low: 0xaf2186e7afa85296f106336e376669f7,
        high: 0x387a8233c96e1fc0ad5e284353276177
    };

    let value = u256_to_u160(hash);
    assert(value == 0x53276177af2186e7afa85296f106336e376669f7, 'invalid value');
}