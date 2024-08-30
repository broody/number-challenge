use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Jackpot {
    #[key]
    pub jackpot_id: u32,
    pub winner: Option<ContractAddress>,
    pub token: ContractAddress,
    pub entry_fee: u256,
    pub total: u256,
}