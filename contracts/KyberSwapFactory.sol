pragma solidity ^0.6.0;

import "./KyberNetworkProxy.sol";
import "./ERC20Interface.sol";

library KyberSwapFactory {
    
    event SwapTokenToToken(address indexed sender, ERC20 srcToken, ERC20 destToken, uint amount);
    event Swap(address indexed sender, ERC20 destToken, uint amount);
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2);
    ERC20 constant internal DAI_TOKEN_ADDRESS = ERC20(0x6b175474e89094c44da98b954eedeac495271d0f);
    address constant kyberAddress = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
    KyberNetworkProxy constant internal kyberManger = KyberNetworkProxy(kyberAddress);
    
    
    function getPrice(ERC20 srcToken,ERC20 destToken,uint256 amount) public returns(uint,uint){
        return kyberManger.getExpectedRate(srcToken,destToken,amount);
    }
    
    function getPriceOfDAI(ERC20 srcToken,uint256 amount) public returns(uint256){
         uint256 minConversionRate;
         (minConversionRate,) = kyberManger.getExpectedRate(srcToken,DAI_TOKEN_ADDRESS,amount);
        return minConversionRate;
    }
    
    function getEthToDaiPrice(uint256 amount) public view returns(uint,uint){
        ERC20 srcToken = ETH_TOKEN_ADDRESS;
        ERC20 destToken = DAI_TOKEN_ADDRESS;
        return kyberManger.getExpectedRate(srcToken,destToken,amount);
    }
    
    //@dev Swap the user's ETH to ERC20 token
    //@param token destination token contract address
    //@param destAddress address to send swapped tokens to
    function execSwapEthToToken(ERC20 token, address destAddress) public returns(uint256){
        uint minConversionRate;

        // Get the minimum conversion rate
        (minConversionRate,) = kyberManger.getExpectedRate(ETH_TOKEN_ADDRESS, token, msg.value);

        // Swap the ETH to ERC20 token
        uint destAmount = kyberManger.swapEtherToToken.value(msg.value)(token, minConversionRate);

        // Send the swapped tokens to the destination address
        require(token.transfer(destAddress, destAmount));

        // Log the event
        emit Swap(msg.sender, token, destAmount);

        return destAmount;
    }


    //@dev Swap the user's ETH to ERC20 token
    //@param ethAmount eth amount 
    //@param token destination token contract address
    //@param destAddress address to send swapped tokens to
    function execSwapEthToToken_Amount(uint256 ethAmount,ERC20 token, address destAddress) public returns(uint256){
        uint minConversionRate;

        // Get the minimum conversion rate
        (minConversionRate,) = kyberManger.getExpectedRate(ETH_TOKEN_ADDRESS, token, ethAmount);

        // Swap the ETH to ERC20 token
        uint destAmount = kyberManger.swapEtherToToken.value(ethAmount)(token, minConversionRate);

        // Send the swapped tokens to the destination address
        require(token.transfer(destAddress, destAmount));

        // Log the event
        emit Swap(msg.sender, token, destAmount);

        return destAmount;
    }


    //@dev Swap the user's ERC20 token to ETH
    //@param token source token contract address
    //@param tokenQty amount of source tokens
    //@param destAddress address to send swapped ETH to
    function execSwapTokenToEth(ERC20 token, uint tokenQty, address payable destAddress) public {
        uint minConversionRate;

         // Set the spender's token allowance to tokenQty
        require(token.approve(kyberAddress, tokenQty));

        // Get the minimum conversion rate
        (minConversionRate,) = kyberManger.getExpectedRate(token, ETH_TOKEN_ADDRESS, tokenQty);

        // Swap the ERC20 token to ETH
        uint destAmount = kyberManger.swapTokenToEther(token, tokenQty, minConversionRate);

        // Send the swapped ETH to the destination address
        destAddress.transfer(destAmount);

        // Log the event
       emit Swap(msg.sender, token, destAmount);
    }


    //@dev Swap the user's ERC20 token to another ERC20 token
    //@param srcToken source token contract address
    //@param srcQty amount of source tokens
    //@param destToken destination token contract address
    //@param destAddress address to send swapped tokens to
    function execSwapTokenToToken(ERC20 srcToken, uint srcQty, ERC20 destToken, address destAddress) public returns(uint256){
        uint minConversionRate;

        // Set the spender's token allowance to tokenQty
        require(srcToken.approve(address(kyberManger), srcQty));

        // Get the minimum conversion rate
        (minConversionRate,) = kyberManger.getExpectedRate(srcToken, destToken, srcQty);

        // Swap the ERC20 token 
        uint destAmount = kyberManger.swapTokenToToken(srcToken, srcQty, destToken, minConversionRate);

        // Send the swapped tokens to the destination address
        require(destToken.transfer(destAddress, destAmount));

        // Log the event
        emit SwapTokenToToken(msg.sender, srcToken, destToken, destAmount);
        return destAmount;
    }


    /*
     * @dev Swap the user's ERC20 token to another ERC20 token/ETH
     * @param srcToken source token contract address
     * @param srcQty amount of source tokens
     * @param destToken destination token contract address
     * @param destAddress address to send swapped tokens to
     * @param maxDestAmount address to send swapped tokens to
     */
    function executeSwap(
        ERC20 srcToken,
        uint srcQty,
        ERC20 destToken,
        address destAddress,
        uint maxDestAmount
    ) public {
        uint minConversionRate;

        // Mitigate ERC20 Approve front-running attack, by initially setting
        // allowance to 0
        require(srcToken.approve(kyberAddress, 0));

        // Set the spender's token allowance to tokenQty
        require(srcToken.approve(kyberAddress, srcQty));

        // Get the minimum conversion rate
        (minConversionRate,) = kyberManger.getExpectedRate(srcToken, destToken, srcQty);

        // Swap the ERC20 token and send to destAddress
        kyberManger.trade(
            srcToken,
            srcQty,
            destToken,
            destAddress,
            maxDestAmount,
            minConversionRate,
            address(0x8b287f6c437c028efe083237891eb27b2d4e029e) //walletId for fee sharing program
        );
    }
    
}


