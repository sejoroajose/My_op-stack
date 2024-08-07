const { solidity } = require('ethereum-waffle');
const { network } = require('hardhat');

require('@nomiclabs/hardhat-waffle');
require('dotenv').config();

module.exports = {
    solidity: '0.8.15',
    networks: {
        optimismSepolia: {
            url: process.env.OPTIMISM_SEPOLIA_RPC_URL,
            accounts: [process.env.PRIVATE_KEY],
        },
    },
};