const KOLOUnique = artifacts.require("KOLOUnique");

module.exports = function (deployer) {
  deployer.deploy(KOLOUnique, "https://www.kolonft.com/api/nft/unique/");
};
