use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub enum TokenType {
    ERC20,
    ERC721,
    ERC1155,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
pub struct Token {
    pub id: Option<u256>, // for erc721 and 1155
    pub address: ContractAddress,
    pub ty: TokenType,
    pub total: u256,
}
