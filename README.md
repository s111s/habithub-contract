# Habithub Smart Contract  

## Overview  
Habithub is a decentralized platform that enables campaign creators to request specific data from users while ensuring secure and automated data validation using AI. Built on the **Aptos blockchain** via the **Movement network**, Habithub leverages smart contracts to guarantee fair and transparent data collection and reward distribution.  

## Key Features  

### 🎯 **Campaign Creation & Management** (For Creators)  
- **Create a Campaign**:  
  ```move
  public entry fun create_campaign(sender: &signer, campaign_name: String, duration: u64, reward_pool: u64, reward_per_submit: u64, max_participant: u64, data_type: String, data_validation_type: String)
  ```  
  - Initiates a new campaign with a reward pool, participant limits, and data validation rules.  

- **Close Campaign & Withdraw Remaining Stake**:  
  ```move
  public entry fun close_campaign_and_withdraw_stake_reward_left(sender: &signer, campaign_id: u64)
  ```  
  - Ends a campaign and allows the creator to withdraw any unallocated rewards.  

### 👥 **User Participation & Rewards**  
- **Join a Campaign**:  
  ```move
  public entry fun participate_on_campaign(sender: &signer, campaign_id: u64)
  ```  
  - Users enroll in a campaign to submit required data.  

- **Submit Data for Verification**:  
  ```move
  public entry fun submit_on_campaign(sender: &signer, campaign_id: u64, submit_hash: String)
  ```  
  - Users submit data (hashed for privacy) for validation.  

- **Claim Rewards**:  
  ```move
  public entry fun claim_reward(receiver: &signer, campaign_id: u64)
  ```  
  - Users receive rewards once their data passes AI validation.  

### 🤖 **AI-Powered Data Validation**  
- **Validate Submitted Data**:  
  ```move
  public entry fun validate_data(validator: &signer, campaign_id: u64, submit_id: u64, is_pass: bool)
  ```  
  - AI validators check if submitted data meets campaign criteria.  

### 🔧 **Administrative Controls**  
- **Manage Validators**:  
  - Add a validator:  
    ```move
    public entry fun add_validator(sender: &signer, validator_addr: address, rule: String)
    ```  
  - Remove a validator:  
    ```move
    public entry fun remove_validator(sender: &signer, validator_addr: address)
    ```  

- **Update Campaign Configuration**:  
  ```move
  public entry fun update_config(sender: &signer, min_duration: u64, min_reward_pool: u64, min_total_participant: u64, max_total_participant: u64, reward_token: address)
  ```  
  - Adjusts campaign rules such as duration, reward pool, and participant limits.  

- **Admin Role Transfer**:  
  - Initiate admin transfer:  
    ```move
    public entry fun transfer_admin(sender: &signer, pending_admin: address)
    ```  
  - Claim admin rights:  
    ```move
    public entry fun claim_admin(sender: &signer)
    ```  

## Prerequisites 

Before getting started, ensure you have the following installed:  

- [Movement CLI](https://github.com/movementlabs/movement)  

## Setup Instructions  

### 1. Initialize Movement CLI  

Run the following command to initialize the Movement CLI:  
```
$ movement init
```

Select a network. For testing on the testnet, use a custom network and configure it manually:  

- **REST Endpoint:** `https://aptos.testnet.porto.movementlabs.xyz/v1`  
- **Faucet Endpoint:** `https://fund.testnet.porto.movementlabs.xyz/`  

Set up your account by either providing an existing private key or creating a new one (leave it empty to generate a new key).  

### 2. Initialize a Movement Project  

Use the command below to initialize a new Movement project:  
```
$ movement move init --name <PROJECT_NAME>
```

For example:
```
$ movement move init --name Campaign
```

### 3. Configure the Account  

Copy the generated account address from `config.yaml`. Add it under the `[addresses]` section in `Move.toml`:  
```
[addresses] movement = "<YOUR_ACCOUNT_ADDRESS>"
```


### 4. Copy Contract Files  

Copy the contract files from the `sources/` directory of this repository into your project's `sources/` directory.  

### 5. Compile the Smart Contract  

Run the following command to compile the contract:  
```
$ movement move compile
```


### 6. Run Tests  

Execute the test suite using:  
```
$ movement move test
```


### 7. Deploy to a Custom Network  

Publish the contract on your selected network with:  
```
$ movement move publish
```
