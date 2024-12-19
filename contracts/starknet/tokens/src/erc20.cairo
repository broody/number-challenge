use starknet::ContractAddress;

#[starknet::interface]
pub trait INumsToken<TContractState> {
    fn reward(ref self: TContractState, recipient: ContractAddress, amount: u16) -> bool;
    fn set_rewards_caller(ref self: TContractState, caller: ContractAddress);
    fn renounce_ownership(ref self: TContractState);
    fn owner(ref self: TContractState) -> ContractAddress;
}

#[starknet::contract]
mod NumsToken {
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::{ContractAddress, ClassHash, get_caller_address, contract_address_const};
    
    use core::option::OptionTrait;
    use starknet::storage::{
        StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess
    };

    const DECIMALS: u256 = 1000000000000000000;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        rewards_caller: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        rewards_caller: ContractAddress
    ) {
        let name = "Nums";
        let symbol = "NUMS";

        self.erc20.initializer(name, symbol);
        self.rewards_caller.write(rewards_caller);
        self.ownable.initializer(get_caller_address());
    }

    #[abi(embed_v0)]
    impl NumsTokenImpl of super::INumsToken<ContractState> {
        // restrict amount to u16 so upper limit is 0xFFFF tokens
        fn reward(ref self: ContractState, recipient: ContractAddress, amount: u16) -> bool {
            assert!(self.rewards_caller.read() == get_caller_address(), "Only the reward caller can mint tokens");
            self.erc20.mint(recipient, amount.into() * DECIMALS);
            true
        }

        fn set_rewards_caller(ref self: ContractState, caller: ContractAddress) {
            self.ownable.assert_only_owner();
            self.rewards_caller.write(caller);
        }

        fn renounce_ownership(ref self: ContractState) {
            self.ownable.renounce_ownership();
        }

        fn owner(ref self: ContractState) -> ContractAddress {
            self.ownable.owner()
        }
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }
}
