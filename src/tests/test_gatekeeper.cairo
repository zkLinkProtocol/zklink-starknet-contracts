use starknet::{ContractAddress, ClassHash, contract_address_const, class_hash_const};
use starknet::testing::{set_contract_address, set_block_timestamp};
use starknet::testing;
use test::test_utils::assert_eq;
use clone::Clone;
use traits::TryInto;
use debug::PrintTrait;
use zklink::contracts::gatekeeper::UpgradeGateKeeper;
use zklink::contracts::gatekeeper::IUpgradeGateKeeperDispatcher;
use zklink::contracts::gatekeeper::IUpgradeGateKeeperDispatcherTrait;
use zklink::tests::mocks::zklink_upgrade_v1::ZklinkUpgradeV1;
use zklink::tests::mocks::zklink_upgrade_v1::IZklinkUpgradeV1Dispatcher;
use zklink::tests::mocks::zklink_upgrade_v1::IZklinkUpgradeV1DispatcherTrait;
use zklink::tests::mocks::zklink_upgrade_v2::ZklinkUpgradeV2;
use zklink::tests::mocks::zklink_upgrade_v2::IZklinkUpgradeV2Dispatcher;
use zklink::tests::mocks::zklink_upgrade_v2::IZklinkUpgradeV2DispatcherTrait;
use zklink::tests::utils;

fn deploy_zklink() -> (ContractAddress, ContractAddress, ContractAddress) {
    let deployer: ContractAddress =
        contract_address_const::<0x74a0c0f8e8756218a96c2d9aae21152d786a0704202b10fb30496e46222b72d>();
    set_contract_address(deployer);

    let calldata = array![
        deployer.into(), // master
        0x123, // verifier
        2, // governor
        0, // blockNumber
        0, // timestamp
        utils::GENESIS_ROOT.low.into(), // stateHash low
        utils::GENESIS_ROOT.high.into(), // stateHash high
        0, // commitment low
        0, // commitment high
        utils::EMPTY_STRING_KECCAK.low.into(), // syncHash low
        utils::EMPTY_STRING_KECCAK.high.into(), // syncHash high
    ];

    let v1: ContractAddress = utils::deploy(ZklinkUpgradeV1::TEST_CLASS_HASH, calldata.clone());
    let v2: ContractAddress = utils::deploy(ZklinkUpgradeV2::TEST_CLASS_HASH, calldata);
    let gatekeeper: ContractAddress = utils::deploy(
        UpgradeGateKeeper::TEST_CLASS_HASH, array![deployer.into(), v1.into()]
    );
    (v1, v2, gatekeeper)
}

fn assert_event_NewUpgradable(
    gatekeeper: ContractAddress, versionId: u256, upgradeable: ContractAddress
) {
    assert_eq(
        @testing::pop_log(gatekeeper).unwrap(),
        @UpgradeGateKeeper::Event::NewUpgradable(
            UpgradeGateKeeper::NewUpgradable { versionId: versionId, upgradeable: upgradeable, }
        ),
        'NewUpgradable Emit'
    )
}

fn assert_event_NoticePeriodStart(
    gatekeeper: ContractAddress, versionId: u256, newTargets: Array<ClassHash>, noticePeriod: u256
) {
    assert_eq(
        @testing::pop_log(gatekeeper).unwrap(),
        @UpgradeGateKeeper::Event::NoticePeriodStart(
            UpgradeGateKeeper::NoticePeriodStart {
                versionId: versionId, newTargets: newTargets, noticePeriod: noticePeriod
            }
        ),
        'NoticePeriodStart Emit'
    )
}

