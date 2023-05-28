use traits::Into;
use traits::TryInto;

// usize div mod function
// value = q * div + r
fn usize_div_rem(value: usize, div: usize) -> (usize, usize) {
    let q = value / div;
    let r = value % div;
    assert(q * div + r == value, 'div_rem error');
    (q, r)
}

// u128 div mod function
// value = q * div + r
fn u128_div_rem(value: u128, div: u128) -> (u128, u128) {
     let q = value / div;
    let r = value % div;
    assert(q * div + r == value, 'div_rem error');
    (q, r)
}

// Split a u128 into two parts, [0, size-1] and [size, end]
// Parameters:
//  - value: data of u128
//  - value_size: the size of `value` in bytes
//  - size: the size of left part in bytes
// Returns:
//  - letf: [0, size-1] of the origin u128
//  - right: [size, end] of the origin u128 which size is (value_size - size)
fn u128_split(value: u128, value_size: usize, size: usize) -> (u128, u128) {
    assert(value_size <= 16, 'value_size can not be gt 16');
    assert(size <= value_size, 'size can not be gt value_size');

    if size == 0 {
        return (0_u128, value);
    } else {
        let (left, right) = u128_div_rem(value, u128_fast_pow2((value_size - size) * 8));
        return (left, right);
    }

}

// Read sub value from u128 just like substr in other language
// Parameters:
//  - value: data of u128
//  - value_size: the size of data in bytes
//  - offset: the offset of sub value
//  - size: the size of sub value in bytes
// Returns:
//  - sub_value: the sub value of origin u128
fn u128_sub_value(value: u128, value_size: usize, offset: usize, size: usize) -> u128 {
    assert(value_size != 0, 'value_size can not be 0');
    assert(size != 0, 'size can not be 0');
    assert(offset + size <= value_size, 'too long');

    if size == value_size {
        return value;
    }

    let (_, right) = u128_split(value, value_size, offset);
    let (sub_value, _) = u128_split(right, value_size - offset, size);
    sub_value
}

// Join two u128 into one
// Parameters:
//  - left: the left part of u128
//  - right: the right part of u128
//  - right_size: the size of right part in bytes
// Returns:
//  - value: the joined u128
fn u128_join(left: u128, right: u128, right_size: usize) -> u128 {
    let shit = u128_fast_pow2(right_size * 8);
    left * shit + right
}

impl U32IntoU256 of Into<u32, u256> {
    fn into(self: u32) -> u256 {
        u256{low: self.into(), high: 0}
    }
}

impl U64IntoU256 of Into<u64, u256> {
    fn into(self: u64) -> u256 {
        u256{low: self.into(), high: 0}
    }
}

impl U128IntoU256 of Into<u128, u256> {
    fn into(self: u128) -> u256 {
        u256{low: self, high: 0}
    }
}

impl U256TryIntoU128 of TryInto<u256, u128> {
    fn try_into(self: u256) -> Option<u128> {
        if self.high == 0 {
            return Option::Some(self.low);
        } else {
            return Option::None(());
        }
    }
}

// common u128 pow
fn u128_pow(base: u128, mut exp: usize) -> u128 {
    let mut res = 1;
    loop {
        if exp == 0 {
            break res;
        } else {
            res = base * res;
        }
        exp = exp - 1;
    }
}

// common 256 pow2
fn u256_pow2(mut exp: usize) -> u256 {
    // TODO: change to 1_256
    let mut res: u256 = u256{low: 1, high: 0};
    loop {
        if exp == 0 {
            break res;
        } else {
            // TODO: change to 2_256
            res = u256{low: 2, high: 0} * res;
        }
        exp = exp - 1;
    }
}

// min u8
fn u8_min(l: u8, r: u8) -> u8 {
    if l <= r {
        return l;
    } else {
        return r;
    }
}

