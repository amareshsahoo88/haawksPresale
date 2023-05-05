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
        // bool locked;
        bool invested;
        uint claimed;
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
// Id=Catagory=address=struct
mapping(uint256  => mapping ( uint =>mapping (address => preSaleInvestor))) public preSaleInvestorList;
mapping(uint256 => address) referralCodeToReferralAddress ;
mapping(address => uint256) referralAddressToReferralCode ;

//Event for creation of preSale phase
event preSalePhaseCreated(uint id,uint startTime,uint endTime,uint totalTokens, uint tokenPrice) ; 

//Constructor to initialise
constructor (address _token, uint256 _TGE) {
        token = IERC20(_token);
        tgeTimestamp = _TGE;
        uint referralID = Counters.Counter(1000);
}

//Function to 
function setTGE (uint256 _tgeTimestamp) public onlyOwner  {
        require(_tgeTimestamp>=block.timestamp,"Invalid date entered");
        tgeTimestamp = _tgeTimestamp ;
}

function createPreSale(uint256 _totalToken , uint256 _tokenPrice , uint256 _startTime , uint256 _endTime) external onlyOwner  returns(bool){
        require(_startTime>=block.timestamp,"Invalid date entered");
        require(_startTime < _endTime,"End time should be more than start time");
        preSaleEventID.increment();
        preSalePhase[preSaleEventID.current()].startTime = _startTime;
        preSalePhase[preSaleEventID.current()].endTime = _endTime;
        preSalePhase[preSaleEventID.current()].totalTokens = _totalToken;
        preSalePhase[preSaleEventID.current()].tokenPrice = _tokenPrice;
        emit preSalePhaseCreated(preSaleEventID.current(), preSalePhase[preSaleEventID.current()].startTime, preSalePhase[preSaleEventID.current()].endTime, preSalePhase[preSaleEventID.current()].totalTokens, preSalePhase[preSaleEventID.current()].tokenPrice);
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
        categoryInvestor = categoryOfInvestor(_amount);
        pushToArrayById(_id , _investor);

 // Determine the price of the token based on the presale ID
            uint tokenPrice ;
            if (_id == 1) {
                tokenPrice = 10; // 0.1 USD per token
            } else if (_id == 2) {
                tokenPrice = 12; // 0.12 USD per token
            } else if (_id == 3) {
                tokenPrice = 14; // 0.14 USD per token
            } else if (_id == 4) {
                tokenPrice = 16; // 0.16 USD per token
            } else if (_id == 5) {
                tokenPrice = 18; // 0.18 USD per token
            } else if (_id == 6) {
                tokenPrice = 20; // 0.20 USD per token
            } else if (_id == 7) {
                tokenPrice = 25; // 0.25 USD per token
            } else {
                revert("Invalid presale ID"); // Revert if the presale ID is invalid
            }

            uint tokenAmount = _amount / tokenPrice ;


        token.transferFrom(_from, address(this), tokenAmount);
        preSaleInvestorList[_id][categoryInvestor][_investor].balance += tokenAmount;
        preSaleInvestorList[_id][categoryInvestor][_investor].invested = true;
        // preSaleInvestorList[_id][categoryInvestor][_investor].locked = true;
        // preSaleInvestorList[_id][categoryInvestor][_investor].claimed = false;
        preSaleInvestorList[_id][categoryInvestor][_investor].lockTime = block.timestamp;//?
        if(_referralCode!=0 && referralCodeToReferralAddress[_referralCode]!=address(0)) {
            preSaleInvestorList[_id][categoryInvestor][_investor].refferalUsed=true;
            preSaleInvestorList[_id][categoryInvestor][_investor].refferal=_referralCode;
            token.transferFrom(_from , referralCodeToReferralAddress[_referralCode] , _amount/20) ;
        }
        else{
            preSaleInvestorList[_id][categoryInvestor][_investor].refferalUsed=false;
        }
}

