const Migrations = artifacts.require("Migrations");
const TimeBox = artifacts.require("TimeBox");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(TimeBox, 365);

};
