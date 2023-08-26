use starknet::ContractAddress;

#[starknet::interface]
trait IStandardDecimalsToken<TContractState> {
    fn decimals(self: @TContractState) -> u8;
    fn mint(ref self: TContractState, amount: u256);
    fn mintTo(ref self: TContractState, to: ContractAddress, amount: u256);
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
}

#[starknet::contract]
mod StandardDecimalsToken {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;

    #[storage]
    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _decimals: u8,
        _total_supply: u256,
        _balances: LegacyMap<ContractAddress, u256>,
        _allowances: LegacyMap<(ContractAddress, ContractAddress), u256>
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252, decimals: u8) {
        self.initializer(name, symbol, decimals);
    }

    #[external(v0)]
    impl IStandardDecimalsTokenImpl of super::IStandardDecimalsToken<ContractState> {
        fn decimals(self: @ContractState) -> u8 {
            self._decimals.read()
        }

        fn mint(ref self: ContractState, amount: u256) {
            self._mint(get_caller_address(), amount);
        }

        fn mintTo(ref self: ContractState, to: ContractAddress, amount: u256) {
            self._mint(to, amount);
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            self._approve(caller, spender, amount);
            true
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self._balances.read(account)
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            self._transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let caller = get_caller_address();
            self._spend_allowance(sender, caller, amount);
            self._transfer(sender, recipient, amount);
            true
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn initializer(ref self: ContractState, name_: felt252, symbol_: felt252, decimals_: u8) {
            self._name.write(name_);
            self._symbol.write(symbol_);
            self._decimals.write(decimals_);
        }

        fn _mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            assert(!recipient.is_zero(), 'ERC20: mint to 0');
            self._total_supply.write(self._total_supply.read() + amount);
            self._balances.write(recipient, self._balances.read(recipient) + amount);
        }

        fn _approve(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            assert(!owner.is_zero(), 'ERC20: approve from 0');
            assert(!spender.is_zero(), 'ERC20: approve to 0');
            self._allowances.write((owner, spender), amount);
        }

        fn _burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            assert(!account.is_zero(), 'ERC20: burn from 0');
            self._total_supply.write(self._total_supply.read() - amount);
            self._balances.write(account, self._balances.read(account) - amount);
        }

        fn _transfer(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            assert(!sender.is_zero(), 'ERC20: transfer from 0');
            assert(!recipient.is_zero(), 'ERC20: transfer to 0');
            self._balances.write(sender, self._balances.read(sender) - amount);
            self._balances.write(recipient, self._balances.read(recipient) + amount);
        }

        fn _spend_allowance(
            ref self: ContractState, owner: ContractAddress, spender: ContractAddress, amount: u256
        ) {
            let current_allowance = self._allowances.read((owner, spender));
            self._approve(owner, spender, current_allowance - amount);
        }
    }
}
