// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "../interface/IERC721OnReceiver.sol";

contract ERC721Token {
    string public name;
    string public symbol;
    uint public nextTokenIdToMint;
    address public contractOwner;

    // token id => owners
    mapping(uint => address) internal _owners;
    //owner => token count
    mapping(address => uint) internal _balances;
    //token id => approved address
    mapping(uint => address) internal _tokenApprovals;
    //owner => (operator => yes/no)
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    //token id => token uri
    mapping(uint => string) internal _tokenUris;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event BatchMint(address indexed _to, uint256 _fromTokenId, uint256 _toTokenId);

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
        nextTokenIdToMint = 1;
        contractOwner = msg.sender;
    }

    function balanceOf(address _owner) public view returns(uint){
        require(_owner != address(0), "! Addr0");
        return _balances[_owner];
    }

    function ownerOf(uint _tokenId) public view returns(address){
        return _owners[_tokenId];
    }

     function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable {
        require(ownerOf(_tokenId) == msg.sender || _tokenApprovals[_tokenId] == msg.sender || _operatorApprovals[ownerOf(_tokenId)][msg.sender], "!Auth");
        _transfer(_from, _to, _tokenId);
        // trigger func check
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "!ERC721Implementer");
    }

    function transferFrom(address _from, address _to, uint _tokenId) public payable {
        // unsafe transfer without onERC721Received, used for contracts that dont implement
        require(ownerOf(_tokenId) == msg.sender || _tokenApprovals[_tokenId] == msg.sender || _operatorApprovals[ownerOf(_tokenId)][msg.sender], "!Auth");
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public payable {
        require(ownerOf(_tokenId) == msg.sender, "!Owner");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function mintTo(address _to, string memory _uri) public {
        require(contractOwner == msg.sender, "!Auth");
        _owners[nextTokenIdToMint] = _to;
        _balances[_to] += 1;
        _tokenUris[nextTokenIdToMint] = _uri;
        emit Transfer(address(0), _to, nextTokenIdToMint);
        nextTokenIdToMint += 1;
    }

    /**
     * @dev Batch mint multiple tokens to a single address with different URIs
     * @param _to Address to mint the tokens to
     * @param _uris Array of URIs for each token
     * @return The starting and ending token IDs that were minted
     */
    function batchMintTo(address _to, string[] memory _uris) public returns (uint256, uint256) {
        require(contractOwner == msg.sender, "!Auth");
        require(_to != address(0), "Cannot mint to zero address");
        require(_uris.length > 0, "Must provide at least one URI");
        
        uint256 startTokenId = nextTokenIdToMint;
        uint256 quantity = _uris.length;
        
        for (uint256 i = 0; i < quantity; i++) {
            _owners[nextTokenIdToMint] = _to;
            _tokenUris[nextTokenIdToMint] = _uris[i];
            emit Transfer(address(0), _to, nextTokenIdToMint);
            nextTokenIdToMint += 1;
        }
        
        // Update balance once instead of in the loop for gas efficiency
        _balances[_to] += quantity;
        
        // Emit batch mint event
        emit BatchMint(_to, startTokenId, nextTokenIdToMint - 1);
        
        return (startTokenId, nextTokenIdToMint - 1);
    }

    /**
     * @dev Batch mint tokens with the same URI to multiple recipients
     * @param _recipients Array of recipient addresses
     * @param _uri Single URI to use for all tokens
     * @return The starting and ending token IDs that were minted
     */
    function batchMintSameURI(address[] memory _recipients, string memory _uri) public returns (uint256, uint256) {
        require(contractOwner == msg.sender, "!Auth");
        require(_recipients.length > 0, "Must provide at least one recipient");
        
        uint256 startTokenId = nextTokenIdToMint;
        uint256 quantity = _recipients.length;
        
        for (uint256 i = 0; i < quantity; i++) {
            address recipient = _recipients[i];
            require(recipient != address(0), "Cannot mint to zero address");
            
            _owners[nextTokenIdToMint] = recipient;
            _balances[recipient] += 1;
            _tokenUris[nextTokenIdToMint] = _uri;
            emit Transfer(address(0), recipient, nextTokenIdToMint);
            nextTokenIdToMint += 1;
        }
        
        // Emit batch mint event
        emit BatchMint(address(0), startTokenId, nextTokenIdToMint - 1);
        
        return (startTokenId, nextTokenIdToMint - 1);
    }

    /**
     * @dev Batch mint with complete customization (different recipients and URIs)
     * @param _recipients Array of recipient addresses
     * @param _uris Array of URIs for each token
     * @return The starting and ending token IDs that were minted
     */
    function batchMintCustom(address[] memory _recipients, string[] memory _uris) public returns (uint256, uint256) {
        require(contractOwner == msg.sender, "!Auth");
        require(_recipients.length > 0, "Must provide at least one recipient");
        require(_recipients.length == _uris.length, "Recipients and URIs arrays must be same length");
        
        uint256 startTokenId = nextTokenIdToMint;
        uint256 quantity = _recipients.length;
        
        for (uint256 i = 0; i < quantity; i++) {
            address recipient = _recipients[i];
            require(recipient != address(0), "Cannot mint to zero address");
            
            _owners[nextTokenIdToMint] = recipient;
            _balances[recipient] += 1;
            _tokenUris[nextTokenIdToMint] = _uris[i];
            emit Transfer(address(0), recipient, nextTokenIdToMint);
            nextTokenIdToMint += 1;
        }
        
        // Emit batch mint event
        emit BatchMint(address(0), startTokenId, nextTokenIdToMint - 1);
        
        return (startTokenId, nextTokenIdToMint - 1);
    }

        /**
     * @dev Mint multiple tokens with the same URI to a single recipient
     * @param _to Address to mint the tokens to
     * @param _uri Single URI to use for all tokens
     * @param _quantity Number of tokens to mint
     * @return The starting and ending token IDs that were minted
     */
    function batchMintSameURIToOne(address _to, string memory _uri, uint256 _quantity) public returns (uint256, uint256) {
        require(contractOwner == msg.sender, "!Auth");
        require(_to != address(0), "Cannot mint to zero address");
        require(_quantity > 0, "Quantity must be greater than 0");
        
        uint256 startTokenId = nextTokenIdToMint;
        
        for (uint256 i = 0; i < _quantity; i++) {
            _owners[nextTokenIdToMint] = _to;
            _tokenUris[nextTokenIdToMint] = _uri;
            emit Transfer(address(0), _to, nextTokenIdToMint);
            nextTokenIdToMint += 1;
        }
        
        // Update balance once instead of in the loop
        _balances[_to] += _quantity;
        
        // Emit batch mint event
        emit BatchMint(_to, startTokenId, nextTokenIdToMint - 1);
        
        return (startTokenId, nextTokenIdToMint - 1);
    }

    function tokenURI(uint256 _tokenId) public view returns(string memory) {
        return _tokenUris[_tokenId];
    }

    function totalSupply() public view returns(uint256) {
        return nextTokenIdToMint - 1;
    }

    // Internal Functions
    function _checkOnERC721Received(address from, address to, uint tokenId, bytes memory data) private returns(bool){
        // check if to is a contract, if yes, to.code.length will always > 0
        if(to.code.length > 0){
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval){
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason){
                if(reason.length == 0){
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }else {
            return true;
        }
    }

    //unsafe transfer
    function _transfer(address _from, address _to, uint _tokenId) internal{
        require(ownerOf(_tokenId) == _from, "! owner");
        require(_to != address(0), "!ToAdd0");

        delete _tokenApprovals[_tokenId];
        _balances[_from] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}