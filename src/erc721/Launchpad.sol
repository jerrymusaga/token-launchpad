// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import "./ERC721.sol";

contract LaunchPad {
    event Erc721TokenCreated(address indexed creator, address indexed tokenAddress, string name, string symbol);
    address[] public allErc721Tokens;
    mapping(address => address[]) public erc721CreatorTokenAddresses;

    function isCreatorOf(address _tokenAddress, address _creator) public view returns (bool) {
        address[] memory tokens = erc721CreatorTokenAddresses[_creator];
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    function createNFT(string memory _name, string memory _symbol, string memory _uri, bool _mintInitial) external returns(address){
        ERC721Token newToken = new ERC721Token(_name, _symbol);

        if (_mintInitial && bytes(_uri).length > 0){
            newToken.mintTo(msg.sender, _uri);
        }
       
        address tokenAddress = address(newToken);
        allErc721Tokens.push(tokenAddress);
        erc721CreatorTokenAddresses[msg.sender].push(tokenAddress);

        emit Erc721TokenCreated(msg.sender, tokenAddress, _name, _symbol);

        return tokenAddress;
    }

    function batchMint(address _tokenAddress, address _to, string[] memory _uris) external returns(uint, uint) {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        ERC721Token token = ERC721Token(_tokenAddress);
        return token.batchMintTo(_to, _uris);
    }

    function batchMintSame(
        address _tokenAddress,
        address[] memory _recipients, 
        string memory _uri
    ) external returns (uint, uint) {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        
        ERC721Token token = ERC721Token(_tokenAddress);
        return token.batchMintSameURI(_recipients, _uri);
    }

    function batchMintCustom(address _tokenAddress, address[] memory _recipients, string[] memory _uris) external returns(uint, uint){
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        ERC721Token token = ERC721Token(_tokenAddress);
        return token.batchMintCustom(_recipients, _uris);
    }

    function batchMintSameToOne(address _tokenAddress,address _to, string memory _uri,uint256 _quantity) external returns (uint, uint) {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        ERC721Token token = ERC721Token(_tokenAddress);
        return token.batchMintSameURIToOne(_to, _uri, _quantity);
    }

    function getAllErc721TokenCounts() external view returns(uint){
        return allErc721Tokens.length;
    }

    function getErc721TokensByCreator(address _creator) external view returns(address[] memory){
        return erc721CreatorTokenAddresses[_creator];
    }

    function getErc721TokensByCreatorCount(address _creator) external view returns(uint){
        return erc721CreatorTokenAddresses[_creator].length;
    }
}