use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum JackpotType {
    ERC20,
    ERC721,
    ERC1155,
}

#[derive(Copy, Drop, Serde, PartialEq)]
#[dojo::model]
pub struct Jackpot {
    #[key]
    pub jackpot_id: u32,
    pub threshold_offset: u8,
    pub winner: Option<ContractAddress>,
    pub token_type: JackpotType,
    pub token_address: ContractAddress,
    pub token_total: u256,
    pub token_id: Option<u256>,
    pub fee: u256,
    pub fee_address: ContractAddress,
    pub fee_total: u256,
    pub fee_recipient: Option<ContractAddress>, // if no recipient, jackpot is for the house
    pub enable_powerups: bool,
}
