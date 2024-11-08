#[derive(Drop, Serde, Introspect)]
#[dojo::model]
pub struct Metadata {
    #[key]
    pub jackpot_id: u32,
    pub description: ByteArray,
    pub sponsor_url: ByteArray,
}
