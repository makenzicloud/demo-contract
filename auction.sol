
// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

//import {IERC721} from "sce/sol/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);
    event End(address winner, uint256 amount);

    IERC721 public immutable nft;
    uint256 public immutable nftId;

    address payable public immutable seller;
    uint256 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;
    // mapping from bidder to amount of ETH the bidder can withdraw
    mapping(address => uint256) public bids;

    constructor(address _nft, uint256 _nftId, uint256 _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function start() external {
        // start auction code
        require(msg.sender == seller, "Only the seller can call this function");
        require(!started, "Auction has already started");
        //require(!started, "started");
        // require(msg.sender == seller, "not seller");

        // Transfer ownership of the NFT from the seller to this contract
        nft.transferFrom(seller, address(this), nftId);

        // Set auction started flag to true
        started = true;

        // Set expiration date to 7 days in the future
        endAt = block.timestamp + 7 days;

        // Emit Start event
        emit Start();
    }

    function bid() external payable {
        
        // Cannot bid if auction has not started
        require(started, "Auction has not started yet");
        // Cannot bid if auction has expired
        require(block.timestamp < endAt, "Auction has expired");
        // Amount of ETH sent must be greater than the previous highest bid
        require(msg.value > highestBid, "Bid amount must be higher than the current highest bid");

        // Update the amount of ETH the previous highest bidder can withdraw
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        // Update highestBidder and highestBid
        highestBidder = msg.sender;
        highestBid = msg.value;

        // Emit the Bid event
        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        // Withdrawal code
        uint256 bal = bids[msg.sender];
        bids[msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Withdraw(msg.sender, bal);


    }

    function end() external {
        // FINISH AUCTION
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended =true;
        if (highestBidder != address(0)) {
            nft.safeTransferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);

        } else {
            nft.safeTransferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}
