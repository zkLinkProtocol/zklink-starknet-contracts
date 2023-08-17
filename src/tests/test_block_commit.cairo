use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;

use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::utils::data_structures::DataStructures::CommitBlockInfo;
use zklink::utils::data_structures::DataStructures::OnchainOperationData;
use zklink::utils::constants::{EMPTY_STRING_KECCAK, CHUNK_BYTES};
use zklink::utils::bytes::{Bytes, BytesTrait};
use zklink::utils::operations::Operations::{OpType, U8TryIntoOpType};
use zklink::utils::utils::concatHash;
use zklink::tests::utils;
use debug::PrintTrait;

fn deploy_contract() -> IZklinkMockDispatcher {
    let calldata = array![];
    let address = utils::deploy(ZklinkMock::TEST_CLASS_HASH, calldata);
    IZklinkMockDispatcher { contract_address: address }
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_length1() {
    let dispatcher = deploy_contract();

    let mut publicData: Bytes = BytesTrait::new_empty();
    let onchainOperations: Array<OnchainOperationData> = array![];
    // 1 bytes
    publicData.append_u8(0x01);

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h0', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_length2() {
    let dispatcher = deploy_contract();

    let mut publicData: Bytes = BytesTrait::new_empty();
    let onchainOperations: Array<OnchainOperationData> = array![];
    // 13 bytes
    publicData.append_u128_packed(0x01010101010101010101010101, 13);

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_collectOnchainOps_no_pubdata() {
    let dispatcher = deploy_contract();

    let mut publicData: Bytes = BytesTrait::new_empty();
    // 0 bytes
    let onchainOperations: Array<OnchainOperationData> = array![];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);

    assert(processableOperationsHash == EMPTY_STRING_KECCAK, 'invalid value 0');
    assert(priorityOperationsProcessed == 0, 'invalid value 1');
    assert(offsetsCommitment == 0, 'invalid value 2');
    assert(*onchainOperationPubdataHashs[0] == 0, 'invalid value 3');
    assert(*onchainOperationPubdataHashs[1] == EMPTY_STRING_KECCAK, 'invalid value 3');
    assert(*onchainOperationPubdataHashs[2] == EMPTY_STRING_KECCAK, 'invalid value 4');
    assert(*onchainOperationPubdataHashs[3] == EMPTY_STRING_KECCAK, 'invalid value 5');
    assert(*onchainOperationPubdataHashs[4] == EMPTY_STRING_KECCAK, 'invalid value 6');
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset1() {
    let dispatcher = deploy_contract();

    let mut publicData: Bytes = BytesTrait::new_empty();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new_empty(), publicDataOffset: publicData.size
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset2() {
    let dispatcher = deploy_contract();

    let mut publicData: Bytes = BytesTrait::new_empty();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new_empty(), publicDataOffset: 1
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_pubdata_offset3() {
    let dispatcher = deploy_contract();

    let mut publicData: Bytes = BytesTrait::new_empty();
    publicData.append_u8(0x00);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new_empty(), publicDataOffset: CHUNK_BYTES - 2
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('k2', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_op_type() {
    let dispatcher = deploy_contract();

    let mut publicData: Bytes = BytesTrait::new_empty();
    publicData.append_u16(0x0001);
    utils::paddingChunk(ref publicData, utils::OP_NOOP_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new_empty(), publicDataOffset: 0
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);
}

// calculate pubData from Python
// from eth_abi.packed import encode_abi_packed
// def cal():
//     data = encode_abi_packed(encode_format, example)
//     size = len(data)
//     data += b'\x00' * (16 - size % 16)
//     data = [int.from_bytes(x, 'big') for x in [data[i:i+16] for i in range(0, len(data), 16)]]
//     print(size)
//     print(data)

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('i1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_chain_id1() {
    let dispatcher = deploy_contract();
    // chain_id = MIN_CHAIN_ID - 1
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 0, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 59
    // data = [1329227995786124801101358576590389248, 549787120963470, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]
    let mut publicData: Bytes = BytesTrait::new(
        59,
        array![
            1329227995786124801101358576590389248,
            549787120963470,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769728000
        ]
    );
    utils::paddingChunk(ref publicData, utils::OP_DEPOSIT_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new_empty(), publicDataOffset: 0
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('i1', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_invalid_chain_id2() {
    let dispatcher = deploy_contract();
    // chain_id = MAX_CHAIN_ID + 1
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 5, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 59
    // data = [1329227995786148412933772924816457728, 549787120963470, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]
    let mut publicData: Bytes = BytesTrait::new(
        59,
        array![
            1329227995786148412933772924816457728,
            549787120963470,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769728000
        ]
    );
    utils::paddingChunk(ref publicData, utils::OP_DEPOSIT_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new_empty(), publicDataOffset: 0
    };
    let onchainOperations: Array<OnchainOperationData> = array![onchainOperation];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: publicData,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('h3', 'ENTRYPOINT_FAILED'))]
fn test_zklink_collectOnchainOps_duplicate_pubdata_offset() {
    let dispatcher = deploy_contract();
    // depositData0 and depositData1
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 2, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 59
    // data = [1339612589503194456358419569248829440, 549787120963470, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]
    let mut depositData0: Bytes = BytesTrait::new(
        59,
        array![
            1339612589503194456358419569248829440,
            549787120963470,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769728000
        ]
    );
    let mut depositData1: Bytes = BytesTrait::new(
        59,
        array![
            1339612589503194456358419569248829440,
            549787120963470,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769728000
        ]
    );

    utils::paddingChunk(ref depositData0, utils::OP_DEPOSIT_CHUNKS);
    utils::paddingChunk(ref depositData1, utils::OP_DEPOSIT_CHUNKS);

    depositData0.concat(@depositData1);

    let onchainOperations: Array<OnchainOperationData> = array![
        OnchainOperationData {
            ethWitness: BytesTrait::new_empty(), publicDataOffset: 0
            }, OnchainOperationData {
            ethWitness: BytesTrait::new_empty(), publicDataOffset: 0
        }
    ];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: depositData0,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (
        processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) =
        dispatcher
        .testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_collectOnchainOps_success() {
    let mut dispatcher = deploy_contract();

    let mut pubdatas: Bytes = BytesTrait::new_empty();
    let mut pubdatasOfChain1: Bytes = BytesTrait::new_empty();
    let mut ops: Array<OnchainOperationData> = array![];
    let mut opsOfChain1: Array<OnchainOperationData> = array![];
    // no op of chain 2
    let mut onchainOpPubdataHash1: u256 = EMPTY_STRING_KECCAK;
    let mut onchainOpPubdataHash3: u256 = EMPTY_STRING_KECCAK;
    let mut onchainOpPubdataHash4: u256 = EMPTY_STRING_KECCAK;
    let mut publicDataOffset: usize = 0;
    let mut publicDataOffsetOfChain1: usize = 0;
    let mut priorityOperationsProcessed: u64 = 0;
    let mut processableOpPubdataHash: u256 = EMPTY_STRING_KECCAK;
    let mut offsetsCommitment: u256 = 0;

    // deposit of current chain(chain 1)
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 59
    // data = [1334420292644659628729889072919609344, 549787120963470, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]
    let mut op: Bytes = BytesTrait::new(
        59,
        array![
            1334420292644659628729889072919609344,
            549787120963470,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769728000
        ]
    );
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 1, 0, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 59
    // data = [1334420292643450702910274443744903168, 549787120963470, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]
    let opOfWrite: Bytes = BytesTrait::new(
        59,
        array![
            1334420292643450702910274443744903168,
            549787120963470,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769728000
        ]
    );
    dispatcher.testAddPriorityRequest(utils::OP_DEPOSIT.try_into().unwrap(), opOfWrite);
    utils::paddingChunk(ref op, utils::OP_DEPOSIT_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);
    publicDataOffset += op.size;
    publicDataOffsetOfChain1 += op.size;
    priorityOperationsProcessed += 1;

    // change pubkey of chain 3
    // encode_format = ["uint8","uint8","uint32","uint8","uint160","uint256","uint32","uint16","uint16"]
    // example = [6, 3, 2, 0, 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d, 32, 37, 145]
    //
    // size = 67
    // data = [7990944865287520720191985022115949226, 226854911280625642308916404252811464590, 179892997260459296479640320015568236610, 3577810954935998486498406173769736192, 49184376793434416789652333581809221632]
    let mut op: Bytes = BytesTrait::new(
        67,
        array![
            7990944865287520720191985022115949226,
            226854911280625642308916404252811464590,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769736192,
            49184376793434416789652333581809221632
        ]
    );
    utils::paddingChunk(ref op, utils::OP_CHANGE_PUBKEY_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash3 = concatHash(onchainOpPubdataHash3, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);
    publicDataOffset += op.size;

    // transfer of chain 4
    // encode_format = ["uint8","uint32","uint8","uint16","uint40","uint32","uint8","uint16"]
    // example = [4, 1, 0, 33, 456, 4, 3, 34]
    //
    // size = 20
    // data = [5316911983449149110179127749911773184, 5332491567472793459488297910603350016]
    let mut op: Bytes = BytesTrait::new(
        20,
        array![
            5316911983449149110179127749911773184,
            5332491567472793459488297910603350016
        ]
    );
    utils::paddingChunk(ref op, utils::OP_TRANSFER_CHUNKS);
    pubdatas.concat(@op);
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, false);
    publicDataOffset += op.size;

    // deposit of chain4
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [1, 4, 3, 6, 35, 35, 345, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 59
    // data = [1349997183222710297597724425227075584, 379362818658190, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]
    let mut op: Bytes = BytesTrait::new(
        59,
        array![
            1349997183222710297597724425227075584,
            379362818658190,
            179892997260459296479640320015568236610,
            3577810954935998486498406173769728000
        ]
    );
    utils::paddingChunk(ref op, utils::OP_DEPOSIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);
    publicDataOffset += op.size;

    // full exit of chain4
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 4, 43, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 35, 35, 245]
    //
    // size = 59
    // data = [6666909166410712037873566033893757948, 42577624153754863967194330481103536495, 278544165408887043319642418119171899392, 269380348805120]
    let mut op: Bytes = BytesTrait::new(
        59,
        array![
            6666909166410712037873566033893757948,
            42577624153754863967194330481103536495,
            278544165408887043319642418119171899392,
            269380348805120
        ]
    );
    utils::paddingChunk(ref op, utils::OP_FULL_EXIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);
    publicDataOffset += op.size;

    // mock Noop
    // encode_format = ["uint8"]
    // example = [0]
    //
    // size = 1
    // data = [0]
    let mut op: Bytes = BytesTrait::new(1, array![0]);
    utils::paddingChunk(ref op, utils::OP_NOOP_CHUNKS);
    pubdatas.concat(@op);
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, false);
    publicDataOffset += op.size;

    // force exit of chain3
    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [7, 3, 30, 7, 3, 43, 2, 35, 35, 245, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 68
    // data = [9320172861106316424366063172242647810, 181733163034406966250383145560965120, 19413155728529532836176956146393, 227142569737839188506614686513323349732, 130444596926336721081525902839130357760]
    let mut op: Bytes = BytesTrait::new(
        68,
        array![
            9320172861106316424366063172242647810,
            181733163034406966250383145560965120,
            19413155728529532836176956146393,
            227142569737839188506614686513323349732,
            130444596926336721081525902839130357760
        ]
    );
    utils::paddingChunk(ref op, utils::OP_FORCE_EXIT_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash3 = concatHash(onchainOpPubdataHash3, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);
    publicDataOffset += op.size;

    // withdraw of current chain(chain 1)
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8"]
    // example = [3, 1, 5, 0, 34, 34, 900, 33, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 14, 50, 1]
    //
    // size = 68
    // data = [3992876284219327077888020403728678912, 989561019029737, 325930098572440622605242809423852945235, 258714655159228338356975277813679521792, 18610206140697167318438833800033075200]
    let mut op: Bytes = BytesTrait::new(
        68,
        array![
            3992876284219327077888020403728678912,
            989561019029737,
            325930098572440622605242809423852945235,
            258714655159228338356975277813679521792,
            18610206140697167318438833800033075200
        ]
    );
    utils::paddingChunk(ref op, utils::OP_WITHDRAW_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);
    publicDataOffset += op.size;
    publicDataOffsetOfChain1 += op.size;

    // full exit of current chain
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 15, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 33, 33, 14]
    //
    // size = 59
    // data = [6651332275801257632038764928014324732, 42577624153754863967194330481103536495, 278544165408887043319498300732072787968, 15393162788864]
    let mut op: Bytes = BytesTrait::new(
        59,
        array![
            6651332275801257632038764928014324732,
            42577624153754863967194330481103536495,
            278544165408887043319498300732072787968,
            15393162788864
        ]
    );
    // encode_format = ["uint8","uint8","uint32","uint8","uint256","uint16","uint16","uint128"]
    // example = [5, 1, 15, 2, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 33, 33, 0]
    //
    // size = 59
    // data = [6651332275801257632038764928014324732, 42577624153754863967194330481103536495, 278544165408887043319498300732072787968, 0]
    let opOfWrite: Bytes = BytesTrait::new(
        59,
        array![
            6651332275801257632038764928014324732,
            42577624153754863967194330481103536495,
            278544165408887043319498300732072787968,
            0
        ]
    );
    dispatcher.testAddPriorityRequest(utils::OP_FULL_EXIT.try_into().unwrap(), opOfWrite);
    utils::paddingChunk(ref op, utils::OP_FULL_EXIT_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);
    publicDataOffset += op.size;
    publicDataOffsetOfChain1 += op.size;
    priorityOperationsProcessed += 1;

    // force exit of current chain
    // encode_format = ["uint8","uint8","uint32","uint8","uint32","uint32","uint8","uint16","uint16","uint128","uint256"]
    // example = [7, 1, 13, 4, 0, 23, 2, 35, 35, 2450, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    //
    // size = 68
    // data = [9309788267368680863076101576143673090, 181733163034406966250383145560965120, 194111254072482397229941366637273, 227142569737839188506614686513323349732, 130444596926336721081525902839130357760]
    let mut op: Bytes = BytesTrait::new(
        68,
        array![
            9309788267368680863076101576143673090,
            181733163034406966250383145560965120,
            194111254072482397229941366637273,
            227142569737839188506614686513323349732,
            130444596926336721081525902839130357760
        ]
    );
    utils::paddingChunk(ref op, utils::OP_FORCE_EXIT_CHUNKS);
    pubdatas.concat(@op);
    pubdatasOfChain1.concat(@op);
    onchainOpPubdataHash1 = concatHash(onchainOpPubdataHash1, @op);
    processableOpPubdataHash = concatHash(processableOpPubdataHash, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    opsOfChain1
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffsetOfChain1
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);
    publicDataOffset += op.size;

    // withdraw of chain 4
    // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint16","uint256","uint32","uint16","uint8"]
    // example = [3, 4, 15, 5, 34, 34, 1000, 33, 0x5D8E9F533DA8993FC200826F21D0b88F33f53c2a2a151016FD18dA7a77eEb0c, 14, 50, 0]
    //
    // size = 68
    // data = [4008453174807044430802172532689469440, 1099512181807337, 325930098572440622605242809423852945235, 258714655159228338356975277813679521792, 18610206061469004804174496206489124864]
    let mut op: Bytes = BytesTrait::new(
        68,
        array![
            4008453174807044430802172532689469440,
            1099512181807337,
            325930098572440622605242809423852945235,
            258714655159228338356975277813679521792,
            18610206061469004804174496206489124864
        ]
    );
    utils::paddingChunk(ref op, utils::OP_WITHDRAW_CHUNKS);
    pubdatas.concat(@op);
    onchainOpPubdataHash4 = concatHash(onchainOpPubdataHash4, @op);
    ops
        .append(
            OnchainOperationData {
                ethWitness: BytesTrait::new_empty(), publicDataOffset: publicDataOffset
            }
        );
    utils::createOffsetCommitment(ref offsetsCommitment, publicDataOffset, true);

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: pubdatas,
        timestamp: 1652422395,
        onchainOperations: ops,
        blockNumber: 10,
        feeAccount: 0
    };

    let (actual_processableOperationsHash,
        actual_priorityOperationsProcessed,
        actual_offsetsCommitment,
        actual_onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);

    assert(actual_processableOperationsHash == processableOpPubdataHash, 'invaid value1');
    assert(actual_priorityOperationsProcessed == priorityOperationsProcessed, 'invaid value2');
    assert(actual_offsetsCommitment == offsetsCommitment, 'invaid value3');

    assert(*actual_onchainOperationPubdataHashs[0] == 0, 'invaid value4');
    assert(*actual_onchainOperationPubdataHashs[1] == onchainOpPubdataHash1, 'invaid value4');
    assert(*actual_onchainOperationPubdataHashs[2] == EMPTY_STRING_KECCAK, 'invaid value4');
    assert(*actual_onchainOperationPubdataHashs[3] == onchainOpPubdataHash3, 'invaid value4');
    assert(*actual_onchainOperationPubdataHashs[4] == onchainOpPubdataHash4, 'invaid value4');
}
