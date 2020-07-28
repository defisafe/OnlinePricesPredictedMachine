pragma solidity 0.6.0;
import "./KyberSwapFactory.sol";
import "./SafeMath.sol";



contract OnlinePricesPredictedMachine {


    using SafeMath for uint256;

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

    function swapEthToToken_Amount(uint256 ethAmount,ERC20 token, address destAddress) public returns(uint256){

         return KyberSwapFactory.execSwapEthToToken_Amount(ethAmount,token,destAddress);
    }

    function swapTokenToEth(ERC20 token, uint tokenQty, address payable destAddress) public{
        return KyberSwapFactory.execSwapTokenToEth(token,tokenQty,destAddress);
    }

    function swapTokenToToken(ERC20 srcToken, uint srcQty, ERC20 destToken, address destAddress) public returns(uint256){
        return KyberSwapFactory.execSwapTokenToToken(srcToken,srcQty,destToken,destAddress);
    }

    function slipPriceProtectionOfDai(ERC20 srcToken,uint256 amount)public returns(uint256,uint256){

        uint256 standardPrice = getPriceOfDAI(srcToken,mulDiv(_amount,1,100));
        uint256 actualPrice = getPriceOfDAI(srcToken,_amount);

        uint256 errorType = 0;
        if(_standardPrice == 0){
            errorType = 10;
        }else if(_actualPrice == 0){
            errorType = 11;
        }else if(_actualPrice > _standardPrice){
            errorType = 12;
        }
        uint256 actualSlip = _standardPrice.sub(_actualPrice); 
        uint256 maxSlip = mulDiv(_standardPrice,5,100);
        if(actualSlip > maxSlip){
            errorType = 13;
        }
        return (errorType,actualPrice);
    }

     function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }

}