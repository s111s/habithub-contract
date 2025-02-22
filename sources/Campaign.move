module movement::Campaign {
    use std::vector;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::signer;
    use std::debug::print;

    const SEC_IN_1_DAY: u64 = 86400;

    const ERR_PAST_START_TIME: u64 = 101;
    const ERR_MINIMUM_PERIOD: u64 = 102;
    const ERR_MAX_PARTICIPANT_EXISTED: u64 = 104;
    const ERR_CAMPAIGN_IS_NOT_IN_START_TIME: u64 = 105;
    const ERR_CAMPAIGN_IS_ENDED: u64 = 106;
    const ERR_NOT_IN_WHITELIST: u64 = 107;
    const ERR_ALREADY_JOIN_THIS_CAMPAIGN: u64 = 108;

    const ERR_LIVE_CAMPAIGN_ALREADY_EXISTS: u64 = 1001;
    const ERR_CAMPAIGN_DOES_NOT_EXIST: u64 = 1002;
    const ERR_CAMPAIGN_HAS_ENDED: u64 = 1003;
    const ERR_USER_ALREADY_PARTICIPATED: u64 = 1004;
    const ERR_LIMIT_PARTICIPANT_EXISTED: u64 = 1005;

    const ERR_ADDRESS_NOT_EXIST_IN_PARTICIPANT: u64 = 1008;
    
    // verify data, 
    // distribute reward

    struct CampaignRegistry has key, store, copy, drop {
        campaigns: vector<Campaign>
    }

    struct Campaign has key, store, copy, drop {
        campaign_id: u64,
        name: String,
        creator: address,
        start_time: u64,
        end_time: u64,
        reward_pool: u64,
        reward_per_submit: u64,
        current_participant: u64,
        max_participant: u64,
        participants: vector<Participant>,
        participant_id_index: vector<u64>,
        participant_address_index: vector<address>
    }

    struct Participant has key, store, copy, drop {
        participant_id: u64,
        participant_address: address,
        submit_hash: String,
        is_participated: bool,
        is_submitted: bool,
        is_validated: bool,
        is_validation_pass: bool,
        is_claimed_reward: bool
    }

    struct ValidatorRegistry has key, store, copy, drop {
        validators: vector<Validator>
    }

    struct Validator has key, store, copy, drop {
        ids: vector<u64>,
        addresses: vector<address>
    }

    fun init_module_internal(owner: &signer) {
        move_to(owner, CampaignRegistry{
            campaigns: vector::empty<Campaign>()
        });

        move_to(owner, ValidatorRegistry{
            validators: vector::empty<Validator>()
        });

        // let validator = Validator {
        //     ids: vector::empty<u64>,
        //     addresses: vector::empty<u64>
        // }
    }

    fun create_campaign(sender: &signer, campaign_name: String, duration: u64, reward_pool: u64, reward_per_submit: u64, max_participant: u64) acquires CampaignRegistry {
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);
        let campaign_registry_length = vector::length(&campaign_registry.campaigns);
        let campaign_end_time = if(campaign_registry_length > 0) {
            vector::borrow(&campaign_registry.campaigns, campaign_registry_length - 1).end_time
        } else {
            0
        };

        let now = timestamp::now_seconds();
        // assert!(campaign_end_time == 0 || now >= campaign_end_time, ERR_LIVE_CAMPAIGN_ALREADY_EXISTS);
        let next_campaign_id = campaign_registry_length + 1;
        let new_campaign = Campaign {
            campaign_id: next_campaign_id,
            name: campaign_name,
            creator: signer::address_of(sender),
            start_time: now,
            end_time: now + duration,
            reward_pool: reward_pool,
            reward_per_submit: reward_per_submit,
            current_participant: 0,
            max_participant: max_participant,
            participants: vector::empty<Participant>(),
            participant_id_index: vector::empty<u64>(),
            participant_address_index: vector::empty<address>()
        };

        vector::push_back(&mut campaign_registry.campaigns, new_campaign);
    }

    fun participate_on_campaign(sender: &signer, campaign_id: u64) acquires CampaignRegistry {
        let sender_addr = signer::address_of(sender);

        // check campaign exists
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);
        let campaign_registry_length = vector::length(&campaign_registry.campaigns);
        assert!(campaign_id > 0 && campaign_id <= campaign_registry_length, ERR_CAMPAIGN_DOES_NOT_EXIST);

        // check campaign has ended
        let campaign = vector::borrow_mut(&mut campaign_registry.campaigns, campaign_id - 1);
        
        let now = timestamp::now_seconds();
        // assert!(now < campaign.end_time, ERR_CAMPAIGN_HAS_ENDED);
        
        // check users already participate 
        // assert!(!exists<Participant>(campaign.participants), ERR_USER_ALREADY_PARTICIPATED);

        // check limit number of participant
        assert!(campaign.current_participant < campaign.max_participant, ERR_LIMIT_PARTICIPANT_EXISTED);

        // check remaining allocated reward
        // Todo

        // count participant
        campaign.current_participant = campaign.current_participant + 1;

        let new_participant = Participant {
            participant_id: campaign.current_participant,
            participant_address: sender_addr,
            submit_hash: utf8(b""),
            is_participated: true,
            is_submitted: false,
            is_validated: false,
            is_validation_pass: false,
            is_claimed_reward: false
        };

        vector::push_back(&mut campaign.participants, new_participant);

        // map participant index
        vector::push_back(&mut campaign.participant_id_index, campaign.current_participant);
        vector::push_back(&mut campaign.participant_address_index, sender_addr);
    }

    fun submit_on_campaign(sender: &signer, campaign_id: u64) acquires CampaignRegistry {
        let sender_addr = signer::address_of(sender);
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);
        let campaign = vector::borrow_mut(&mut campaign_registry.campaigns, campaign_id - 1);

        let now = timestamp::now_seconds();
        // assert!(now < campaign.end_time, ERR_CAMPAIGN_HAS_ENDED);

        // check users must participated before
        // assert!(exists<Participant>(campaign.participants), ERR_NOT_IN_PARTICIPATE);

        // check users already submit 
        // assert!(!exists<Participant>(campaign.participants), ERR_USER_ALREADY_SUBMITTED);

        let addr_list = campaign.participant_address_index;
        let (result, index) = vector::index_of(&addr_list, &sender_addr);

        assert!(result, ERR_ADDRESS_NOT_EXIST_IN_PARTICIPANT);
        let id_list = campaign.participant_id_index;

        let participant_id = *vector::borrow(&id_list, index);
        let participant_info = vector::borrow_mut(&mut campaign.participants, participant_id - 1);
        
        let new_submit_hash = utf8(b"testsubmithash");

        participant_info.submit_hash = new_submit_hash;
        participant_info.is_submitted = true;
    }

    fun get_participant_id_from_address(campaign_id: u64, addr: address): u64 acquires CampaignRegistry {
        let campaign_registry = borrow_global<CampaignRegistry>(@movement);
        let campaign = vector::borrow(&campaign_registry.campaigns, campaign_id - 1);
        let addr_list = campaign.participant_address_index;
        let (result, index) = vector::index_of(&addr_list, &addr);

        assert!(result, ERR_ADDRESS_NOT_EXIST_IN_PARTICIPANT);
        let id_list = campaign.participant_id_index;

        *vector::borrow(&id_list, index)
    } 

    // fun add_validator(validator_addr: address) acquires ValidatorRegistry {
    //     let validator_registry = borrow_global_mut<ValidatorRegistry>(@movement);
    //     let validator_length = vector::length(&validator_registry);
        
    //     let next_validator_id = validator_length + 1;
        
    //     vector::push_back(&mut validator_registry.ids, validator_addr);
    //     vector::push_back(&mut validator_registry.addresses, next_validator_id);
    // }

    #[view]
    public fun get_all_campaign(): vector<Campaign> acquires CampaignRegistry {
        return borrow_global<CampaignRegistry>(@movement).campaigns
    }

    public fun get_campaign_by_id(campaign_id: u64) {
        // let campaign_registry = borrow_global<CampaignRegistry>(@movement);
        // let campaign_registry_length = vector::length(&campaign_registry.campaigns);
        // assert!(campaign_id > 0 && campaign_id <= campaign_registry_length, ERR_CAMPAIGN_DOES_NOT_EXIST);

        // let campaign = vector::borrow(&campaign_registry.campaigns, campaign_id);
        // return *vector::borrow(campaign, campaign_id)
        // // let (result, index) = vector::index_of(&ids, &id);
        // if (result == true) {
        //     let campaign = get_all_campaign();
        //     *vector::borrow(&campaign, index)
        // } else {
        //     CampaignInfo {
        //         name: utf8(b"Campaign Name"),
        //         reward_pool: 0,
        //         reward_per_submit: 0,
        //         max_participant: 0,
        //         current_participant: 0,
        //         start: 0,
        //         end: 0,
        //         whitelist_required: false,
        //         whitelist_list: vector::empty<address>(),
        //         participant_addresses: vector::empty<address>(),
        //         participant_info: vector::empty<ParticipantInfo>(),
        //         campaign_owner: @0x00
        //     }
        // }
    }

    #[test(owner = @movement, init_addr = @0x1, participant1 = @0x101)]
    fun test_function(owner: &signer, init_addr: signer, participant1: &signer) acquires CampaignRegistry {
        timestamp::set_time_has_started_for_testing(&init_addr);
        init_module_internal(owner);
        create_campaign(owner, utf8(b"Campaign Name 1 Naja"), 90000, 5001, 500, 10);
        create_campaign(owner, utf8(b"Campaign Name 2 Naja"), 90000, 5002, 500, 10);
        create_campaign(owner, utf8(b"Campaign Name 3 Naja"), 90000, 5003, 500, 10);
        participate_on_campaign(owner, 1);
        participate_on_campaign(participant1, 1);
        submit_on_campaign(participant1, 1);

        let campaign_result = get_all_campaign();
        print(&campaign_result);

        submit_on_campaign(owner, 1);

        let p_id_from_addr = get_participant_id_from_address(1, signer::address_of(participant1));
        print(&p_id_from_addr);
        

        // let p_index = get_campaign_participant_index(1);
        // print(&p_index);
        
    }

}