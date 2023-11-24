#[starknet::interface]
trait ISyncService<TContractState> {
    fn sendSyncHash(ref self: TContractState, syncHash: u256);
}
