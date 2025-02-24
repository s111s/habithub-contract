# Habithub Smart Contract  

## Prerequisites  

Before getting started, ensure you have the following installed:  

- [Movement CLI](https://github.com/movementlabs/movement)  

## Setup Instructions  

### 1. Initialize Movement CLI  

Run the following command to initialize the Movement CLI:  
```
movement init
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
