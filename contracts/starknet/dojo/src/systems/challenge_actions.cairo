use nums_starknet::models::token::Token;


#[starknet::interface]
pub trait IChallengeActions<T> {
    fn create_king_of_the_hill(
        ref self: T,
        title: felt252,
        expiration: u64,
        token: Option<Token>,
        extension_time: u64,
    ) -> u32;
    fn create_conditional_victory(
        ref self: T,
        title: felt252,
        expiration: u64,
        token: Option<Token>,
        slots_required: u8,
    ) -> u32;
    fn verify(ref self: T, challenge_id: u32, verified: bool);
    //fn claim(ref self: T, game_id: u32);
    //fn king_me(ref self: T, game_id: u32);
}


#[dojo::contract]
pub mod challenge_actions {
    use core::array::ArrayTrait;
    use core::num::traits::Zero;
    use nums_starknet::models::challenge::Challenge;
    use nums_starknet::interfaces::token::{ITokenDispatcher, ITokenDispatcherTrait};
    use nums_starknet::models::token::{Token, TokenType};
    use nums_common::challenge_mode::{ChallengeMode, ConditionalVictory, KingOfTheHill};

    use dojo::model::ModelStorage;
    use dojo::event::EventStorage;
    use dojo::world::IWorldDispatcherTrait;

    use starknet::{ContractAddress, get_contract_address, get_caller_address, get_block_timestamp};
    use super::IChallengeActions;

    const WORLD: felt252 = 0;

