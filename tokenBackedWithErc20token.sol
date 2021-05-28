// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


abstract contract OTokenInterface  {
  function balanceOf(address account)  virtual external view returns (uint256);
  function transfer(address recipient, uint256 amount) virtual external returns (bool success);
}

interface TokenRecipient { 
    function tokenFallback(address _from, uint _value, bytes calldata data) external;
}

contract token is Ownable, ERC20, TokenRecipient {

    using SafeMath for uint256;
    OTokenInterface public oTokenContract;
    uint8 public decimal;
    uint256 public commission_numerator = 1; // commission percentage numerator
    uint256 public commission_denominator= 4;// commission percentage denominator
    address public feeCollector;

    constructor(address _owner, string memory _symbol, string memory _name, uint8 _decimal, address _otaddress, address _feecollector) ERC20(_name, _symbol) {
        _owner = msg.sender;
        decimal = _decimal;
        oTokenContract = OTokenInterface(_otaddress);
        feeCollector = _feecollector;
    }

    ////////////////////////////////////////////////////////////////
    //                 modifiers
    ////////////////////////////////////////////////////////////////
    
    modifier onlyNonZeroAddress(address _user) {
        require(_user != address(0), "Zero address not allowed");
        _;
    }

    modifier onlyTokenContract() {
        require(msg.sender == address(oTokenContract), "Only Token contract is allowed");
        _;
    }


    ////////////////////////////////////////////////////////////////
    //                  Only Owner functions
    ////////////////////////////////////////////////////////////////
      /**
     * @notice Function called by token contract wherever tokens are deposited to this contract
     * @dev Only token contract can call.
     * @param _amount the amount of OT to be transferred
     */
    function transferOt(uint _amount) external onlyOwner {
        uint balanceOt = oTokenContract.balanceOf(address(this));
        require(balanceOt >= _amount, 'Insufficiet balance of OT');
        oTokenContract.transfer(owner(), _amount);
        _burn(msg.sender,_amount);

    }

    // removed in future
    function BalanceOfOt() public view returns (uint256) {
        uint256 balanceOt = oTokenContract.balanceOf(address(this));
        return balanceOt;
    }
    
      /**
     * @notice Function called by token contract wherever tokens are deposited to this contract
     * @dev Only token contract can call.
     * @param _from Who transferred, not in use
     * @param _value The user corresponding to which tokens are burned
     * @param data The data supplied by token contract. It will be ignored
     */
    function tokenFallback(address _from, uint _value, bytes calldata data) external override onlyTokenContract {
        uint256 fee = calculateCommission(_value);
        if(fee > 0) _mint(feeCollector, fee);
        _mint(owner(), _value.sub(fee)); // mint to owner always
    }
    
    function decimals() public view virtual override returns (uint8) {
        return decimal;
    }
    
    function calculateCommission(uint256 _amount) public view returns (uint256) {
        return _amount.mul(commission_numerator).div(commission_denominator).div(100);
    }
}
