use array::ArrayTrait;
use result::ResultTrait;
use option::OptionTrait;
use traits::TryInto;
use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;

use zklink::tests::mocks::zklink_test::ZklinkMock;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcher;
use zklink::tests::mocks::zklink_test::IZklinkMockDispatcherTrait;
use zklink::utils::data_structures::DataStructures::{
    CommitBlockInfo, OnchainOperationData
};
use zklink::utils::constants::{EMPTY_STRING_KECCAK, CHUNK_BYTES};
use zklink::utils::bytes::{Bytes, BytesTrait};
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

    let (processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);

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
        ethWitness: BytesTrait::new_empty(),
        publicDataOffset: publicData.size
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

    let (processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);
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
        ethWitness: BytesTrait::new_empty(),
        publicDataOffset: 1
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

    let (processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);
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
        ethWitness: BytesTrait::new_empty(),
        publicDataOffset: CHUNK_BYTES - 2
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

    let (processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);
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
        ethWitness: BytesTrait::new_empty(),
        publicDataOffset: 0
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

    let (processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);
}

// calculate pubData from Python
// from eth_abi.packed import encode_abi_packed
// data = encode_abi_packed(encode_format, example)
// size = len(data)
// data += b'\x00' * (16 - size % 16)
// data = [int.from_bytes(x, 'big') for x in [data[i:i+16] for i in range(0, len(data), 16)]]

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
    let mut publicData: Bytes = BytesTrait::new(59, array![
        1329227995786124801101358576590389248,
        549787120963470,
        179892997260459296479640320015568236610,
        3577810954935998486498406173769728000
    ]);
    utils::paddingChunk(ref publicData, utils::OP_DEPOSIT_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new_empty(),
        publicDataOffset: 0
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

    let (processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);
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
    let mut publicData: Bytes = BytesTrait::new(59, array![
        1329227995786148412933772924816457728,
        549787120963470,
        179892997260459296479640320015568236610,
        3577810954935998486498406173769728000
    ]);
    utils::paddingChunk(ref publicData, utils::OP_DEPOSIT_CHUNKS);

    let onchainOperation = OnchainOperationData {
        ethWitness: BytesTrait::new_empty(),
        publicDataOffset: 0
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

    let (processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);
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
    let mut depositData0: Bytes = BytesTrait::new(59, array![
        1339612589503194456358419569248829440,
        549787120963470,
        179892997260459296479640320015568236610,
        3577810954935998486498406173769728000
    ]);
    let mut depositData1: Bytes = BytesTrait::new(59, array![
        1339612589503194456358419569248829440,
        549787120963470,
        179892997260459296479640320015568236610,
        3577810954935998486498406173769728000
    ]);

    utils::paddingChunk(ref depositData0, utils::OP_DEPOSIT_CHUNKS);
    utils::paddingChunk(ref depositData1, utils::OP_DEPOSIT_CHUNKS);

    depositData0.concat(@depositData1);

    let onchainOperations: Array<OnchainOperationData> = array![
        OnchainOperationData { ethWitness: BytesTrait::new_empty(), publicDataOffset: 0 },
        OnchainOperationData { ethWitness: BytesTrait::new_empty(), publicDataOffset: 0 }
    ];

    let mut block = CommitBlockInfo {
        newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
        publicData: depositData0,
        timestamp: 1652422395,
        onchainOperations: onchainOperations,
        blockNumber: 10,
        feeAccount: 0
    };

    let (processableOperationsHash,
        priorityOperationsProcessed,
        offsetsCommitment,
        onchainOperationPubdataHashs
    ) = dispatcher.testCollectOnchainOps(block);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_collectOnchainOps_success() {
    // let dispatcher = deploy_contract();
    // // deposit of current chain
    // // encode_format = ["uint8","uint8","uint32","uint8","uint16","uint16","uint128","uint256"]
    // // example = [1, 1, 1, 0, 33, 33, 500, 0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d]
    // //
    // // size = 59
    // // data = [1334420292644659628729889072919609344, 549787120963470, 179892997260459296479640320015568236610, 3577810954935998486498406173769728000]
    // let mut depositData1: Bytes = BytesTrait::new(59, array![
    //     1334420292644659628729889072919609344,
    //     549787120963470,
    //     179892997260459296479640320015568236610,
    //     3577810954935998486498406173769728000
    // ]);


    

    // let mut block = CommitBlockInfo {
    //     newStateHash: 0xbb66ffc06a476f05a218f6789ca8946e4f0cf29f1efc2e4d0f9a8e70f0326313,
    //     publicData: depositData0,
    //     timestamp: 1652422395,
    //     onchainOperations: onchainOperations,
    //     blockNumber: 10,
    //     feeAccount: 0
    // };

    // let (processableOperationsHash,
    //     priorityOperationsProcessed,
    //     offsetsCommitment,
    //     onchainOperationPubdataHashs
    // ) = dispatcher.testCollectOnchainOps(block);
}