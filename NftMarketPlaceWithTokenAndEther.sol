// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// 1: PreSale/Sale(preSale limit 30mints)(sale 1hour) ✅
// 2: WhiteListUser(merkle tree root)
// 4: TotalSupply(1691) ✅
// 5: PriceOfNFT(presale(0.0027) tokens/sale(0.1691)) ✅
// 6: LimitOfNFT(presale(1)/sale(3) ✅
// 7: NFTOnRent(you give nft to use for specific time & after That automatic nft backed)
// 8: mint(presale/sale) ✅
// 9: bulkMint(Actibe on sale)
// 10: Reserve(50 nft Reserve for owner) ✅
// 11: Status(TotalMinted NFTs, Total NFts MInted by owner, PreSale(Start&endTime), Sale(Start&endTime),Price(presale&sale),TotalSuply,Owneraddress,limitofusermint)
// 12: ERC20 half reserved for owner and half of users

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

error SimilarToCurrentBaseURI(string currentBaseURI);
error PriceNotMatched(uint256 price);
error InvalidTypeOrUserType(uint256 _type);
error TimeEndedForPreSale(uint256 _blockTime);
error WrongMethodSelected(uint256 _method);
error NFTLimitReached(uint256 _mintIndex);
error TransferFailed();
error UserNFTLimitReached();

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Practice is ERC721Enumerable, Ownable {
    struct User {
        uint256 userTyprWhiteList;
        uint256 userTyprNonWhiteList;
        uint256 nftCountPreSale;
        uint256 nftCountSale;
    }

    address private wallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256 public blockTime;
    uint256 public preSaleTimestamp;
    uint256 public saleTimestamp;
    uint256 public salePrice = 0.1691 ether;
    uint256 public preSalePrice = 0.0027 ether;
    uint256 public preSalePriceToken = 100;
    uint256 public salePriceToken = 200;
    uint256 immutable maxSupply = 1691;
    IBEP20 public immutable TokenAddress;

    string private baseURI;

    mapping(address => User) public Records;
    mapping(uint256 => string) private _tokenURIs;

    event NFTMinted(address indexed user, uint256 indexed tokenId);
    event UserSaved(
        address indexed userAddress,
        uint256 userTyprWhiteList,
        uint256 userTyprNonWhiteList,
        uint256 nftCountPreSale,
        uint256 nftCountSale
    );

    constructor(address token) ERC721("Practice", "PT") {
        TokenAddress = IBEP20(token);
        blockTime = block.timestamp;
        preSaleTimestamp = blockTime + 1800; // Adding 30 minutes (30 * 60 seconds)
        saleTimestamp = preSaleTimestamp + 3600; // Adding 60 minutes (60 * 60 seconds)
    }

    function saveUser(
        address _userAddress,
        uint256 _userTyprWhiteList,
        uint256 _userTyprNonWhiteList,
        uint256 _nftCountPreSale,
        uint256 _nftCountSale
    ) public {
        User memory newUser = User(
            _userTyprWhiteList,
            _userTyprNonWhiteList,
            _nftCountPreSale,
            _nftCountSale
        );
        Records[_userAddress] = newUser;

        emit UserSaved(
            _userAddress,
            _userTyprWhiteList,
            _userTyprNonWhiteList,
            _nftCountPreSale,
            _nftCountSale
        );
    }

    function checkIfSenderExistsInWhiteList() public view returns (bool) {
        return
            Records[msg.sender].userTyprWhiteList != 0 ||
            Records[msg.sender].userTyprWhiteList != 0;
    }

    function buyNFT(
        string calldata data,
        uint256 _type, // here _type 1 is preSale and _type 2 is sale
        uint256 _method //here _method 1 is to buy nft from eth and _method w is to buy nft from token
    ) public payable {
        if (checkIfSenderExistsInWhiteList() && _type == 1) {
            if (block.timestamp <= preSaleTimestamp) {
                if (_method == 1) {

                    if(Records[msg.sender].nftCountPreSale < 1){
                        revert UserNFTLimitReached();
                    }

                    if (msg.value < preSalePrice) {
                        revert PriceNotMatched(preSalePrice);
                    }

                    uint256 mintIndex = totalSupply() + 50;

                    if (mintIndex > maxSupply) {
                        revert NFTLimitReached(mintIndex);
                    }

                    _safeMint(_msgSender(), mintIndex);
                    _setTokenURI(mintIndex, data);

                    emit NFTMinted(_msgSender(), mintIndex);
                } else if (_method == 2) {

                    if(Records[msg.sender].nftCountPreSale < 1){
                        revert UserNFTLimitReached();
                    }

                    if (msg.value < preSalePriceToken) {    //yhn check karo msg.value say to nhi jay ga tokens
                        revert PriceNotMatched(preSalePrice);
                    }
                    uint256 mintIndex = totalSupply() + 50;
                    if (mintIndex > maxSupply) {
                        revert NFTLimitReached(mintIndex);
                    }

                    bool success = TokenAddress.transferFrom(
                        msg.sender,
                        wallet,
                        preSalePriceToken
                    );
                    if (!success) {
                        revert TransferFailed();
                    }
                    _safeMint(_msgSender(), mintIndex);
                    _setTokenURI(mintIndex, data);

                    emit NFTMinted(_msgSender(), mintIndex);
                } else {
                    revert WrongMethodSelected(_method);
                }
            } else {
                revert TimeEndedForPreSale(block.timestamp);
            }
        } else if (!checkIfSenderExistsInWhiteList() && _type == 2) {
             if (block.timestamp <= saleTimestamp) {
                if (_method == 1) {

                    if(Records[msg.sender].nftCountSale < 3){
                        revert UserNFTLimitReached();
                    }

                    if (msg.value < salePrice) {
                        revert PriceNotMatched(salePrice);
                    }
                    uint256 mintIndex = totalSupply() + 50;
                    if (mintIndex > maxSupply) {
                        revert NFTLimitReached(mintIndex);
                    }
                    _safeMint(_msgSender(), mintIndex);
                    _setTokenURI(mintIndex, data);

                    emit NFTMinted(_msgSender(), mintIndex);
                } else if (_method == 2) {  

                     if(Records[msg.sender].nftCountSale < 3){
                        revert UserNFTLimitReached();
                    }

                    if (msg.value < salePriceToken) {    //yhn check karo msg.value say to nhi jay ga tokens
                        revert PriceNotMatched(salePriceToken);
                    }
                    uint256 mintIndex = totalSupply() + 50;
                    if (mintIndex > maxSupply) {
                        revert NFTLimitReached(mintIndex);
                    }

                    bool success = TokenAddress.transferFrom(
                        msg.sender,
                        wallet,
                        salePriceToken
                    );
                    if (!success) {
                        revert TransferFailed();
                    }
                    _safeMint(_msgSender(), mintIndex);
                    _setTokenURI(mintIndex, data);

                    emit NFTMinted(_msgSender(), mintIndex);
                } else {
                    revert WrongMethodSelected(_method);
                }
            } else {
                revert TimeEndedForPreSale(block.timestamp);
            }
            
        } else {
            revert InvalidTypeOrUserType(_type);
        }
        // if (_opt == 1) {
        //     if (msg.value < preSalePrice) {
        //         revert PriceNotMatched(preSalePrice);
        //     }
        // } else if (_opt == 2) {
        //     if (msg.value < preSalePrice) {
        //         revert PriceNotMatched(preSalePrice);
        //     }
        // } else if (_opt == 3) {
        //     if (msg.value < preSalePrice) {
        //         revert PriceNotMatched(preSalePrice);
        //     }
        // } else if (_opt == 4) {
        //     if (msg.value < preSalePrice) {
        //         revert PriceNotMatched(preSalePrice);
        //     }
        // } else {
        //     // revert ArbitrumNFT_InvalidOption(1, 2, 3, 4);
        // }
        // uint256 mintIndex = totalSupply() + 10001;
        // (bool success, ) = payable(owner()).call{value: msg.value}("");
        // if (!success) {
        //     // revert ArbitrumNFT_TransferFailed();
        // }
        // _safeMint(_msgSender(), mintIndex);
        // _setTokenURI(mintIndex, data);
        // emit NFTMinted(_msgSender(), mintIndex);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        if (
            keccak256(abi.encodePacked(baseURI)) ==
            keccak256(abi.encodePacked(_uri))
        ) {
            revert SimilarToCurrentBaseURI(baseURI);
        }

        baseURI = _uri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // function getBlockTimestamp() public view returns (bool) {
    //     if(blockTime == preSaleTimestamp){
    //         return true;
    //     }
    //     else {
    //         return false;
    //     }
    // }

    function getLatestTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }
}
