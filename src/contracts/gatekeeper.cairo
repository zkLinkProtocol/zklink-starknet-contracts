use starknet::{ContractAddress, ClassHash};
use zklink::utils::data_structures::DataStructures::UpgradeStatus;

#[starknet::interface]
trait IUpgradeGateKeeper<TContractState> {
    fn getMaster(self: @TContractState) -> ContractAddress;
    fn transferMastership(ref self: TContractState, _newMaster: ContractAddress);
    fn addUpgradeable(ref self: TContractState, _address: ContractAddress);
    fn startUpgrade(ref self: TContractState, _newTargets: Array<ClassHash>);
    fn finishUpgrade(ref self: TContractState) -> bool;
    fn cancelUpgrade(ref self: TContractState);
    fn upgradeStatus(self: @TContractState) -> UpgradeStatus;
    fn mainContract(self: @TContractState) -> ContractAddress;
    fn managedContracts(self: @TContractState, _index: usize) -> ContractAddress;
    fn managedContractsLength(self: @TContractState) -> usize;
    fn noticePeriodFinishTimestamp(self: @TContractState) -> u256;
    fn nextTargets(self: @TContractState, _index: usize) -> ClassHash;
    fn nextTargetsLength(self: @TContractState) -> usize;
    fn versionId(self: @TContractState) -> u256;
}

#[starknet::contract]
mod UpgradeGateKeeper {
    use starknet::{ContractAddress, ClassHash, get_caller_address, get_block_timestamp};
    use zeroable::Zeroable;
    use openzeppelin::upgrades::interface::IUpgradeableDispatcher;
    use openzeppelin::upgrades::interface::IUpgradeableDispatcherTrait;
    use zklink::utils::data_structures::DataStructures::UpgradeStatus;
    use zklink::contracts::zklink::IZklinkDispatcher;
    use zklink::contracts::zklink::IZklinkDispatcherTrait;

    #[storage]
    struct Storage {
        // master address, which can call upgrade functions
        master: ContractAddress,
        // public, Contract which defines notice period duration and allows finish upgrade during preparation of it
        mainContract: ContractAddress,
        // public, Array of addresses of upgradeable contracts managed by the gatekeeper
        managedContracts: LegacyMap::<usize, ContractAddress>,
        // public, managedContracts length
        managedContractsLength: usize,
        // public, upgrade status
        upgradeStatus: UpgradeStatus,
        // public, Notice period finish timestamp (as seconds since unix epoch)
        // Will be equal to zero in case of not active upgrade mode
        noticePeriodFinishTimestamp: u256,
        // public, Addresses of the next versions of the contracts to be upgraded (if element of this array is equal to zero address it means that appropriate upgradeable contract wouldn't be upgraded this time)
        // Will be empty in case of not active upgrade mode
        nextTargets: LegacyMap::<usize, ClassHash>,
        // public, nextTargets length
        nextTargetsLength: usize,
        // public, Version id of contracts
        versionId: u256
    }

    /// Events
    // Event emitted when new upgradeable contract is added to upgrade gatekeeper's list of managed contracts
    #[derive(Drop, PartialEq, starknet::Event)]
    struct NewUpgradable {
        #[key]
        versionId: u256,
        #[key]
        upgradeable: ContractAddress
    }

    // Upgrade mode enter event
    #[derive(Drop, PartialEq, starknet::Event)]
    struct NoticePeriodStart {
        #[key]
        versionId: u256,
        newTargets: Array<ClassHash>,
        noticePeriod: u256 // notice period (in seconds)
    }

    // Upgrade mode cancel event
    #[derive(Drop, PartialEq, starknet::Event)]
    struct UpgradeCancel {
        #[key]
        versionId: u256
    }

    // Upgrade mode complete event
    #[derive(Drop, PartialEq, starknet::Event)]
    struct UpgradeComplete {
        #[key]
        versionId: u256,
        newTargets: Array<ClassHash>
    }

    #[event]
    #[derive(Drop, PartialEq, starknet::Event)]
    enum Event {
        NewUpgradable: NewUpgradable,
        NoticePeriodStart: NoticePeriodStart,
        UpgradeCancel: UpgradeCancel,
        UpgradeComplete: UpgradeComplete
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, _master: ContractAddress, _mainContract: ContractAddress
    ) {
        self.mainContract.write(_mainContract);
        self.versionId.write(0);
        self.master.write(_master);
        self.upgradeStatus.write(UpgradeStatus::Idle(()));
    }

    #[external(v0)]
    impl UpgradeGateKeeperImpl of super::IUpgradeGateKeeper<ContractState> {
        fn getMaster(self: @ContractState) -> ContractAddress {
            self.master.read()
        }

        fn transferMastership(ref self: ContractState, _newMaster: ContractAddress) {
            self.requireMaster(get_caller_address());
            assert(
                _newMaster != Zeroable::zero(), '1d'
            ); // otp11 - new masters address can't be zero address
            self.setMaster(_newMaster);
        }

        // Adds a new upgradeable contract to the list of contracts managed by the gatekeeper
        // _address: addr Address of upgradeable contract to add
        fn addUpgradeable(ref self: ContractState, _address: ContractAddress) {
            self.requireMaster(get_caller_address());
            assert(
                self.upgradeStatus.read() == UpgradeStatus::Idle(()), 'apc11'
            ); // apc11 - upgradeable contract can't be added during upgrade

            let index = self.managedContractsLength.read();
            self.managedContracts.write(index, _address);
            self.managedContractsLength.write(index + 1);

            self
                .emit(
                    Event::NewUpgradable(
                        NewUpgradable { versionId: self.versionId.read(), upgradeable: _address }
                    )
                );
        }

