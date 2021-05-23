pragma solidity ^0.5.3;

import "@openzeppelin/upgrades/contracts/upgradeability/ProxyFactory.sol";

contract SimpleTokenFactory is ProxyFactory {
    address[] public tokens;
    address public logic;
    constructor(address _logic) public {
        logic = _logic;
    }

    event TokenCreated(address indexed tokenAddress);

    function createToken(address owner, string calldata name, string calldata symbol, uint8 decimal, uint256 ratio, address _otaddress) external {
        bytes memory payload = abi.encodeWithSignature("initialize(address,string,string,uint8,uint256,address)", owner, name, symbol, decimal, ratio, _otaddress);
        // Deploy minimal proxy
        address token = deployMinimal(logic, payload);
        tokens.push(token);
        emit TokenCreated(token);
    }

}