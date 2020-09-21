pragma solidity >=0.6.2;

import "./SafeMath.sol";
import "./ERC20Interface.sol";
import "./AggregatorV3Interface.sol";



contract OpenOraclePriceData {

    using SafeMath for uint256;
    address public owner;

    mapping(address => address) private feedAddressManager;
    address constant private ETH_TOKEN_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    ERC20 constant private USDT_TOKEN_ADDRESS = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    uint256 public frequency;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setHistoryPriceCheckFrequency(uint256 _frequency)public onlyOwner {
        require(_frequency > 10,"frequency is too short . ");
        frequency = _frequency;        
    }
    

    function setFeedAddressManager(address tokenAddress,address feedAddress) public onlyOwner{
       require(tokenAddress != address(0),"setFeedAddressManager-tokenAddress error .");
       require(feedAddress != address(0),"setFeedAddressManager-feedAddress error .");
       feedAddressManager[tokenAddress] = feedAddress;
    }
    
    //srcToken contains weth
    function getPriceTokenToUsdt(ERC20 srcToken) public view returns(uint256 lastPrice,uint256 tokenToEthRoundID,uint256 usdtToEthRoundID){
        
        address srcTokenAddress = address(srcToken);
        if(srcTokenAddress == ETH_TOKEN_ADDRESS){
            (lastPrice,usdtToEthRoundID) = getPriceEthToUsdt();
            return(lastPrice,uint256(0),usdtToEthRoundID);
        }else{
             address feedAddress = feedAddressManager[address(srcToken)];
            require (feedAddress != address(0),"This Token quote is not supported .");
            AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
            (
                uint80 id,
                int price,,
                uint timeStamp,
            ) = priceFeed.latestRoundData();
            require(timeStamp > 0,"TimeStamp error .");
            require(price > 0,"Token price error .");
            uint256 priceSrcTokenToEth = uint256(price);
            uint256 piceEthToUsdt = 0;
            uint256 roundID = 0;
            (piceEthToUsdt,roundID) = getPriceEthToUsdt();
            lastPrice = mulDiv(priceSrcTokenToEth,piceEthToUsdt,1e18);
            tokenToEthRoundID = uint256(id);
            usdtToEthRoundID = uint256(roundID);
            return (lastPrice,tokenToEthRoundID,usdtToEthRoundID);
        }
    }

     function getPriceEthToUsdt() public view returns(uint256 lastPrice,uint256 usdtToEthRoundID){
         
        address usdtToETHFeedAddress = feedAddressManager[address(USDT_TOKEN_ADDRESS)];
        require(usdtToETHFeedAddress != address(0),"usdtToETHFeedAddress error .");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(usdtToETHFeedAddress);
        (
            uint80 id,
            int price,,
            uint timeStamp,
        ) = priceFeed.latestRoundData();
        require(timeStamp > 0,"TimeStamp error .");
        require(price > 0,"Token price error .");
        uint256 priceUsdtToETH = uint256(price);
        return (mulDiv(1e18,1e18,priceUsdtToETH),uint256(id));
     }

    //srcToken != weth
    function getPriceTokenToEth(ERC20 srcToken) public view returns(uint256 lastPrice,uint256 tokenToEthRoundID) {
        address tokenToETHFeedAddress = feedAddressManager[address(srcToken)];
        require(tokenToETHFeedAddress != address(0),"getPriceTokenToEth tokenToETHFeedAddress error .");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenToETHFeedAddress);
        (
            uint80 id,
            int price,,
            uint timeStamp,
        ) = priceFeed.latestRoundData();
        require(timeStamp > 0,"TimeStamp error .");
        require(price > 0,"Token price error .");
        return (uint256(price),uint256(id));
    }

    //srcToken != weth//eth,destToken != weth//eth
    function getPriceTokenToToken(ERC20 srcToken,ERC20 destToken) public view returns(uint256 _lastPrice,uint256 _srcTokenToETHRoundID,uint256 _destTokenToEthRoundID){
        
        (uint256 priceSrcTokenToEth,uint256 srcTokenToETHRoundID) = getPriceTokenToEth(srcToken);
        (uint256 priceDestTokenToEth,uint256 destTokenToEthRoundID) = getPriceTokenToEth(destToken);
        uint256 priceEthToDestToken = mulDiv(1e18,1e18,priceDestTokenToEth);
        return (mulDiv(priceSrcTokenToEth,priceEthToDestToken,1e18),srcTokenToETHRoundID,destTokenToEthRoundID);
    }
    
    //destToken != weth
    function getPriceEthToToken(ERC20 destToken) public view returns(uint256 lastPrice,uint256 _destTokenToEthRoundID){
        
        (uint256 priceDestTokenToEth,uint256 destTokenToEthRoundID) = getPriceTokenToEth(destToken);
        uint256 priceEthToDestToken = mulDiv(1e18,1e18,priceDestTokenToEth);
        return (priceEthToDestToken,destTokenToEthRoundID);
    }

    function getPriceEthToUsdt_specified(uint256 oldUsdtToEthRoundID) public view returns(uint256 priceSpecified,uint256 timeSpecified){
        address usdtToETHFeedAddress = feedAddressManager[address(USDT_TOKEN_ADDRESS)];
        require(usdtToETHFeedAddress != address(0),"usdtToETHFeedAddress error .");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(usdtToETHFeedAddress);
        (
            ,int price,,
            uint timeStamp,
        ) = priceFeed.getRoundData(uint80(oldUsdtToEthRoundID));
        require(timeStamp > 0,"TimeStamp error .");
        require(price > 0,"Token price error .");
        uint256 priceUsdtToETH = uint256(price);
        timeSpecified = uint256(timeStamp);
        return (mulDiv(1e18,1e18,priceUsdtToETH),timeSpecified);
     }
     

    function getPriceTokenToUsdt_specified(ERC20 srcToken,uint256 tokenToEthRoundID,uint256 usdtToEthRoundID) public view returns(uint256 priceSpecified,uint256 timeTokenToEthSpecified,uint256 timeUsdtToEthSpecified){

        address srcTokenAddress = address(srcToken);
        if(srcTokenAddress == ETH_TOKEN_ADDRESS){
            (priceSpecified,timeUsdtToEthSpecified) = getPriceEthToUsdt_specified(usdtToEthRoundID);
            return(priceSpecified,0,timeUsdtToEthSpecified);
        }else{
            address feedAddress = feedAddressManager[address(srcToken)];
            require (feedAddress != address(0),"This Token quote is not supported .");
            AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
            (
                uint80 id,
                int price,,
                uint timeStamp,
            ) = priceFeed.getRoundData(uint80(tokenToEthRoundID));
            require(timeStamp > 0,"TimeStamp error .");
            require(price > 0,"Token price error .");
            timeTokenToEthSpecified = uint256(timeStamp);
            uint256 priceSrcTokenToEth = uint256(price);
            uint256 piceEthToUsdt = 0;
            (piceEthToUsdt,timeUsdtToEthSpecified) = getPriceEthToUsdt_specified(usdtToEthRoundID);
            priceSpecified = mulDiv(priceSrcTokenToEth,piceEthToUsdt,1e18);
            return (priceSpecified,timeTokenToEthSpecified,timeUsdtToEthSpecified);
        }
    }


     function getPriceEthToUsdt_history(uint256 oldUsdtToEthRoundID,uint256 oldStartTime,uint256 timePeriod) public view returns(uint256 lastPrice){
        address usdtToETHFeedAddress = feedAddressManager[address(USDT_TOKEN_ADDRESS)];
        require(usdtToETHFeedAddress != address(0),"usdtToETHFeedAddress error .");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(usdtToETHFeedAddress);
        uint256 targetPriceID = getRoundID_history(USDT_TOKEN_ADDRESS,oldUsdtToEthRoundID,oldStartTime,timePeriod);
        targetPriceID = getRoundID_check(priceFeed,targetPriceID,oldStartTime+timePeriod);
         (
                    ,int price,,
                    uint timeStamp,
                    
                ) = priceFeed.getRoundData(uint80(targetPriceID));
        require(timeStamp > 0,"TimeStamp error .");
        require(price > 0,"Token price error .");
        uint256 priceUsdtToETH = uint256(price);
        return (mulDiv(1e18,1e18,priceUsdtToETH));
     }
     
     
    function getPriceTokenToUsdt_history(ERC20 srcToken,uint256 tokenToEthRoundID,uint256 usdtToEthRoundID,uint256 oldStartTime,uint256 timePeriod) public view returns(uint256){
        
        address srcTokenAddress = address(srcToken);
        if(srcTokenAddress == ETH_TOKEN_ADDRESS){
            return getPriceEthToUsdt_history(usdtToEthRoundID,oldStartTime,timePeriod);
        }else{
            address feedAddress = feedAddressManager[address(srcToken)];
            require (feedAddress != address(0),"This Token quote is not supported .");
            AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
            uint256 tokenToEthTargetID = getRoundID_history(srcToken,tokenToEthRoundID,oldStartTime,timePeriod);
            tokenToEthTargetID = getRoundID_check(priceFeed,tokenToEthTargetID,oldStartTime+timePeriod);
            (
                ,int price,,
                uint timeStamp,
                    
            ) = priceFeed.getRoundData(uint80(tokenToEthTargetID));
            require(timeStamp > 0,"TimeStamp error .");
            require(price > 0,"Token price error .");
            uint256 priceSrcTokenToEth = uint256(price);
            uint256 piceEthToUsdt = 0;
        
            piceEthToUsdt = getPriceEthToUsdt_history(usdtToEthRoundID,oldStartTime,timePeriod);
            return mulDiv(priceSrcTokenToEth,piceEthToUsdt,1e18);
        }
    }

    
    //Get token-Eth the historical price
    function getRoundID_history(ERC20 srcToken,uint256 oldRoundID,uint256 oldStartTime,uint256 timePeriod) public view returns(uint256){

        uint256 currentTime = block.timestamp;
        require(currentTime > (oldStartTime+timePeriod),"getRoundID_history time error !");
        address feedAddress = feedAddressManager[address(srcToken)];
        require(feedAddress != address(0),"getPriceTokenToEth feedAddress error .");
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
         (
            uint80 id,,,
            uint timeStamp,
        ) = priceFeed.latestRoundData();
        require(timeStamp > 0, "Round not complete");
        require(id > 0,"RoundID error !");
        
        uint256 currentPriceID = id;
        uint256 differPriceID = currentPriceID - oldRoundID;
        if(differPriceID <= 0){
            return currentPriceID;
        }
        
        uint256 differTime = currentTime - oldStartTime;
        uint256 ratio = 0;
        uint256 targetPriceID = 0;
        if(differTime >= differPriceID){
            ratio = differTime.div(differPriceID);
            uint256 targetRoundIDDiffer = timePeriod.div(ratio);
            targetPriceID = oldRoundID + targetRoundIDDiffer;
        }else{
            ratio = differPriceID.div(differTime);
            uint256 targetRoundIDDiffer = timePeriod.mul(ratio);
            targetPriceID = oldRoundID + targetRoundIDDiffer;
        }
        
        require(targetPriceID > 0,"RoundID caulate error !");
        uint256 endTime = oldStartTime+timePeriod;
        return getRoundID_check(priceFeed,targetPriceID,endTime);
    }

    function getRoundID_check(AggregatorV3Interface priceFeed,uint256 targetPriceID,uint256 endTime) public view returns(uint256){
    
        uint256 verifiedPriceID = targetPriceID;
        (
            ,,,
            uint oneTempRoundIDTime,
            
        ) = priceFeed.getRoundData(uint80(targetPriceID));
        
        if(endTime > oneTempRoundIDTime){
            //
            uint256 checkTimes = (endTime-oneTempRoundIDTime).div(frequency);
            for(uint256 i = 0;i < checkTimes;i++){
                (
                    ,,,
                    uint tempRoundIDTime,
                    
                ) = priceFeed.getRoundData(uint80(targetPriceID+i));
                verifiedPriceID = targetPriceID+i;
                if(tempRoundIDTime >= endTime){
                    break;
                }
            }
        }else if(endTime < oneTempRoundIDTime){
            uint256 checkTimes = (oneTempRoundIDTime - endTime).div(frequency);
            for(uint256 i = 0;i < checkTimes;i++){
                (
                    ,,,
                uint tempRoundIDTime,
                
                ) = priceFeed.getRoundData(uint80(targetPriceID-i));
                verifiedPriceID = targetPriceID-i;
                if(tempRoundIDTime <= endTime){
                    break;
                }
            }
        }
        return verifiedPriceID;
    }

    
    // Receive ETH
    fallback() external payable {}
    receive() external payable {}

    function mulDiv (uint256 _x, uint256 _y, uint256 _z) public pure returns (uint256) {
        uint256 temp = _x.mul(_y);
        return temp.div(_z);
    }

}