use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
pub struct Name {
    #[key]
    pub game_id: u32,
    #[key]
    pub player: ContractAddress,
    pub name: felt252
}
