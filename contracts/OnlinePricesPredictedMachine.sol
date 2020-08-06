pragma solidity 0.6.0;
import "./SafeMath.sol";
import "./ERC20Interface.sol";

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
    
    struct PriceFeedStruct{
        uint256 feedAddressTotal;
        uint256 tokenID_Total;
        address daiToETHFeedAddress;
        mapping(uint256 => address) feedAddressManager;
        mapping(address => uint256) tokenID_Manager;
    }
    
    PriceFeedStruct public tokenPriceFeedStruct;
    
    constructor() public {
        tokenPriceFeedStruct = PriceFeedStruct({feedAddressTotal:0,tokenID_Total: 0});
        owner = msg.sender;
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setDaiToETHFeedAddress(address feedAddress) public onlyOwner{
        
        require(feedAddress != address(0),"daiToETHFeedAddress error .");
        tokenPriceFeedStruct.daiToETHFeedAddress = feedAddress;

    }
    
    function setPriceFeedAddress(uint256 tokenID,address feedAddress) public onlyOwner{
        
        require(tokenID == tokenPriceFeedStruct.feedAddressTotal,"feedAddressTotal error .");
        tokenPriceFeedStruct.feedAddressManager(tokenID) = feedAddress;
        tokenPriceFeedStruct.feedAddressTotal = tokenPriceFeedStruct.feedAddressTotal+1;
        
    }
    
     function setTokenIDAddress(address tokenAddress,uint256 tokenID) public onlyOwner{
        
        require(tokenID == tokenPriceFeedStruct.tokenID_Total,"tokenID_Total error .");
        tokenPriceFeedStruct.tokenID_Manager(tokenAddress) = tokenID;
        tokenPriceFeedStruct.tokenID_Total = tokenPriceFeedStruct.tokenID_Total+1;
        
    }
    
    

    function getPriceOfDAI(ERC20 srcToken,uint256 amount) public returns(uint256){
        
        uint256 tokenID = tokenPriceFeedStruct.tokenID_Manager[address(srcToken)];
        address feedAddress = tokenPriceFeedStruct.feedAddressManager[tokenID];
        AggregatorInterface feedManager = AggregatorInterface(feedAddress);
        uint256 priceSrcTokenToEth = feedManager.latestAnswer;
        uint256 getPriceEthToDai = getPriceEthToDai(0);
        return mulDiv(priceSrcTokenToEth,getPriceEthToDai,1e18);
    }

     function getPriceEthToDai(uint256 amount) public view returns(uint,uint){
         
         require(tokenPriceFeedStruct.daiToETHFeedAddress != address(0),"no set daiToETHFeedAddress");
         AggregatorInterface feedManager = AggregatorInterface(tokenPriceFeedStruct.daiToETHFeedAddress);
         uint256 priceDaiToETH = feedManager.latestAnswer;
         return mulDiv(1e18,1e18,priceDaiToETH);
     }


    function getPriceTokenToToken(ERC20 srcToken,ERC20 destToken,uint256 amount) public returns(uint,uint){
        
        uint256 tokenIDSrcToken = tokenPriceFeedStruct.tokenID_Manager[address(srcToken)];
        address feedAddressSrcToken = tokenPriceFeedStruct.feedAddressManager[tokenIDSrcToken];
        AggregatorInterface feedManagerSrcToken = AggregatorInterface(feedAddressSrcToken);
        uint256 priceSrcTokenToEth = feedManagerSrcToken.latestAnswer;
        
        uint256 tokenIDDestToken = tokenPriceFeedStruct.tokenID_Manager[address(destToken)];
        address feedAddressDestToken = tokenPriceFeedStruct.feedAddressManager[tokenIDDestToken];
        AggregatorInterface feedManagerDestToken = AggregatorInterface(feedAddressDestToken);
        uint256 priceDestTokenToEth = feedManagerDestToken.latestAnswer;
        
        uint256 getPriceEthToDestToken = mulDiv(1e18,1e18,priceDestTokenToEth);
        
        return mulDiv(priceSrcTokenToEth,getPriceEthToDestToken,1e18);
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


    // Receive ETH
    fallback() external payable {}
    receive() external payable {}

    function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }

}