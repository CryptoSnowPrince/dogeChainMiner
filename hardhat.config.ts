import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
    ]
  },
  defaultNetwork: "hardhat",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545"
    },
    hardhat: {
      forking: {
        url: process.env.BSCTESTNET_URL || "",
      },
      accounts: {
        mnemonic: process.env.MNEMONIC,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 40,
        passphrase: "",
      },
    },
    doge_test: {
      url: process.env.DOGE_TEST_URL || "",
      accounts:
        process.env.PK !== undefined ? [process.env.PK] : [],
    },
    doge: {
      url: process.env.DOGE_URL || "",
      accounts:
        process.env.PK !== undefined ? [process.env.PK] : [],
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  mocha: {
    timeout: 100000000
  },
};

export default config;
