use starknet::ContractAddress;
use piltover::messaging::types::{
    MessageHash, Nonce, MessageToAppchainStatus, MessageToStarknetStatus
};

#[starknet::interface]
pub trait IMessaging<TState> {
    fn send_message_to_appchain(
        ref self: TState, to_address: ContractAddress, selector: felt252, payload: Span<felt252>
    ) -> (MessageHash, Nonce);
    fn consume_message_from_appchain(
        ref self: TState, from_address: ContractAddress, selector: felt252, payload: Span<felt252>
    ) -> MessageHash;
    fn sn_to_appchain_messages(self: @TState, message_hash: felt252) -> MessageToAppchainStatus;
    fn appchain_to_sn_messages(self: @TState, message_hash: felt252) -> MessageToStarknetStatus;
}