        // Starts upgrade (activates notice period)
        // _newTargets: New managed contracts class hash (if element of this array is equal to zero it means that appropriate upgradeable contract wouldn't be upgraded this time)
        fn startUpgrade(ref self: ContractState, _newTargets: Array<ClassHash>) {
            self.requireMaster(get_caller_address());
            assert(
                self.upgradeStatus.read() == UpgradeStatus::Idle(()), 'spu11'
            ); // spu11 - unable to activate active upgrade mode
            assert(
                _newTargets.len() == self.managedContractsLength.read(), 'spu12'
            ); // spu12 - number of new targets must be equal to the number of managed contracts

            let zklink_dispatcher = IZklinkDispatcher {
                contract_address: self.mainContract.read()
            };
            let notice_period = zklink_dispatcher.getNoticePeriod();
            self.upgradeStatus.write(UpgradeStatus::NoticePeriod(()));
            self.noticePeriodFinishTimestamp.write(get_block_timestamp().into() + notice_period);

            let newTargets: Span<ClassHash> = _newTargets.span();
            let mut newTargetsIndex = 0;
            loop {
                if newTargetsIndex >= newTargets.len() {
                    break;
                }

                let newTarget: ClassHash = *newTargets[newTargetsIndex];
                self.nextTargets.write(newTargetsIndex, newTarget);
                newTargetsIndex += 1;
            };
            self.nextTargetsLength.write(newTargetsIndex);

            self
                .emit(
                    Event::NoticePeriodStart(
                        NoticePeriodStart {
                            versionId: self.versionId.read(),
                            newTargets: _newTargets,
                            noticePeriod: notice_period
                        }
                    )
                );
        }

        fn finishUpgrade(ref self: ContractState) -> bool {
            self.requireMaster(get_caller_address());
            assert(
                self.upgradeStatus.read() == UpgradeStatus::NoticePeriod(()), 'fpu11'
            ); // ugp11 - unable to finish upgrade in case of not active notice period status

            if (get_block_timestamp().into() < self.noticePeriodFinishTimestamp.read()) {
                return false;
            }
            assert(
                self.managedContractsLength.read() == self.nextTargetsLength.read(), 'fpu12'
            ); // fpu12 - number of new targets class hash must be equal to the number of managed contracts
            let zklink_dispatcher = IZklinkDispatcher {
                contract_address: self.mainContract.read()
            };
            assert(
                zklink_dispatcher.isReadyForUpgrade(), 'fpu13'
            ); // main contract is not ready for upgrade

            let mut i = 0;
            loop {
                if i >= self.managedContractsLength.read() {
                    break;
                }

                let nextTarget: ClassHash = self.nextTargets.read(i);
                if nextTarget != Zeroable::zero() {
                    let managedContract = self.managedContracts.read(i);
                    let upgrade_dispatcher = IUpgradeableDispatcher {
                        contract_address: managedContract
                    };
                    upgrade_dispatcher.upgrade(nextTarget);
                }
                i += 1;
            };

            self.versionId.write(self.versionId.read() + 1);

            let mut newTargets: Array<ClassHash> = array![];
            // delete nextTargets
            let mut i = 0;
            loop {
                if i >= self.nextTargetsLength.read() {
                    break;
                }
                newTargets.append(self.nextTargets.read(i));
                self.nextTargets.write(i, Zeroable::zero());
                i += 1;
            };
            self.nextTargetsLength.write(0);
            self
                .emit(
                    Event::UpgradeComplete(
                        UpgradeComplete { versionId: self.versionId.read(), newTargets: newTargets }
                    )
                );

            self.upgradeStatus.write(UpgradeStatus::Idle(()));
            self.noticePeriodFinishTimestamp.write(0);

            return true;
        }

        fn cancelUpgrade(ref self: ContractState) {
            self.requireMaster(get_caller_address());
            assert(
                self.upgradeStatus.read() != UpgradeStatus::Idle(()), 'cpu11'
            ); // cpu11 - unable to cancel not active upgrade mode

            self.upgradeStatus.write(UpgradeStatus::Idle(()));
            self.noticePeriodFinishTimestamp.write(0);
            // delete nextTargets
            let mut i = 0;
            loop {
                if i >= self.nextTargetsLength.read() {
                    break;
                }
                self.nextTargets.write(i, Zeroable::zero());
                i += 1;
            };
            self.nextTargetsLength.write(0);

            self.emit(Event::UpgradeCancel(UpgradeCancel { versionId: self.versionId.read() }))
        }

        fn upgradeStatus(self: @ContractState) -> UpgradeStatus {
            self.upgradeStatus.read()
        }

        fn mainContract(self: @ContractState) -> ContractAddress {
            self.mainContract.read()
        }

        fn managedContracts(self: @ContractState, _index: usize) -> ContractAddress {
            self.managedContracts.read(_index)
        }

        fn managedContractsLength(self: @ContractState) -> usize {
            self.managedContractsLength.read()
        }

        fn noticePeriodFinishTimestamp(self: @ContractState) -> u256 {
            self.noticePeriodFinishTimestamp.read()
        }

        fn nextTargets(self: @ContractState, _index: usize) -> ClassHash {
            self.nextTargets.read(_index)
        }

        fn nextTargetsLength(self: @ContractState) -> usize {
            self.nextTargetsLength.read()
        }

        fn versionId(self: @ContractState) -> u256 {
            self.versionId.read()
        }
    }

    #[generate_trait]
    impl InternalOwnableImpl of InternalOwnableTrait {
        fn setMaster(ref self: ContractState, _newMaster: ContractAddress) {
            self.master.write(_newMaster);
        }

        fn requireMaster(self: @ContractState, _address: ContractAddress) {
            assert(self.master.read() == _address, '1c'); // oro11 - only by master
        }
    }
}
