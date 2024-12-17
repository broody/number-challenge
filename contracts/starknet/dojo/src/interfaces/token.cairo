use starknet::ContractAddress;

#[starknet::interface]
pub trait IToken<TState> {
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transferFrom(
        ref self: TState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
}

#[starknet::interface]
pub trait INumsToken<TState> {
    // amount is in 10*18 units
    fn reward(ref self: TState, recipient: ContractAddress, amount: u16) -> bool;
}
