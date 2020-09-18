pragma solidity >=0.6.2;

import "./ERC20Interface.sol";

interface OpenOraclePriceData {
    function getPriceOfUSDT(ERC20 srcToken) external view returns(uint256 lastPrice,uint256 tokenToEthRoundID,uint256 usdtToEthRoundID);
    function getPriceEthToUsdt() external view returns(uint256 lastPrice,uint256 usdtToEthRoundID);
    function getPriceTokenToEth(ERC20 srcToken) external view returns(uint256 lastPrice,uint256 tokenToEthRoundID);
    function getPriceTokenToToken(ERC20 srcToken,ERC20 destToken) external view returns(uint256 lastPrice,uint256 srcTokenToETHRoundID,uint256 destTokenToEthRoundID);
    function getPriceEthToToken(ERC20 destToken) external view returns(uint256 lastPrice,uint256 destTokenToEthRoundID);
    function getPriceEthToUsdt_history(uint256 oldUsdtToEthRoundID,uint256 oldStartTime,uint256 timePeriod) external view returns(uint256 lastPrice);
    function getPriceOfUSDT_history(ERC20 srcToken,uint256 tokenToEthRoundID,uint256 usdtToEthRoundID,uint256 oldStartTime,uint256 timePeriod) external view returns(uint256);
    //Get token-Eth the historical price
    function getRoundID_history(ERC20 srcToken,uint256 oldRoundID,uint256 oldStartTime,uint256 timePeriod) external view returns(uint256);
}