const U256_TO_U160_MASK: u256 = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
// Take the 20-byte(u160) low-order bits of u256 and store them into felt252.
fn u256_to_u160(src: u256) -> felt252 {
    // TODO: use try_into
    // (src & U256_TO_U160_MASK).try_into().unwrap()
    let value: u256 = src & U256_TO_U160_MASK;
    let value: felt252 = value.high.into() * felt252_fast_pow2(128) + value.low.into();
    value
}


// u128 fast pow2 function
// TODO: Now cairo match just support 0, future we use fast pow2 will be better
fn u128_fast_pow2(exp: usize) -> u128 {
    if exp == 0_usize { 1_u128 }
    else if exp == 1_usize { 2_u128 }
    else if exp == 2_usize { 4_u128 }
    else if exp == 3_usize { 8_u128 }
    else if exp == 4_usize { 16_u128 }
    else if exp == 5_usize { 32_u128 }
    else if exp == 6_usize { 64_u128 }
    else if exp == 7_usize { 128_u128 }
    else if exp == 8_usize { 256_u128 }
    else if exp == 9_usize { 512_u128 }
    else if exp == 10_usize { 1024_u128 }
    else if exp == 11_usize { 2048_u128 }
    else if exp == 12_usize { 4096_u128 }
    else if exp == 13_usize { 8192_u128 }
    else if exp == 14_usize { 16384_u128 }
    else if exp == 15_usize { 32768_u128 }
    else if exp == 16_usize { 65536_u128 }
    else if exp == 17_usize { 131072_u128 }
    else if exp == 18_usize { 262144_u128 }
    else if exp == 19_usize { 524288_u128 }
    else if exp == 20_usize { 1048576_u128 }
    else if exp == 21_usize { 2097152_u128 }
    else if exp == 22_usize { 4194304_u128 }
    else if exp == 23_usize { 8388608_u128 }
    else if exp == 24_usize { 16777216_u128 }
    else if exp == 25_usize { 33554432_u128 }
    else if exp == 26_usize { 67108864_u128 }
    else if exp == 27_usize { 134217728_u128 }
    else if exp == 28_usize { 268435456_u128 }
    else if exp == 29_usize { 536870912_u128 }
    else if exp == 30_usize { 1073741824_u128 }
    else if exp == 31_usize { 2147483648_u128 }
    else if exp == 32_usize { 4294967296_u128 }
    else if exp == 33_usize { 8589934592_u128 }
    else if exp == 34_usize { 17179869184_u128 }
    else if exp == 35_usize { 34359738368_u128 }
    else if exp == 36_usize { 68719476736_u128 }
    else if exp == 37_usize { 137438953472_u128 }
    else if exp == 38_usize { 274877906944_u128 }
    else if exp == 39_usize { 549755813888_u128 }
    else if exp == 40_usize { 1099511627776_u128 }
    else if exp == 41_usize { 2199023255552_u128 }
    else if exp == 42_usize { 4398046511104_u128 }
    else if exp == 43_usize { 8796093022208_u128 }
    else if exp == 44_usize { 17592186044416_u128 }
    else if exp == 45_usize { 35184372088832_u128 }
    else if exp == 46_usize { 70368744177664_u128 }
    else if exp == 47_usize { 140737488355328_u128 }
    else if exp == 48_usize { 281474976710656_u128 }
    else if exp == 49_usize { 562949953421312_u128 }
    else if exp == 50_usize { 1125899906842624_u128 }
    else if exp == 51_usize { 2251799813685248_u128 }
    else if exp == 52_usize { 4503599627370496_u128 }
    else if exp == 53_usize { 9007199254740992_u128 }
    else if exp == 54_usize { 18014398509481984_u128 }
    else if exp == 55_usize { 36028797018963968_u128 }
    else if exp == 56_usize { 72057594037927936_u128 }
    else if exp == 57_usize { 144115188075855872_u128 }
    else if exp == 58_usize { 288230376151711744_u128 }
    else if exp == 59_usize { 576460752303423488_u128 }
    else if exp == 60_usize { 1152921504606846976_u128 }
    else if exp == 61_usize { 2305843009213693952_u128 }
    else if exp == 62_usize { 4611686018427387904_u128 }
    else if exp == 63_usize { 9223372036854775808_u128 }
    else if exp == 64_usize { 18446744073709551616_u128 }
    else if exp == 65_usize { 36893488147419103232_u128 }
    else if exp == 66_usize { 73786976294838206464_u128 }
    else if exp == 67_usize { 147573952589676412928_u128 }
    else if exp == 68_usize { 295147905179352825856_u128 }
    else if exp == 69_usize { 590295810358705651712_u128 }
    else if exp == 70_usize { 1180591620717411303424_u128 }
    else if exp == 71_usize { 2361183241434822606848_u128 }
    else if exp == 72_usize { 4722366482869645213696_u128 }
    else if exp == 73_usize { 9444732965739290427392_u128 }
    else if exp == 74_usize { 18889465931478580854784_u128 }
    else if exp == 75_usize { 37778931862957161709568_u128 }
    else if exp == 76_usize { 75557863725914323419136_u128 }
    else if exp == 77_usize { 151115727451828646838272_u128 }
    else if exp == 78_usize { 302231454903657293676544_u128 }
    else if exp == 79_usize { 604462909807314587353088_u128 }
    else if exp == 80_usize { 1208925819614629174706176_u128 }
    else if exp == 81_usize { 2417851639229258349412352_u128 }
    else if exp == 82_usize { 4835703278458516698824704_u128 }
    else if exp == 83_usize { 9671406556917033397649408_u128 }
    else if exp == 84_usize { 19342813113834066795298816_u128 }
    else if exp == 85_usize { 38685626227668133590597632_u128 }
    else if exp == 86_usize { 77371252455336267181195264_u128 }
    else if exp == 87_usize { 154742504910672534362390528_u128 }
    else if exp == 88_usize { 309485009821345068724781056_u128 }
    else if exp == 89_usize { 618970019642690137449562112_u128 }
    else if exp == 90_usize { 1237940039285380274899124224_u128 }
    else if exp == 91_usize { 2475880078570760549798248448_u128 }
    else if exp == 92_usize { 4951760157141521099596496896_u128 }
    else if exp == 93_usize { 9903520314283042199192993792_u128 }
    else if exp == 94_usize { 19807040628566084398385987584_u128 }
    else if exp == 95_usize { 39614081257132168796771975168_u128 }
    else if exp == 96_usize { 79228162514264337593543950336_u128 }
    else if exp == 97_usize { 158456325028528675187087900672_u128 }
    else if exp == 98_usize { 316912650057057350374175801344_u128 }
    else if exp == 99_usize { 633825300114114700748351602688_u128 }
    else if exp == 100_usize { 1267650600228229401496703205376_u128 }
    else if exp == 101_usize { 2535301200456458802993406410752_u128 }
    else if exp == 102_usize { 5070602400912917605986812821504_u128 }
    else if exp == 103_usize { 10141204801825835211973625643008_u128 }
    else if exp == 104_usize { 20282409603651670423947251286016_u128 }
    else if exp == 105_usize { 40564819207303340847894502572032_u128 }
    else if exp == 106_usize { 81129638414606681695789005144064_u128 }
    else if exp == 107_usize { 162259276829213363391578010288128_u128 }
    else if exp == 108_usize { 324518553658426726783156020576256_u128 }
    else if exp == 109_usize { 649037107316853453566312041152512_u128 }
    else if exp == 110_usize { 1298074214633706907132624082305024_u128 }
    else if exp == 111_usize { 2596148429267413814265248164610048_u128 }
    else if exp == 112_usize { 5192296858534827628530496329220096_u128 }
    else if exp == 113_usize { 10384593717069655257060992658440192_u128 }
    else if exp == 114_usize { 20769187434139310514121985316880384_u128 }
    else if exp == 115_usize { 41538374868278621028243970633760768_u128 }
    else if exp == 116_usize { 83076749736557242056487941267521536_u128 }
    else if exp == 117_usize { 166153499473114484112975882535043072_u128 }
    else if exp == 118_usize { 332306998946228968225951765070086144_u128 }
    else if exp == 119_usize { 664613997892457936451903530140172288_u128 }
    else if exp == 120_usize { 1329227995784915872903807060280344576_u128 }
    else if exp == 121_usize { 2658455991569831745807614120560689152_u128 }
    else if exp == 122_usize { 5316911983139663491615228241121378304_u128 }
    else if exp == 123_usize { 10633823966279326983230456482242756608_u128 }
    else if exp == 124_usize { 21267647932558653966460912964485513216_u128 }
    else if exp == 125_usize { 42535295865117307932921825928971026432_u128 }
    else if exp == 126_usize { 85070591730234615865843651857942052864_u128 }
    else if exp == 127_usize { 170141183460469231731687303715884105728_u128 }
    else { 0 }
}

