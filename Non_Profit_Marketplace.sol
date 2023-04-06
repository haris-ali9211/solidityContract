// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC721 {
    function mintNFT(address _to,uint256 _count) external; 
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function safeTransferFrom(address _from,address _to, uint256 _amount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketplace__PriceNotMet(
    address nftAddress,
    uint256 tokenId,
    uint256 price
);
error NftMarketplace__NoProceeds();
error NftMarketplace__TransferFailed();
error NftMarketplace__ItemIsInAuction();
error NftMarketplace__OwnerCantBuyHisItem();

contract MarketPlace is ReentrancyGuard, Ownable {
///////////////////////////////////Struct////////////////////////////////////
 struct Listing {
        uint256 price;
        address seller;
        bool auction;
    }

    struct AuctionDetails { 
    uint256 tokenId; 
    uint256 basePrice; 
    address highestBidder; 
    uint256 highestBid; 
    uint256 endTime;  
    uint256 starTime; 
    }

    struct Bid { 
    address bidder; 
    uint256 amount; 
    uint256 biddingUnix; 
    }  

 ///////////////////////////State Variables////////////////////////////////////

    IERC721 private nft;
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => mapping(uint256 => AuctionDetails)) private s_auctionDetail;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public s_payedBids;  
    mapping(address => mapping(uint256 => Bid[])) private s_auctionBids; 
    mapping(address => uint256) private s_pendingReturns; 
    uint256[] private s_tokenids;

//////////////////////////////Events////////////////////////////////////////
event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

event ItemCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

///////////////////////////////Modifiers//////////////////////////////////

        modifier notListed(
        address nftAddress,
        uint256 tokenId,
        address owner
    ) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }

        modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert NftMarketplace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    constructor(address _nft) {
    require(_nft.code.length > 0 , "Provide contract Address");
    nft = IERC721(_nft);
 }

//////////////////////////////Main functions/////////////////////////////////
    
function mint(uint256 _count) external onlyOwner {
      nft.mintNFT(msg.sender,_count);   
} 

     function listItem(address nftAddress, uint256 tokenId, uint256 price)
        external
        notListed(nftAddress, tokenId, msg.sender)
        isOwner(nftAddress, tokenId, msg.sender)
      {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }

        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }

        s_listings[nftAddress][tokenId] = Listing(price, msg.sender,false);
        s_tokenids.push(tokenId);
        emit ItemListed(msg.sender, nftAddress, tokenId, price);
    }

     function cancelListing(address nftAddress, uint256 tokenId)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
      {
          if(s_listings[nftAddress][tokenId].auction) {
              AuctionDetails memory item = s_auctionDetail[nftAddress][tokenId];
            require(_checkAuctionStatus(nftAddress,tokenId) == false,"Auction is in progress");
            require(item.highestBidder == address(0), "You are not owner");
            delete (s_auctionDetail[nftAddress][tokenId]);
            delete (s_listings[nftAddress][tokenId]);
            
          }else {
            delete (s_listings[nftAddress][tokenId]);
          }
        removeTokenId(tokenId);
        emit ItemCanceled(msg.sender, nftAddress, tokenId);
    }

    function updateListing(address nftAddress, uint256 tokenId, uint256 newPrice)
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
     {
         if(s_listings[nftAddress][tokenId].auction) {
             revert NftMarketplace__ItemIsInAuction();
         }
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice);
    }

    function getListing() public view returns (Listing[] memory listing) {
        listing = new Listing[](s_tokenids.length); 
       for(uint256 i = 0 ; i < s_tokenids.length ; ++i) {
           listing[i] = s_listings[address(nft)][s_tokenids[i]];
       }
       return listing;
    }

    function removeTokenId(uint256 _tokenId) private {
        for(uint256 i = 0; i<s_tokenids.length; ++i){
            if(_tokenId==s_tokenids[i]){
                for(uint256 j = i; j<s_tokenids.length-1; ++j){
                    s_tokenids[j]= s_tokenids[j+1];
                }
            }
        }
        s_tokenids.pop();
    }

   function buyItems(address nftAddress, uint256 tokenId) external payable isListed(nftAddress, tokenId) nonReentrant {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(listing.auction) {
            revert NftMarketplace__ItemIsInAuction();
        }
        if(msg.sender == listing.seller) {
            revert NftMarketplace__OwnerCantBuyHisItem();
        }
        
        if (msg.value < listing.price) {
            revert NftMarketplace__PriceNotMet(
                nftAddress,
                tokenId,
                listing.price
            );
        }

            (bool success, ) = payable(listing.seller).call{value : msg.value}("");
            if(!success) {
                revert NftMarketplace__TransferFailed();
            }
            delete (s_listings[nftAddress][tokenId]);
            removeTokenId(tokenId);
            nft.safeTransferFrom(
                listing.seller,
                msg.sender,
                tokenId
            );
            emit ItemBought(msg.sender, nftAddress, tokenId, listing.price);
    
    }


