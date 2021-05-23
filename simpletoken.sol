pragma solidity ^0.5.0;

import "./ERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./SafeMath.sol";
import "./ERC20Detailed.sol";
import  "./IERC20.sol";

contract OTokenInterface is IERC20 {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 tokens) public returns (bool success);

}

contract simpleToken is Initializable, ERC20 ,ERC20Detailed {

    address public owner;
    uint8 public decimal;
    uint256 public blocked_token;
    uint256 public ratio; //ratio to OTOKEN
    OTokenInterface public oTokenContract;

    function initialize(address _owner, string memory _symbol, string memory _name, uint8 _decimal, uint256 _ratio, address _otaddress)  public initializer   {
        ERC20Detailed.initialize(_name, _symbol, _decimal);
        owner = _owner;
        decimal = _decimal;
        ratio = _ratio;
        oTokenContract = OTokenInterface(_otaddress);
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function mint(uint _amount) external onlyOwner{
        uint balanceOt = oTokenContract.balanceOf(address(this));
        require(balanceOt.sub(blocked_token).mul(ratio) >= _amount, "OT Balance should be sufficient to mint token amount * ratio");
        require(_amount.mul(ratio) >= ratio, "Min. token to be minted corresponding to OT"); // ratio to 1 OT should be minted for token 
        blocked_token = blocked_token.add(_amount.div(ratio));
        _mint(owner, _amount); // mint to owner always
    }

    function burn(uint _amount) external onlyOwner { 
          require(blocked_token.mul(ratio) >= _amount, "Balance should be greater than equal to _amount");
         blocked_token = blocked_token.sub(_amount);
        _burn(msg.sender,_amount);
    }

    function transferOt(uint _amount) external onlyOwner {
        uint balanceOt = oTokenContract.balanceOf(address(this));
        require(balanceOt.sub(blocked_token) >= _amount, "Balance should be greater than 0 & unblocked tokens");
      oTokenContract.transfer(owner, _amount);
    }

    function BalanceOfOt() public view returns (uint256) {
        uint256 balanceOt = oTokenContract.balanceOf(address(this));
        return balanceOt;
    }
}