#[test_only]
module movement::Campaign_tests {
    use std::signer;
    use movement::Campaign;
    use std::string::utf8;
    use std::timestamp;
    use std::debug::print;

    #[test(owner = @movement, init_addr = @0x1, creator1 = @0x168, participant1 = @0x101, validator1 = @0x999)]
    fun happy_case_test(owner: &signer, init_addr: signer, creator1: &signer, participant1: &signer, validator1: &signer) {
        timestamp::set_time_has_started_for_testing(&init_addr);
        Campaign::init_for_test(owner);
        Campaign::faucet(creator1);
        Campaign::create_campaign(creator1, utf8(b"Campaign Name 1 Naja"), 90000, 5000, 500, 10, utf8(b"Image"), utf8(b"Shopping Receipt"));
        Campaign::create_campaign(creator1, utf8(b"Campaign Name 2 Naja"), 90000, 4000, 400, 10, utf8(b"Image"), utf8(b"Shopping Receipt"));
        Campaign::create_campaign(creator1, utf8(b"Campaign Name 3 Naja"), 90000, 3000, 300, 10, utf8(b"Image"), utf8(b"Shopping Receipt"));
        Campaign::participate_on_campaign(owner, 1);
        Campaign::participate_on_campaign(participant1, 1);
        Campaign::submit_on_campaign(participant1, 1, utf8(b"Test submit hash by participant1"));
        Campaign::add_validator(owner, signer::address_of(validator1), utf8(b"ANY"));
        Campaign::validate_data(validator1, 1, 2, true);
        Campaign::claim_reward(participant1, 1);

        let campaign_result = Campaign::get_all_campaign();
        print(&campaign_result);

        Campaign::submit_on_campaign(owner, 1, utf8(b"Test submit hash by owner"));

        let p_id_from_addr = Campaign::get_participant_id_from_address(1, signer::address_of(participant1));
        print(&p_id_from_addr);
        
        let all_validator_result = Campaign::get_all_validator();
        print(&all_validator_result);

        let is_validator = Campaign::is_validator(signer::address_of(validator1));
        print(&is_validator);

        let is_validator2 = Campaign::is_validator(signer::address_of(owner));
        print(&is_validator2);
        
        let campaign_1_info = Campaign::get_campaign_by_id(1);
        print(&campaign_1_info);

        print(&utf8(b"ggggggg ptcp"));
        let ptcp111 = Campaign::get_participant_by_addr(1, signer::address_of(participant1));
        print(&ptcp111);

        let ptcp222 = Campaign::get_participant_by_id(1, 2);
        print(&ptcp222);

        print(&utf8(b"Creator Bal"));
        let cbl = Campaign::get_wallet_by_addr(signer::address_of(creator1));
        print(&cbl);
        
        print(&utf8(b"Wallet bal"));
        let tbl = Campaign::get_wallet_by_addr(signer::address_of(owner));
        print(&tbl);

        print(&utf8(b"Participant bal"));
        let pbl = Campaign::get_wallet_by_addr(signer::address_of(participant1));
        print(&pbl);

        print(&utf8(b"Get Creator"));
        let cat = Campaign::get_creator_by_addr(signer::address_of(creator1));
        print(&cat);
        // create_wallet_if_not_exist(signer::address_of(participant1));
        // create_wallet_if_not_exist(signer::address_of(owner));
        // let aw = get_all_wallet();
        // print(&aw);

        print(&utf8(b"Get Creator c1"));
        let uc1 = Campaign::get_user_by_addr(signer::address_of(creator1));
        print(&uc1);

        print(&utf8(b"Get User P1"));
        let up1 = Campaign::get_user_by_addr(signer::address_of(participant1));
        print(&up1);
    }

}