///////////////////////////////////Auction///////////////////////////////////////

    function listItemWithAuction(address nftAddress, uint256 tokenId, uint256 _basePrice, uint256 endTime) external notListed(nftAddress, tokenId, msg.sender) isOwner(nftAddress, tokenId, msg.sender) {
        if (_basePrice <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }

            if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        endTime = block.timestamp + endTime;
        s_listings[nftAddress][tokenId] = Listing(_basePrice, msg.sender,true);
        s_auctionDetail[nftAddress][tokenId] = AuctionDetails(tokenId,_basePrice,address(0),0,endTime,block.timestamp);
        s_tokenids.push(tokenId);
        emit ItemListed(msg.sender, nftAddress, tokenId, _basePrice);

    }

    function bidOnItem(address nftAddress, uint256 tokenId) external payable isListed(nftAddress, tokenId) {
         AuctionDetails memory auction = s_auctionDetail[nftAddress][tokenId]; 
         require(_checkAuctionStatus(nftAddress,tokenId) == true , "Auction does not exist"); 
         require(msg.sender != s_listings[nftAddress][tokenId].seller, "You cannot bid in your own auction");

         uint256 amount = s_payedBids[nftAddress][msg.sender][tokenId];
         require(auction.basePrice<=msg.value + amount && auction.highestBid < msg.value + amount, "Please send more fund");
         s_payedBids[nftAddress][msg.sender][tokenId] += msg.value;
         amount = s_payedBids[nftAddress][msg.sender][tokenId];
         auction.highestBid = amount; 
         auction.highestBidder = msg.sender; 
         s_auctionBids[nftAddress][tokenId].push(Bid(msg.sender,amount,block.timestamp));
         s_auctionDetail[nftAddress][tokenId] = auction;
        
    }

    function returnBids(address nftAddress, uint256 tokenId) private {
        Bid[] memory bid = s_auctionBids[nftAddress][tokenId];
        AuctionDetails memory auction = s_auctionDetail[nftAddress][tokenId];
        for(uint256 i= 0 ; i < bid.length ; ++i) {
        if(bid[i].amount != auction.highestBid) {
            s_pendingReturns[bid[i].bidder] += s_payedBids[nftAddress][bid[i].bidder][tokenId];
            delete (s_payedBids[nftAddress][bid[i].bidder][tokenId]);
        }
      }
    }

    function withdraw() public {
        require(s_pendingReturns[msg.sender] != 0, "Don't have Funds");
        uint256 temp = s_pendingReturns[msg.sender];
        s_pendingReturns[msg.sender] = 0;
        (bool success, ) =payable(msg.sender).call{value: temp}("");
        if(!success) {
            revert NftMarketplace__TransferFailed();
        }
    }

    function getItem(address nftAddress, uint256 tokenId) isListed(nftAddress, tokenId) nonReentrant external {
     require(_checkAuctionStatus(nftAddress,tokenId) == false,"Auction is in progress");
        AuctionDetails memory auction = s_auctionDetail[nftAddress][tokenId];
        Listing memory listing = s_listings[nftAddress][tokenId];
        if(auction.highestBidder != msg.sender) {
            revert NftMarketplace__NotOwner();
        }
       
        returnBids(nftAddress,tokenId); 
        delete (s_auctionDetail[nftAddress][tokenId]);
        delete (s_listings[nftAddress][tokenId]);
        delete (s_payedBids[nftAddress][auction.highestBidder][tokenId]);
        removeTokenId(tokenId);
            nft.safeTransferFrom(
                listing.seller,
                msg.sender,
                tokenId
            );
            emit ItemBought(msg.sender, nftAddress, tokenId, listing.price);

    }


///////////////////////////////////View Functions///////////////////////////////////////////

    function getPendingReturns(address account)public view returns(uint256){ 
    return s_pendingReturns[account]; 
    }

    function getHighestBid(address nftAddress,uint256 tokenId)public view returns(uint256){ 
    AuctionDetails memory auction = s_auctionDetail[nftAddress][tokenId]; 
    return auction.highestBid; 
    } 

    function getHighestBidder(address nftAddress,uint256 tokenId)public view returns(address){ 
    AuctionDetails memory auction = s_auctionDetail[nftAddress][tokenId]; 
    return auction.highestBidder; 
    }

    function getLastTime(address nftAddress,uint256 tokenId) public view returns(uint256){ 
    AuctionDetails memory auction = s_auctionDetail[nftAddress][tokenId]; 
    return auction.endTime; 
    }

    function getLastTime() public view returns(uint256){ 
        return block.timestamp; 
    }

    
    function getAllTokenId() public view returns(uint256[] memory _tokenIds) {
        return s_tokenids;
    }

    function _checkAuctionStatus(address nftAddress,uint256 tokenId) isListed(nftAddress, tokenId) public view returns(bool){  
    AuctionDetails memory auction = s_auctionDetail[nftAddress][tokenId];
    if(auction.endTime > block.timestamp) {
        return true;
    }else {
        return false;
    } 
    }   

}

// function mint(uint256 _count) external onlyOwner {
//     //  uint256 temp = nft.totalSupply() + 1;
//       nft.mintNFT(msg.sender,_count);
//     //  if(_count == 1) {
//     //  listItem(address(nft),temp,_price);   
//     //  tokenids.push(temp);  
//     //  }else {
//     //  uint256 temp2 = nft.totalSupply();

//     // for(uint256 i = temp ; i <= temp2 ; ++i) {
//     //  listItem(address(nft),i,_price);
//     //  tokenids.push(i);
//     // }
//     //  }
    
// } 
