// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";



contract vesting is Ownable {

    using Counters for Counters.Counter;

// This structure will create a presale which shall have 7 phases 1% of total supply each.
// This shall be setup by the owner.

    struct preSalePhase {
        uint startTime;
        uint endTime;
        uint totalTokens;
        uint tokenPrice;
    }
    
    event StorePreSalePhase(uint id,uint startTime,
        uint endTime,
        uint totalTokens,
        uint tokenPrice) ; 

// This structure is for the investor details who is investing in the pre-sale . 
// This shall keep updating as the investors keep getting added.

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
        uint refferal;
        bool refferalUsed;
        
    }

// Following are the variables that are getting declared.
// token - refers to the token to be used in the contract
// TGE - the "Token generation event" timestamp.
// owner - Owner of the contract
// id - id of the presale phase that is going on.
// cat - category of the investor that it bellongs to 
// based on the amount he is investing.
// idList - The array in which the data of investors is 
// stored as per their phase of investment to be retreved in the frontend by the admin
// count - counter used to increment the array counter
// len - length of the array idList

    IERC20 public token;
    uint256 public TGE = block.timestamp;
    Counters.Counter public id;
    Counters.Counter public referralID;
    uint public cat;
    address [][] idList ;
    Counters.Counter count;
    uint256 len ;
   
// This mapping is to store details of the individual phases of the preSale
    
    mapping (uint256 => preSalePhase) preSaleNumber;

// this mapping to the tract investor details mapping it through phase Id , category of investor and address

    mapping(uint256  => mapping ( uint =>mapping (address => preSaleInvestor))) public preSaleInvestorList;

// this mapping is for storing value of referal code to the address of the sponcer
    mapping(uint256 => address) referralMap ;
    mapping(address => uint256) referralMap2 ;
   

// constructor stores the address of the owner and the token.

    uint256 public tgeTimestamp;

    constructor (address _token, uint16 year, uint256 month, uint256 day) {
        
        token = IERC20(_token);
        tgeTimestamp = dateToTimestamp(year, month, day);
         referralID = Counters.Counter(1000);
        
    }

    // unix timestamp conversion  
    function dateToTimestamp(uint16 year, uint month, uint day) public pure returns (uint256) {
        require(year >= 1970, "Year must be 1970 or later");
        require(month >= 1 && month <= 12, "Month must be between 1 and 12");
        require(day >= 1 && day <= 31, "Day must be between 1 and 31");
        
        uint timestamp = (uint(year) - 1970) * 31536000; // number of seconds in a non-leap year
        uint i;
        
        // add up the number of seconds for each month
        for (i = 1; i < month; i++) {
            if (i == 2) { // February
                if (isLeapYear(year)) {
                    timestamp += 2505600; // 29 days in a leap year
                } else {
                    timestamp += 2419200; // 28 days in a non-leap year
                }
            } else if (i == 4 || i == 6 || i == 9 || i == 11) {
                timestamp += 2592000; // 30 days in April, June, September, November
            } else {
                timestamp += 2678400; // 31 days in the other months
            }
        }
        
        // add the number of seconds for the given day
        timestamp += (uint256(day) - 1) * 86400; // 86400 seconds in a day
        
        return timestamp;
    }
    
    function isLeapYear(uint16 year) internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        } else if (year % 100 != 0) {
            return true;
        } else if (year % 400 != 0) {
            return false;
        } else {
            return true;
        }
    }


// Through this function TGE date can be altered by the owner .

    function setTGE (uint _TGE) public onlyOwner  {
        require(_TGE>=block.timestamp,"Invalid date entered");
        TGE = _TGE ;
    }

// This function shall create a presale phase and the values are set.

    function createPreSale(uint256 _totalToken , uint256 _tokenPrice , uint _startTime , uint _endTime) external onlyOwner  returns(bool){
        require(_startTime>=block.timestamp,"Invalid date entered");
        require(_startTime < _endTime,"End time should be more than start time");
        
        id.increment();
        preSaleNumber[id.current()].startTime = _startTime;
        preSaleNumber[id.current()].endTime = _endTime;
        preSaleNumber[id.current()].totalTokens = _totalToken;
        preSaleNumber[id.current()].tokenPrice = _tokenPrice;
        emit StorePreSalePhase(id.current(), preSaleNumber[id.current()].startTime, preSaleNumber[id.current()].endTime, preSaleNumber[id.current()].totalTokens, preSaleNumber[id.current()].tokenPrice);
        //emit an event here along with timestamp
        return true;
    }

