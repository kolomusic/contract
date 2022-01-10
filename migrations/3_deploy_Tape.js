const KOLOTape = artifacts.require("KOLOTape");

module.exports = function (deployer) {
  deployer.deploy(KOLOTape, "https://www.kolonft.com/api/nft/tape/");
};
