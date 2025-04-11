Add your secrets.json file

``` json
{
    "mnemonic": "<MNEMONIC>",
    "bscscanApiKey": "<API_KEY>"
}
```

``` bash
npx hardhat run scripts/deploy.ts --network bsc

npx hardhat run scripts/verify.ts --network bsc
```