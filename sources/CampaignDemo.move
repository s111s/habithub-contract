module movement::CampaignDemo {
    use std::vector;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::signer;
    use std::debug::print;

    const SEC_IN_1_DAY: u64 = 86400;

    const ERR_PAST_START_TIME: u64 = 101;
    const ERR_MINIMUM_PERIOD: u64 = 102;
    const ERR_CAMPAIGN_DOES_NOT_EXIST: u64 = 103;
    const ERR_MAX_PARTICIPANT_EXISTED: u64 = 104;
    const ERR_CAMPAIGN_IS_NOT_IN_START_TIME: u64 = 105;
    const ERR_CAMPAIGN_IS_ENDED: u64 = 106;
    const ERR_NOT_IN_WHITELIST: u64 = 107;
    const ERR_ALREADY_JOIN_THIS_CAMPAIGN: u64 = 108;

    // Todo 
    // join campaign, 
    // submit data, 
    // verify data, 
    // distribute reward

    struct Campaigns has key, store, drop, copy {
        ids: vector<u64>,
        campaign_info: vector<CampaignInfo>
    }

    struct CampaignInfo has key, store, drop, copy {
        name: String,
        reward_pool: u64,
        reward_per_submit: u64,
        max_participant: u64,
        current_participant: u64,
        start: u64,
        end: u64,
        whitelist_required: bool,
        whitelist_list: vector<address>,
        participant_addresses: vector<address>,
        participant_info: vector<ParticipantInfo>,
        campaign_owner: address
    }

    struct ParticipantInfo has store, drop, copy {
        is_joined: bool,
        submit_hash: String,
        is_submitted: bool,
        is_validated: bool,
        is_claimed_reward: bool
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
            whitelist_required: false,
            whitelist_list: vector::empty<address>(),
            participant_addresses: vector::empty<address>(),
            participant_info: vector::empty<ParticipantInfo>(),
            campaign_owner: @0x00
        };
        let campaign_feed = Campaigns {
            ids: ids,
            campaign_info: (vector[new_campaign_info])
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
            end: end,
            whitelist_required: false,
            whitelist_list: vector::empty<address>(),
            participant_addresses: vector::empty<address>(),
            participant_info: vector::empty<ParticipantInfo>(),
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
        // todo: deposit reward to contract
    }

    fun internal_update_campaign(id: u64, c_name: String, reward_pool: u64, reward_per_submit: u64, max_participant: u64, current_participant: u64, start: u64, end: u64, participant_addresses: vector<address>, participant_info: vector<ParticipantInfo>, campaign_owner: address) acquires Campaigns {
        let campaign_store = borrow_global_mut<Campaigns>(@movement);
        let new_campaign = CampaignInfo {
            name: c_name,
            reward_pool: reward_pool,
            reward_per_submit: reward_per_submit,
            max_participant: max_participant,
            current_participant: current_participant,
            start: start,
            end: end,
            whitelist_required: false,
            whitelist_list: vector::empty<address>(),
            participant_addresses: participant_addresses,
            participant_info: participant_info,
            campaign_owner: campaign_owner
        };
        // get is indexed or not, get index
        let (result, index) = vector::index_of(&mut campaign_store.ids, &id);
        // is indexed: remove old data and replace new one, is not: put new one in the lase index
        if (result == true) {
            vector::remove(&mut campaign_store.campaign_info, index);
            vector::insert(&mut campaign_store.campaign_info, index, new_campaign);
        } else {
            vector::push_back(&mut campaign_store.ids, id);
            vector::push_back(&mut campaign_store.campaign_info, new_campaign);
        };
    }

    public fun join_campaign(participant_sign: &signer, id: u64) acquires Campaigns {
        let ids = borrow_global<Campaigns>(@movement).ids;
        let (campaign_result, campaign_index) = vector::index_of(&ids, &id);
        assert!(campaign_result == true, ERR_CAMPAIGN_DOES_NOT_EXIST);

        let campaign_info_store = &mut get_campaign_info(1);
        
        assert!(campaign_info_store.current_participant >= campaign_info_store.max_participant || campaign_info_store.current_participant == 0, ERR_MAX_PARTICIPANT_EXISTED);

        let now = timestamp::now_seconds();
        assert!(now >= campaign_info_store.start, ERR_CAMPAIGN_IS_NOT_IN_START_TIME);
        // assert!(now > campaign_info_store.end, ERR_CAMPAIGN_IS_ENDED);

        let participant_addr = signer::address_of(participant_sign);

        // if (campaign_info_store.whitelist_required == true) {
        //     let (wl_result, wl_index) = vector::index_of(&campaign_info_store.whitelist_list, &participant_addr);
        //     assert!(wl_result, ERR_NOT_IN_WHITELIST);
        // }

        let (participant_address_result, participant_index) = vector::index_of(&mut campaign_info_store.participant_addresses, &participant_addr);
        assert!(participant_address_result == false, ERR_ALREADY_JOIN_THIS_CAMPAIGN);
        
        let new_participant_info = ParticipantInfo {
            is_joined: true,
            submit_hash: utf8(b""),
            is_submitted: false,
            is_validated: false,
            is_claimed_reward: false
        };
        
        if (participant_address_result == true) {
            vector::remove(&mut campaign_info_store.participant_info, participant_index);
            vector::insert(&mut campaign_info_store.participant_info, participant_index, new_participant_info);
        } else {
            vector::push_back(&mut campaign_info_store.participant_addresses, participant_addr);
            vector::push_back(&mut campaign_info_store.participant_info, new_participant_info);
        }
    }

    fun is_joined_campaign(participant: address, campaign_id: u64): bool acquires Campaigns {
        let participant_list = get_participant_addresses(campaign_id);
        let participant_length = vector::length(&participant_list);
        
        let join_count = 0;
        let i = 0;
        while (i < participant_length) {
            let participant_addr = vector::borrow(&participant_list, i);
            if (&participant == participant_addr) {
                join_count = join_count + 1;
            };
            i = i + 1;
        };

        if (join_count > 0) {
            true
        } else {
            false
        }
    }

    #[view]
    public fun get_all_campaign(): vector<CampaignInfo> acquires Campaigns {
        return borrow_global<Campaigns>(@movement).campaign_info
    }

    #[view]
    public fun get_campaign_info(id: u64): CampaignInfo acquires Campaigns {
        let ids = borrow_global<Campaigns>(@movement).ids;
        let (result, index) = vector::index_of(&ids, &id);
        if (result == true) {
            let campaign = get_all_campaign();
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
                whitelist_required: false,
                whitelist_list: vector::empty<address>(),
                participant_addresses: vector::empty<address>(),
                participant_info: vector::empty<ParticipantInfo>(),
                campaign_owner: @0x00
            }
        }
    }

    #[view]
    public fun get_participant_addresses(id: u64): vector<address> acquires Campaigns {
        get_campaign_info(id).participant_addresses
    }

    #[view]
    public fun get_participant_info(id: u64): vector<ParticipantInfo> acquires Campaigns {
        get_campaign_info(id).participant_info
    }

    #[test(owner = @movement, init_addr = @0x1, participant1 = @0x101)]
    fun test_user_function(owner: &signer, init_addr: signer, participant1: &signer) acquires Campaigns {
        timestamp::set_time_has_started_for_testing(&init_addr);

        print(&utf8(b"=== Initialize Module ==="));
        init_module(owner);
        print(&utf8(b"Module was initialized"));
        
        let st = timestamp::now_seconds();
        let en = timestamp::now_seconds() + 900000;
        print(&utf8(b"Start Time"));
        print(&st);
        print(&utf8(b"End Time"));
        print(&en);

        print(&utf8(b"=== Create Campaign ==="));
        create_campaign(1, owner, utf8(b"Name Campaign 1"), 1000, 10, 100, st, en);
        print(&utf8(b"Campaign was created"));

        print(&utf8(b"=== Get Created Campaign ==="));
        let campaign_result = get_campaign_info(1);
        print(&campaign_result);
        
        print(&utf8(b"=== Join Created Campaign ==="));
        join_campaign(participant1, 1);
        print(&utf8(b"Participant No.1 was joined campaign No.1"));
        
        print(&utf8(b"=== Check Joined Result ==="));
        let joined_result = is_joined_campaign(@0x101, 1);
        print(&joined_result);

        print(&utf8(b"=== Check Participant Address ==="));
        let ptcp_addrs = get_participant_addresses(1);
        print(&ptcp_addrs);

        print(&utf8(b"=== Check Participant Info ==="));
        let ptcp_info = get_participant_info(1);
        print(&ptcp_info);

    }

    #[test(owner = @movement, init_addr = @0x1)]
    fun test_view_function(owner: &signer, init_addr: signer) acquires Campaigns {
        timestamp::set_time_has_started_for_testing(&init_addr);
        init_module(owner);

        print(&utf8(b"=== Get All Campaign ==="));
        let all_campaign_result = get_all_campaign();
        print(&all_campaign_result);

        print(&utf8(b"=== Get Campaign Info ==="));
        let campaign_result = get_campaign_info(0);
        print(&campaign_result);

        print(&utf8(b"=== Get Participant Addresses ==="));
        let participant_addresses_result = get_participant_addresses(0);
        print(&participant_addresses_result);
        
        print(&utf8(b"=== Get Participant Info ==="));
        let get_participant_info = get_participant_info(0);
        print(&get_participant_info);
        
    }

}