const KyberSwapFactory = artifacts.require("KyberSwapFactory");
const OnlinePricesPredictedMachine = artifacts.require("OnlinePricesPredictedMachine");

module.exports = function(deployer) {
  deployer.deploy(KyberSwapFactory);
  deployer.link(KyberSwapFactory, OnlinePricesPredictedMachine);
  deployer.deploy(OnlinePricesPredictedMachine);
};
