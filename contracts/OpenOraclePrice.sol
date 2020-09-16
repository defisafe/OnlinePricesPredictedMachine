pragma solidity >=0.6.2;

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


contract OpenOraclePrice {

    using SafeMath for uint256;
    address payable owner;

    //USDT_TOKEN_ADDRESS
    mapping(address => address) private feedAddressManager;

    ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    ERC20 constant private USDT_TOKEN_ADDRESS = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        
    constructor() public {
        owner = msg.sender;
    }
    
     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setFeedAddressManager(address tokenAddress,address feedAddress) public onlyOwner{
       require(tokenAddress != address(0),"setFeedAddressManager-tokenAddress error .");
       require(feedAddress != address(0),"setFeedAddressManager-feedAddress error .");
       feedAddressManager[tokenAddress] = feedAddress;
    }

    function getPriceOfUsdt(ERC20 srcToken) public view returns(uint256){
        
        address feedAddress = feedAddressManager[address(srcToken)];
        require (feedAddress != address(0),"This Token quote is not supported .");
        
        AggregatorInterface feedManager = AggregatorInterface(feedAddress);
        int256 _price = feedManager.latestAnswer();
        require(_price > 0,"Token price error .");
        
        uint256 priceSrcTokenToEth = uint256(_price);
        uint256 piceEthToUsdt = 0;
        (piceEthToUsdt,) = getPriceEthToUsdt();
        return mulDiv(priceSrcTokenToEth,piceEthToUsdt,1e18);
    }

     function getPriceEthToUsdt() public view returns(uint256){
         
        address usdtToETHFeedAddress = feedAddressManager[address(USDT_TOKEN_ADDRESS)];
        require(usdtToETHFeedAddress != address(0),"usdtToETHFeedAddress error .");
        AggregatorInterface feedManager = AggregatorInterface(usdtToETHFeedAddress);
        int256 _price = feedManager.latestAnswer();
        require(_price > 0,"Usdt to Eth price error .");
        uint256 priceUsdtToETH = uint256(_price);
        return (mulDiv(1e18,1e18,priceUsdtToETH));
     }


    function getPriceTokenToEth(ERC20 srcToken) public view returns(uint256) {
        address tokenToETHFeedAddress = feedAddressManager[address(srcToken)];
        require(tokenToETHFeedAddress != address(0),"getPriceTokenToEth tokenToETHFeedAddress error .");
        AggregatorInterface feedManagerSrcToken = AggregatorInterface(tokenToETHFeedAddress);
        int256 _price = feedManagerSrcToken.latestAnswer();
        require(_price > 0,"getPriceTokenToEth price error .");
        return uint256(_price);
    }

    function getPriceTokenToToken(ERC20 srcToken,ERC20 destToken) public view returns(uint256){
        uint256 priceSrcTokenToEth = getPriceTokenToEth(srcToken);
        uint256 priceDestTokenToEth = getPriceTokenToEth(destToken);
        uint256 priceEthToDestToken = mulDiv(1e18,1e18,priceDestTokenToEth);
        return (mulDiv(priceSrcTokenToEth,priceEthToDestToken,1e18));
    }
    
    function getPriceEthToToken(ERC20 destToken) public view returns(uint256){
        uint256 priceDestTokenToEth = getPriceTokenToEth(destToken);
        uint256 priceEthToDestToken = mulDiv(1e18,1e18,priceDestTokenToEth);
        return priceEthToDestToken;
    }

    function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }

}