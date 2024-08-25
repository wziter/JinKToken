// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../ERC/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract JinKToken is ERC1155, Ownable{
    uint256 constant MAX_ID = 10000; 
    address constant OWNER_ADDRESS = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    constructor() ERC1155("JinKToken", "JIK") Ownable(OWNER_ADDRESS){
    }

    function _baseUri() internal pure override returns(string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }

    function mint(address _to, uint256 _id, uint256 _value) public onlyOwner {
        _mint(_to, _id, _value, "");
    }

    function mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _values) public onlyOwner {
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_ids[i] < MAX_ID, "id overflow");
        }
        _mintBatch(_to, _ids, _values, "");
    }

}