require('dotenv').config()

const HDWalletProvider = require('truffle-hdwallet-provider');
const mnemonic = process.env.PRIVATE_KEY;
const rpcUrl = process.env.RPC_URL;

const mnemonic97 = process.env.PRIVATE_KEY_97;
const rpcUrl97 = process.env.RPC_URL_97;

const mnemonic56 = process.env.PRIVATE_KEY_56;
const rpcUrl56 = process.env.RPC_URL_56;

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */

  networks: {
    development: {
     host: "127.0.0.1",     // Localhost (default: none)
     port: 7545,            // Standard Ethereum port (default: none)
     network_id: "*",       // Any network (default: none)
    },

    ropsten: {
      provider: () => new HDWalletProvider(mnemonic, rpcUrl),
      network_id: 3,       // Ropsten's id
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 1,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },

    bsc: {
      provider: () => new HDWalletProvider(mnemonic56, rpcUrl56),
      gasPrice: '5000000000', 
      network_id: 56,       // Ropsten's id
      gas: 5500000,  
      confirmations: 1,    
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: false     // Skip dry run before migrations? (default: false for public nets )
    },

    bsctestnet: {
      provider: () => new HDWalletProvider(mnemonic97, rpcUrl97),
      gasPrice: '12000000000',
      network_id: 97,       
      gas: 6000000,
      confirmations: 1,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 2000,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets ),
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    timeout: 100000000
  },

  compilers: {
    solc: {
      version: "0.7.4",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}
