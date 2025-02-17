module movement::CampaignDemo {
    use std::vector;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::signer;
    use std::debug::print;

    const SEC_IN_1_DAY: u64 = 86400;
    const ERR_PAST_START_TIME: u64 = 101;
    const ERR_MINIMUM_PERIOD: u64 = 102;

    struct CampaignInfo has key, store, drop, copy {
        name: String,
        reward_pool: u64,
        reward_per_submit: u64,
        max_participant: u64,
        current_participant: u64,
        start: u64,
        end: u64,
        participant: vector<Participant>,
        campaign_owner: address
    }

    struct Participant has store, drop, copy {
        wallet_address: address,
        submit_hash: String,
        is_submitted: bool,
        is_claimed_reward: bool
    }

    struct Campaigns has key, store, drop, copy {
        ids: vector<u64>,
        campaign_info: vector<CampaignInfo>,
        total_campaign: u64
    }

    fun init_module(owner: &signer) {
        let ids = vector::empty<u64>();
        vector::push_back(&mut ids, 0);
        let new_campaign_info = CampaignInfo {
            name: utf8(b"Campaign Name"),
            reward_pool: 0,
            reward_per_submit: 0,
            max_participant: 0,
            current_participant: 0,
            start: 0,
            end: 0,
            participant: vector::empty<Participant>(),
            campaign_owner: @0x00
        };
        let campaign_feed = Campaigns {
            ids: ids,
            campaign_info: (vector[new_campaign_info]),
            total_campaign: 0
        };

        move_to(owner, campaign_feed);
    }

    public entry fun create_campaign(id: u64, owner: &signer, c_name: String, reward_pool: u64, reward_per_submit: u64, max_participant: u64, start: u64, end: u64) acquires Campaigns {
        let signer_addr = signer::address_of(owner);
        let now = timestamp::now_seconds();
        assert!(start >= now, ERR_PAST_START_TIME);
        assert!(end > now + SEC_IN_1_DAY, ERR_MINIMUM_PERIOD);
        let campaign_store = borrow_global_mut<Campaigns>(@movement);
        let new_campaign = CampaignInfo {
            name: c_name,
            reward_pool: reward_pool,
            reward_per_submit: reward_per_submit,
            max_participant: max_participant,
            current_participant: 0,
            start: start,
            end: 0,
            participant: vector::empty<Participant>(),
            campaign_owner: signer_addr
        };
        let (result, index) = vector::index_of(&mut campaign_store.ids, &id);
        if (result == true) {
            vector::remove(&mut campaign_store.campaign_info, index);
            vector::insert(&mut campaign_store.campaign_info, index, new_campaign);
        } else {
            vector::push_back(&mut campaign_store.ids, id);
            vector::push_back(&mut campaign_store.campaign_info, new_campaign);
        };
        let total_campaign = &mut borrow_global_mut<Campaigns>(@movement).total_campaign;
        *total_campaign = *total_campaign + 1;
    }

    #[view]
    public fun get_campaign_info(id: u64): CampaignInfo acquires Campaigns {
        let ids = borrow_global<Campaigns>(@movement).ids;
        let (result, index) = vector::index_of(&ids, &id);
        if (result == true) {
            let campaign = borrow_global<Campaigns>(@movement).campaign_info;
            *vector::borrow(&campaign, index)
        } else {
            CampaignInfo {
                name: utf8(b"Campaign Name"),
                reward_pool: 0,
                reward_per_submit: 0,
                max_participant: 0,
                current_participant: 0,
                start: 0,
                end: 0,
                participant: vector::empty<Participant>(),
                campaign_owner: @0x00
            }
        }
    }

    #[view]
    public fun get_all_campaign(): vector<CampaignInfo> acquires Campaigns {
        return borrow_global<Campaigns>(@movement).campaign_info
    }


    #[test(owner = @movement, init_addr = @0x1)]
    fun test_function(owner: &signer, init_addr: signer) acquires Campaigns {
        timestamp::set_time_has_started_for_testing(&init_addr);
        init_module(owner);
        // update_feed(owner, 63400, utf8(b"BTC"));
        let result = get_campaign_info(0);
        print(&result);

        // create_campaign(owner: &signer, c_name: String, reward_pool: u64, reward_per_submit: u64, max_participant: u64, start: u64, end: u64)
        let st = timestamp::now_seconds();
        print(&st);
        let en = timestamp::now_seconds() + 90000;
        print(&en);
        create_campaign(1, owner, utf8(b"Name Campaign 1"), 1000, 10, 100, st, en);
        
        result = get_campaign_info(1);
        print(&result);

        print(&utf8(b"Total campaign"));
        // let ttcp = borrow_global<Campaigns>(@movement).campaign_info;
        let ttcp = get_all_campaign();
        print(&ttcp)
    }

}