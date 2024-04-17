// define the interface
#[dojo::interface]
trait IActions {
    fn create() -> (u32, u16);
    fn set_slot(game_id: u32, slot: u8) -> u16;
}

// dojo decorator
#[dojo::contract]
mod actions {
    use super::IActions;

    use starknet::{ContractAddress, get_caller_address};
    use number_challenge::models::game::Game;
    use number_challenge::models::slot::Slot;
    use number_challenge::utils::random::{Random, RandomImpl};

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Created: Created,
        Inserted: Inserted,
    }

    #[derive(starknet::Event, Model, Copy, Drop, Serde)]
    struct Inserted {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        slot: u8,
        number: u16,
        next_number: u16,
        remaining_slots: u8
    }

    #[derive(starknet::Event, Model, Copy, Drop, Serde)]
    struct Created {
        #[key]
        game_id: u32,
        #[key]
        player: ContractAddress,
        max_slots: u8,
        max_number: u16
    }

    // impl: implement functions specified in trait
    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn create(world: IWorldDispatcher) -> (u32, u16) {
            let game_id = world.uuid();
            let player = get_caller_address();
            let mut rand = RandomImpl::new(world);
            let next_number = rand.between::<u16>(1, 1000);

            set!(
                world,
                (
                    Game {
                        game_id,
                        player,
                        max_slots: 20,
                        remaining_slots: 20,
                        max_number: 1000,
                        next_number,
                    },
                )
            );

            emit!(world, Created { game_id, player, max_slots: 20, max_number: 1000 });

            (game_id, next_number)
        }


        fn set_slot(world: IWorldDispatcher, game_id: u32, slot: u8) -> u16 {
            let player = get_caller_address();
            let mut game = get!(world, (game_id, player), Game);

            assert!(game.player == player, "Unauthorized player");
            assert!(game.remaining_slots > 0, "No more slots available");
            assert!(slot < game.max_slots, "Invalid slot");

            let mut target = get!(world, (game_id, player, slot), Slot);
            assert!(target.number == 0, "Slot already filled");

            if slot != 0 {
                let mut idx = slot;

                loop {
                    idx -= 1;
                    let prev = get!(world, (game_id, player, idx), Slot);
                    if prev.number != 0 {
                        assert!(prev.number <= game.next_number, "Number must be > than prev");
                        break;
                    }

                    if idx == 0 {
                        break;
                    }
                }
            }

            if slot != game.max_slots - 1_u8 {
                let mut idx = slot;

                loop {
                    idx += 1;
                    let next = get!(world, (game_id, player, idx), Slot);
                    if next.number != 0 {
                        assert!(next.number >= game.next_number, "Number must be < than next");
                        break;
                    }

                    if idx == game.max_slots - 1_u8 {
                        break;
                    }
                }
            }

            target.number = game.next_number;
            let mut rand = RandomImpl::new(world);
            let next_number = rand.between::<u16>(1, 1000);
            game.next_number = next_number;
            game.remaining_slots -= 1;
            emit!(
                world,
                Inserted {
                    game_id,
                    player,
                    slot,
                    number: target.number,
                    next_number,
                    remaining_slots: game.remaining_slots
                }
            );

            set!(world, (game, target));

            next_number
        }
    }
}

