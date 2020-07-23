pragma solidity 0.6.0;
import "./ERC20Interface.sol";

interface OnlinePricesPredictedMachine {
    function getPriceOfDAI(ERC20 srcToken,uint256 amount) external returns(uint256);
    function getPriceEthToDai(uint256 amount) external view returns(uint,uint);
    function getPriceTokenToToken(ERC20 srcToken,ERC20 destToken,uint256 amount) external returns(uint,uint);
    function swapEthToToken(ERC20 token, address destAddress) external returns(uint256);
    function swapTokenToEth(ERC20 token, uint tokenQty, address payable destAddress) external;
    function swapTokenToToken(ERC20 srcToken, uint srcQty, ERC20 destToken, address destAddress) external returns(uint256);
}