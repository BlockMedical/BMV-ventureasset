/*jshint esversion: 6*/
const BigNumber = web3.BigNumber;
var erc20 = artifacts.require("ERC20VCToken");
var trade = artifacts.require("TradeContract");
var erc20_instance;
var trade_instance;
var decimals = 18;
/* jshint ignore:start */
var eth_to_wei = new BigNumber(10**decimals);
/* jshint ignore:end */

// deployer, network, accounts must be in the exact order.
module.exports = function(deployer, network, accounts) {
  let deploy_address = accounts[0];
  console.log("network=" + JSON.stringify(network) + " accounts=" + JSON.stringify(accounts));
  console.log("Contracts are deployed by wallet " + deploy_address);  
  deployer.deploy(erc20, 'BlockMed_Venture', 'BMV', {from: deploy_address}).then(function(erc20_i) {
    erc20_instance = erc20_i;
    console.log("ERC20Token BMV address is created on " + erc20_instance.address);
    return deployer.deploy(trade, erc20_instance.address, deploy_address, true, {from: deploy_address});
  }).then(function(trade_i) {
    trade_instance = trade_i;
    console.log("TradeContract address is created on " + trade_i.address);
    // hard cap at 100M
    erc20_instance.transfer(trade_i.address, new BigNumber(100000000).mul(eth_to_wei));
    console.log("Funding TradeContract contract " + trade_i.address + " 100000000 tokens from accounts=" + deploy_address);
  });
};
