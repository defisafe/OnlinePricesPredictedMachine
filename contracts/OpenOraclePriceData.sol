pragma solidity >=0.6.2;

import "./SafeMath.sol";
import "./AggregatorV3Interface.sol";


contract OpenOraclePriceData {

    using SafeMath for uint256;
    address public owner;

    //eth == eth-usdt
    //erc20 == erc20-eth
    mapping(address => address) private feedAddressManager;
    address public ethAddress;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setEthAddress(address _eth)public onlyOwner {
        require(_eth != address(0),"Eth Address error .");
        ethAddress = _eth;        
    }

    function setFeedAddressManager(address tokenAddress,address feedAddress) public onlyOwner{
       require(tokenAddress != address(0),"setFeedAddressManager-tokenAddress error .");
       require(feedAddress != address(0),"setFeedAddressManager-feedAddress error .");
       feedAddressManager[tokenAddress] = feedAddress;
    }
    
    //srcToken contains weth
    function getPriceTokenToUsdt(address srcTokenAddress) public view returns(uint256,uint256){
        address feedAddress = feedAddressManager[srcTokenAddress];
        if(feedAddress == address(0)){
            return(0,0);
        }
        if(srcTokenAddress == ethAddress){
            return (10,getPriceEthToUsdt());
        }else{
            AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
            (
                ,
                int srcToEthPrice,,
                uint timeStamp,
            )   = priceFeed.latestRoundData();
            require(timeStamp > 0,"TimeStamp error .");
            require(srcToEthPrice > 0,"Token srcToEthPrice error .");
            uint256 srcToEthPrice_256 = uint256(srcToEthPrice);
            uint256 ethToUsdtPrice_256 = getPriceEthToUsdt();
            return (10,mulDiv(srcToEthPrice_256,ethToUsdtPrice_256,1e18));
        }
    }

    function getPriceEthToUsdt()public view returns(uint256){
        address feedAddress = feedAddressManager[ethAddress];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        (
            ,
            int price,,
            uint timeStamp,
        )   = priceFeed.latestRoundData();
        require(timeStamp > 0,"TimeStamp error .");
        require(price > 0,"Token price error .");
        return uint256(price);
    }

     function getPriceTokenToEth(address srcTokenAddress)public view returns(uint256){
        address feedAddress = feedAddressManager[srcTokenAddress];
        if(feedAddress == address(0)){
            return(0);
        }
        if(srcTokenAddress == ethAddress){
            return (1e18);
        }else{
            AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
            (
                ,
                int srcToEthPrice,,
                uint timeStamp,
            )   = priceFeed.latestRoundData();
            require(timeStamp > 0,"TimeStamp error .");
            require(srcToEthPrice > 0,"Token srcToEthPrice error .");
            uint256 srcToEthPrice_256 = uint256(srcToEthPrice);
            return srcToEthPrice_256;
        }
     }

    function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }

}