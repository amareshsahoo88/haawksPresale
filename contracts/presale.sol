// SPDX-License-Identifier: MIT
pragma solidity ^0.9.0;

import "@openzeppelin/contracts@4.8.2/token/ERC20/IERC20.sol";
contract vesting {
    
    struct preSaleInvestor {
        bool invested;
        uint256 balance;
        bool locked;
        bool claimed;
        uint256 lockTime;
        bytes32 refferal;
    }
     
    IERC20 public token;
    uint256 public TGE;
    
    mapping (address => preSaleInvestor) preSaleInvestorList;

    constructor (address _token) {
        token = IERC20(_token);
        
    }

    function lock(address _from , address _investor , uint256 _amount) external {
        
        token.transferFrom(_from, address(this), _amount);
        preSaleInvestorList[_investor].balance = _amount;
        preSaleInvestorList[_investor].invested = true;
        preSaleInvestorList[_investor].locked = true;
        preSaleInvestorList[_investor].claimed = false;
        preSaleInvestorList[_investor].lockTime = TGE + 1000;
        preSaleInvestorList[_investor].refferal = keccak256(abi.encodePacked(_investor)); 

    }

    function withdraw(address _investor) external {
        require(preSaleInvestorList[_investor].invested , "You are not an investor");
        require(block.timestamp > preSaleInvestorList[_investor].lockTime ,"Tokens have not been unlocked");
        require(! preSaleInvestorList[_investor].claimed,"Token have already been claimed");
        preSaleInvestorList[_investor].claimed = true;
        preSaleInvestorList[_investor].locked = false;
        token.transfer(_investor , preSaleInvestorList[_investor].balance);

    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

}