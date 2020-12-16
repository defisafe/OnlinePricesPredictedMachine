pragma solidity >=0.6.2;

import "./ERC20Interface.sol";

interface OpenOraclePriceData {
    function getPriceTokenToUsdt(address srcTokenAddress) external view returns(uint256 isValid, uint256 lastPrice);
    function getPriceTokenToEth(address srcTokenAddress)external view returns(uint256);
}


