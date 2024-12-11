#[starknet::interface]
pub trait IRandomActions<T> {
    fn gimme_random(ref self: T) -> u16;
}

#[dojo::contract]
pub mod random_actions {
    use super::IRandomActions;
    use nums::utils::random::RandomImpl;

    #[abi(embed_v0)]
    impl RandomActionsImpl of IRandomActions<ContractState> {
        fn gimme_random(ref self: ContractState) -> u16 {
            let mut rand = RandomImpl::new_vrf();
            rand.between::<u16>(0, 100)
        }
    }
}