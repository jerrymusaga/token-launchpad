// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import "./ERC721Token.sol";
import "../erc20/ERC20.sol";

contract LaunchPad {
    event Erc721TokenCreated(address indexed creator, address indexed tokenAddress, string name, string symbol);
    event Erc20TokenCreated(address indexed creator, address indexed tokenAddress, string name, string symbol, uint quantity);
    event TokenOwnershipTransferred(address indexed previousOwner, address indexed newOwner, address indexed tokenAddress);
    
    address[] public allErc721Tokens;
    address[] public allErc20Tokens;

    mapping(address => address[]) public erc721CreatorTokenAddresses;
    mapping(address => address[]) public erc20CreatorTokenAddresses;
    
    // O(1) lookups for creator verification - this is the source of truth
    mapping(address => mapping(address => bool)) public tokenCreators; // token => creator => bool

    function isCreatorOf(address _tokenAddress, address _creator) public view returns (bool) {
        return tokenCreators[_tokenAddress][_creator];
    }

    function createToken(string memory _name, string memory _symbol, uint _quantity) external returns(address){
        Erc20Token newToken = new Erc20Token(_name, _symbol);
        newToken.mint(msg.sender, _quantity);

        address tokenAddress = address(newToken);
        allErc20Tokens.push(tokenAddress);
        erc20CreatorTokenAddresses[msg.sender].push(tokenAddress);
        tokenCreators[tokenAddress][msg.sender] = true;

        emit Erc20TokenCreated(msg.sender, tokenAddress, _name, _symbol, _quantity);
        return tokenAddress;
    }

    function createNFT(string memory _name, string memory _symbol, string memory _uri, bool _mintInitial) external returns(address){
        ERC721Token newToken = new ERC721Token(_name, _symbol);

        if (_mintInitial && bytes(_uri).length > 0){
            newToken.mintTo(msg.sender, _uri);
        }
       
        address tokenAddress = address(newToken);
        allErc721Tokens.push(tokenAddress);
        erc721CreatorTokenAddresses[msg.sender].push(tokenAddress);
        tokenCreators[tokenAddress][msg.sender] = true;

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

    function batchMintSameToOne(address _tokenAddress, address _to, string memory _uri, uint256 _quantity) external returns (uint, uint) {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        ERC721Token token = ERC721Token(_tokenAddress);
        return token.batchMintSameURIToOne(_to, _uri, _quantity);
    }

    function transferTokenOwnership(address _tokenAddress, address _newOwner) external {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        require(_newOwner != address(0), "New owner cannot be zero address");
        
        // Update mapping only - O(1) operation
        tokenCreators[_tokenAddress][msg.sender] = false;
        tokenCreators[_tokenAddress][_newOwner] = true;
        
        emit TokenOwnershipTransferred(msg.sender, _newOwner, _tokenAddress);
    }

    function getAllErc721TokenCounts() external view returns(uint){
        return allErc721Tokens.length;
    }

    // Modified getter function that filters results based on current ownership
    function getErc721TokensByCreator(address _creator) external view returns(address[] memory) {
        address[] memory allTokens = erc721CreatorTokenAddresses[_creator];
        
        // First count valid tokens
        uint validCount = 0;
        for (uint i = 0; i < allTokens.length; i++) {
            if (tokenCreators[allTokens[i]][_creator]) {
                validCount++;
            }
        }
        
        // Then create a filtered array
        address[] memory result = new address[](validCount);
        uint index = 0;
        for (uint i = 0; i < allTokens.length; i++) {
            if (tokenCreators[allTokens[i]][_creator]) {
                result[index] = allTokens[i];
                index++;
            }
        }
        
        return result;
    }

    function getErc721TokensByCreatorCount(address _creator) external view returns(uint){
        address[] memory allTokens = erc721CreatorTokenAddresses[_creator];
        
        uint validCount = 0;
        for (uint i = 0; i < allTokens.length; i++) {
            if (tokenCreators[allTokens[i]][_creator]) {
                validCount++;
            }
        }
        
        return validCount;
    }

    function getAllErc20TokenCounts() external view returns(uint){
        return allErc20Tokens.length;
    }

   
    function getErc20TokensByCreator(address _creator) external view returns(address[] memory) {
        address[] memory allTokens = erc20CreatorTokenAddresses[_creator];
        
        // First count valid tokens
        uint validCount = 0;
        for (uint i = 0; i < allTokens.length; i++) {
            if (tokenCreators[allTokens[i]][_creator]) {
                validCount++;
            }
        }
        
        // Then create a filtered array
        address[] memory result = new address[](validCount);
        uint index = 0;
        for (uint i = 0; i < allTokens.length; i++) {
            if (tokenCreators[allTokens[i]][_creator]) {
                result[index] = allTokens[i];
                index++;
            }
        }
        
        return result;
    }

    function getErc20TokensByCreatorCount(address _creator) external view returns(uint){
        address[] memory allTokens = erc20CreatorTokenAddresses[_creator];
        
        uint validCount = 0;
        for (uint i = 0; i < allTokens.length; i++) {
            if (tokenCreators[allTokens[i]][_creator]) {
                validCount++;
            }
        }
        
        return validCount;
    }

    function isERC721Token(address _tokenAddress) public view returns (bool) {
        for (uint i = 0; i < allErc721Tokens.length; i++) {
            if (allErc721Tokens[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }

    function isERC20Token(address _tokenAddress) public view returns (bool) {
        for (uint i = 0; i < allErc20Tokens.length; i++) {
            if (allErc20Tokens[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}