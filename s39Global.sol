// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

error BnbNFT_OnlyOwnerCanCall();
error BnbNFT_NotEnoughBalanceToWithdraw();
error BnbNFT_TransferFailed();
error BnbNFT_PriceNotMatched(uint256 price);
error BnbNFT_SimilarToCurrentPrice(uint256 currentPrice);
error BnbNFT_SimilarToCurrentBaseURI(string currentBaseURI);
error BnbNFT_InvalidOption(string _err);

contract S39Global is ERC721Enumerable, IERC2981, Ownable {
    /////////////////////////State Varaibles///////////////////////////////////
    AggregatorV3Interface internal priceFeed;
    string private baseURI;
    uint256[9] public categories;
    uint256 public royalty = 100;

    /////////////////////////Mapping///////////////////////////////////
    mapping(uint256 => string) private _tokenURIs;

    /////////////////////////Events///////////////////////////////////
    event NFTMinted(address indexed user, uint256 indexed tokenId);

    constructor(string memory _uri, uint256[9] memory _prices)
        ERC721("s39global.com", "s39global")
    {
        baseURI = _uri;
        for (uint256 i = 0; i < categories.length; i++) {
            categories[i] = _prices[i];
        }
        priceFeed = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526 // bnb
        );
    }

    /////////////////////////Main Functions///////////////////////////////////

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

    function buyNFT(string calldata data, uint256 _opt) public payable {
        if (_opt != 0 && _opt <= categories.length) {
            if (msg.value < getPrice(categories[_opt - 1])) {
                revert BnbNFT_PriceNotMatched(
                    getPrice(categories[_opt - 1])
                );
            }
        } else {
            revert BnbNFT_InvalidOption(
                "Please select option between 1 t o 9"
            );
        }

        uint256 mintIndex = totalSupply() + 11001;
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        if (!success) {
            revert BnbNFT_TransferFailed();
        }
        _safeMint(_msgSender(), mintIndex);
        _setTokenURI(mintIndex, data);

        emit NFTMinted(_msgSender(), mintIndex);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /////////////////////////OnlyOwner Functions///////////////////////////////////

    function setPrice(uint256 _price, uint256 _opt) public onlyOwner {
        if (_opt != 0 && _opt <= categories.length) {
            if (categories[_opt - 1] == _price) {
                revert BnbNFT_SimilarToCurrentPrice(categories[_opt - 1]);
            }

            categories[_opt - 1] = _price;
        } else {
            revert BnbNFT_InvalidOption(
                "Please select option between 1 t o 9"
            );
        }
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        if (
            keccak256(abi.encodePacked(baseURI)) ==
            keccak256(abi.encodePacked(_uri))
        ) {
            revert BnbNFT_SimilarToCurrentBaseURI(baseURI);
        }

        baseURI = _uri;
    }

    // function withdraw() public onlyOwner returns (bool) {
    //     if (address(this).balance == 0) {
    //         revert BnbNFT_NotEnoughBalanceToWithdraw();
    //     }
    //     (bool success, ) = payable(_msgSender()).call{
    //         value: address(this).balance
    //     }("");
    //     if (!success) {
    //         revert BnbNFT_TransferFailed();
    //     }
    //     return true;
    // }

    /////////////////////////View Functions///////////////////////////////////

    function getLatestPrice() internal view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getPrice(uint256 _price) public view returns (uint256) {
        uint256 temp = uint256(getLatestPrice());
        uint256 price = (((_price * 10**18) / temp) * 10**8);
        return price;
    }

    function getOptionPrice(uint256 _opt) public view returns (uint256) {
        if (_opt == 0 && _opt > categories.length) {
            revert BnbNFT_InvalidOption(
                "Please select option between 1 to 9"
            );
        }
        return categories[_opt - 1];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override(IERC2981)
        returns (address Receiver, uint256 royaltyAmount)
    {
        return (owner(), (_salePrice * royalty) / 1000); //100*10 = 1000
    }
}
