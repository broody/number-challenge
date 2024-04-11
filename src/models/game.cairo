use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
#[dojo::event]
struct Game {
    #[key]
    game_id: u32,
    #[key]
    player: ContractAddress,
    max_slots: u8,
    remaining_slots: u8,
    max_number: u16,
    next_number: u16,
}