    #[derive(Drop, Serde)]
    #[dojo::event]
    pub struct ChallengeCreated {
        #[key]
        challenge_id: u32,
        token: Option<Token>,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    pub struct ChallengeClaimed {
        #[key]
        game_id: u32,
        #[key]
        challenge_id: u32,
        player: ContractAddress,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    pub struct KingCrowned {
        #[key]
        game_id: u32,
        #[key]
        challenge_id: u32,
        player: ContractAddress
    }

    #[abi(embed_v0)]
    impl ChallengeActions of IChallengeActions<ContractState> {
        fn create_conditional_victory(
            ref self: ContractState,
            title: felt252,
            expiration: u64,
            token: Option<Token>,
            slots_required: u8
        ) -> u32 {
            let mode = ChallengeMode::CONDITIONAL_VICTORY(ConditionalVictory { slots_required });
            self._create(title, mode, expiration, token,)
        }

        fn create_king_of_the_hill(
            ref self: ContractState,
            title: felt252,
            expiration: u64,
            token: Option<Token>,
            extension_time: u64,
        ) -> u32 {
            if expiration == 0 && extension_time > 0 {
                panic!("cannot set extension with no expiration");
            }

            let mode = ChallengeMode::KING_OF_THE_HILL(
                KingOfTheHill {
                    extension_time,
                    king: starknet::contract_address_const::<0x0>(),
                }
            );
            self._create(title, mode, expiration, token)
        }

        /// Claims the challenge for a specific game. Ensures that the player is authorized and that
        /// the challenge has not been claimed before.
        /// Transfers the challenge token to the player and updates the challenge state.
        ///
        /// # Arguments
        /// * `game_id` - The identifier of the game.
        // fn claim(ref self: ContractState, game_id: u32) {
        //     let mut world = self.world(@"nums");
        //     let player = get_caller_address();
        //     let game: Game = world.read_model((game_id, player));
        //     let config: Config = world.read_model(WORLD);
        //     let game_config = config.game.expect('game config not set');
        //     let challenge_id = game.challenge_id.expect('challenge not defined');
        //     let mut challenge: Challenge = world.read_model(challenge_id);

        //     if challenge.expiration > 0 {
        //         assert(challenge.expiration < get_block_timestamp(), 'cannot claim yet')
        //     }

        //     let mut nums = ArrayTrait::<u16>::new();
        //     let mut idx = game_config.max_slots;
        //     while idx > 0 {
        //         let slot: Slot = world.read_model(((game_id, player, game_config.max_slots - idx)));
        //         if slot.number != 0 {
        //             nums.append(slot.number);
        //         }
        //         idx -= 1_u8;
        //     };

        //     assert(nums.len() != 0, 'no slots filled');
        //     assert(game.is_valid(@nums), 'invalid game state');
        //     assert(challenge.can_claim(@nums), 'cannot claim challenge');

        //     challenge.winner = Option::Some(game.player);
        //     challenge.claimed = true;
        //     world.write_model(@challenge);
        //     world.emit_event(@ChallengeClaimed { game_id, challenge_id, player });

        //     if let Option::Some(token) = challenge.token {
        //         ITokenDispatcher { contract_address: token.address }
        //             .transfer(game.player, token.total);
        //     }
        // }

        /// Attempts to crown the caller as the new king in a King of the Hill challenge.
        ///
        /// This function allows a player to claim the position of "king" in a King of the Hill
        /// challenge game. It verifies that the game is associated with a King of the Hill
        /// challenge, updates the current king, and potentially extends the challenge's expiration
        /// time.
        ///
        /// The remaining_slots mechanism ensures that each new king must have fewer or equal
        /// remaining slots compared to the previous king. This creates a progressively more
        /// challenging game as it continues.
        ///
        /// # Arguments
        /// * `game_id` - The identifier of the game associated with the challenge.
        // fn king_me(ref self: ContractState, game_id: u32) {
        //     let mut world = self.world(@"nums");
        //     let player = get_caller_address();
        //     let game: Game = world.read_model((game_id, player));
        //     let challenge_id = game.challenge_id.expect('Challenge not defined');
        //     let mut challenge: Challenge = world.read_model(challenge_id);

        //     let mut king_of_the_hill = match challenge.mode {
        //         ChallengeMode::KING_OF_THE_HILL(koth) => koth,
        //         _ => panic!("Not a King of the Hill challenge")
        //     };

        //     assert(challenge.expiration > get_block_timestamp(), 'Challenge already expired');
        //     assert(
        //         game.remaining_slots < king_of_the_hill.remaining_slots
        //             || (game.remaining_slots == king_of_the_hill.remaining_slots
        //                 && player != king_of_the_hill.king),
        //         'No improvement or already king'
        //     );

        //     king_of_the_hill.king = player;
        //     king_of_the_hill.remaining_slots = game.remaining_slots;

        //     if king_of_the_hill.extension_time > 0 {
        //         let new_expiration = challenge.expiration + king_of_the_hill.extension_time;
        //         if new_expiration > challenge.expiration {
        //             challenge.expiration = new_expiration;
        //         }
        //     }

        //     // Update the challenge with the new king
        //     challenge.mode = ChallengeMode::KING_OF_THE_HILL(king_of_the_hill);
        //     world.write_model(@challenge);
        //     world.emit_event(@KingCrowned { game_id, challenge_id, player });
        // }


        /// Verifies or unverifies a challenge as legitimate.
        /// Only the game owner can call this function to mark a challenge as verified or not.
        ///
        /// # Arguments
        /// * `challenge_id` - The identifier of the challenge to verify.
        /// * `verified` - A boolean indicating whether the challenge should be marked as verified
        /// (true) or not (false).
        fn verify(ref self: ContractState, challenge_id: u32, verified: bool) {
            let mut world = self.world(@"nums");
            let owner = get_caller_address();
            assert!(world.dispatcher.is_owner(WORLD, owner), "Unauthorized owner");
            let mut challenge: Challenge = world.read_model(challenge_id);
            challenge.verified = verified;

            world.write_model(@challenge);
        }
    }


    #[generate_trait]
    pub impl InternalImpl of InternalTrait {
        fn _create(
            self: @ContractState,
            title: felt252,
            mode: ChallengeMode,
            expiration: u64,
            token: Option<Token>,
        ) -> u32 {
            if expiration > 0 {
                assert!(expiration > get_block_timestamp(), "Expiration already passed")
            }

            let mut world = self.world(@"nums");
            let creator = get_caller_address();
            let challenge_id = world.dispatcher.uuid();
            world
                .write_model(
                    @Challenge {
                        challenge_id,
                        title,
                        creator,
                        mode,
                        expiration,
                        token,
                        claimed: false,
                        verified: false,
                        winner: Option::None,
                    }
                );

            world.emit_event(@ChallengeCreated { challenge_id, token });

            if let Option::Some(token) = token {
                assert(token.ty == TokenType::ERC20, 'only ERC20 supported');
                assert(token.total.is_non_zero(), 'total cannot be zero');

                ITokenDispatcher { contract_address: token.address }
                    .transferFrom(get_caller_address(), get_contract_address(), token.total);
            }

            challenge_id
        }
    }
}

