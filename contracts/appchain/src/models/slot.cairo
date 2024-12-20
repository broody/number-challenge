use starknet::ContractAddress;

#[derive(Debug, Drop, Serde)]
#[dojo::model]
pub struct Slot {
    #[key]
    pub game_id: u32,
    #[key]
    pub player: ContractAddress,
    #[key]
    pub index: u8,
    pub number: u16,
}
