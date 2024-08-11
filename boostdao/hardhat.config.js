require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('dotenv').config();

module.exports = {
    solidity: "0.8.20",
    networks: {
        optimismSepolia: {
            url: 'https://opt-sepolia.g.alchemy.com/v2/zW4qCrEs9oi0EQAZsh4JQ8AGp3U20IRi',
            accounts: ['4c55353cdaf0f0453e9eb04e77d45f013070eb7a814f4bf1e08cf28c8fb88ee5']
        }
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY
    }
};
