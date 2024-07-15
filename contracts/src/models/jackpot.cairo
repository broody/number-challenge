use starknet::ContractAddress;

#[derive(Drop, Serde)]
#[dojo::model]
struct Jackpot {
    #[key]
    jackpot_id: u32,
    winner: Option<ContractAddress>,
    token: ContractAddress,
    amount: u256,
}