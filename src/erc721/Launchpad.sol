// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;
import "./ERC721.sol";

contract LaunchPad {
    address[] public allTokens;
    mapping(address => address[]) public creatorTokens;

    function createNFT(string memory _name, string memory _symbol, string memory _uri, bool _mintInitial) external returns(address){
        ERC721Token newToken = new ERC721Token(_name, _symbol);
        newToken.mintTo(msg.sender, _uri);

        address tokenAddress = address(newToken);
        allTokens.push(tokenAddress);
    }
}