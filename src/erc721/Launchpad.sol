// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import "./ERC721Token.sol";
import "./ERC1155Token.sol";
import "../erc20/ERC20.sol";

contract LaunchPad {
    event Erc721TokenCreated(address indexed creator, address indexed tokenAddress, string name, string symbol);
    event Erc20TokenCreated(address indexed creator, address indexed tokenAddress, string name, string symbol, uint quantity);
    event Erc1155TokenCreated(address indexed creator, address indexed tokenAddress, string name, string symbol);
    event TokenOwnershipTransferred(address indexed previousOwner, address indexed newOwner, address indexed tokenAddress);
    event CollectibleCreated(address indexed tokenAddress, uint256 indexed collectibleId, string name, uint256 maxSupply);
    event NFTMinted(address indexed tokenAddress, address indexed to, uint256 tokenId);
    event CollectibleNFTMinted(address indexed tokenAddress, address indexed to, uint256 collectibleId, uint256 amount);
    
    address[] public allErc721Tokens;
    address[] public allErc20Tokens;
    address[] public allErc1155Tokens;

    mapping(address => address[]) public erc721CreatorTokenAddresses;
    mapping(address => address[]) public erc20CreatorTokenAddresses;
    mapping(address => address[]) public erc1155CreatorTokenAddresses;
    
    // O(1) lookups for creator verification - this is the source of truth
    mapping(address => mapping(address => bool)) public tokenCreators; // token => creator => bool

    constructor(){}
    
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
    
    // Create a new ERC1155 token contract for collectibles
    function createCollectibleContract(string memory _name, string memory _symbol) external returns (address) {
        ERC1155Token newToken = new ERC1155Token(_name, _symbol);
        
        address tokenAddress = address(newToken);
        allErc1155Tokens.push(tokenAddress);
        erc1155CreatorTokenAddresses[msg.sender].push(tokenAddress);
        tokenCreators[tokenAddress][msg.sender] = true;
        
        emit Erc1155TokenCreated(msg.sender, tokenAddress, _name, _symbol);
        
        return tokenAddress;
    }
    
    // Create a new collectible type within an ERC1155 contract
    function createCollectible(
        address _tokenAddress,
        string memory _name,
        string memory _uri,
        uint256 _maxSupply
    ) external returns (uint256) {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        
        ERC1155Token token = ERC1155Token(_tokenAddress);
        uint256 collectibleId = token.createCollectible(_name, _uri, _maxSupply);
        
        emit CollectibleCreated(_tokenAddress, collectibleId, _name, _maxSupply);
        
        return collectibleId;
    }
    
    // Mint individual NFT in ERC721 contract
    function mintNFT(address _tokenAddress, address _to, string memory _uri) external {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        
        ERC721Token token = ERC721Token(_tokenAddress);
        uint256 tokenId = token.nextTokenIdToMint();
        token.mintTo(_to, _uri);
        
        emit NFTMinted(_tokenAddress, _to, tokenId);
    }
    
    // Mint collectible NFTs (one type) in ERC1155 contract
    function mintCollectible(
        address _tokenAddress,
        address _to,
        uint256 _collectibleId,
        uint256 _amount,
        bytes memory _data
    ) external {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        
        ERC1155Token token = ERC1155Token(_tokenAddress);
        token.mint(_to, _collectibleId, _amount, _data);
        
        emit CollectibleNFTMinted(_tokenAddress, _to, _collectibleId, _amount);
    }
    
    // Batch mint collectible NFTs (multiple types) in ERC1155 contract
    function batchMintCollectible(
        address _tokenAddress,
        address _to,
        uint256[] memory _collectibleIds,
        uint256[] memory _amounts,
        bytes memory _data
    ) external {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        require(_collectibleIds.length == _amounts.length, "Collectible IDs and amounts length mismatch");
        
        ERC1155Token token = ERC1155Token(_tokenAddress);
        token.mintBatch(_to, _collectibleIds, _amounts, _data);
        
        for (uint256 i = 0; i < _collectibleIds.length; i++) {
            emit CollectibleNFTMinted(_tokenAddress, _to, _collectibleIds[i], _amounts[i]);
        }
    }
    
    // Get collectible information from ERC1155 contract
    function getCollectibleInfo(address _tokenAddress, uint256 _collectibleId) external view returns (
        string memory name,
        uint256 maxSupply,
        uint256 currentSupply
    ) {
        ERC1155Token token = ERC1155Token(_tokenAddress);
        return token.getCollectibleInfo(_collectibleId);
    }
    
    // Get collectible URI from ERC1155 contract
    function getCollectibleURI(address _tokenAddress, uint256 _collectibleId) external view returns (string memory) {
        ERC1155Token token = ERC1155Token(_tokenAddress);
        return token.uri(_collectibleId);
    }
    
    // Get user's balance of a collectible
    function balanceOfCollectible(address _tokenAddress, address _owner, uint256 _collectibleId) external view returns (uint256) {
        ERC1155Token token = ERC1155Token(_tokenAddress);
        return token.balanceOf(_owner, _collectibleId);
    }
    
    function transferTokenOwnership(address _tokenAddress, address _newOwner) external {
        require(isCreatorOf(_tokenAddress, msg.sender), "You are not the creator of this Token");
        require(_newOwner != address(0), "New owner cannot be zero address");
        
        // Update mapping only - O(1) operation
        tokenCreators[_tokenAddress][msg.sender] = false;
        tokenCreators[_tokenAddress][_newOwner] = true;
        
        emit TokenOwnershipTransferred(msg.sender, _newOwner, _tokenAddress);
    }

    function getAllErc20TokenCounts() external view returns(uint){
        return allErc20Tokens.length;
    }
    
    function getAllErc721TokenCounts() external view returns(uint){
        return allErc721Tokens.length;
    }
    
    function getAllErc1155TokenCounts() external view returns(uint){
        return allErc1155Tokens.length;
    }
}