use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Jackpot {
    #[key]
    jackpot_id: u32,
    winner: Option<ContractAddress>,
    token: ContractAddress,
    entry_fee: u256,
    total: u256,
}