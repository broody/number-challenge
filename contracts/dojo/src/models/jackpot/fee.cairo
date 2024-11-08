use starknet::ContractAddress;

#[derive(Drop, Serde, PartialEq, Introspect)]
pub struct Fee {
    #[key]
    pub jackpot_id: u32,
    pub address: ContractAddress,
    pub amount: u256,
    pub total: u256,
    pub recipient: Option<ContractAddress>, // if no recipient, jackpot is for the house
}
