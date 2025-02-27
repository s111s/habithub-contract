module movement::Campaign {
    use std::vector;
    use std::string::{String, utf8};
    use std::timestamp;
    use std::signer;

    // Error Code
    const ERR_ADDRESS_NOT_EXIST_IN_PARTICIPANT: u64 = 101;
    const ERR_LOWER_THAN_MINIMUM_DURATION: u64 = 102;
    const ERR_LOWER_THAN_MINIMUM_REWARD_POOL: u64 = 103;
    const ERR_OUT_OF_PARTICIPANT_RANGE: u64 = 104;
    const ERR_INCORRECT_REWARD_SETTING: u64 = 105;
    const ERR_CREATOR_WALLET_DOES_NOT_EXIST: u64 = 106;
    const ERR_INSUFFICIENT_CREATOR_BALANCE: u64 = 107;
    const ERR_INCORRECT_DEPOSIT_AMOUNT: u64 = 108;
    const ERR_ONLY_CAMPAIGN_OWNER: u64 = 109;
    const ERR_CAMPAIGN_DOES_NOT_EXIST: u64 = 110;
    const ERR_CAMPAIGN_IS_NOT_END: u64 = 111;
    const ERR_SOME_SUBMISSIONS_ARE_NOT_VALIDATED: u64 = 112;
    const ERR_CAMPAIGN_HAS_ENDED: u64 = 113;
    const ERR_USER_ALREADY_PARTICIPATED: u64 = 114;
    const ERR_LIMIT_PARTICIPANT_EXISTED: u64 = 115;
    const ERR_ALREADY_SUBMIT: u64 = 116;
    const ERR_SUBMIT_IS_NOT_VALIDATED: u64 = 117;
    const ERR_NOT_PASS_VERIFICATION: u64 = 118;
    const ERR_ALREADY_CLAIMED_REWARD: u64 = 119;
    const ERR_INSUFFICIENT_THIS_CONTRACT_BALANCE: u64 = 120;
    const ERR_INCORRECT_DECREASING_BALANCE: u64 = 121;
    const ERR_CAMPAIGN_IS_ALREADY_CLOSED: u64 = 122;
    const ERR_RECEIVER_WALLET_DOES_NOT_EXIST: u64 = 123;
    const ERR_NOT_VALIDATOR: u64 = 124;
    const ERR_USER_IS_NOT_SUBMITTED: u64 = 125;
    const ERR_ONLY_ADMIN: u64 = 126;
    const ERR_ALREADY_BE_A_VALIDATOR: u64 = 127;
    const ERR_ADDRESS_IS_NOT_VALIDATOR: u64 = 128;
    const ERR_ONLY_PENDING_ADMIN: u64 = 129;

    // Struct
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
        data_type: String,
        data_validation_type: String,
        participants: vector<Participant>,
        participant_id_index: vector<u64>,
        participant_address_index: vector<address>,
        is_closed: bool
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

    struct CreatorRegistry has key, store, copy, drop {
        creators: vector<CreatorStat>,
        creator_id_index: vector<u64>,
        creator_addr_index: vector<address>
    }

    struct CreatorStat has key, store, copy, drop {
        id: u64,
        addr: address,
        total_campaign_created: u64,
        total_reward_paid: u64,
        created_campaign_ids: vector<u64>
    }

    struct UserRegistry has key, store, copy, drop {
        users: vector<UserStat>,
        user_id_index: vector<u64>,
        user_addr_index: vector<address>
    }

    struct UserStat has key, store, copy, drop  {
        id: u64,
        addr: address,
        total_participant: u64,
        total_submitted: u64,
        total_validation_pass: u64,
        total_rewarded: u64,
        participated_campaign_ids: vector<u64>
    }

    struct WalletRegistry has key, store, copy, drop {
        wallets: vector<Wallet>,
        wallet_id_index: vector<u64>,
        wallet_addr_index: vector<address>
    }

    struct Wallet has key, store, copy, drop {
        id: u64,
        addr: address,
        balance: u64
    }

    struct ValidatorRegistry has key, store, copy, drop {
        validators: vector<Validator>,
        validator_id_index: vector<u64>,
        validator_addr_index: vector<address>
    }

    struct Validator has key, store, copy, drop {
        id: u64,
        addr: address,
        rule: String
    }

    struct Config has key, store, copy, drop {
        min_duration: u64,
        min_reward_pool: u64,
        min_total_participant: u64,
        max_total_participant: u64,
        reward_token: address,
        pending_admin: address,
        admin: address
    }

    // Initialization
    fun init_module(owner: &signer) acquires WalletRegistry {
        // Store CampaignRegistry struct
        move_to(owner, CampaignRegistry{
            campaigns: vector::empty<Campaign>()
        });

        // Store CreatorRegistry struct
        move_to(owner, CreatorRegistry{
            creators: vector::empty<CreatorStat>(),
            creator_id_index: vector::empty<u64>(),
            creator_addr_index: vector::empty<address>()
        });

        // Store UserRegistry struct
        move_to(owner, UserRegistry{
            users: vector::empty<UserStat>(),
            user_id_index: vector::empty<u64>(),
            user_addr_index: vector::empty<address>()
        });

        // Store WalletRegistry struct
        move_to(owner, WalletRegistry{
            wallets: vector::empty<Wallet>(),
            wallet_id_index: vector::empty<u64>(),
            wallet_addr_index: vector::empty<address>()
        });

        // Store ValidatorRegistry struct
        move_to(owner, ValidatorRegistry{
            validators: vector::empty<Validator>(),
            validator_id_index: vector::empty<u64>(),
            validator_addr_index: vector::empty<address>()
        });

        // Store Config struct
        move_to(owner, Config{
            min_duration: 0,
            min_reward_pool: 1,
            min_total_participant: 1,
            max_total_participant: 1000000,
            reward_token: @0x00,
            pending_admin: @0x00,
            admin: @movement
        });

        // Create wallet of this addr
        create_wallet_if_not_exist(@movement);
    }

    // View Function

    #[view] // Check contract initialization
    public fun is_initialized(addr: address): bool {
        exists<CampaignRegistry>(addr) && exists<ValidatorRegistry>(addr)
    }

    #[view] // Get all campaign struct data
    public fun get_all_campaign(): vector<Campaign> acquires CampaignRegistry {
        return borrow_global<CampaignRegistry>(@movement).campaigns
    }

    #[view] // Get data from specific campaign
    public fun get_campaign_by_id(campaign_id: u64): Campaign acquires CampaignRegistry {
        let campaigns = get_all_campaign();
        *vector::borrow(&campaigns, campaign_id - 1)
    }

    #[view] // Get all participant in specific campaign
    public fun get_all_participant(campaign_id: u64): vector<Participant> acquires CampaignRegistry {
        let campaign_registry = borrow_global<CampaignRegistry>(@movement);
        let campaign = vector::borrow(&campaign_registry.campaigns, campaign_id - 1);
        campaign.participants
    }

    #[view] // Get participant id from specific campaign by given participant address
    public fun get_participant_id_from_address(campaign_id: u64, addr: address): u64 acquires CampaignRegistry {
        let campaign_registry = borrow_global<CampaignRegistry>(@movement);
        let campaign = vector::borrow(&campaign_registry.campaigns, campaign_id - 1);
        let addr_list = campaign.participant_address_index;
        let (result, index) = vector::index_of(&addr_list, &addr);

        assert!(result, ERR_ADDRESS_NOT_EXIST_IN_PARTICIPANT);
        let id_list = campaign.participant_id_index;

        *vector::borrow(&id_list, index)
    }

    #[view] // Get specific participant in specific campaign by given participant address
    public fun get_participant_by_addr(campaign_id: u64, addr: address): Participant acquires CampaignRegistry {
        let participants = get_all_participant(campaign_id);
        let participant_id = get_participant_id_from_address(campaign_id, addr);
        *vector::borrow(&participants, participant_id - 1)
    }

    #[view] // Get specific participant in specific campaign by given participant address
    public fun get_participant_by_id(campaign_id: u64, participant_id: u64): Participant acquires CampaignRegistry {
        let participants = get_all_participant(campaign_id);
        *vector::borrow(&participants, participant_id - 1)
    }

    #[view] // Get validator list
    public fun get_all_validator(): vector<Validator> acquires ValidatorRegistry {
        return borrow_global<ValidatorRegistry>(@movement).validators
    }

    #[view] // Check address is validator or not
    public fun is_validator(addr: address): bool acquires ValidatorRegistry {
        // Get validator registry struct
        let validator_registry = borrow_global<ValidatorRegistry>(@movement);
        
        // Get validator address list
        let validator_addr_list = validator_registry.validator_addr_index;

        // Get validator index
        let (result, _index) = vector::index_of(&validator_addr_list, &addr);
        result
    }

    #[view] // Get creator list
    public fun get_all_creator(): vector<CreatorStat> acquires CreatorRegistry {
        return borrow_global<CreatorRegistry>(@movement).creators
    }

    #[view] // Get creator data by given addr
    public fun get_creator_by_addr(addr: address): CreatorStat acquires CreatorRegistry {
        let creator_registry = borrow_global<CreatorRegistry>(@movement);
        let creator_addr_list = creator_registry.creator_addr_index;
        let (result, index) = vector::index_of(&creator_addr_list, &addr);
        if (result) {
            *vector::borrow(&creator_registry.creators, index)
        } else {
            CreatorStat {
                id: 0,
                addr: addr,
                total_campaign_created: 0,
                total_reward_paid: 0,
                created_campaign_ids: vector::empty<u64>()
            }
        }
    }

    #[view] // Get user list
    public fun get_all_user(): vector<UserStat> acquires UserRegistry {
        return borrow_global<UserRegistry>(@movement).users
    }

    #[view] // Get user data by given addr
    public fun get_user_by_addr(addr: address): UserStat acquires UserRegistry {
        let user_registry = borrow_global<UserRegistry>(@movement);
        let user_addr_list = user_registry.user_addr_index;
        let (result, index) = vector::index_of(&user_addr_list, &addr);
        if (result) {
            *vector::borrow(&user_registry.users, index)
        } else {
            UserStat {
                id: 0,
                addr: addr,
                total_participant: 0,
                total_submitted: 0,
                total_validation_pass: 0,
                total_rewarded: 0,
                participated_campaign_ids: vector::empty<u64>(),
            }
        }
    }

    #[view] // Get wallet list
    public fun get_all_wallet(): vector<Wallet> acquires WalletRegistry {
        return borrow_global<WalletRegistry>(@movement).wallets
    }

    #[view] // Get wallet data by given addr
    public fun get_wallet_by_addr(addr: address): Wallet acquires WalletRegistry {
        let wallet_registry = borrow_global<WalletRegistry>(@movement);
        let wallet_addr_list = wallet_registry.wallet_addr_index;
        let (result, index) = vector::index_of(&wallet_addr_list, &addr);
        if (result) { 
            *vector::borrow(&wallet_registry.wallets, index)
        } else {
            Wallet {
                id: 0,
                addr: addr,
                balance: 0
            }
        }
    }

    #[view] // Get wallet balance
    public fun balance_of(addr: address): u64 acquires WalletRegistry {
        let wallet = get_wallet_by_addr(addr);
        wallet.balance
    }
        
    // User data function
    
    fun create_user_if_not_exist(addr: address) acquires UserRegistry {
        // Get user registry struct
        let user_registry = borrow_global_mut<UserRegistry>(@movement);
        
        // Count user
        let user_registry_length = vector::length(&user_registry.users);

        // Pre set user id
        let next_user_id = user_registry_length + 1;

        // Craft new user data
        let new_user = UserStat {
            id: next_user_id,
            addr: addr,
            total_participant: 0,
            total_submitted: 0,
            total_validation_pass: 0,
            total_rewarded: 0,
            participated_campaign_ids: vector::empty<u64>(),
        };

        // Get user address list
        let user_addr_list = user_registry.user_addr_index;

        // find given addr in user address list
        let (result, _index) = vector::index_of(&user_addr_list, &addr);

        // Create new user and store index if wallet does not exist
        if (!result) {
            // Store new user data
            vector::push_back(&mut user_registry.users, new_user);

            // Store user address and id - used for mapping
            vector::push_back(&mut user_registry.user_id_index, next_user_id);
            vector::push_back(&mut user_registry.user_addr_index, addr);
        }
    }

    // Creator data function
    
    fun create_creator_if_not_exist(addr: address) acquires CreatorRegistry {
        // Get creator registry struct
        let creator_registry = borrow_global_mut<CreatorRegistry>(@movement);
        
        // Count creator
        let creator_registry_length = vector::length(&creator_registry.creators);

        // Pre set creator id
        let next_creator_id = creator_registry_length + 1;

        // Craft new creator data
        let new_creator = CreatorStat {
            id: next_creator_id,
            addr: addr,
            total_campaign_created: 0,
            total_reward_paid: 0,
            created_campaign_ids: vector::empty<u64>()
        };

        // Get creator address list
        let creator_addr_list = creator_registry.creator_addr_index;

        // find given addr in creator address list
        let (result, _index) = vector::index_of(&creator_addr_list, &addr);

        // Create new user and store index if wallet does not exist
        if (!result) {
            // Store new user data
            vector::push_back(&mut creator_registry.creators, new_creator);

            // Store user address and id - used for mapping
            vector::push_back(&mut creator_registry.creator_id_index, next_creator_id);
            vector::push_back(&mut creator_registry.creator_addr_index, addr);
        }
    }

    // Wallet Function

    // Faucet for testnet only
    public entry fun faucet(wallet: &signer) acquires WalletRegistry {
        let wallet_addr = signer::address_of(wallet);
        create_wallet_if_not_exist(wallet_addr);
        
        let wallet_registry = borrow_global_mut<WalletRegistry>(@movement);
        
        // Get wallet address list
        let wallet_addr_list = wallet_registry.wallet_addr_index;

        // find given addr in wallet list
        let (_result, index) = vector::index_of(&wallet_addr_list, &wallet_addr);

        let wallet = vector::borrow_mut(&mut wallet_registry.wallets, index);

        wallet.balance = wallet.balance + 1000000000;
    }

    // Create wallet - Internal use only
    fun create_wallet_if_not_exist(addr: address) acquires WalletRegistry {
        // Get wallet registry struct
        let wallet_registry = borrow_global_mut<WalletRegistry>(@movement);
        
        // Count wallet
        let wallet_registry_length = vector::length(&wallet_registry.wallets);

        // Pre set campaign id
        let next_wallet_id = wallet_registry_length + 1;

        // Craft new wallet data
        let new_wallet = Wallet {
            id: next_wallet_id,
            addr: addr,
            balance: 0
        };

        // Get wallet address list
        let wallet_addr_list = wallet_registry.wallet_addr_index;

        // find given addr in wallet list
        let (result, _index) = vector::index_of(&wallet_addr_list, &addr);

        // Create new wallet and store index if wallet does not exist
        if (!result) {
            // Store new wallet data
            vector::push_back(&mut wallet_registry.wallets, new_wallet);

            // Store wallet address and id - used for mapping
            vector::push_back(&mut wallet_registry.wallet_id_index, next_wallet_id);
            vector::push_back(&mut wallet_registry.wallet_addr_index, addr);
        }
    }

    // Campaign Creator Function

    // Create campaign and stake reward pool
    public entry fun create_campaign(sender: &signer, campaign_name: String, duration: u64, reward_pool: u64, reward_per_submit: u64, max_participant: u64, data_type: String, data_validation_type: String) acquires Config, CampaignRegistry, WalletRegistry, CreatorRegistry {
        // Get creator address
        let creator_addr = signer::address_of(sender);
        // Get config data
        let config = borrow_global<Config>(@movement);
        // Verify campaign duration
        assert!(duration >= config.min_duration, ERR_LOWER_THAN_MINIMUM_DURATION);

        // Verify minimum reward pool
        assert!(reward_pool >= config.min_reward_pool, ERR_LOWER_THAN_MINIMUM_REWARD_POOL);

        // Verify minimum and maximum of max_participant
        assert!(max_participant >= config.min_total_participant && max_participant <= config.max_total_participant, ERR_OUT_OF_PARTICIPANT_RANGE);

        // Verify reward is enough for every participant
        assert!(reward_per_submit * max_participant <= reward_pool, ERR_INCORRECT_REWARD_SETTING);

        // Get campaign registry struct
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);
        
        // Count campaign
        let campaign_registry_length = vector::length(&campaign_registry.campaigns);

        // Get current time in seconds
        let now = timestamp::now_seconds();
        
        // Pre set campaign id
        let next_campaign_id = campaign_registry_length + 1;

        // Craft new Campaign data
        let new_campaign = Campaign {
            campaign_id: next_campaign_id,
            name: campaign_name,
            creator: creator_addr,
            start_time: now,
            end_time: now + duration,
            reward_pool: reward_pool,
            reward_per_submit: reward_per_submit,
            current_participant: 0,
            max_participant: max_participant,
            data_type: data_type,
            data_validation_type: data_validation_type,
            participants: vector::empty<Participant>(),
            participant_id_index: vector::empty<u64>(),
            participant_address_index: vector::empty<address>(),
            is_closed: false
        };

        // Store crafted campaign data in the last member of CampaignRegistry vector
        vector::push_back(&mut campaign_registry.campaigns, new_campaign);

        // Get walletdata
        let wallet_registry = borrow_global_mut<WalletRegistry>(@movement);
        let wallet_addr_list = wallet_registry.wallet_addr_index;

        // Get creator wallet index and data
        let (creator_result, creator_index) = vector::index_of(&wallet_addr_list, &creator_addr);
        let creator_wallet = vector::borrow_mut(&mut wallet_registry.wallets, creator_index);
        // Verify creator wallet is exits
        assert!(creator_result, ERR_CREATOR_WALLET_DOES_NOT_EXIST);
        // Verify creator balance
        assert!(creator_wallet.balance >= reward_pool, ERR_INSUFFICIENT_CREATOR_BALANCE);
        // Decrease creator balance
        creator_wallet.balance = creator_wallet.balance - reward_pool;

        // Get this contract wallet
        let this_addr = @movement;
        let (_this_result, this_index) = vector::index_of(&wallet_addr_list, &this_addr);
        let this_wallet = vector::borrow_mut(&mut wallet_registry.wallets, this_index);
        
        // get this contract balance before deposit
        let this_balance_before = this_wallet.balance;

        // Increase this contract balance
        this_wallet.balance = this_wallet.balance + reward_pool;

        // Verify reward is already deposit
        assert!(this_balance_before + reward_pool == this_wallet.balance, ERR_INCORRECT_DEPOSIT_AMOUNT);

        // Create creator if not exist
        create_creator_if_not_exist(creator_addr);

        // Get creator data
        let creator_registry = borrow_global_mut<CreatorRegistry>(@movement);
        let creator_addr_list = creator_registry.creator_addr_index;
        let (_result, index) = vector::index_of(&creator_addr_list, &creator_addr);
        let creator = vector::borrow_mut(&mut creator_registry.creators, index);

        // Update total campaign created
        creator.total_campaign_created = creator.total_campaign_created + 1;
        // Add created campaign id in created list
        vector::push_back(&mut creator.created_campaign_ids, next_campaign_id);
    }

    // Withdraw reward left after campaign is end for creator
    public entry fun close_campaign_and_withdraw_stake_reward_left(sender: &signer, campaign_id: u64) acquires CampaignRegistry, WalletRegistry {
        // Get address of signer (participant)
        let sender_addr = signer::address_of(sender);

        // Get campaign registry struct
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);

        // Count campaign
        let campaign_registry_length = vector::length(&campaign_registry.campaigns);
        // Verify campaign id is existed
        assert!(campaign_id > 0 && campaign_id <= campaign_registry_length, ERR_CAMPAIGN_DOES_NOT_EXIST);

        // Get campaign data
        let campaign = vector::borrow_mut(&mut campaign_registry.campaigns, campaign_id - 1);

        // Verify withdrawer is owner of the campaign
        assert!(sender_addr == campaign.creator, ERR_ONLY_CAMPAIGN_OWNER);

        // Get current time in seconds
        let now = timestamp::now_seconds();
        // Verify campaign is end
        assert!(now >= campaign.end_time, ERR_CAMPAIGN_IS_NOT_END);

        // Count participant data
        let participant_count = vector::length(&campaign.participants);
        let submit_count = 0;
        let verified_count = 0;
        let verification_pass_count = 0;
        let is_claimed_reward_count = 0;
        let i = 1;

        // Loop for counting reward info
        while (i <= participant_count) {
            let participant = vector::borrow(&campaign.participants, i - 1);
            if (participant.is_submitted == true) {
                submit_count = submit_count + 1;
            };
            if (participant.is_validated == true) {
                verified_count = verified_count + 1;
            };
            if (participant.is_validation_pass == true) {
                verification_pass_count = verification_pass_count + 1;
            };
            if (participant.is_claimed_reward == true) {
                is_claimed_reward_count = is_claimed_reward_count + 1;
            };
            i = i + 1;
        };
        
        // Verify all submission is already validate
        assert!(submit_count == verified_count, ERR_SOME_SUBMISSIONS_ARE_NOT_VALIDATED);

        // Calculate total reward left of the campaign
        let reward_left = campaign.reward_per_submit * (campaign.max_participant - verification_pass_count);

        // Get walletdata
        let wallet_registry = borrow_global_mut<WalletRegistry>(@movement);
        let wallet_addr_list = wallet_registry.wallet_addr_index;

        // Get creator wallet index and data
        let (_creator_result, creator_index) = vector::index_of(&wallet_addr_list, &sender_addr);
        let creator_wallet = vector::borrow_mut(&mut wallet_registry.wallets, creator_index);
        
        // Increase creator balance
        creator_wallet.balance = creator_wallet.balance + reward_left;

        // Get this contract wallet
        let this_addr = @movement;
        let (_this_result, this_index) = vector::index_of(&wallet_addr_list, &this_addr);
        let this_wallet = vector::borrow_mut(&mut wallet_registry.wallets, this_index);
        
        // get this contract balance before deposit
        let this_balance_before = this_wallet.balance;

        // Verify this contract balance
        assert!(this_wallet.balance >= reward_left, ERR_INSUFFICIENT_THIS_CONTRACT_BALANCE);
        // Decrease this contract balance
        this_wallet.balance = this_wallet.balance - reward_left;
        // Verify this wallet balance was decrease correctly
        assert!(this_balance_before - reward_left == this_wallet.balance, ERR_INCORRECT_DECREASING_BALANCE);

        // Verify the campaign is not closed
        assert!(!campaign.is_closed, ERR_CAMPAIGN_IS_ALREADY_CLOSED);
        campaign.is_closed = true;
    }

    // User Function

    // Participate in the campaign
    public entry fun participate_on_campaign(sender: &signer, campaign_id: u64) acquires CampaignRegistry, UserRegistry {
        // Get address of signer (participant)
        let sender_addr = signer::address_of(sender);

        // Get campaign registry struct
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);

        // Count campaign
        let campaign_registry_length = vector::length(&campaign_registry.campaigns);
        // Verify campaign id is existed
        assert!(campaign_id > 0 && campaign_id <= campaign_registry_length, ERR_CAMPAIGN_DOES_NOT_EXIST);

        // Get specific campaign
        let campaign = vector::borrow_mut(&mut campaign_registry.campaigns, campaign_id - 1);
        
        // Get current time in seconds
        let now = timestamp::now_seconds();
        // Verify campaign is not ended
        assert!(now < campaign.end_time, ERR_CAMPAIGN_HAS_ENDED);
        
        // Get participant list
        let participant_list = campaign.participant_address_index;
        // Find index of participant
        let (result, _index) = vector::index_of(&participant_list, &sender_addr);
        // Verify user is not participated
        assert!(!result, ERR_USER_ALREADY_PARTICIPATED);

        // Verify participant is not full
        assert!(campaign.current_participant < campaign.max_participant, ERR_LIMIT_PARTICIPANT_EXISTED);

        // Increase current participant & pre set participant id 
        campaign.current_participant = campaign.current_participant + 1;

        // Craft new Participant data
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

        // Store crafted campaign data in the last member of CampaignRegistry vector
        vector::push_back(&mut campaign.participants, new_participant);

        // Store participant address and participant id - used for mapping
        vector::push_back(&mut campaign.participant_id_index, campaign.current_participant);
        vector::push_back(&mut campaign.participant_address_index, sender_addr);

        // Create user if not exist
        create_user_if_not_exist(sender_addr);

        // Get user data
        let user_registry = borrow_global_mut<UserRegistry>(@movement);
        let user_addr_list = user_registry.user_addr_index;
        let (_result, index) = vector::index_of(&user_addr_list, &signer::address_of(sender));
        let user = vector::borrow_mut(&mut user_registry.users, index);

        // Update total participant
        user.total_participant = user.total_participant + 1;
        // Add participated campaign id in participated list
        vector::push_back(&mut user.participated_campaign_ids, campaign_id);
    }

    // Submit data on the campaign
    public entry fun submit_on_campaign(sender: &signer, campaign_id: u64, submit_hash: String) acquires CampaignRegistry, UserRegistry {
        // Get address of signer (participant)
        let sender_addr = signer::address_of(sender);

        // Get campaign registry struct
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);
        // Get specific campaign
        let campaign = vector::borrow_mut(&mut campaign_registry.campaigns, campaign_id - 1);

        // Get current time in seconds
        let now = timestamp::now_seconds();

        // Verify campaign is not ended
        assert!(now < campaign.end_time, ERR_CAMPAIGN_HAS_ENDED);

        // Get participant list
        let participant_list = campaign.participant_address_index;
        // Find index of participant
        let (result, index) = vector::index_of(&participant_list, &sender_addr);
        // Verify user is already participate
        assert!(result, ERR_ADDRESS_NOT_EXIST_IN_PARTICIPANT);

        // Get participant id list
        let id_list = campaign.participant_id_index;
        // Get id of participant
        let participant_id = *vector::borrow(&id_list, index);
        // Get participant data
        let participant_info = vector::borrow_mut(&mut campaign.participants, participant_id - 1);
        
        // Verify user is not submitted
        assert!(participant_info.is_submitted == false, ERR_ALREADY_SUBMIT);

        // Craft submit hash - used to verify stored data
        let new_submit_hash = submit_hash;

        // Store submit hash in participant data and change submit status to true
        participant_info.submit_hash = new_submit_hash;
        participant_info.is_submitted = true;

        // Get user data
        let user_registry = borrow_global_mut<UserRegistry>(@movement);
        let user_addr_list = user_registry.user_addr_index;
        let (_result, index) = vector::index_of(&user_addr_list, &sender_addr);
        let user = vector::borrow_mut(&mut user_registry.users, index);

        // Update total submitted
        user.total_submitted = user.total_submitted + 1;
    }

    // Claim reward
    public entry fun claim_reward(receiver: &signer, campaign_id: u64) acquires CampaignRegistry, WalletRegistry, UserRegistry, CreatorRegistry {
        // Get receiver address
        let receiver_addr = signer::address_of(receiver);
        // Get campaign registry struct
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);
        // Get campaign data
        let campaign = vector::borrow_mut(&mut campaign_registry.campaigns, campaign_id - 1);

        // Verify user is in participant list
        // assert!(result, ERR_ADDRESS_NOT_EXIST_IN_PARTICIPANT);
        
        let addr_list = campaign.participant_address_index;

        let (_result, index) = vector::index_of(&addr_list, &receiver_addr);
        let id_list = campaign.participant_id_index;

        let participant_id = *vector::borrow_mut(&mut id_list, index);

        // Get participant data from specific id
        let participant_info = vector::borrow_mut(&mut campaign.participants, participant_id - 1);

        // Verify submitted data is validated and pass the verification
        assert!(participant_info.is_validated == true, ERR_SUBMIT_IS_NOT_VALIDATED);
        assert!(participant_info.is_validation_pass == true, ERR_NOT_PASS_VERIFICATION);

        // Verify user is not claimed 
        assert!(!participant_info.is_claimed_reward, ERR_ALREADY_CLAIMED_REWARD);

        // Create wallet if not exist
        create_wallet_if_not_exist(receiver_addr);

        // Get walletdata
        let wallet_registry = borrow_global_mut<WalletRegistry>(@movement);
        let wallet_addr_list = wallet_registry.wallet_addr_index;

        // Get this contract wallet
        let this_addr = @movement;
        let (_this_result, this_index) = vector::index_of(&wallet_addr_list, &this_addr);
        let this_wallet = vector::borrow_mut(&mut wallet_registry.wallets, this_index);
        
        // get this contract balance before deposit
        let this_balance_before = this_wallet.balance;

        // Verify this contract balance
        assert!(this_wallet.balance >= campaign.reward_per_submit, ERR_INSUFFICIENT_THIS_CONTRACT_BALANCE);
        // Decrease this contract balance
        this_wallet.balance = this_wallet.balance - campaign.reward_per_submit;
        // Verify this wallet balance was decrease correctly
        assert!(this_balance_before - campaign.reward_per_submit == this_wallet.balance, ERR_INCORRECT_DECREASING_BALANCE);

        // Get creator wallet index and data
        let (receiver_result, receiver_index) = vector::index_of(&wallet_addr_list, &receiver_addr);
        // Verify creator wallet is exits
        assert!(receiver_result, ERR_RECEIVER_WALLET_DOES_NOT_EXIST);
        // Get receiver wallet data
        let receiver_wallet = vector::borrow_mut(&mut wallet_registry.wallets, receiver_index);

        // Increase receiver balance
        receiver_wallet.balance = receiver_wallet.balance + campaign.reward_per_submit;
        
        // Change validate status to true
        participant_info.is_claimed_reward = true;

        // Get user data
        let user_registry = borrow_global_mut<UserRegistry>(@movement);
        let user_addr_list = user_registry.user_addr_index;
        let (_result, index) = vector::index_of(&user_addr_list, &receiver_addr);
        let user = vector::borrow_mut(&mut user_registry.users, index);

        // Update total rewarded
        user.total_rewarded = user.total_rewarded + campaign.reward_per_submit;

        // Get creator data
        let creator_registry = borrow_global_mut<CreatorRegistry>(@movement);
        let creator_addr_list = creator_registry.creator_addr_index;
        let (_result, index) = vector::index_of(&creator_addr_list, &campaign.creator);
        let creator = vector::borrow_mut(&mut creator_registry.creators, index);

        // Update total campaign created
        creator.total_reward_paid = creator.total_reward_paid + campaign.reward_per_submit;
    }

    // Validator Function

    // Validate participant submitted data
    public entry fun validate_data(validator: &signer, campaign_id: u64, submit_id: u64, is_pass: bool) acquires CampaignRegistry, ValidatorRegistry, UserRegistry {
        // Get address of signer (validator)
        let validator_addr = signer::address_of(validator);
        // Verify signer is validator
        assert!(is_validator(validator_addr), ERR_NOT_VALIDATOR);

        // Get campaign registry struct
        let campaign_registry = borrow_global_mut<CampaignRegistry>(@movement);
        // Get campaign data
        let campaign = vector::borrow_mut(&mut campaign_registry.campaigns, campaign_id - 1);

        // Get id list of participant
        let id_list = campaign.participant_id_index;
        // Get id of specific participant
        let participant_id = *vector::borrow(&id_list, submit_id - 1);
        // Get participant data from specific id
        let participant_info = vector::borrow_mut(&mut campaign.participants, participant_id - 1);

        // Verify user is already submitted
        assert!(participant_info.is_submitted == true, ERR_USER_IS_NOT_SUBMITTED);

        // Change validate status to true
        participant_info.is_validated = true;
        // Change validation status
        participant_info.is_validation_pass = is_pass;

        // Get user data
        let user_registry = borrow_global_mut<UserRegistry>(@movement);
        let user_addr_list = user_registry.user_addr_index;
        let (_result, index) = vector::index_of(&user_addr_list, &participant_info.participant_address);
        let user = vector::borrow_mut(&mut user_registry.users, index);

        // Update total validation if it pass
        if (is_pass) {
            user.total_validation_pass = user.total_validation_pass + 1;
        }
    }

    // Admin Function

    // Add validator
    public entry fun add_validator(sender: &signer, validator_addr: address, rule: String) acquires ValidatorRegistry, Config {
        // Get admin addr
        let admin = borrow_global_mut<Config>(@movement).admin;
        let sender_addr = signer::address_of(sender);

        // Verify signer is admin
        assert!(sender_addr == admin, ERR_ONLY_ADMIN);

        // Get validator registry struct
        let validator_registry = borrow_global_mut<ValidatorRegistry>(@movement);
        // Get validator list
        let validators = validator_registry.validators;
        // Count validator
        let validator_length = vector::length(&validators);

        // Pre set validator id
        let next_validator_id = validator_length + 1;

        // Craft validator data
        let new_validator = Validator {
            id: next_validator_id,
            addr: validator_addr,
            rule: rule
        };

        // Get validator address list
        let validator_addr_list = validator_registry.validator_addr_index;

        // find given addr in wallet list
        let (result, _index) = vector::index_of(&validator_addr_list, &validator_addr);

        assert!(!result, ERR_ALREADY_BE_A_VALIDATOR);
        
        // Store crafted validator data
        vector::push_back(&mut validator_registry.validators, new_validator);

        // Store validator index
        vector::push_back(&mut validator_registry.validator_id_index, next_validator_id);
        vector::push_back(&mut validator_registry.validator_addr_index, validator_addr);
    }

    public entry fun remove_validator(sender: &signer, validator_addr: address) acquires ValidatorRegistry, Config {
        // Get admin addr
        let admin = borrow_global_mut<Config>(@movement).admin;
        let sender_addr = signer::address_of(sender);

        // Verify signer is admin
        assert!(sender_addr == admin, ERR_ONLY_ADMIN);

        // Get validator registry struct
        let validator_registry = borrow_global_mut<ValidatorRegistry>(@movement);
        
        // Get validator address list
        let validator_addr_list = validator_registry.validator_addr_index;

        // Get validator index
        let (result, index) = vector::index_of(&validator_addr_list, &validator_addr);
        // Verify given address is validator
        assert!(result, ERR_ADDRESS_IS_NOT_VALIDATOR);
        
        // Store crafted validator data
        vector::remove(&mut validator_registry.validators, index);
    }

    // Update config
    public entry fun update_config(sender: &signer, min_duration: u64, min_reward_pool: u64, min_total_participant: u64, max_total_participant: u64, reward_token: address) acquires Config {
        // Get address of signer (admin)
        let signer_addr = signer::address_of(sender);

        // Get config data
        let config = borrow_global_mut<Config>(@movement);

        // Verify signer is admin
        assert!(signer_addr == config.admin, ERR_ONLY_ADMIN);

        // Update config data
        config.min_duration = min_duration;
        config.min_reward_pool = min_reward_pool;
        config.min_reward_pool = min_reward_pool;
        config.min_total_participant = min_total_participant;
        config.max_total_participant = max_total_participant;
        config.reward_token = reward_token;
    }

    // Transfer admin
    public entry fun transfer_admin(sender: &signer, pending_admin: address) acquires Config {
        // Get address of signer (admin)
        let signer_addr = signer::address_of(sender);

        // Get config data
        let config = borrow_global_mut<Config>(@movement);

        // Verify signer is admin
        assert!(signer_addr == config.admin, ERR_ONLY_ADMIN);

        // Update pending admin address
        config.pending_admin = pending_admin;
    }

    // Claim admin
    public entry fun claim_admin(sender: &signer) acquires Config {
        // Get address of signer (admin)
        let signer_addr = signer::address_of(sender);

        // Get config data
        let config = borrow_global_mut<Config>(@movement);

        // Verify signer is pending admin
        assert!(signer_addr == config.pending_admin, ERR_ONLY_PENDING_ADMIN);

        // Set new admin address and reset pending admin
        config.admin = signer_addr;
        config.pending_admin = @0x00;
    }

    #[test_only]
    public fun init_for_test(movement_tester: &signer) acquires WalletRegistry {
        init_module(movement_tester);
    }
}