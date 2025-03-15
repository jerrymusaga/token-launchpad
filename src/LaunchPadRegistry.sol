// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// LaunchPadRegistry.sol - Core registry contract
contract LaunchPadRegistry {
    event TokenOwnershipTransferred(address indexed previousOwner, address indexed newOwner, address indexed tokenAddress);
    
    address[] public allErc721Tokens;
    address[] public allErc20Tokens;

    mapping(address => address[]) public erc721CreatorTokenAddresses;
    mapping(address => address[]) public erc20CreatorTokenAddresses;
    
    // O(1) lookups for creator verification
    mapping(address => mapping(address => bool)) public tokenCreators; // token => creator => bool

    // Factory addresses
    address public erc20Factory;
    address public erc721Factory;
    
    // Only allow factories to call certain functions
    modifier onlyFactory() {
        require(
            msg.sender == erc20Factory || msg.sender == erc721Factory,
            "Only factory contracts can call this function"
        );
        _;
    }
    
    constructor(address _erc20Factory, address _erc721Factory) {
        erc20Factory = _erc20Factory;
        erc721Factory = _erc721Factory;
    }
    
    function isCreatorOf(address _tokenAddress, address _creator) public view returns (bool) {
        return tokenCreators[_tokenAddress][_creator];
    }
    
    // Function to register a new token (called by factories)
    function registerErc20Token(address _creator, address _tokenAddress, string memory _name, string memory _symbol) external onlyFactory {
        allErc20Tokens.push(_tokenAddress);
        erc20CreatorTokenAddresses[_creator].push(_tokenAddress);
        tokenCreators[_tokenAddress][_creator] = true;
    }
    
    function registerErc721Token(address _creator, address _tokenAddress, string memory _name, string memory _symbol) external onlyFactory {
        allErc721Tokens.push(_tokenAddress);
        erc721CreatorTokenAddresses[_creator].push(_tokenAddress);
        tokenCreators[_tokenAddress][_creator] = true;
    }
    
    function transferTokenOwnership(address _tokenAddress, address _newOwner) external {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        require(_newOwner != address(0), "New owner cannot be zero address");
        
        // Update mapping
        tokenCreators[_tokenAddress][msg.sender] = false;
        tokenCreators[_tokenAddress][_newOwner] = true;
        
        emit TokenOwnershipTransferred(msg.sender, _newOwner, _tokenAddress);
    }
    
    // Getter functions
    function getAllErc721TokenCounts() external view returns(uint){
        return allErc721Tokens.length;
    }
    
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
        
        uint validCount = 0;
        for (uint i = 0; i < allTokens.length; i++) {
            if (tokenCreators[allTokens[i]][_creator]) {
                validCount++;
            }
        }
        
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