use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct Name {
    #[key]
    game_id: u32,
    #[key]
    player: ContractAddress,
    name: felt252
}