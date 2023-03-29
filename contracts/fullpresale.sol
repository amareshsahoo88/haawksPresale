// SPDX-License-Identifier: MIT
pragma solidity ^0.9.0;

import "@openzeppelin/contracts@4.8.2/token/ERC20/IERC20.sol";
contract vesting {

    struct preSalePhase {
        uint startTime;
        uint endTime;
        uint totalTokens;
        uint tokenPrice;
    }
    
    struct preSaleInvestor {
        bool invested;
        uint256 balance;
        uint256 unlockedTokens;
        uint256 availableForClaim;
        uint256 tokenClaimed;
        bool locked;
        bool claimed;
        uint256 lockTime;
        uint category;
        bytes32 refferal;
        
    }

    IERC20 public token;
    uint256 public TGE;
    address public owner; 
    uint public id ;
    uint256 [] public category = [1 , 2 , 3 , 4 , 5] ;
    
    
    mapping (uint256 => preSalePhase) preSaleNumber;

    mapping(uint256 => mapping (address => preSaleInvestor)) public preSaleInvestorList;

    constructor (address _token) {
        owner = msg.sender;
        token = IERC20(_token);
        
    }

    modifier onlyowner {
        require(msg.sender == owner , "Only owner can change the TGE");
        _;
    }

    function setTGE (uint _TGE) public onlyowner {
        TGE = _TGE ;
    }

    function createPreSale(uint256 _totalToken , uint256 _tokenPrice , uint _startTime , uint _endTime) external onlyowner returns(bool){
        id++;
        preSaleNumber[id].startTime = _startTime;
        preSaleNumber[id].endTime = _endTime;
        preSaleNumber[id].totalTokens = _totalToken;
        preSaleNumber[id].tokenPrice = _tokenPrice;
        return true;
    }

    function lock(uint256 _id ,address _from , address _investor , uint256 _amount) external {
        require(_amount <= preSaleNumber[id].totalTokens , "Insufficient tokens try a lower value");
        require(block.timestamp > preSaleNumber[id].startTime , "Time of presale has not yet arrived");
        require(block.timestamp > preSaleNumber[id].endTime , "Time of presale has passed");
        
        token.transferFrom(_from, address(this), _amount);
        preSaleInvestorList[_id][_investor].balance = _amount;
        preSaleInvestorList[_id][_investor].invested = true;
        preSaleInvestorList[_id][_investor].locked = true;
        preSaleInvestorList[_id][_investor].claimed = false;
        preSaleInvestorList[_id][_investor].lockTime = TGE;
        preSaleInvestorList[_id][_investor].refferal = keccak256(abi.encodePacked(_investor)); 
        
        if(_amount> 100 && _amount< 500){        
            preSaleInvestorList[_id][_investor].category = category[0];
        }
        else if (_amount> 500 && _amount< 1000){        
            preSaleInvestorList[_id][_investor].category = category[1];
        }
        else if (_amount> 1000 && _amount< 5000){        
            preSaleInvestorList[_id][_investor].category = category[2];
        }
        else if (_amount> 5000 && _amount< 10000){        
            preSaleInvestorList[_id][_investor].category = category[3];
        }
        else if (_amount> 100000 && _amount< 10000){        
            preSaleInvestorList[_id][_investor].category = category[4];
        }


    }

    function unlockedTokens(uint _id , address _investor) internal returns (uint) {

        if(block.timestamp> TGE && block.timestamp< TGE+10){
            preSaleInvestorList[_id][_investor].unlockedTokens += preSaleInvestorList[_id][_investor].balance/2;
        }
        if(block.timestamp> TGE+10 && block.timestamp< TGE+20){
            preSaleInvestorList[_id][_investor].unlockedTokens += preSaleInvestorList[_id][_investor].balance/2;
        }

        return preSaleInvestorList[_id][_investor].unlockedTokens;

    }

    function withdraw(uint _id , address _investor , uint256 _claimAmount) external {
        require(preSaleInvestorList[_id][_investor].invested , "You are not an investor");
        require(block.timestamp > preSaleInvestorList[_id][_investor].lockTime ,"Tokens have not been unlocked");
        
        preSaleInvestorList[_id][_investor].unlockedTokens = unlockedTokens(_id , _investor);
        if(preSaleInvestorList[_id][_investor].claimed){
            preSaleInvestorList[_id][_investor].availableForClaim = preSaleInvestorList[_id][_investor].unlockedTokens - preSaleInvestorList[_id][_investor].tokenClaimed;
        }
        else{
            preSaleInvestorList[_id][_investor].availableForClaim = preSaleInvestorList[_id][_investor].unlockedTokens;
        }

        if(_claimAmount<= preSaleInvestorList[_id][_investor].availableForClaim) {
            preSaleInvestorList[id][_investor].claimed = true;
            preSaleInvestorList[_id][_investor].locked = false;
            token.transfer(_investor , _claimAmount);
        }
        
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

}