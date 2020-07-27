pragma solidity 0.6.0;
import "./KyberSwapFactory.sol";


contract OnlinePricesPredictedMachine {
    constructor() public {}

    function getPriceOfDAI(ERC20 srcToken,uint256 amount) public returns(uint256){
        return  KyberSwapFactory.getPriceOfDAI(srcToken,amount);
    }

     function getPriceEthToDai(uint256 amount) public view returns(uint,uint){
         return KyberSwapFactory.getEthToDaiPrice(amount);
     }

    function getPriceTokenToToken(ERC20 srcToken,ERC20 destToken,uint256 amount) public returns(uint,uint){
        return KyberSwapFactory.getPrice(srcToken,destToken,amount);
    }

    function swapEthToToken(ERC20 token, address destAddress) public returns(uint256){
         return KyberSwapFactory.execSwapEthToToken(token,destAddress);
    }

    function swapTokenToEth(ERC20 token, uint tokenQty, address payable destAddress) public{
        return KyberSwapFactory.execSwapTokenToEth(token,tokenQty,destAddress);
    }

    function swapTokenToToken(ERC20 srcToken, uint srcQty, ERC20 destToken, address destAddress) public returns(uint256){
        return KyberSwapFactory.execSwapTokenToToken(srcToken,srcQty,destToken,destAddress);
    }
}