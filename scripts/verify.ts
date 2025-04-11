import hre, { ethers } from "hardhat";

async function main() {
    const contractAddress = "0xCFF56157CBf7f96d68897d89309F407C58b0faBd";

    const name = "AIMM";
    const symbol = "AIMM";
    const decimals = 2;
    const totalSupply = ethers.parseUnits("1000000000", 2);
    const newIssue = true;
    const tokenAddress = ethers.ZeroAddress;

    try {
        await hre.run("verify:verify", {
            address: contractAddress,
            constructorArguments: [
                name,
                symbol,
                decimals,
                totalSupply,
                newIssue,
                tokenAddress
            ],
        });
        console.log("Contract verified successfully");
    } catch (error) {
        console.error("Verification failed:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });