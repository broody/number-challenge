use starknet::ContractAddress;

#[starknet::interface]
pub trait INumsToken<TContractState> {
    fn reward(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn set_rewards_caller(ref self: TContractState, caller: ContractAddress);
    fn revoke_owner(ref self: TContractState);
}


#[starknet::contract]
mod NumsToken {
    // If only the token package was added as a dependency, use `openzeppelin_token::` instead
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::{ContractAddress, get_caller_address, contract_address_const};
    
    use starknet::storage::{
        StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess
    };

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        owner: ContractAddress,
        rewards_caller: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
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
        self.owner.write(get_caller_address());
    }

    #[abi(embed_v0)]
    impl NumsTokenImpl of super::INumsToken<ContractState> {
        fn reward(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            assert!(self.rewards_caller.read() == get_caller_address(), "Only the reward caller can mint tokens");
            self.erc20.mint(recipient, amount);
            true
        }

        fn set_rewards_caller(ref self: ContractState, caller: ContractAddress) {
            assert!(self.owner.read() == get_caller_address(), "Only the owner can set the rewards caller");
            self.rewards_caller.write(caller);
        }

        fn revoke_owner(ref self: ContractState) {
            assert!(self.owner.read() == get_caller_address(), "Only the owner can revoke ownership");
            self.owner.write(contract_address_const::<0>());
        }
    }
}
