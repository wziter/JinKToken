// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC1155Metadata_URI  {
     function uri(uint256 _id) external view returns (string memory);
     
}