require("@nomicfoundation/hardhat-toolbox");
require("./tasks/index.js");

module.exports = {
  solidity: "0.8.26",
  networks: {
    hardhat: {
      chainId: 31337,
    },
  },
};
