// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract Tender is Ownable {
    address public winner;
    //bidders
    address[] public bidders;
    //(address => amount bidded)
    mapping(address => uint256) address_to_amount;
    enum TENDER_STATE {
        CLOSED,
        OPEN,
        WINNER_ANNOUNCED
    }

    TENDER_STATE public tender_status;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        tender_status = TENDER_STATE.CLOSED;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); //answer is in 8 decimals making it into 18 decimals
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // dividing with 10^18 to make it 18 decimals
        return ethAmountInUsd;
    }

    function start_tender() public onlyOwner {
        require(tender_status == TENDER_STATE.CLOSED, "cant start the tender");
        tender_status = TENDER_STATE.OPEN;
    }

    function start_refund(uint256 winner_idx) private {
        uint256 amount;
        for (uint256 i = 0; i < bidders.length; i++) {
            if (i == winner_idx) {
                continue;
            }
            amount = address_to_amount[bidders[i]];
            payable(bidders[i]).transfer(amount);
        }
        tender_status = TENDER_STATE.WINNER_ANNOUNCED;
    }

    function calculate_winner() private {
        uint256 max = 0;
        uint256 winner_idx;
        for (uint256 i = 0; i < bidders.length; i++) {
            if (address_to_amount[bidders[i]] > max) {
                max = address_to_amount[bidders[i]];
                winner_idx = i;
            }
        }
        winner = bidders[winner_idx];
        start_refund(winner_idx);
    }

    function end_tender() public onlyOwner {
        require(tender_status == TENDER_STATE.OPEN, "cant end the tender");
        tender_status = TENDER_STATE.CLOSED;
        calculate_winner();
    }

    function check_the_bidder(address bidder) private view returns (bool) {
        for (uint256 i = 0; i < bidders.length; i++) {
            if (bidder == bidders[i]) {
                return true;
            }
        }
        return false;
    }

    function bid_for_tender() public payable {
        require(tender_status == TENDER_STATE.OPEN, "cant bid for the tender");
        //check for minimum entry for the tender
        uint256 mimimumUSD = 50 * 10**18; // 50 dollars
        require(
            getConversionRate(msg.value) >= mimimumUSD,
            "You need to spend more ETH!"
        );
        address_to_amount[msg.sender] += msg.value;
        if (!check_the_bidder(msg.sender)) {
            bidders.push(msg.sender);
        }
    }

    function withdraw() public onlyOwner {
        require(
            tender_status == TENDER_STATE.WINNER_ANNOUNCED,
            "cant withdraw now ..!"
        );
        payable(msg.sender).transfer(address(this).balance);
    }
}