// felt252 fast pow2 function
// TODO: Now cairo match just support 0, future we use fast pow2 will be better
fn felt252_fast_pow2(exp: usize) -> felt252 {
    if exp == 0_usize { 1 }
    else if exp == 1_usize { 2 }
    else if exp == 2_usize { 4 }
    else if exp == 3_usize { 8 }
    else if exp == 4_usize { 16 }
    else if exp == 5_usize { 32 }
    else if exp == 6_usize { 64 }
    else if exp == 7_usize { 128 }
    else if exp == 8_usize { 256 }
    else if exp == 9_usize { 512 }
    else if exp == 10_usize { 1024 }
    else if exp == 11_usize { 2048 }
    else if exp == 12_usize { 4096 }
    else if exp == 13_usize { 8192 }
    else if exp == 14_usize { 16384 }
    else if exp == 15_usize { 32768 }
    else if exp == 16_usize { 65536 }
    else if exp == 17_usize { 131072 }
    else if exp == 18_usize { 262144 }
    else if exp == 19_usize { 524288 }
    else if exp == 20_usize { 1048576 }
    else if exp == 21_usize { 2097152 }
    else if exp == 22_usize { 4194304 }
    else if exp == 23_usize { 8388608 }
    else if exp == 24_usize { 16777216 }
    else if exp == 25_usize { 33554432 }
    else if exp == 26_usize { 67108864 }
    else if exp == 27_usize { 134217728 }
    else if exp == 28_usize { 268435456 }
    else if exp == 29_usize { 536870912 }
    else if exp == 30_usize { 1073741824 }
    else if exp == 31_usize { 2147483648 }
    else if exp == 32_usize { 4294967296 }
    else if exp == 33_usize { 8589934592 }
    else if exp == 34_usize { 17179869184 }
    else if exp == 35_usize { 34359738368 }
    else if exp == 36_usize { 68719476736 }
    else if exp == 37_usize { 137438953472 }
    else if exp == 38_usize { 274877906944 }
    else if exp == 39_usize { 549755813888 }
    else if exp == 40_usize { 1099511627776 }
    else if exp == 41_usize { 2199023255552 }
    else if exp == 42_usize { 4398046511104 }
    else if exp == 43_usize { 8796093022208 }
    else if exp == 44_usize { 17592186044416 }
    else if exp == 45_usize { 35184372088832 }
    else if exp == 46_usize { 70368744177664 }
    else if exp == 47_usize { 140737488355328 }
    else if exp == 48_usize { 281474976710656 }
    else if exp == 49_usize { 562949953421312 }
    else if exp == 50_usize { 1125899906842624 }
    else if exp == 51_usize { 2251799813685248 }
    else if exp == 52_usize { 4503599627370496 }
    else if exp == 53_usize { 9007199254740992 }
    else if exp == 54_usize { 18014398509481984 }
    else if exp == 55_usize { 36028797018963968 }
    else if exp == 56_usize { 72057594037927936 }
    else if exp == 57_usize { 144115188075855872 }
    else if exp == 58_usize { 288230376151711744 }
    else if exp == 59_usize { 576460752303423488 }
    else if exp == 60_usize { 1152921504606846976 }
    else if exp == 61_usize { 2305843009213693952 }
    else if exp == 62_usize { 4611686018427387904 }
    else if exp == 63_usize { 9223372036854775808 }
    else if exp == 64_usize { 18446744073709551616 }
    else if exp == 65_usize { 36893488147419103232 }
    else if exp == 66_usize { 73786976294838206464 }
    else if exp == 67_usize { 147573952589676412928 }
    else if exp == 68_usize { 295147905179352825856 }
    else if exp == 69_usize { 590295810358705651712 }
    else if exp == 70_usize { 1180591620717411303424 }
    else if exp == 71_usize { 2361183241434822606848 }
    else if exp == 72_usize { 4722366482869645213696 }
    else if exp == 73_usize { 9444732965739290427392 }
    else if exp == 74_usize { 18889465931478580854784 }
    else if exp == 75_usize { 37778931862957161709568 }
    else if exp == 76_usize { 75557863725914323419136 }
    else if exp == 77_usize { 151115727451828646838272 }
    else if exp == 78_usize { 302231454903657293676544 }
    else if exp == 79_usize { 604462909807314587353088 }
    else if exp == 80_usize { 1208925819614629174706176 }
    else if exp == 81_usize { 2417851639229258349412352 }
    else if exp == 82_usize { 4835703278458516698824704 }
    else if exp == 83_usize { 9671406556917033397649408 }
    else if exp == 84_usize { 19342813113834066795298816 }
    else if exp == 85_usize { 38685626227668133590597632 }
    else if exp == 86_usize { 77371252455336267181195264 }
    else if exp == 87_usize { 154742504910672534362390528 }
    else if exp == 88_usize { 309485009821345068724781056 }
    else if exp == 89_usize { 618970019642690137449562112 }
    else if exp == 90_usize { 1237940039285380274899124224 }
    else if exp == 91_usize { 2475880078570760549798248448 }
    else if exp == 92_usize { 4951760157141521099596496896 }
    else if exp == 93_usize { 9903520314283042199192993792 }
    else if exp == 94_usize { 19807040628566084398385987584 }
    else if exp == 95_usize { 39614081257132168796771975168 }
    else if exp == 96_usize { 79228162514264337593543950336 }
    else if exp == 97_usize { 158456325028528675187087900672 }
    else if exp == 98_usize { 316912650057057350374175801344 }
    else if exp == 99_usize { 633825300114114700748351602688 }
    else if exp == 100_usize { 1267650600228229401496703205376 }
    else if exp == 101_usize { 2535301200456458802993406410752 }
    else if exp == 102_usize { 5070602400912917605986812821504 }
    else if exp == 103_usize { 10141204801825835211973625643008 }
    else if exp == 104_usize { 20282409603651670423947251286016 }
    else if exp == 105_usize { 40564819207303340847894502572032 }
    else if exp == 106_usize { 81129638414606681695789005144064 }
    else if exp == 107_usize { 162259276829213363391578010288128 }
    else if exp == 108_usize { 324518553658426726783156020576256 }
    else if exp == 109_usize { 649037107316853453566312041152512 }
    else if exp == 110_usize { 1298074214633706907132624082305024 }
    else if exp == 111_usize { 2596148429267413814265248164610048 }
    else if exp == 112_usize { 5192296858534827628530496329220096 }
    else if exp == 113_usize { 10384593717069655257060992658440192 }
    else if exp == 114_usize { 20769187434139310514121985316880384 }
    else if exp == 115_usize { 41538374868278621028243970633760768 }
    else if exp == 116_usize { 83076749736557242056487941267521536 }
    else if exp == 117_usize { 166153499473114484112975882535043072 }
    else if exp == 118_usize { 332306998946228968225951765070086144 }
    else if exp == 119_usize { 664613997892457936451903530140172288 }
    else if exp == 120_usize { 1329227995784915872903807060280344576 }
    else if exp == 121_usize { 2658455991569831745807614120560689152 }
    else if exp == 122_usize { 5316911983139663491615228241121378304 }
    else if exp == 123_usize { 10633823966279326983230456482242756608 }
    else if exp == 124_usize { 21267647932558653966460912964485513216 }
    else if exp == 125_usize { 42535295865117307932921825928971026432 }
    else if exp == 126_usize { 85070591730234615865843651857942052864 }
    else if exp == 127_usize { 170141183460469231731687303715884105728 }
    else if exp == 128_usize { 340282366920938463463374607431768211456 }
    else if exp == 129_usize { 680564733841876926926749214863536422912 }
    else if exp == 130_usize { 1361129467683753853853498429727072845824 }
    else if exp == 131_usize { 2722258935367507707706996859454145691648 }
    else if exp == 132_usize { 5444517870735015415413993718908291383296 }
    else if exp == 133_usize { 10889035741470030830827987437816582766592 }
    else if exp == 134_usize { 21778071482940061661655974875633165533184 }
    else if exp == 135_usize { 43556142965880123323311949751266331066368 }
    else if exp == 136_usize { 87112285931760246646623899502532662132736 }
    else if exp == 137_usize { 174224571863520493293247799005065324265472 }
    else if exp == 138_usize { 348449143727040986586495598010130648530944 }
    else if exp == 139_usize { 696898287454081973172991196020261297061888 }
    else if exp == 140_usize { 1393796574908163946345982392040522594123776 }
    else if exp == 141_usize { 2787593149816327892691964784081045188247552 }
    else if exp == 142_usize { 5575186299632655785383929568162090376495104 }
    else if exp == 143_usize { 11150372599265311570767859136324180752990208 }
    else if exp == 144_usize { 22300745198530623141535718272648361505980416 }
    else if exp == 145_usize { 44601490397061246283071436545296723011960832 }
    else if exp == 146_usize { 89202980794122492566142873090593446023921664 }
    else if exp == 147_usize { 178405961588244985132285746181186892047843328 }
    else if exp == 148_usize { 356811923176489970264571492362373784095686656 }
    else if exp == 149_usize { 713623846352979940529142984724747568191373312 }
    else if exp == 150_usize { 1427247692705959881058285969449495136382746624 }
    else if exp == 151_usize { 2854495385411919762116571938898990272765493248 }
    else if exp == 152_usize { 5708990770823839524233143877797980545530986496 }
    else if exp == 153_usize { 11417981541647679048466287755595961091061972992 }
    else if exp == 154_usize { 22835963083295358096932575511191922182123945984 }
    else if exp == 155_usize { 45671926166590716193865151022383844364247891968 }
    else if exp == 156_usize { 91343852333181432387730302044767688728495783936 }
    else if exp == 157_usize { 182687704666362864775460604089535377456991567872 }
    else if exp == 158_usize { 365375409332725729550921208179070754913983135744 }
    else if exp == 159_usize { 730750818665451459101842416358141509827966271488 }
    else if exp == 160_usize { 1461501637330902918203684832716283019655932542976 }
    else if exp == 161_usize { 2923003274661805836407369665432566039311865085952 }
    else if exp == 162_usize { 5846006549323611672814739330865132078623730171904 }
    else if exp == 163_usize { 11692013098647223345629478661730264157247460343808 }
    else if exp == 164_usize { 23384026197294446691258957323460528314494920687616 }
    else if exp == 165_usize { 46768052394588893382517914646921056628989841375232 }
    else if exp == 166_usize { 93536104789177786765035829293842113257979682750464 }
    else if exp == 167_usize { 187072209578355573530071658587684226515959365500928 }
    else if exp == 168_usize { 374144419156711147060143317175368453031918731001856 }
    else if exp == 169_usize { 748288838313422294120286634350736906063837462003712 }
    else if exp == 170_usize { 1496577676626844588240573268701473812127674924007424 }
    else if exp == 171_usize { 2993155353253689176481146537402947624255349848014848 }
    else if exp == 172_usize { 5986310706507378352962293074805895248510699696029696 }
    else if exp == 173_usize { 11972621413014756705924586149611790497021399392059392 }
    else if exp == 174_usize { 23945242826029513411849172299223580994042798784118784 }
    else if exp == 175_usize { 47890485652059026823698344598447161988085597568237568 }
    else if exp == 176_usize { 95780971304118053647396689196894323976171195136475136 }
    else if exp == 177_usize { 191561942608236107294793378393788647952342390272950272 }
    else if exp == 178_usize { 383123885216472214589586756787577295904684780545900544 }
    else if exp == 179_usize { 766247770432944429179173513575154591809369561091801088 }
    else if exp == 180_usize { 1532495540865888858358347027150309183618739122183602176 }
    else if exp == 181_usize { 3064991081731777716716694054300618367237478244367204352 }
    else if exp == 182_usize { 6129982163463555433433388108601236734474956488734408704 }
    else if exp == 183_usize { 12259964326927110866866776217202473468949912977468817408 }
    else if exp == 184_usize { 24519928653854221733733552434404946937899825954937634816 }
    else if exp == 185_usize { 49039857307708443467467104868809893875799651909875269632 }
    else if exp == 186_usize { 98079714615416886934934209737619787751599303819750539264 }
    else if exp == 187_usize { 196159429230833773869868419475239575503198607639501078528 }
    else if exp == 188_usize { 392318858461667547739736838950479151006397215279002157056 }
    else if exp == 189_usize { 784637716923335095479473677900958302012794430558004314112 }
    else if exp == 190_usize { 1569275433846670190958947355801916604025588861116008628224 }
    else if exp == 191_usize { 3138550867693340381917894711603833208051177722232017256448 }
    else if exp == 192_usize { 6277101735386680763835789423207666416102355444464034512896 }
    else if exp == 193_usize { 12554203470773361527671578846415332832204710888928069025792 }
    else if exp == 194_usize { 25108406941546723055343157692830665664409421777856138051584 }
    else if exp == 195_usize { 50216813883093446110686315385661331328818843555712276103168 }
    else if exp == 196_usize { 100433627766186892221372630771322662657637687111424552206336 }
    else if exp == 197_usize { 200867255532373784442745261542645325315275374222849104412672 }
    else if exp == 198_usize { 401734511064747568885490523085290650630550748445698208825344 }
    else if exp == 199_usize { 803469022129495137770981046170581301261101496891396417650688 }
    else if exp == 200_usize { 1606938044258990275541962092341162602522202993782792835301376 }
    else if exp == 201_usize { 3213876088517980551083924184682325205044405987565585670602752 }
    else if exp == 202_usize { 6427752177035961102167848369364650410088811975131171341205504 }
    else if exp == 203_usize { 12855504354071922204335696738729300820177623950262342682411008 }
    else if exp == 204_usize { 25711008708143844408671393477458601640355247900524685364822016 }
    else if exp == 205_usize { 51422017416287688817342786954917203280710495801049370729644032 }
    else if exp == 206_usize { 102844034832575377634685573909834406561420991602098741459288064 }
    else if exp == 207_usize { 205688069665150755269371147819668813122841983204197482918576128 }
    else if exp == 208_usize { 411376139330301510538742295639337626245683966408394965837152256 }
    else if exp == 209_usize { 822752278660603021077484591278675252491367932816789931674304512 }
    else if exp == 210_usize { 1645504557321206042154969182557350504982735865633579863348609024 }
    else if exp == 211_usize { 3291009114642412084309938365114701009965471731267159726697218048 }
    else if exp == 212_usize { 6582018229284824168619876730229402019930943462534319453394436096 }
    else if exp == 213_usize { 13164036458569648337239753460458804039861886925068638906788872192 }
    else if exp == 214_usize { 26328072917139296674479506920917608079723773850137277813577744384 }
    else if exp == 215_usize { 52656145834278593348959013841835216159447547700274555627155488768 }
    else if exp == 216_usize { 105312291668557186697918027683670432318895095400549111254310977536 }
    else if exp == 217_usize { 210624583337114373395836055367340864637790190801098222508621955072 }
    else if exp == 218_usize { 421249166674228746791672110734681729275580381602196445017243910144 }
    else if exp == 219_usize { 842498333348457493583344221469363458551160763204392890034487820288 }
    else if exp == 220_usize { 1684996666696914987166688442938726917102321526408785780068975640576 }
    else if exp == 221_usize { 3369993333393829974333376885877453834204643052817571560137951281152 }
    else if exp == 222_usize { 6739986666787659948666753771754907668409286105635143120275902562304 }
    else if exp == 223_usize { 13479973333575319897333507543509815336818572211270286240551805124608 }
    else if exp == 224_usize { 26959946667150639794667015087019630673637144422540572481103610249216 }
    else if exp == 225_usize { 53919893334301279589334030174039261347274288845081144962207220498432 }
    else if exp == 226_usize { 107839786668602559178668060348078522694548577690162289924414440996864 }
    else if exp == 227_usize { 215679573337205118357336120696157045389097155380324579848828881993728 }
    else if exp == 228_usize { 431359146674410236714672241392314090778194310760649159697657763987456 }
    else if exp == 229_usize { 862718293348820473429344482784628181556388621521298319395315527974912 }
    else if exp == 230_usize { 1725436586697640946858688965569256363112777243042596638790631055949824 }
    else if exp == 231_usize { 3450873173395281893717377931138512726225554486085193277581262111899648 }
    else if exp == 232_usize { 6901746346790563787434755862277025452451108972170386555162524223799296 }
    else if exp == 233_usize { 13803492693581127574869511724554050904902217944340773110325048447598592 }
    else if exp == 234_usize { 27606985387162255149739023449108101809804435888681546220650096895197184 }
    else if exp == 235_usize { 55213970774324510299478046898216203619608871777363092441300193790394368 }
    else if exp == 236_usize { 110427941548649020598956093796432407239217743554726184882600387580788736 }
    else if exp == 237_usize { 220855883097298041197912187592864814478435487109452369765200775161577472 }
    else if exp == 238_usize { 441711766194596082395824375185729628956870974218904739530401550323154944 }
    else if exp == 239_usize { 883423532389192164791648750371459257913741948437809479060803100646309888 }
    else if exp == 240_usize { 1766847064778384329583297500742918515827483896875618958121606201292619776 }
    else if exp == 241_usize { 3533694129556768659166595001485837031654967793751237916243212402585239552 }
    else if exp == 242_usize { 7067388259113537318333190002971674063309935587502475832486424805170479104 }
    else if exp == 243_usize { 14134776518227074636666380005943348126619871175004951664972849610340958208 }
    else if exp == 244_usize { 28269553036454149273332760011886696253239742350009903329945699220681916416 }
    else if exp == 245_usize { 56539106072908298546665520023773392506479484700019806659891398441363832832 }
    else if exp == 246_usize { 113078212145816597093331040047546785012958969400039613319782796882727665664 }
    else if exp == 247_usize { 226156424291633194186662080095093570025917938800079226639565593765455331328 }
    else if exp == 248_usize { 452312848583266388373324160190187140051835877600158453279131187530910662656 }
    else if exp == 249_usize { 904625697166532776746648320380374280103671755200316906558262375061821325312 }
    else if exp == 250_usize { 1809251394333065553493296640760748560207343510400633813116524750123642650624 }
    else { 0 }
}