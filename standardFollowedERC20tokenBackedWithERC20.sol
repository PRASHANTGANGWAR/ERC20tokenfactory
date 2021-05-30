// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract OTokenInterface {
    function balanceOf(address account) external view virtual returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool success);
}

interface TokenRecipient {
    function tokenFallback(
        address _from,
        uint256 _value,
        bytes calldata data
    ) external;
}

contract token is Ownable, ERC20, TokenRecipient {
    // attach library functions
    using SafeMath for uint256;
    using SafeERC20 for OTokenInterface;
    using Address for address;

    //event
    event TaxFreeUserUpdate(address _user, bool _isWhitelisted, string _type);

    //public variables
    OTokenInterface public oTokenContract;

    //private variables
    uint8 private decimal;
    // to hold commissions on each token transfer

    uint256 public commission_numerator = 1; // commission percentage numerator
    uint256 public commission_denominator = 4; // commission percentage denominator
    // olegacy admin address fees transferred to this address
    address public olegacyAdmin;

    // mappings
    mapping(address => bool) public isTaxFreeSender; // tokens transferred from these users won't be charged with fee
    mapping(address => bool) public isTaxFreeRecipeint; // if token transferred to these addresses won't be charged

    constructor(
        string memory _symbol,
        string memory _name,
        uint8 _decimal,
        address _otaddress,
        address _olegacyAdmin
    )
        onlyNonZeroAddress(_olegacyAdmin)
        isContractaAddress(_otaddress)
        ERC20(_name, _symbol)
    {
        decimal = _decimal;
        oTokenContract = OTokenInterface(_otaddress);
        olegacyAdmin = _olegacyAdmin;
    }

    ////////////////////////////////////////////////////////////////
    //                 modifiers
    ////////////////////////////////////////////////////////////////

    modifier onlyNonZeroAddress(address _user) {
        require(_user != address(0), "Zero address not allowed");
        _;
    }

    modifier onlyTokenContract() {
        require(
            msg.sender == address(oTokenContract),
            "Only Token contract is allowed"
        );
        _;
    }

    modifier isContractaAddress(address _addressContract) {
        require(
            _addressContract.isContract(),
            "Only Token contract is allowed"
        );
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
    function transferOt(uint256 _amount, address _receiver)
        external
        onlyOwner
        onlyNonZeroAddress(_receiver)
    {
        uint256 balanceOt = oTokenContract.balanceOf(address(this));
        require(balanceOt >= _amount, "Insufficiet balance of OT");
        oTokenContract.transfer(_receiver, _amount);
        _burn(msg.sender, _amount);
    }

    /**
     * @notice Function called by token contract wherever tokens are deposited to this contract
     * @dev Only token contract can call.
     * @param _from Who transferred, not utlised
     * @param _value The amount transferred
     * @param data The data supplied by token contract. It will be ignored
     */
    function tokenFallback(
        address _from,
        uint256 _value,
        bytes calldata data
    ) external override onlyTokenContract {
        uint256 fee = calculateCommission(_value);
        if (fee > 0) _mint(olegacyAdmin, fee);
        _mint(owner(), _value.sub(fee)); // mint to owner always
    }

    ////////////////////////////////////////////////////////////////
    //                  overriden functions
    ////////////////////////////////////////////////////////////////
    function decimals() public view virtual override returns (uint8) {
        return decimal;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        uint256 fee = calculateCommission(amount);
        uint256 feeToZowner = fee.div(2);
        if (fee > 0) _transfer(_msgSender(), olegacyAdmin, feeToZowner);
        if (fee.sub(feeToZowner) > 0)
            _transfer(_msgSender(), owner(), feeToZowner);
        _transfer(_msgSender(), recipient, amount.sub(fee));
    }

    /**
     * @notice check transer fee
     * @dev Does not checks if sender/recipient is whitelisted
     * @param _amount The intended amount of transfer
     * @return uint256 Calculated commission
     */
    function calculateCommission(uint256 _amount)
        public
        view
        returns (uint256)
    {
        return
            _amount.mul(commission_numerator).div(commission_denominator).div(
                100
            );
    }

    /**
     * @notice Add/Remove a whitelisted recipient. Token transfer to this address won't be taxed
     * @dev Only Deputy owner can call
     * @param _users The array of addresses to be whitelisted/blacklisted
     * @param _isSpecial true means user will be added; false means user will be removed
     * @return Bool value
     */
    function updateTaxFreeRecipient(address[] memory _users, bool _isSpecial)
        public
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Zero address not allowed");
            isTaxFreeRecipeint[_users[i]] = _isSpecial;
            emit TaxFreeUserUpdate(_users[i], _isSpecial, "Recipient");
        }

        return true;
    }

    /**
     * @notice Add/Remove a whitelisted sender. Token transfer from this address won't be taxed
     * @dev Only Deputy owner can call
     * @param _users The array of addresses to be whitelisted/blacklisted
     * @param _isSpecial true means user will be added; false means user will be removed
     * @return Bool value
     */
    function updateTaxFreeSender(address[] memory _users, bool _isSpecial)
        public
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "Zero address not allowed");
            isTaxFreeSender[_users[i]] = _isSpecial;
            emit TaxFreeUserUpdate(_users[i], _isSpecial, "Sender");
        }
        return true;
    }
}
