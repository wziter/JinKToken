// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IERC165.sol";
import "./IERC1155Metadata_URI.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC1155 is IERC165, IERC1155Metadata_URI, IERC1155TokenReceiver, IERC1155{
    mapping (uint256 tokenId => mapping(address owner => uint256 amount)) _balances;
    mapping (address owner => mapping(address operator => bool)) _operatorApprovals;

    string public name;
    string public symbol;

    event LogonERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data);
    event LogonERC1155BatchReceived(address _operator, address _from, uint256[]  _ids, uint256[]  _values, bytes  _data);

    error ERRonERC1155Received();
    error ERRonERC1155BatchReceived();

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // implement IERC165
    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == type(IERC165).interfaceId ||              //0x01ffc9a7
            interfaceID == type(IERC1155).interfaceId ||                //0xd9b67a26
            interfaceID == type(IERC1155TokenReceiver).interfaceId;     //0x4e2312e0                                                   
    }

    // implement IERC1155Metadata_URI
    function uri(uint256 _id) external view override returns (string memory){
        string memory baseUri = _baseUri();
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, Strings.toString(_id))) : "";
    }
    function _baseUri() internal view virtual returns(string memory) {
        return "";
    }

    // implement IERC1155TokenReceiver
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4) {
        emit LogonERC1155Received(_operator, _from, _id, _value, _data);
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));

    }
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4) {
        emit LogonERC1155BatchReceived(_operator, _from, _ids, _values, _data);
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    // implement IERC1155
    function balanceOf(address _owner, uint256 _id) external view override returns (uint256) {
        require(_owner != address(0), "ERC1155: address zero is not a valid owner for get balance");
        return _balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view override returns (uint256[] memory) {
        require(_owners.length == _ids.length, "ERC1155: arr _owners and _ids length not equal!");
        
        uint256[] memory retBalances = new uint256[](_owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            retBalances[i] = this.balanceOf(_owners[i], _ids[i]);
        }
        return retBalances;
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        require(_owner != address(0), "ERC1155: address zero is not a valid owner for get approve");
        require(_operator != address(0), "ERC1155: address zero is not a valid operator for get approve");
        return _operatorApprovals[_owner][_operator];
    }

     function setApprovalForAll(address _operator, bool _approved) external override{
        require(_operator != address(0), "ERC1155: address zero is not a valid operator for set approve");
        require(msg.sender != _operator, "ERC1155: setting approval status for self");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
     }
    
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external override {
        require(_from == msg.sender || this.isApprovedForAll(_from, msg.sender), "ERC1155: msg.sender has no power to transfer!");
        require(_to != address(0), "ERC1155: address zero is not vaild for transfer!");
        require(this.balanceOf(_from, _id) >= _value, "ERC1155: not enough value!");

        _balances[_id][_from] -= _value;
        _balances[_id][_to] += _value;
        emit TransferSingle(msg.sender, _from, _to, _id, _value);
        
        _checkTransfer(msg.sender, _from, _to, _id, _value, _data);
    }

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external override {
        require(_from == msg.sender || this.isApprovedForAll(_from, msg.sender), "ERC1155: msg.sender has no power batch transfer!");
        require(_to != address(0), "ERC1155: address zero is not vaild for batch transfer!");
        require(_ids.length == _values.length, "ERC1155: arr ids length not equal values, so can not batch transfer!");

        for (uint256 i = 0; i < _ids.length; i++) {
            require(this.balanceOf(_from, _ids[i]) >= _values[i], "ERC1155: not enough value for batch transfer!");
            _balances[_ids[i]][_from] -= _values[i];
            _balances[_ids[i]][_to] += _values[i];
        }
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);
        _checkBatchTransfer(msg.sender, _from, _to, _ids, _values, _data);
    }

    function _checkTransfer(address operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {
        if (_to.code.length > 0) {
            bytes4 ret =  this.onERC1155Received(operator, _from, _id, _value, _data);
            if (ret != bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))){ //0xf23a6e61
                revert ERRonERC1155Received();
            }
        }
    }

    function _checkBatchTransfer(address operator, address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes memory _data) internal {
         if (_to.code.length > 0) {
            bytes4 ret = this.onERC1155BatchReceived(operator, _from, _ids, _values, _data);
            if (ret != bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))) { //0xbc197c81
                revert ERRonERC1155BatchReceived();
            }
        }
    }

    function _mint(address _to, uint256 _id, uint256 _value, bytes memory _data) internal  {
        require(_to != address(0), "ERC1155 _mint: zero address is invalid!");
        _balances[_id][_to] += _value;
        emit TransferSingle(msg.sender, address(0), _to, _id, _value);
        _checkTransfer(msg.sender, address(0), _to, _id, _value, _data);
    }

    function _mintBatch(address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes memory _data) internal {
        require(_to != address(0), "ERC1155 _mint: zero address is invalid!");
        require(_ids.length == _values.length, "ERC1155 _mintBatch: array ids length not equal values!");
        for (uint256 i = 0; i < _ids.length; i++) {
            _balances[_ids[i]][_to] += _values[i];
        }
        emit TransferBatch(msg.sender, address(0), _to, _ids, _values);
        _checkBatchTransfer(msg.sender, address(0), _to, _ids, _values, _data);
    }

    function _burn(address _from, uint256 _id, uint256 _value) internal {
        require(_from != address(0), "ERC1155 _burn: burn from the zero address");
        require(_balances[_id][_from] >= _value, "ERC1155 _burn:not enough value!");
        _balances[_id][_from] -= _value;
        emit TransferSingle(msg.sender, _from, address(0), _id, _value); 
    }

    function _burnBatch(address _from, uint256[] calldata _ids, uint256[] calldata _values) internal {
        require(_from != address(0), "ERC1155 _burnBatch: _burnBatch from the zero address");
        require(_ids.length == _values.length, "ERC1155 _burnBatch: array ids length not equal values!");

        for (uint256 i = 0; i < _ids.length; i++) {
            require(_balances[_ids[i]][_from] >= _values[i], "ERC1155 _burnBatch:not enough value!");
            _balances[_ids[i]][_from] -= _values[i];
        }
        emit TransferBatch(msg.sender, _from, address(0), _ids, _values);
    }

}