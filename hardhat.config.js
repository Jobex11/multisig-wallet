require("@nomiclabs/hardhat-etherscan");

module.exports = {
  solidity: "0.8.0",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/<YOUR_INFURA_PROJECT_ID>`,
      accounts: [`0x${YOUR_PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: "<YOUR_ETHERSCAN_API_KEY>", // Replace with your Etherscan API Key
  },
};

/* 1st trial


require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.0",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/<YOUR_INFURA_PROJECT_ID>`,
      accounts: [`0x${YOUR_PRIVATE_KEY}`],
    },
  },
};
*/

/* set code


require("@nomicfoundation/hardhat-toolbox");
module.exports = {
  solidity: "0.8.24",
};

*/