fn assert_event_UpgradeCancel(gatekeeper: ContractAddress, versionId: u256) {
    assert_eq(
        @testing::pop_log(gatekeeper).unwrap(),
        @UpgradeGateKeeper::Event::UpgradeCancel(
            UpgradeGateKeeper::UpgradeCancel { versionId: versionId }
        ),
        'UpgradeCancel Emit'
    )
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_gatekeeper_add_upgradeable() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);

    gatekeeper_dispatcher.addUpgradeable(v1);
    assert_event_NewUpgradable(gatekeeper, 0, v1);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1c', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_add_upgradeable_invalid_master1() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);
    gatekeeper_dispatcher.addUpgradeable(v1);
    let newMaster: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();
    set_contract_address(newMaster);
    gatekeeper_dispatcher.addUpgradeable(contract_address_const::<0>());
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1c', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_add_upgradeable_invalid_master2() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);
    gatekeeper_dispatcher.addUpgradeable(v1);
    let newMaster: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();
    set_contract_address(newMaster);
    gatekeeper_dispatcher.startUpgrade(array![]);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1c', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_add_upgradeable_invalid_master3() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);
    gatekeeper_dispatcher.addUpgradeable(v1);
    let newMaster: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();
    set_contract_address(newMaster);
    gatekeeper_dispatcher.cancelUpgrade();
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('1c', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_add_upgradeable_invalid_master4() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);
    gatekeeper_dispatcher.addUpgradeable(v1);
    let newMaster: ContractAddress = contract_address_const::<0x64656661756c7453656e646572>();
    set_contract_address(newMaster);
    gatekeeper_dispatcher.finishUpgrade();
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('cpu11', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_add_upgradeable_invalid_status1() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);
    gatekeeper_dispatcher.addUpgradeable(v1);
    gatekeeper_dispatcher.cancelUpgrade();
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('fpu11', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_add_upgradeable_invalid_status2() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);
    gatekeeper_dispatcher.addUpgradeable(v1);
    gatekeeper_dispatcher.finishUpgrade();
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('spu12', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_add_upgradeable_invalid_status3() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);
    gatekeeper_dispatcher.addUpgradeable(v1);
    gatekeeper_dispatcher.startUpgrade(array![]);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('spu11', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_add_upgradeable_invalid_status4() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);
    gatekeeper_dispatcher.addUpgradeable(v1);
    let v2_class_hash: ClassHash = ZklinkUpgradeV2::TEST_CLASS_HASH.try_into().unwrap();
    gatekeeper_dispatcher.startUpgrade(array![v2_class_hash]);

    gatekeeper_dispatcher.startUpgrade(array![]);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_gatekeeper_startUpgradeable_success() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);

    gatekeeper_dispatcher.addUpgradeable(v1);
    utils::drop_event(gatekeeper);
    let v2_class_hash: ClassHash = ZklinkUpgradeV2::TEST_CLASS_HASH.try_into().unwrap();
    gatekeeper_dispatcher.startUpgrade(array![v2_class_hash]);
    assert_event_NoticePeriodStart(gatekeeper, 0, array![v2_class_hash], 0);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_gatekeeper_cancelUpgrade_success() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);

    gatekeeper_dispatcher.addUpgradeable(v1);
    utils::drop_event(gatekeeper);
    let v2_class_hash: ClassHash = ZklinkUpgradeV2::TEST_CLASS_HASH.try_into().unwrap();
    gatekeeper_dispatcher.startUpgrade(array![v2_class_hash]);
    utils::drop_event(gatekeeper);

    gatekeeper_dispatcher.cancelUpgrade();
    assert_event_UpgradeCancel(gatekeeper, 0);
}

#[test]
#[available_gas(20000000000)]
#[should_panic(expected: ('fpu13', 'ENTRYPOINT_FAILED'))]
fn test_zklink_gatekeeper_finishUpgrade_not_ready() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);

    gatekeeper_dispatcher.addUpgradeable(v1);
    utils::drop_event(gatekeeper);
    let v2_class_hash: ClassHash = ZklinkUpgradeV2::TEST_CLASS_HASH.try_into().unwrap();
    gatekeeper_dispatcher.startUpgrade(array![v2_class_hash]);
    utils::drop_event(gatekeeper);
    v1_dispatcher.setExodus(true);
    gatekeeper_dispatcher.finishUpgrade();
    assert_event_UpgradeCancel(gatekeeper, 0);
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_gatekeeper_finishUpgrade_not_reach_noticePeriod() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);

    gatekeeper_dispatcher.addUpgradeable(v1);
    utils::drop_event(gatekeeper);
    // set block timestamp to 10
    set_block_timestamp(10);
    let v2_class_hash: ClassHash = ZklinkUpgradeV2::TEST_CLASS_HASH.try_into().unwrap();
    gatekeeper_dispatcher.startUpgrade(array![v2_class_hash]);
    utils::drop_event(gatekeeper);

    // set block timestamp to 0
    set_block_timestamp(0);
    let success = gatekeeper_dispatcher.finishUpgrade();
    assert(!success, 'finishUpgrade should fail');
}

#[test]
#[available_gas(20000000000)]
fn test_zklink_gatekeeper_upgrade_success() {
    let (v1, v2, gatekeeper) = deploy_zklink();
    let v1_dispatcher = IZklinkUpgradeV1Dispatcher { contract_address: v1 };
    let gatekeeper_dispatcher = IUpgradeGateKeeperDispatcher { contract_address: gatekeeper };
    v1_dispatcher.transferMastership(gatekeeper);

    v1_dispatcher.set_value1(1);
    assert(v1_dispatcher.get_value1() == 1, 'v1 value');

    gatekeeper_dispatcher.addUpgradeable(v1);
    utils::drop_event(gatekeeper);

    let v2_class_hash: ClassHash = ZklinkUpgradeV2::TEST_CLASS_HASH.try_into().unwrap();
    gatekeeper_dispatcher.startUpgrade(array![v2_class_hash]);
    utils::drop_event(gatekeeper);

    let success = gatekeeper_dispatcher.finishUpgrade();
    assert(success, 'finishUpgrade should success');

    let v2_dispatcher = IZklinkUpgradeV2Dispatcher { contract_address: v1 };
    v2_dispatcher.set_value2(2);
    assert(v2_dispatcher.get_value2() == 2, 'v2 should be upgraded');
    assert(v2_dispatcher.get_value1() == 1, 'v1 should be kept');
}
