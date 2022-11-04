// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() { // set contract related
        _checkOwner();
        _;
    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context, Ownable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}




contract FIFFA is Context, Ownable, Pausable, ERC20{
    using SafeMath for uint256;


    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // address public constant BUSDTest = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

    address public dev1 = 0xCCd390B3e220fb74590d5C3339343ab119C8Ec95;
    address public dev2 = 0x67f6d9cb21FaF4D21a635E96d11D91A787E4cDB2;
    address public dev3 = 0x439Ad67675Fb0Cd029b8a912173C7921E9284eae;

    IERC20 private busd;
    AggregatorV3Interface public priceFeed;
    uint256 stopMintTime = 1671375600;//2022-12-18 15:00:00 GMT
    uint256 maxSupply = 1000000000 ether;

    constructor() ERC20("FIFFA", "FIFFA") {
        // busd = IERC20(BUSDTest);
        busd = IERC20(BUSD);
        priceFeed = AggregatorV3Interface(0x87Ea38c9F24264Ec1Fff41B04ec94a97Caf99941);//(BUSD / BNB)
        // priceFeed = AggregatorV3Interface(0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c);
        
    }

    function freemint(address referral) public payable whenNotPaused{
        (,int price,,,) = priceFeed.latestRoundData();
        uint256 payfee = SafeMath.div(uint256(price), 2);
        require(msg.value > payfee, "not enough payment");
        require(SafeMath.add(totalSupply(), 100000 ether) <= maxSupply, "max supply reached");
        

        if(referral != msg.sender && referral != address(0)){
            payable(referral).transfer(SafeMath.div(payfee, 15));
        }
        
        uint256 devfee = SafeMath.div(address(this).balance, 3);

        payable(dev1).transfer(devfee);
        payable(dev2).transfer(devfee);
        payable(dev3).transfer(devfee);
        
        _mint(msg.sender, 100000 ether);

    }
    
    function total() public view returns(uint256){
        return totalSupply();
    }


    function mint(address referral) public payable whenNotPaused beforeLastGame{
        require(msg.value > 0, "not enough payment");
        uint256 totalMint = SafeMath.div(SafeMath.mul(msg.value, 1 ether), 10 ** 10);

        require(SafeMath.add(totalSupply(), totalMint) <= maxSupply, "max supply reached");
        if(referral != msg.sender && referral != address(0)){
            payable(referral).transfer(SafeMath.div(msg.value, 15));
        }

        uint256 devfee = SafeMath.div(address(this).balance, 3);

        payable(dev1).transfer(devfee);
        payable(dev2).transfer(devfee);
        payable(dev3).transfer(devfee);

        _mint(msg.sender, totalMint);
    }

    function returnStopMintTime() public view returns(uint256){
        return stopMintTime;
    }


    modifier beforeLastGame (){
        require(block.timestamp < stopMintTime);
        _;
    }

    function returnRemainSupply() public view returns(uint256){
        return SafeMath.sub(maxSupply, totalSupply());
    }


    function marketingMint(uint256 amount) public payable onlyOwner whenNotPaused beforeLastGame{
        _mint(msg.sender, amount);
        payable(owner()).transfer(msg.value);
    }
}
library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }


    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}