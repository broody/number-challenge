use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum JackpotType {
    ERC20,
    ERC721,
    ERC1155,
}

#[derive(Drop, Serde, PartialEq)]
#[dojo::model]
pub struct Jackpot {
    #[key]
    pub jackpot_id: u32,
    pub creator: ContractAddress,
    pub win_condition: u8,
    pub winner: Option<ContractAddress>,
    pub info: Option<Info>,
    pub token: Token,
    pub fee: Option<Fee>,
    pub powerups: bool,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub struct Token {
    pub id: Option<u256>,
    pub address: ContractAddress,
    pub ty: JackpotType,
    pub total: u256,
}

#[derive(Drop, Serde, PartialEq, Introspect)]
pub struct Fee {
    pub address: ContractAddress,
    pub amount: u256,
    pub total: u256,
    pub recipient: Option<ContractAddress>, // if no recipient, jackpot is for the house
}

#[derive(Drop, Serde, PartialEq, Introspect)]
pub struct Info {
    pub title: ByteArray,
    pub description: ByteArray,
    pub sponsor_url: ByteArray,
}
