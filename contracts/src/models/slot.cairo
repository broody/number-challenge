use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
#[dojo::event]
struct Slot {
    #[key]
    game_id: u32,
    #[key]
    player: ContractAddress,
    #[key]
    slot: u8,
    number: u16,
}
