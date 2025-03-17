// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../interface/IERC1155Receiver.sol";

contract ERC1155Token {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    
    string public name;
    string public symbol;
    address public contractOwner;
    
    // Mappings for token data
    // owner => (id => balance)
    mapping(address => mapping(uint256 => uint256)) private _balances;
    // owner => (operator => approved)
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // token id => token uri
    mapping(uint256 => string) private _tokenUris;
    // token id => token metadata
    mapping(uint256 => CollectibleMetadata) private _collectibleMetadata;
    
    
    struct CollectibleMetadata {
        string name;
        uint256 maxSupply;
        uint256 currentSupply;
        bool exists;
    }
    
    // Tracking next token ID
    uint256 public nextTokenIdToMint;
    
    // Reentrancy guard
    uint8 private _notEntered = 1;
    modifier nonReentrant() {
        require(_notEntered == 1, "ReentrancyGuard: reentrant call");
        _notEntered = 2;
        _;
        _notEntered = 1;
    }
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        contractOwner = msg.sender;
        nextTokenIdToMint = 1;
    }
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "ERC1155: caller is not the owner");
        _;
    }
    
    // Create a new collectible token type
    function createCollectible(
        string memory collectibleName, 
        string memory _uri, 
        uint256 maxSupply
    ) public onlyOwner returns (uint256) {
        uint256 id = nextTokenIdToMint;
        _tokenUris[id] = _uri;
        _collectibleMetadata[id] = CollectibleMetadata({
            name: collectibleName,
            maxSupply: maxSupply,
            currentSupply: 0,
            exists: true
        });
        
        emit URI(_uri, id);
        nextTokenIdToMint = id + 1;
        
        return id;
    }
    
    // Mint tokens of a specific type to an address
    function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyOwner {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(_collectibleMetadata[id].exists, "ERC1155: token type does not exist");
        require(
            _collectibleMetadata[id].maxSupply == 0 || 
            _collectibleMetadata[id].currentSupply + amount <= _collectibleMetadata[id].maxSupply, 
            "ERC1155: exceeds maximum supply"
        );
        
        address operator = msg.sender;
        
        _balances[to][id] += amount;
        _collectibleMetadata[id].currentSupply += amount;
        
        emit TransferSingle(operator, address(0), to, id, amount);
        
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }
    
    // Batch mint tokens
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        
        address operator = msg.sender;
        
        for (uint256 i = 0; i < ids.length; i++) {
            require(_collectibleMetadata[ids[i]].exists, "ERC1155: token type does not exist");
            require(
                _collectibleMetadata[ids[i]].maxSupply == 0 || 
                _collectibleMetadata[ids[i]].currentSupply + amounts[i] <= _collectibleMetadata[ids[i]].maxSupply, 
                "ERC1155: exceeds maximum supply"
            );
            
            _balances[to][ids[i]] += amounts[i];
            _collectibleMetadata[ids[i]].currentSupply += amounts[i];
        }
        
        emit TransferBatch(operator, address(0), to, ids, amounts);
        
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }
    
    // Standard ERC1155 functions
    function balanceOf(address account, uint256 id) public view returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[account][id];
    }
    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        
        uint256[] memory batchBalances = new uint256[](accounts.length);
        
        for (uint256 i = 0; i < accounts.length; i++) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        
        return batchBalances;
    }
    
    function setApprovalForAll(address operator, bool approved) public {
        require(msg.sender != operator, "ERC1155: setting approval status for self");
        
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }
    
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public nonReentrant {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        
        address operator = msg.sender;
        
        _balances[from][id] -= amount;
        _balances[to][id] += amount;
        
        emit TransferSingle(operator, from, to, id, amount);
        
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public nonReentrant {
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        
        address operator = msg.sender;
        
        for (uint256 i = 0; i < ids.length; i++) {
            _balances[from][ids[i]] -= amounts[i];
            _balances[to][ids[i]] += amounts[i];
        }
        
        emit TransferBatch(operator, from, to, ids, amounts);
        
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    
    function uri(uint256 id) public view returns (string memory) {
        require(_collectibleMetadata[id].exists, "ERC1155: URI query for nonexistent token");
        return _tokenUris[id];
    }
    
    function getCollectibleInfo(uint256 id) public view returns (
        string memory collectibleName,
        uint256 maxSupply,
        uint256 currentSupply
    ) {
        require(_collectibleMetadata[id].exists, "ERC1155: query for nonexistent token");
        CollectibleMetadata memory metadata = _collectibleMetadata[id];
        return (metadata.name, metadata.maxSupply, metadata.currentSupply);
    }
    
    function totalSupply() public view returns (uint256) {
        return nextTokenIdToMint - 1;
    }
    
    // Internal functions
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
}