module movement::campaign {
    use std::debug;
    use std::string::{String, utf8};

    fun create_campaign(): u64 {
        let campaign_id: u64 = 0;
        let campaign_title: String = utf8(b"Campaign Title");
        let reward_pool: u64 = 1000000;
        debug::print(&campaign_id);
        debug::print(&campaign_title);
        debug::print(&reward_pool);

        campaign_id
    } 

    #[test]
    fun test_create_campaign() {
        let id_value = create_campaign();
        debug::print(&id_value);
    }
}