// this function shall return the category in which the investor belongs .

    function category(uint _amount) public pure returns(uint256){
        
        uint cate;
        if(_amount> 100 && _amount< 500){        
            cate = 1 ;
        }
        else if (_amount> 500 && _amount< 1000){        
            cate = 2;
        }
        else if (_amount> 1000 && _amount< 5000){        
            cate = 3;
        }
        else if (_amount> 5000 && _amount< 10000){        
            cate = 4;
        }
        else if (_amount> 100000 && _amount< 10000){        
            cate = 5;
        }

        return cate;
    }

// this array is to store the address of the investor as per a particular phase

    function pushToArrayById(uint256 _id , address _investor) public {
        require(_investor!= address(0),"Invalid address");
            idList[_id][count.current()] = _investor;
            count.increment();
        
    }

// This is the most important function which locks the investment and other details .

        function lock(uint256 _id ,address _from , uint256 _amount,uint _referralCode ) external {
        require(_amount <= preSaleNumber[_id].totalTokens , "Insufficient tokens try a lower value");
        require(block.timestamp > preSaleNumber[_id].startTime , "Time of presale has not yet arrived");
        require(block.timestamp > preSaleNumber[_id].endTime , "Time of presale has passed");// block.timestamp < preSaleNumber[_id].endTime 
        
        cat = category(_amount);

        address _investor = msg.sender;

        pushToArrayById(_id , _investor);
        
        token.transferFrom(_from, address(this), _amount);
        preSaleInvestorList[_id][cat][_investor].balance = _amount;
        preSaleInvestorList[_id][cat][_investor].invested = true;
        preSaleInvestorList[_id][cat][_investor].locked = true;
        preSaleInvestorList[_id][cat][_investor].claimed = false;
        preSaleInvestorList[_id][cat][_investor].lockTime = TGE;


        // Referral code logic
        if(_referralCode!=0 && referralMap[_referralCode]!=address(0)) {
            preSaleInvestorList[_id][cat][_investor].refferalUsed=true;
            preSaleInvestorList[_id][cat][_investor].refferal=_referralCode;
            token.transferFrom(_from , referralMap[_referralCode] , _amount/20) ;
        }
        else{
            preSaleInvestorList[_id][cat][_investor].refferalUsed=false;
        }
        

    }

// This function is to find the value of the unlocked tokens.

    function unlockedTokens(uint _id , uint _cat) public returns (uint256) {
        
        address _investor = msg.sender;

        if(block.timestamp> TGE && block.timestamp< TGE+10){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance/2;
        }
        if(block.timestamp> TGE+10 && block.timestamp< TGE+20){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance/2;
        }

        return preSaleInvestorList[_id][_cat][_investor].unlockedTokens;

    }

// This is the withdrawal function which shall be used by the investor to withdraw tokens.

    function withdraw(uint _id ,  uint256 _cat , uint256 _claimAmount) external {
        
        address _investor = msg.sender;

        require(preSaleInvestorList[_id][_cat][_investor].invested , "You are not an investor");
        require(block.timestamp > preSaleInvestorList[_id][_cat][_investor].lockTime ,"Tokens have not been unlocked");
        
        
        
        preSaleInvestorList[_id][_cat][_investor].unlockedTokens = unlockedTokens(_id , _cat);
        if(preSaleInvestorList[_id][_cat][_investor].claimed){
            preSaleInvestorList[_id][_cat][_investor].availableForClaim = preSaleInvestorList[_id][_cat][_investor].unlockedTokens - preSaleInvestorList[_id][_cat][_investor].tokenClaimed;
        }
        else{
            preSaleInvestorList[_id][_cat][_investor].availableForClaim = preSaleInvestorList[_id][_cat][_investor].unlockedTokens;
        }

        if(_claimAmount<= preSaleInvestorList[_id][_cat][_investor].availableForClaim) {
            preSaleInvestorList[_id][_cat][_investor].claimed = true;
            preSaleInvestorList[_id][_cat][_investor].locked = false;
            token.transfer(_investor , _claimAmount);
        }
        
    }

// this function is to put values into the array with key value of referral code and sponcer address

    function referal(address _sponcer) public {
        require(referralMap2[_sponcer]==0,"Referal code already generated");
        // uint referralcode=(uint(keccak256(abi.encodePacked(block.timestamp,block.gaslimit,_sponcer))))%10000;
        //     uint i=0;
        //     while(referralcode==referalCodeList[i]) {
        //       referralcode= (uint(keccak256(abi.encodePacked(block.timestamp,block.gaslimit,_sponcer,i))))%10000;
                // i++; 
        //     }        
        referralMap[referralID.current()] = _sponcer;
        referralMap2[_sponcer]=referralID.current();
        referralID.increment();


    
    }

// this function shall return the array with the addresses of the investors of a particular phase.

    // function getPhaseList(uint _id) public view returns(uint256[][] memory ){
    //     return idList[_id] ;
    // }

// this is a redundant function which shall be removed and its used while testing shall be done

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

}