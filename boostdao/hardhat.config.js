require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('dotenv').config();

module.exports = {
    solidity: "0.8.20",
    networks: {
        optimismSepolia: {
            url: process.env.OPTIMISM_SEPOLIA_URL,
            accounts: [process.env.PRIVATE_KEY]
        }
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY
    }
};
