// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


//OpenZeppelin contracts imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

//Struct for each preSale Phase
struct preSalePhase {
        uint256 startTime;
        uint256 endTime;
        uint256 totalTokens;
        uint256 tokenPrice;
}

//Struct for each preSale Investor
struct preSaleInvestor {
        uint256 balance;
        uint256 unlockedTokens;
        uint256 availableForClaim;
        uint256 tokenClaimed;
        uint256 lockTime;
        uint256 category;
        uint256 refferal;
        bool locked;
        bool invested;
        bool claimed;
        bool refferalUsed;
}

contract vesting is Ownable {

using Counters for Counters.Counter;

//State variables to be used in the contract
uint256 public tgeTimestamp;
uint256 public categoryInvestor;
address [][] preSaleEventIDList;
Counters.Counter public preSaleEventID;
Counters.Counter public referralCode;
IERC20 public token;
mapping (uint256 => preSalePhase) preSaleIDToPhaseStruct;
mapping(uint256  => mapping ( uint =>mapping (address => preSaleInvestor))) public preSaleInvestorList;
mapping(uint256 => address) referralCodeToReferralAddress ;
mapping(address => uint256) referralAddressToReferralCode ;

//Event for creation of preSale phase
event preSalePhaseCreated(uint id,uint startTime,uint endTime,uint totalTokens, uint tokenPrice) ; 

//Constructor to initialise
constructor (address _token, uint256 _TGE) {
        token = IERC20(_token);
        tgeTimestamp = _TGE;
        referralID = Counters.Counter(1000);
}

//Function to 
function setTGE (uint256 _tgeTimestamp) public onlyOwner  {
        require(_tgeTimestamp>=block.timestamp,"Invalid date entered");
        tgeTimestamp = _tgeTimestamp ;
}

function createPreSale(uint256 _totalToken , uint256 _tokenPrice , uint256 _startTime , uint256 _endTime) external onlyOwner  returns(bool){
        require(_startTime>=block.timestamp,"Invalid date entered");
        require(_startTime < _endTime,"End time should be more than start time");
        id.increment();
        preSaleNumber[id.current()].startTime = _startTime;
        preSaleNumber[id.current()].endTime = _endTime;
        preSaleNumber[id.current()].totalTokens = _totalToken;
        preSaleNumber[id.current()].tokenPrice = _tokenPrice;
        emit StorePreSalePhase(id.current(), preSaleNumber[id.current()].startTime, preSaleNumber[id.current()].endTime, preSaleNumber[id.current()].totalTokens, preSaleNumber[id.current()].tokenPrice);
        return true;
    }

function categoryOfInvestor(uint _amount) public pure returns(uint256 category){
       require(_amount>=100,"Insufficient investment");
        if(_amount>= 100 && _amount<= 500){        
            category = 1 ;
        }
        else if (_amount> 500 && _amount<= 1000){        
            category = 2;
        }
        else if (_amount> 1000 && _amount<= 5000){        
            category = 3;
        }
        else if (_amount> 5000 && _amount<= 10000){        
            category = 4;
        }
        else if (_amount> 100000){        
            category = 5;
        }
        return category;
    }

function pushToArrayById(uint256 _id , address _investor) public {
        Counters.Counter count;
        require(_investor!= address(0),"Invalid address");
        preSaleEventIDList[_id][count.current()] = _investor;
        count.increment();
}

function getPhaseList(uint _id) public view returns(address[] memory ){
        return preSaleEventIDList[_id] ;
}

function lock(uint256 _id ,address _from , uint256 _amount,uint _referralCode) external payable {
        address _investor = msg.sender;
        require(_amount <= preSaleEventIDList[_id].totalTokens , "Insufficient tokens try a lower value");
        require(block.timestamp >= preSaleEventIDList[_id].startTime , "Time of presale has not yet arrived");
        require(block.timestamp <= preSaleEventIDList[_id].endTime , "Time of presale has passed"); 
        cat = category(_amount);
        pushToArrayById(_id , _investor);
        token.transferFrom(_from, address(this), _amount);
        preSaleInvestorList[_id][cat][_investor].balance = _amount;
        preSaleInvestorList[_id][cat][_investor].invested = true;
        preSaleInvestorList[_id][cat][_investor].locked = true;
        preSaleInvestorList[_id][cat][_investor].claimed = false;
        preSaleInvestorList[_id][cat][_investor].lockTime = block.timestamp;
        if(_referralCode!=0 && referralMap[_referralCode]!=address(0)) {
            preSaleInvestorList[_id][cat][_investor].refferalUsed=true;
            preSaleInvestorList[_id][cat][_investor].refferal=_referralCode;
            token.transferFrom(_from , referralMap[_referralCode] , _amount/20) ;
        }
        else{
            preSaleInvestorList[_id][cat][_investor].refferalUsed=false;
        }
}

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

function withdraw(uint _id ,  uint256 _cat , uint256 _claimAmount) external {
        address _investor = payable(msg.sender);
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

function referal(address _sponsor) public {
        require(referralMap2[_sponsor]==0,"Referal code already generated");
        referralMap[referralID.current()] = _sponsor;
        referralMap2[_sponsor]=referralID.current();
        referralID.increment();
}

function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}