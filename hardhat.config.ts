import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ignition-ethers";
import "@openzeppelin/hardhat-upgrades";

import { vars } from "hardhat/config";
const DEPLOY_PRI_KEY = vars.get("DEPLOY_PRI_KEY");
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings:{
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    ethereum: {
      url:`https://base.llamarpc.com`,
      accounts: [DEPLOY_PRI_KEY],
    }
  }
};

export default config;
