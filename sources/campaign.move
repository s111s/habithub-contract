module movement::campaign {
    use std::debug;
    use std::string::{String, utf8};

    fun create_campaign(campaign_id: u64, campaign_title: String, reward_pool: u64): u64 {
        let campaign_id: u64 = campaign_id;
        let campaign_title: String = campaign_title;
        let reward_pool: u64 = reward_pool;
        debug::print(&campaign_id);
        debug::print(&campaign_title);
        debug::print(&reward_pool);

        campaign_id
    } 

    #[test]
    fun test_create_campaign() {
        let id_value = create_campaign(1, utf8(b"Test Campaign"), 10000);
        debug::print(&id_value);
    }
}