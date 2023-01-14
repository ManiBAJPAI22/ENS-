// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import { StringUtils } from "./libraries/StringUtils.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

address payable public owner;

constructor(string memory _tld) ERC721 ("Original Gangster Name Service", "OGNS") payable {
  owner = payable(msg.sender);
  tld = _tld;
  console.log("%s name service deployed", _tld);
}

contract Domains is ERC721URIStorage {

   using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string public tld;
  string svgPartOne = '<svg width="512px" height="512px" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg"><path fill="#000" d="M256 27.93l-77 92.47-5.8-2c-40.9-13.6-71.3-27.85-99.6-51.64 1.29 28.41 4.96 62.54 11.24 95.44 7.89 41.4 20.06 80.8 34.66 102.7 15.5 23.2 31.5 38.4 38.8 55.5 3.6 8.5 4.4 18.5.1 27.7-3.9 7.9-10.9 14.9-21.1 22.2 1.3 19.6 11.7 39.8 31.1 59.2 20.2 20.3 50.1 39.2 87.6 54.6 37.5-15.4 67.4-34.3 87.6-54.6 19.4-19.4 29.8-39.6 31.1-59.2-10.2-7.3-17.2-14.3-21.1-22.2-4.3-9.2-3.5-19.2.1-27.7 7.3-17.1 23.3-32.3 38.8-55.5 14.6-21.9 26.8-61.3 34.7-102.7 6.2-32.9 9.9-67.03 11.2-95.44-28.3 23.79-58.7 38.04-99.6 51.64l-5.8 2zm0 77.87l30.6 61.1H265v62h50.5l43.9-58.6-6.7-5-11.7-8.7 61-30.7-11.9 67.2-16.2-12.1-49.4 65.9H265v142h21.6L256 450l-24.1-48.1-6.5-13H247v-142h-59.5L138.1 181l-16.2 12.1-11.9-67.2 48 24.2 13 6.5-18.4 13.7 43.9 58.6H247v-62h-21.6z"/></svg>';
  string svgPartTwo = '</text></svg>';

  mapping(string => address) public domains;
  // Checkout our new mapping! This will store values
  mapping(string => string) public records;
  mapping(string => string) public emails;
  mapping(string => string) public links;
  mapping(string => string) private personal;

  

  // We make the contract "payable" by adding this to the constructor
  constructor(string memory _tld) payable ERC721 ("Original Gangster Name Service","OGNS"){
    tld = _tld;
    console.log("%s name service deployed", _tld);
  }
		
  
  function register(string calldata name) public payable {
    require(domains[name] == address(0));

    uint256 _price = price(name);
    require(msg.value >= _price, "Not enough Matic paid");
    
    // Combine the name passed into the function  with the TLD
    string memory _name = string(abi.encodePacked(name, ".", tld));
    // Create the SVG (image) for the NFT with the name
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    uint256 newRecordId = _tokenIds.current();
    uint256 length = StringUtils.strlen(name);
    string memory strLen = Strings.toString(length);

    console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

    // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "',
        _name,
        '", "description": "A domain on the Original Gangster name service", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(finalSvg)),
        '","length":"',
        strLen,
        '"}'
      )
    );

    string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

    console.log("\n--------------------------------------------------------");
    console.log("Final tokenURI", finalTokenUri);
    console.log("--------------------------------------------------------\n");

    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, finalTokenUri);
    domains[name] = msg.sender;

    _tokenIds.increment();
  }
  // constructor() {
  //     console.log("Yo yo, I am a contract and I am smart");
  // }

  // This function will give us the price of a domain based on length
  function price(string calldata name) public pure returns(uint) {
    uint len = StringUtils.strlen(name);
    require(len > 0);
    if (len == 3) {
      return 5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
    } else if (len == 4) {
      return 3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
    } else {
      return 1 * 10**17;
    }
  }

  function getAddress(string calldata name) public view returns (address) {
      return domains[name];
  }

  function setRecord(string calldata name, string calldata record) public {
      // Check that the owner is the transaction sender
      require(domains[name] == msg.sender);
      records[name] = record;
  }

  function getRecord(string calldata name) public view returns(string memory) {
      return records[name];
  }
}
modifier onlyOwner() {
  require(isOwner());
  _;
}

function isOwner() public view returns (bool) {
  return msg.sender == owner;
}

function withdraw() public onlyOwner {
  uint amount = address(this).balance;
  
  (bool success, ) = msg.sender.call{value: amount}("");
  require(success, "Failed to withdraw Matic");
} 