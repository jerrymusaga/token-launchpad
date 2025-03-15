// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "../interface/IERC721Receiver.sol";

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

    // Reentrancy guard
    uint8 private _notEntered = 1;
    modifier nonReentrant() {
        require(_notEntered == 1, "ReentrancyGuard: reentrant call");
        _notEntered = 2;
        _;
        _notEntered = 1;
    }

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
        address owner = _owners[_tokenId];
        require(owner != address(0), "Invalid token ID");
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable nonReentrant {
        require(ownerOf(_tokenId) == msg.sender || _tokenApprovals[_tokenId] == msg.sender || _operatorApprovals[ownerOf(_tokenId)][msg.sender], "!Auth");
        _transfer(_from, _to, _tokenId);
        // trigger func check
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "!ERC721Implementer");
    }

    function transferFrom(address _from, address _to, uint _tokenId) public payable nonReentrant {
        // unsafe transfer without onERC721Received, used for contracts that dont implement
        require(ownerOf(_tokenId) == msg.sender || _tokenApprovals[_tokenId] == msg.sender || _operatorApprovals[ownerOf(_tokenId)][msg.sender], "!Auth");
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public payable {
        address owner = ownerOf(_tokenId);
        require(owner == msg.sender || _operatorApprovals[owner][msg.sender], "!Owner");
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender, "Can't approve self");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_owners[_tokenId] != address(0), "Token doesn't exist");
        return _tokenApprovals[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function mintTo(address _to, string memory _uri) public {
        require(contractOwner == msg.sender, "!Auth");
        require(_to != address(0), "Cannot mint to zero address");
        uint256 tokenId = nextTokenIdToMint;
        _owners[tokenId] = _to;
        _balances[_to] += 1;
        _tokenUris[tokenId] = _uri;
        emit Transfer(address(0), _to, tokenId);
        nextTokenIdToMint = tokenId + 1;
    }

    // function batchMintTo(address _to, string[] memory _uris) public returns (uint256, uint256) {
    //     require(contractOwner == msg.sender, "!Auth");
    //     require(_to != address(0), "Cannot mint to zero address");
    //     require(_uris.length > 0, "Must provide at least one URI");
        
    //     uint256 startTokenId = nextTokenIdToMint;
    //     uint256 quantity = _uris.length;
        
    //     unchecked {
    //         // More gas efficient batch mint without individual events
    //         for (uint256 i = 0; i < quantity; i++) {
    //             uint256 tokenId = startTokenId + i;
    //             _owners[tokenId] = _to;
    //             _tokenUris[tokenId] = _uris[i];
    //         }
            
    //         _balances[_to] += quantity;
    //         nextTokenIdToMint = startTokenId + quantity;
    //     }
        
       
    //     emit BatchMint(_to, startTokenId, nextTokenIdToMint - 1);
        
    //     return (startTokenId, nextTokenIdToMint - 1);
    // }

    // function batchMintSameURI(address[] memory _recipients, string memory _uri) public returns (uint256, uint256) {
    //     require(contractOwner == msg.sender, "!Auth");
    //     require(_recipients.length > 0, "Must provide at least one recipient");
        
    //     uint256 startTokenId = nextTokenIdToMint;
    //     uint256 quantity = _recipients.length;
        
    //     unchecked {
    //         for (uint256 i = 0; i < quantity; i++) {
    //             address recipient = _recipients[i];
    //             require(recipient != address(0), "Cannot mint to zero address");
                
    //             uint256 tokenId = startTokenId + i;
    //             _owners[tokenId] = recipient;
    //             _balances[recipient] += 1;
    //             _tokenUris[tokenId] = _uri;
    //         }
            
    //         nextTokenIdToMint = startTokenId + quantity;
    //     }
        
       
    //     emit BatchMint(address(0), startTokenId, nextTokenIdToMint - 1);
        
    //     return (startTokenId, nextTokenIdToMint - 1);
    // }

    // function batchMintCustom(address[] memory _recipients, string[] memory _uris) public returns (uint256, uint256) {
    //     require(contractOwner == msg.sender, "!Auth");
    //     require(_recipients.length > 0, "Must provide at least one recipient");
    //     require(_recipients.length == _uris.length, "Recipients and URIs arrays must be same length");
        
    //     uint256 startTokenId = nextTokenIdToMint;
    //     uint256 quantity = _recipients.length;
        
    //     unchecked {
    //         for (uint256 i = 0; i < quantity; i++) {
    //             address recipient = _recipients[i];
    //             require(recipient != address(0), "Cannot mint to zero address");
                
    //             uint256 tokenId = startTokenId + i;
    //             _owners[tokenId] = recipient;
    //             _balances[recipient] += 1;
    //             _tokenUris[tokenId] = _uris[i];
    //         }
            
    //         nextTokenIdToMint = startTokenId + quantity;
    //     }
        
       
    //     emit BatchMint(address(0), startTokenId, nextTokenIdToMint - 1);
        
    //     return (startTokenId, nextTokenIdToMint - 1);
    // }

    // function batchMintSameURIToOne(address _to, string memory _uri, uint256 _quantity) public returns (uint256, uint256) {
    //     require(contractOwner == msg.sender, "!Auth");
    //     require(_to != address(0), "Cannot mint to zero address");
    //     require(_quantity > 0, "Quantity must be greater than 0");
        
    //     uint256 startTokenId = nextTokenIdToMint;
        
    //     unchecked {
    //         // Most gas efficient batch mint - no individual events and same URI/recipient
    //         for (uint256 i = 0; i < _quantity; i++) {
    //             _owners[startTokenId + i] = _to;
    //             _tokenUris[startTokenId + i] = _uri;
    //         }
            
    //         _balances[_to] += _quantity;
    //         nextTokenIdToMint = startTokenId + _quantity;
    //     }
        
       
    //     emit BatchMint(_to, startTokenId, nextTokenIdToMint - 1);
        
    //     return (startTokenId, nextTokenIdToMint - 1);
    // }

    function tokenURI(uint256 _tokenId) public view returns(string memory) {
        require(_owners[_tokenId] != address(0), "Token doesn't exist");
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
        
        unchecked {
            _balances[_from] -= 1;
            _balances[_to] += 1;
        }
        
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }
}