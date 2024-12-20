
#[starknet::interface]
pub trait IMessageHandlers<T> {
    fn challenge_message_handler(ref self: T, payload: Span<felt252>);
    fn config_message_handler(ref self: T, payload: Span<felt252>);
}

#[dojo::contract]
pub mod message_handlers {
    use super::IMessageHandlers;

    use dojo::model::ModelStorage;

    use nums_common::messages::ChallengeMessage;
    use nums_appchain::models::challenge::Challenge;

    #[abi(embed_v0)]
    impl MessageHandlers of IMessageHandlers<ContractState> {
        fn challenge_message_handler(
            ref self: ContractState,
            payload: Span<felt252>
        ) {
            // TODO: check if calling address is Starknet Contract
            
            let mut serialized = payload;
            let challenge_message: ChallengeMessage = Serde::deserialize(ref serialized).expect('Failed to deserialize');
            
            let mut world = self.world(@"nums");
            world.write_model(
                @Challenge {
                    id: challenge_message.id,
                    mode: challenge_message.mode,
                    expiration: challenge_message.expiration,
                    winner: Option::None,
                }
            );
        }

        fn config_message_handler(
            ref self: ContractState,
            payload: Span<felt252>
        ) {
            panic!("Not implemented");
        }
    }
}