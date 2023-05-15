// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract vesting is Ownable {
    using Counters for Counters.Counter;

    struct Phase {
        uint256 startTime;
        uint256 endTime;
        uint256 totalTokens;
        uint256 tokenPrice;
    }

    struct Investor {
        uint256 balance;
        uint256 unlockedTokens;
        uint256 availableForClaim;
        uint256 tokenClaimed;
        uint256 lockTime;
        uint256 refferal;
        bool invested;
        bool refferalUsed;
    }

    uint256 public tgeTimestamp;
    IERC20 public token;
    uint256 public categoryInvestor;
    address public investor;
    mapping(uint256 => address[]) public IDWiseInvestorList;
    // address[][] public IDList; // this is no more needed to list the investors in a particular sale
    Counters.Counter public ID;
    Counters.Counter public referralCode;
    mapping(uint256 => Phase) public IDToPhaseMapping;
    mapping(address => uint256) public cumulativeInvestment;
    mapping(uint256 => mapping(address => Investor)) public InvestorMapping;
    mapping(uint256 => address) public referralCodeToReferralAddress;
    mapping(address => uint256) public referralAddressToReferralCode;

    constructor(address _token, uint256 _tgeTimestamp) {
        token = IERC20(_token);
        tgeTimestamp = _tgeTimestamp;
        referralCode = Counters.Counter(1000);
    }

    function createPreSale(
        uint256 _totalToken,
        uint256 _tokenPrice,
        uint256 _startTime,
        uint256 _endTime
    ) external returns (bool) {
        require(_startTime >= block.timestamp, "Invalid date entered");
        require(
            _startTime < _endTime,
            "End time should be more than start time"
        );
        ID.increment();
        IDToPhaseMapping[ID.current()].startTime = _startTime;
        IDToPhaseMapping[ID.current()].endTime = _endTime;
        IDToPhaseMapping[ID.current()].totalTokens = _totalToken;
        IDToPhaseMapping[ID.current()].tokenPrice = _tokenPrice;
        return true;
    }

    function lock(
        uint256 _id,
        address _from,
        uint256 _amount,
        uint256 _referralCode
    ) external {
        investor = msg.sender;
        uint256 tokenAmount = _amount / IDToPhaseMapping[_id].tokenPrice;
        require(
            tokenAmount <= IDToPhaseMapping[_id].totalTokens,
            "Insufficient tokens try a lower value"
        );
        require(
            block.timestamp >= IDToPhaseMapping[_id].startTime,
            "Time of presale has not yet arrived"
        );
        require(
            block.timestamp <= IDToPhaseMapping[_id].endTime,
            "Time of presale has passed"
        );

        IDWiseInvestorList[_id].push(investor);

        token.transferFrom(_from, address(this), tokenAmount);
        cumulativeInvestment[investor] += tokenAmount;
        InvestorMapping[_id][investor].balance += tokenAmount;
        InvestorMapping[_id][investor].invested = true;
        InvestorMapping[_id][investor].lockTime = tgeTimestamp; // discuss this
        // InvestorMapping[_id][investor].lockTime = block.timestamp; // this should be the case

        if (
            _referralCode != 0 &&
            referralCodeToReferralAddress[_referralCode] != address(0)
        ) {
            InvestorMapping[_id][investor].refferalUsed = true;
            InvestorMapping[_id][investor].refferal = _referralCode;
            token.transferFrom(
                _from,
                referralCodeToReferralAddress[_referralCode],
                _amount / 20
            );
        } else {
            InvestorMapping[_id][investor].refferalUsed = false;
        }
    }

    function withdraw(uint256 _id, uint256 _claimAmount) external {
        address _investor = msg.sender;
        require(
            InvestorMapping[_id][_investor].invested,
            "You are not an investor"
        );

        require(
            block.timestamp > InvestorMapping[_id][_investor].lockTime,
            "Tokens have not been unlocked"
        ); // token generation has not begun
        // require(block.timestamp >=tgeTimestamp ,"Tokens have not been unlocked"); // this should be the case


        // Logic for testing vesting schedule

        if (
            block.timestamp >= tgeTimestamp &&
            block.timestamp <= tgeTimestamp + 180
        ) {
            InvestorMapping[_id][_investor].unlockedTokens +=
                InvestorMapping[_id][_investor].balance /
                4;
        }

        if (
            block.timestamp >= tgeTimestamp &&
            block.timestamp <= tgeTimestamp + 360
        ) {
            InvestorMapping[_id][_investor].unlockedTokens +=
                InvestorMapping[_id][_investor].balance /
                4;
        }

        if (
            block.timestamp >= tgeTimestamp &&
            block.timestamp <= tgeTimestamp + 540
        ) {
            InvestorMapping[_id][_investor].unlockedTokens +=
                InvestorMapping[_id][_investor].balance /
                4;
        }

        if (
            block.timestamp >= tgeTimestamp &&
            block.timestamp <= tgeTimestamp + 720
        ) {
            InvestorMapping[_id][_investor].unlockedTokens +=
                InvestorMapping[_id][_investor].balance /
                4;
        }

        // Logic for actual vesting schedule

        // if(block.timestamp>= tgeTimestamp && block.timestamp<= tgeTimestamp+ 30 days){
        //      InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance/10;
        // }
        // else if(block.timestamp> tgeTimestamp+ 30 days && block.timestamp<= tgeTimestamp+ 2*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens +=  InvestorMapping[_id][_investor].balance*11/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 2*30 days && block.timestamp<= tgeTimestamp+ 3*30 days){
        //    InvestorMapping[_id][_investor].unlockedTokens +=InvestorMapping[_id][_investor].balance*12/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 3*30 days && block.timestamp<= tgeTimestamp+ 4*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*13/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 4*30 days && block.timestamp<= tgeTimestamp+ 5*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*14/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 5*30 days && block.timestamp<= tgeTimestamp+ 6*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*26/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 6*30 days && block.timestamp<= tgeTimestamp+ 7*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*27/100;
        // }
        // else if(block.timestamp> tgeTimestamp+7* 30 days && block.timestamp<= tgeTimestamp+ 8*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*29/100;
        // }
        // else if(block.timestamp> tgeTimestamp+8* 30 days && block.timestamp<= tgeTimestamp+ 9*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*30/100;
        // }
        // else if(block.timestamp> tgeTimestamp+9* 30 days && block.timestamp<= tgeTimestamp+ 10*30 days){
        //    InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*32/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 10*30 days && block.timestamp<= tgeTimestamp+ 11*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*33/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 11*30 days && block.timestamp<= tgeTimestamp+ 12*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*45/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 12*30 days && block.timestamp<= tgeTimestamp+ 13*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*47/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 13*30 days && block.timestamp<= tgeTimestamp+ 14*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*49/100;
        // }
        // else if(block.timestamp> tgeTimestamp+14* 30 days && block.timestamp<= tgeTimestamp+ 15*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*51/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 15*30 days && block.timestamp<= tgeTimestamp+ 16*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*53/100;
        // }
        // else if(block.timestamp> tgeTimestamp+16* 30 days && block.timestamp<= tgeTimestamp+ 17*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*55/100;
        // }
        // else if(block.timestamp> tgeTimestamp+17* 30 days && block.timestamp<= tgeTimestamp+ 18*30 days){
        //    InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*57/100;
        // }
        // else if(block.timestamp> tgeTimestamp+18* 30 days && block.timestamp<= tgeTimestamp+ 19*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*71/100;
        // }
        // else if(block.timestamp> tgeTimestamp+19* 30 days && block.timestamp<= tgeTimestamp+ 20*30 days){
        //    InvestorMapping[_id][_investor].unlockedTokens +=InvestorMapping[_id][_investor].balance*73/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 20*30 days && block.timestamp<= tgeTimestamp+ 21*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*76/100;
        // }
        // else if(block.timestamp> tgeTimestamp+21*30 days && block.timestamp<= tgeTimestamp+ 22*30 days){
        //    InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*79/100;
        // }
        // else if(block.timestamp> tgeTimestamp+22*30 days && block.timestamp<= tgeTimestamp+ 23*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*82/100;
        // }
        // else if(block.timestamp> tgeTimestamp+ 23*30 days && block.timestamp<= tgeTimestamp+ 24*30 days){
        //    InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance*85/100;
        // }
        // else if(block.timestamp > tgeTimestamp+ 25*30 days){
        //     InvestorMapping[_id][_investor].unlockedTokens += InvestorMapping[_id][_investor].balance;
        // }

        if (InvestorMapping[_id][_investor].unlockedTokens != 0) {
            InvestorMapping[_id][_investor].availableForClaim =
                InvestorMapping[_id][_investor].unlockedTokens -
                InvestorMapping[_id][_investor].tokenClaimed;
        } else {
            InvestorMapping[_id][_investor].availableForClaim = InvestorMapping[
                _id
            ][_investor].unlockedTokens;
        }
        if (_claimAmount <= InvestorMapping[_id][_investor].availableForClaim) {
            token.transfer(_investor, _claimAmount);
        } else {
            revert(
                "Try a lesser amount as you do not have sufficient funds unlocked for withdrawl as of now"
            );
        }
    }

    //Function to generate referral code
    function generateReferal(address _sponsor) public {
        require(
            referralAddressToReferralCode[_sponsor] == 0,
            "Referal code already generated"
        );
        referralCodeToReferralAddress[referralCode.current()] = _sponsor;
        referralAddressToReferralCode[_sponsor] = referralCode.current();
        referralCode.increment();
    }

    //Function to find category of investor
    function findCategory(uint256 _totalPreSalePhases, address _investor)
        public
        view
        returns (uint256 category)
    {
        uint256 totalInvestment = (cumulativeInvestment[_investor]);
        require(totalInvestment >= 100, "Insufficient investment");
        require(
            block.timestamp >= IDToPhaseMapping[_totalPreSalePhases].endTime,
            "Pre Sale phases are not over yet"
        );
        if (totalInvestment >= 100 && totalInvestment <= 500) {
            category = 1;
        } else if (totalInvestment > 500 && totalInvestment <= 1000) {
            category = 2;
        } else if (totalInvestment > 1000 && totalInvestment <= 5000) {
            category = 3;
        } else if (totalInvestment > 5000 && totalInvestment <= 10000) {
            category = 4;
        } else if (totalInvestment > 100000) {
            category = 5;
        }

        return category;
    }

    //Temporary function for timestamp
    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}