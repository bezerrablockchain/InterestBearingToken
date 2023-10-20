## InterestBearingToken

**InterestBearingToken is a token that incentivates users to hold it, as longest time users hold bigger are the rewards.**

The highlights are:

-   **Users can hold/transfer/burn**: All ERC20 standard +burn functions are kept, and user´s actual balance is used to calculate the rewards.
-   **Configurable APY**: Admin can set APY as many times as is necessary.
-   **Vault Contract**: This solution was crafted to not need the presence of admin all the time, its just necessary the vault has some balance to pay the rewards.
-   **Redeable Rewards**: Users can check and withdraw their rewards any time, and automatically this addition to balance starts to get rewards too.
-   **Foundry**: Foundry was used as framework to craft and build the smartcontracts.
-   **Unit tests**: A good number of unit tests for different use-cases.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```