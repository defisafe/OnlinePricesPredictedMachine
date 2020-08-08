pragma solidity >=0.6.2;

import "./SafeMath.sol";
import "./ERC20Interface.sol";
import "./IUniswapV2Router02.sol";

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}


contract OnlinePricesPredictedMachine {

    using SafeMath for uint256;
    address payable owner;
    
    IUniswapV2Router02 private swapRouter02;
    mapping(address => address) private feedAddressManager;
    ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 constant private DAI_TOKEN_ADDRESS = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    
    uint256 public slipValue;
    
    constructor() public {
        owner = msg.sender;
        slipValue = 1;
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
    function setPriceSlip(uint256 _slip)public onlyOwner {
        
        require(_slip < 6,"slip error .");
        slipValue = _slip;
    }
    
    function setSwapRouter02Address(address routeAddress) public onlyOwner {
        
        require(routeAddress != address(0),"RouteAddress error .");
        swapRouter02 = IUniswapV2Router02(routeAddress);
    }

    
    function setFeedAddressManager(address tokenAddress,address feedAddress) public onlyOwner{
       
       require(tokenAddress != address(0),"setFeedAddressManager-tokenAddress error .");
       require(feedAddress != address(0),"setFeedAddressManager-feedAddress error .");
       
       feedAddressManager[tokenAddress] = feedAddress;
    }
    

    function getPriceOfDAI(ERC20 srcToken,uint256 amount) public view returns(uint256){
        
        address feedAddress = feedAddressManager[address(srcToken)];
        require (feedAddress != address(0),"This Token quote is not supported .");
        
        AggregatorInterface feedManager = AggregatorInterface(feedAddress);
        int256 _price = feedManager.latestAnswer();
        require(_price > 0,"Token price error .");
        
        uint256 priceSrcTokenToEth = uint256(_price);
        uint256 piceEthToDai = 0;
        (piceEthToDai,) = getPriceEthToDai(0);
        return mulDiv(priceSrcTokenToEth,piceEthToDai,1e18);
    }

     function getPriceEthToDai(uint256 amount) public view returns(uint256,uint256){
         
        address daiToETHFeedAddress = feedAddressManager[address(DAI_TOKEN_ADDRESS)];
        require(daiToETHFeedAddress != address(0),"daiToETHFeedAddress error .");
        AggregatorInterface feedManager = AggregatorInterface(daiToETHFeedAddress);
        int256 _price = feedManager.latestAnswer();
        require(_price > 0,"Dai to Eth price error .");
        uint256 priceDaiToETH = uint256(_price);
        return (mulDiv(1e18,1e18,priceDaiToETH),uint256(0));
        
     }


    function getPriceTokenToEth(ERC20 srcToken) public view returns(uint256) {
        
        address tokenToETHFeedAddress = feedAddressManager[address(srcToken)];
        require(tokenToETHFeedAddress != address(0),"getPriceTokenToEth tokenToETHFeedAddress error .");
        AggregatorInterface feedManagerSrcToken = AggregatorInterface(tokenToETHFeedAddress);
        int256 _price = feedManagerSrcToken.latestAnswer();
        require(_price > 0,"getPriceTokenToEth price error .");
        return uint256(_price);
    }


    function getPriceTokenToToken(ERC20 srcToken,ERC20 destToken,uint256 amount) public view returns(uint256,uint256){
        
        uint256 priceSrcTokenToEth = getPriceTokenToEth(srcToken);
        uint256 priceDestTokenToEth = getPriceTokenToEth(destToken);
        uint256 priceEthToDestToken = mulDiv(1e18,1e18,priceDestTokenToEth);
        return (mulDiv(priceSrcTokenToEth,priceEthToDestToken,1e18),uint256(0));
    }
    
    function getPriceEthToToken(ERC20 destToken) public view returns(uint256){
        
        uint256 priceDestTokenToEth = getPriceTokenToEth(destToken);
        uint256 priceEthToDestToken = mulDiv(1e18,1e18,priceDestTokenToEth);
        return priceEthToDestToken;
    }


    function swapEthToToken(ERC20 token, address destAddress) public payable returns(uint256){
        
        uint256 _price = getPriceEthToToken(token);
        uint256 amountOutMin = mulDiv(msg.value,_price,1e18);
        amountOutMin = mulDiv(amountOutMin,(100 - slipValue),100);
        address[] memory path = new address[](2);
        path[0] = address(ETH_TOKEN_ADDRESS);
        path[1] = address(token);
        swapRouter02.swapExactETHForTokensSupportingFeeOnTransferTokens(amountOutMin,path,destAddress,block.timestamp);
        return amountOutMin;
    }


    function swapEthToToken_Amount(uint256 ethAmount,ERC20 token, address destAddress) public returns(uint256){

        uint256 _price = getPriceEthToToken(token);
        uint256 amountOutMin = mulDiv(ethAmount,_price,1e18);
        amountOutMin = mulDiv(amountOutMin,(100 - slipValue),100);
        address[] memory path = new address[](2);
        path[0] = address(ETH_TOKEN_ADDRESS);
        path[1] = address(token);
        swapRouter02.swapExactETHForTokensSupportingFeeOnTransferTokens(amountOutMin,path,destAddress,block.timestamp);
        return amountOutMin;
    }

    function swapTokenToEth(ERC20 token, uint tokenQty, address payable destAddress) public{
        
        require(token.approve(address(swapRouter02), tokenQty), 'swapTokenToEth approve failed.');
        // amountOutMin must be retrieved from an oracle of some kind
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(ETH_TOKEN_ADDRESS);
        uint256 _price = getPriceTokenToEth(token);
        uint256 amountOutMin = mulDiv(tokenQty,_price,1e18);
        amountOutMin = mulDiv(amountOutMin,(100-slipValue),100);
        swapRouter02.swapExactTokensForETH(tokenQty, amountOutMin, path, destAddress, block.timestamp);
    }


    function swapTokenToToken(ERC20 srcToken, uint srcQty, ERC20 destToken, address destAddress) public returns(uint256){
        
        require(srcToken.approve(address(swapRouter02), srcQty), 'approve failed.');
        // amountOutMin must be retrieved from an oracle of some kind
        address[] memory path = new address[](2);
        path[0] = address(srcToken);
        path[1] = address(destAddress);
        uint256 _price;
        (_price,) = getPriceTokenToToken(srcToken,destToken,0);
        uint256 amountOutMin = mulDiv(srcQty,_price,1e18);
        amountOutMin = mulDiv(amountOutMin,(100-slipValue),100);
        swapRouter02.swapExactTokensForTokensSupportingFeeOnTransferTokens(srcQty,amountOutMin,path,destAddress,block.timestamp);
        return amountOutMin;
    }
    

    // Receive ETH
    fallback() external payable {}
    receive() external payable {}

    function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }

}