function withdraw(uint _id ,  uint256 _cat , uint256 _claimAmount) external {
        address _investor = payable(msg.sender);
        require(preSaleInvestorList[_id][_cat][_investor].invested , "You are not an investor");
        require(block.timestamp > preSaleInvestorList[_id][_cat][_investor].lockTime ,"Tokens have not been unlocked");
        // preSaleInvestorList[_id][_cat][_investor].unlockedTokens = unlockedTokens(_id , _cat);
        if(block.timestamp> tgeTimestamp && block.timestamp<= tgeTimestamp+ 30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance/10;
        }
        else if(block.timestamp> tgeTimestamp+ 30 days && block.timestamp<= tgeTimestamp+ 2*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*11/100;
        }
        else if(block.timestamp> tgeTimestamp+ 2*30 days && block.timestamp<= tgeTimestamp+ 3*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*12/100;
        }
        else if(block.timestamp> tgeTimestamp+ 3*30 days && block.timestamp<= tgeTimestamp+ 4*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*13/100;
        }
        else if(block.timestamp> tgeTimestamp+ 4*30 days && block.timestamp<= tgeTimestamp+ 5*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*14/100;
        }
        else if(block.timestamp> tgeTimestamp+ 5*30 days && block.timestamp<= tgeTimestamp+ 6*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*26/100;
        }
        else if(block.timestamp> tgeTimestamp+ 6*30 days && block.timestamp<= tgeTimestamp+ 7*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*27/100;
        }
        else if(block.timestamp> tgeTimestamp+7* 30 days && block.timestamp<= tgeTimestamp+ 8*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*29/100;
        }
        else if(block.timestamp> tgeTimestamp+8* 30 days && block.timestamp<= tgeTimestamp+ 9*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*30/100;
        }
        else if(block.timestamp> tgeTimestamp+9* 30 days && block.timestamp<= tgeTimestamp+ 10*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*32/100;
        }
        else if(block.timestamp> tgeTimestamp+ 10*30 days && block.timestamp<= tgeTimestamp+ 11*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*33/100;
        }
        else if(block.timestamp> tgeTimestamp+ 11*30 days && block.timestamp<= tgeTimestamp+ 12*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*45/100;
        }
        else if(block.timestamp> tgeTimestamp+ 12*30 days && block.timestamp<= tgeTimestamp+ 13*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*47/100;
        }
        else if(block.timestamp> tgeTimestamp+ 13*30 days && block.timestamp<= tgeTimestamp+ 14*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*49/100;
        }
        else if(block.timestamp> tgeTimestamp+14* 30 days && block.timestamp<= tgeTimestamp+ 15*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*51/100;
        }
        else if(block.timestamp> tgeTimestamp+ 15*30 days && block.timestamp<= tgeTimestamp+ 16*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*53/100;
        }
        else if(block.timestamp> tgeTimestamp+16* 30 days && block.timestamp<= tgeTimestamp+ 17*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*55/100;
        }
        else if(block.timestamp> tgeTimestamp+17* 30 days && block.timestamp<= tgeTimestamp+ 18*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*57/100;
        }
        else if(block.timestamp> tgeTimestamp+18* 30 days && block.timestamp<= tgeTimestamp+ 19*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*71/100;
        }
        else if(block.timestamp> tgeTimestamp+19* 30 days && block.timestamp<= tgeTimestamp+ 20*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*73/100;
        }
        else if(block.timestamp> tgeTimestamp+ 20*30 days && block.timestamp<= tgeTimestamp+ 21*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*76/100;
        }
        else if(block.timestamp> tgeTimestamp+21*30 days && block.timestamp<= tgeTimestamp+ 22*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*79/100;
        }
        else if(block.timestamp> tgeTimestamp+22*30 days && block.timestamp<= tgeTimestamp+ 23*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*82/100;
        }
        else if(block.timestamp> tgeTimestamp+ 23*30 days && block.timestamp<= tgeTimestamp+ 24*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance*85/100;
        }
        else if(block.timestamp > tgeTimestamp+ 25*30 days){
            preSaleInvestorList[_id][_cat][_investor].unlockedTokens += preSaleInvestorList[_id][_cat][_investor].balance;
        }
        

        if(preSaleInvestorList[_id][_cat][_investor].unlockedTokens!= 0){
            preSaleInvestorList[_id][_cat][_investor].availableForClaim = preSaleInvestorList[_id][_cat][_investor].unlockedTokens - preSaleInvestorList[_id][_cat][_investor].tokenClaimed;
        }
        else{
            preSaleInvestorList[_id][_cat][_investor].availableForClaim = preSaleInvestorList[_id][_cat][_investor].unlockedTokens;
        }
        if(_claimAmount<= preSaleInvestorList[_id][_cat][_investor].availableForClaim) {
            // preSaleInvestorList[_id][_cat][_investor].claimed = true;
            // preSaleInvestorList[_id][_cat][_investor].locked = false;
            token.transfer(_investor , _claimAmount);
        }
        else {
            revert("Try a lesser amount as you do not have sufficient funds unlocked for withdrawl as of now");
        }
}

function referal(address _sponsor) public {
        require(referralAddressToReferralCode[_sponsor]==0,"Referal code already generated");
        referralCodeToReferralAddress[referralID.current()] = _sponsor;
        referralAddressToReferralCode[_sponsor]=referralID.current();
        referralID.increment();
}

function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}