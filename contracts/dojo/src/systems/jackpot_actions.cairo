use nums::models::jackpot::{Token, Info, Fee};
use starknet::ContractAddress;

#[dojo::interface]
pub trait IJackpotActions {
    fn create_jackpot(
        ref world: IWorldDispatcher,
        win_condition: u8,
        info: Option<Info>,
        token: Token,
        fee: Option<Fee>,
        powerups: bool,
    ) -> u32;
    fn claim_jackpot(ref world: IWorldDispatcher, game_id: u32);
}


#[dojo::contract]
pub mod jackpot_actions {
    use core::array::ArrayTrait;
    use core::num::traits::Zero;
    use nums::interfaces::token::{ITokenDispatcher, ITokenDispatcherTrait};
    use nums::models::config::Config;
    use nums::models::game::{Game, GameTrait};
    use nums::models::jackpot::{Jackpot, JackpotType, Info, Fee, Token};
    use nums::models::name::Name;
    use nums::models::slot::Slot;

    use starknet::{ContractAddress, get_contract_address, get_caller_address};
    use super::IJackpotActions;

    const WORLD: felt252 = 0;

    #[derive(Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
    pub struct JackpotCreated {
        #[key]
        jackpot_id: u32,
        token: Token,
    }

    #[derive(Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
    pub struct JackpotClaimed {
        #[key]
        jackpot_id: u32,
        player: ContractAddress,
    }

    #[abi(embed_v0)]
    impl JackpotActions of IJackpotActions<ContractState> {
        fn create_jackpot(
            ref world: IWorldDispatcher,
            win_condition: u8,
            info: Option<Info>,
            token: Token,
            fee: Option<Fee>,
            powerups: bool,
        ) -> u32 {
            if fee.is_some() {
                panic!("Fee is not implemented");
            }

            if token.ty != JackpotType::ERC20 {
                panic!("Only ERC20 tokens are supported");
            }

            assert!(token.total.is_non_zero(), "Token total cannot be zero");

            let config = get!(world, (WORLD), Config).game.expect('Game config not set');
            assert!(win_condition != 0, "Win condition cannot be zero");
            assert!(
                config.max_slots >= win_condition,
                "Win condition cannot be more than slots available"
            );

            let creator = get_caller_address();
            ITokenDispatcher { contract_address: token.address }
                .transferFrom( creator, get_contract_address(), token.total);

            let jackpot_id = world.uuid();
            set!(
                world,
                (Jackpot {
                    jackpot_id, win_condition, winner: Option::None, info, token, fee, powerups, creator,
                })
            );

            emit!(world, JackpotCreated { jackpot_id, token });

            jackpot_id
        }


        /// Claims the jackpot for a specific game. Ensures that the player is authorized and that
        /// the jackpot has not been claimed before.
        /// Transfers the jackpot token to the player and updates the jackpot state.
        ///
        /// # Arguments
        /// * `world` - A reference to the world dispatcher used to interact with the game state.
        /// * `game_id` - The identifier of the game.
        fn claim_jackpot(ref world: IWorldDispatcher, game_id: u32) {
            let player = get_caller_address();
            let game = get!(world, (game_id, player), Game);
            let jackpot_id = game.jackpot_id.expect('Jackpot not defined');
            let mut jackpot = get!(world, (jackpot_id), Jackpot);
            assert!(jackpot.winner.is_none(), "Jackpot already won");

            let mut nums = ArrayTrait::<u16>::new();
            let mut idx = 0_u8;
            loop {
                let slot = get!(world, (game_id, player, idx), Slot);
                if slot.number != 0 {
                    nums.append(slot.number);
                }

                if idx >= jackpot.win_condition {
                    break;
                }
                idx += 1_u8;
            };

            assert!(game.is_valid(@nums), "Invalid game state");

            // TODO: support erc721 and erc1155 jackpot types
            ITokenDispatcher { contract_address: jackpot.token.address }
                .transfer(game.player, jackpot.token.total);

            jackpot.winner = Option::Some(game.player);
            set!(world, (jackpot));

            emit!(world, JackpotClaimed { jackpot_id, player, })
        }
    }
}

