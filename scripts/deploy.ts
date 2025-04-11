import { ethers } from "hardhat";
import { mnemonic } from "../secrets.json";

async function main() {
    const deployer = ethers.Wallet.fromPhrase(mnemonic);

    console.log("Deploying contracts with the account:", deployer.address);

    const AgentDelegator = await ethers.getContractFactory("AgentDelegator");

    const name = "AIMM";
    const symbol = "AIMM";
    const decimals = 2;
    const totalSupply = ethers.parseUnits("1000000000", 2);
    const newIssue = true;
    const tokenAddress = ethers.ZeroAddress;

    const agentDelegator = await AgentDelegator.deploy(name, symbol, decimals, totalSupply, newIssue, tokenAddress);

    await agentDelegator.deploymentTransaction()?.wait();

    console.log("AgentDelegator deployed to:", await agentDelegator.getAddress());

    const tokenContractAddress = await agentDelegator.tokenAddress();
    console.log("TokenContract deployed to:", tokenContractAddress);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });