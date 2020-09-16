pragma solidity >=0.6.2;

import "./ERC20Interface.sol";

interface OpenOraclePrice {
    function getPriceOfUsdt(ERC20 srcToken) external returns(uint256);
    function getPriceEthToUsdt() external view returns(uint256);
    function getPriceTokenToToken(ERC20 srcToken,ERC20 destToken) external returns(uint256);
    function getPriceTokenToEth(ERC20 token) external returns(uint256);
    function getPriceEthToToken(ERC20 destToken) external returns(uint256);
}



