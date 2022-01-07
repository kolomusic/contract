
var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "input leaf run mutual volume curtain opinion panther bacon banana wrong machine";

var privateKeys = [
  "f401d397f581e467c6e3dc79fa7c57d76dc222344074e2c2de0fb8353592e008",   //0xa19F28dB941005d67274F13A7EDEe57a7b121AD6
  "cc406b2aa4e6ac922355d2054e1f8a6a608a938889172d3c0ed0bcec42e1214b",   //0xd8265a1f765447aad34405be9407ce329d6ef2fb
];
var provider = new HDWalletProvider(privateKeys, "http://127.0.0.1:8545", 0, 2);

module.exports = {

  networks: {
    dev: {
      provider: function () {
        return new HDWalletProvider(privateKeys, "http://127.0.0.1:8545", 0, 2);
      },
      network_id: "*"
    },
    test: {
      provider: function () {
        return new HDWalletProvider(privateKeys,
            "https://192.168.0.52:8545"
        )
      },
      network_id: 4
    },
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(privateKeys,
            "https://rinkeby.infura.io/v3/290f463de1754548871c2b19a7f2c07a"
        )
      },
      network_id: 4
    },
    bsctest: {
      provider: function () {
        return new HDWalletProvider(privateKeys,
            "https://data-seed-prebsc-1-s1.binance.org:8545"
        )
      },
      network_id: "*",
      gasPrice: 10000000000
    }
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.0",
    }
  }
};
