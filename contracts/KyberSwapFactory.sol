pragma solidity ^0.6.0;

import "./KyberNetworkProxy.sol";
import "./ERC20Interface.sol";

library KyberSwapFactory {
    
    event SwapTokenToToken(address indexed sender, ERC20 srcToken, ERC20 destToken, uint amount);
    event Swap(address indexed sender, ERC20 destToken, uint amount);
    ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0xbCA556c912754Bc8E7D4Aad20Ad69a1B1444F42d);
    ERC20 constant internal DAI_TOKEN_ADDRESS = ERC20(0xaD6D458402F60fD3Bd25163575031ACDce07538D);
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
            address(0xdb8bD85A703E895Ca904Ce128B795a786E105c3e) //walletId for fee sharing program
        );
    }
    
}


