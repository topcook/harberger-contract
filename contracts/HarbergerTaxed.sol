// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HarbergerTaxed_v1
 */
contract HarbergerTaxed_v13 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct HarbergerInfo {
        // wallet address of current owner
        address currentOwner;
        // duration of the ownership in seconds
        uint32 ownershipPeriod;
        // timestamp when ownership started
        uint256 startTime;
        // timestamp when ownership ended
        uint256 endTime;
        // value of Harberger Hike
        uint16 harbergerHike;
        // value of Harberger Tax
        uint16 harbergerTax;
        // value of Initial Price
        uint256 initialPrice;
        // value of previous auction Price
        uint256 previousAuctionPrice;
        // value of string will be sold
        string valueOfString;
    }

    // address of the ERC20 token
    // IERC20 private _token;

    address public issuer;

    uint8 decimals = 18;

    // value for minutes in a day
    uint32 private SECONDS_IN_DAY;

    // instance of Harberger
    HarbergerInfo public harbergerInfo;

    // event TokenVested(address indexed accout, uint256 amount);

    event OwnershipPeriodChangedEvent(uint32 ownershipPeriod);

    event OwnershipChangedEvent(address indexed account);

    event DelayEndTimeOfOwnershipEvent(address indexed account);

    event ValueOfStringChangedEvent(string indexed valueOfString);

    event ValueOfSettingsChangedEvent();

    modifier notIssuer() {
        require(msg.sender != issuer, "You are the issuer of Harberger");
        _;
    }

    modifier onlyIssuer() {
        require(msg.sender == issuer, "You are not the issuer of Harberger");
        _;
    }

    modifier onlyCurrentOwnerOfHarberger() {
        require(getCurrentOwner() == msg.sender, "You are not the current owner of Harberger");
        _;
    }

    receive() external payable { }

    fallback() external payable { }        

    /**
     * @dev Creates a vesting contract.
     */
    constructor() {

        // _token = IERC20(token_);

        issuer = msg.sender;

        SECONDS_IN_DAY = 30; // 30s for testnet,  60 * 60 * 24s for mainnet;

        uint32 ownershipPeriod = SECONDS_IN_DAY * 7; // SECONDS_IN_DAY * 7 for mainnet , 90 for testnet
        // timestamp when ownership started
        uint256 startTime = block.timestamp;
        // timestamp when ownership ended
        // uint32 endTime = block.timestamp + ownershipPeriod;
        uint256 endTime = block.timestamp + 60 * 60 * 24 * 365 * 50;// endTime of issuer: 50 years
        // value of Harberger Hike
        uint16 harbergerHike = 20;
        // value of Harberger Tx
        uint16 harbergerTax = 10;
        // value of Initial Price
        uint256 initialPrice = 0.001 ether;
        // value of string
        string memory valueOfString = "first string";

        // create Harberger
        createHarbergerInfo(
            ownershipPeriod,
            startTime,
            endTime,
            harbergerHike,
            harbergerTax,
            initialPrice,
            valueOfString
        );
    }

    /**
     * @notice Creates a new vesting schedule for an account.
     * @param _ownershipPeriod duration of the ownership in seconds
     * @param _startTime timestamp when ownership started
     * @param _endTime timestamp when ownership ended
     * @param _harbergerHike value of Harberger Hike
     * @param _harbergerTax value of Harberger Tax
     * @param _initialPrice value of Initial Price
     * @param _valueOfString value of string will be sold
     */
    function createHarbergerInfo(
        uint32 _ownershipPeriod,
        uint256 _startTime,
        uint256 _endTime,
        uint16 _harbergerHike,
        uint16 _harbergerTax,
        uint256 _initialPrice,
        string memory _valueOfString
    ) internal onlyIssuer {
        require(_ownershipPeriod > 0, "Ownership period must be > 0");
        require(_startTime >= block.timestamp, "Ownership start time must be after the present");
        require(_initialPrice > 0, "Initial Price must be > 0");

        harbergerInfo = HarbergerInfo(
            // address(this),
            msg.sender,
            _ownershipPeriod,
            _startTime,
            _endTime,
            _harbergerHike,
            _harbergerTax,
            _initialPrice,
            0,//previousAuctionPrice
            _valueOfString
        );
    }

    function getIssuer() public view returns (address) {
        return issuer;
    }

    function getCurrentOwner() public view returns (address) {
        if (harbergerInfo.endTime > block.timestamp)
            return harbergerInfo.currentOwner;
        else 
            return issuer;
    }

    function getOwnershipPeriod() public view returns (uint32) {
        uint32 days_ = harbergerInfo.ownershipPeriod / SECONDS_IN_DAY;
        return days_;
    }

    function getHarbergerHike() public view returns (uint32) {
        return harbergerInfo.harbergerHike;
    }

    function getHarbergerTax() public view returns (uint32) {
        return harbergerInfo.harbergerTax;
    }

    function getInitialPrice() public view returns (uint256) {
        return harbergerInfo.initialPrice;
    }

    function getCurrentPrice() public view returns (uint256) {
        return harbergerInfo.previousAuctionPrice;
    }

    function getValueOfString() public view returns (string memory) {
        return harbergerInfo.valueOfString;
    }

    /**
     * @notice Transfer ownership of string to other wallet at first
     * @param _newAuctionPrice auction price of Ether to pay for ownership at first
     */
    function TransferOwnershipOfHarbergerAtFirst(uint256 _newAuctionPrice) public payable {
        uint256 initialPrice = harbergerInfo.initialPrice;
        uint256 harbergerHike = harbergerInfo.harbergerHike;
        // require(_amount >= initialPrice + initialPrice * harbergerHike, "Token amount is not enough");
        require(_newAuctionPrice >= initialPrice, "Auction Price should be bigger than initial price when first sale");
        require(msg.value >= _newAuctionPrice + _newAuctionPrice * harbergerHike / 100, "Ether amount is not enough");

        // _token.transferFrom(msg.sender, issuer, finalPrice);

        // (bool sent, bytes memory data) = payable(issuer).call{value: msg.value}("");
        (bool sent, ) = payable(issuer).call{value: msg.value}("");
        require(sent, "Failed to send Ether");  

        // payable(issuer).send(msg.value);
        harbergerInfo.currentOwner = msg.sender;
        harbergerInfo.startTime = block.timestamp;
        harbergerInfo.endTime = block.timestamp + harbergerInfo.ownershipPeriod;
        harbergerInfo.previousAuctionPrice = _newAuctionPrice;

        emit OwnershipChangedEvent(msg.sender);
    }

    /**
     * @notice Delay endTime of ownership
     */
    function DelayEndTimeOfOwnership() public notIssuer onlyCurrentOwnerOfHarberger payable {
        uint256 endTime = harbergerInfo.endTime;
        uint256 harbergerTax = harbergerInfo.harbergerTax;
        uint256 currentAuctionPrice = harbergerInfo.previousAuctionPrice;
        uint256 ownershipPeriod = harbergerInfo.ownershipPeriod;
        uint256 currentTime = block.timestamp;

        uint256 delayPrice = currentAuctionPrice * harbergerTax / 100;
        require(endTime - currentTime < ownershipPeriod, "You have already delayed end time of ownership");
        // _token.transferFrom(msg.sender, issuer, _amount);
        require(msg.value >= delayPrice, "Ether amount is not enough");

        (bool sent, ) = payable(issuer).call{value: msg.value}("");
        require(sent, "Failed to send Ether");        
        // payable(issuer).send(msg.value);        
        harbergerInfo.endTime = endTime + ownershipPeriod;

        emit DelayEndTimeOfOwnershipEvent(msg.sender);
    }

    /**
     * @notice Transfer ownership of string to other wallet at second phase
     * @param _newAuctionPrice auction price of Ether to pay for ownership at second phase
     */
    function TransferOwnershipOfHarbergerAtSecond(uint256 _newAuctionPrice) public payable {
        uint256 previousAuctionPrice = harbergerInfo.previousAuctionPrice;
        uint16 harbergerTax = harbergerInfo.harbergerTax;
        uint16 harbergerHike = harbergerInfo.harbergerHike;
        uint256 ownershipPeriod = harbergerInfo.ownershipPeriod;
        address currentOwner = getCurrentOwner();

        require(_newAuctionPrice >= previousAuctionPrice + previousAuctionPrice * harbergerTax / 100, "Auction price should be bigger.");

        // require(_amount >= finalPrice + finalPrice * harbergerHike / 100, "Token amount is not enough");
        require(msg.value >= _newAuctionPrice + _newAuctionPrice * harbergerHike / 100 + _newAuctionPrice * harbergerTax / 100, "Ether amount is not enough");
        // _token.transferFrom(msg.sender, issuer, _amount * harbergerTax / 100);
        // _token.transferFrom(msg.sender, currentOwner, _amount + _amount * harbergerHike / 100);

        (bool sent, ) = payable(issuer).call{value: _newAuctionPrice * harbergerTax / 100}("");
        require(sent, "Failed to send Ether");

        (sent, ) = payable(currentOwner).call{value: _newAuctionPrice + _newAuctionPrice * harbergerHike / 100}("");
        require(sent, "Failed to send Ether");        

        harbergerInfo.currentOwner = msg.sender;
        harbergerInfo.startTime = block.timestamp;
        harbergerInfo.endTime = block.timestamp + ownershipPeriod;
        harbergerInfo.previousAuctionPrice = _newAuctionPrice;

        emit OwnershipChangedEvent(msg.sender);
    }

    /**
     * @notice Set ownership time
     * @param _days days of ownership
     */
    function setOwnershipPeriod(uint32 _days) public onlyIssuer {
        uint32 ownershipPeriod = _days * SECONDS_IN_DAY;
        harbergerInfo.ownershipPeriod = ownershipPeriod;
        emit OwnershipPeriodChangedEvent(ownershipPeriod);
    }

    // function getTokenAddress() public onlyIssuer view returns (address) {
    //     return address(_token);
    // }

    // /**
    //  * @notice Creates a new vesting schedule for an account.
    //  * @param token_ address of token
    //  */
    // function setTokenAddress(address token_) public onlyIssuer {
    //     _token = IERC20(token_);
    // }

    /**
     * @notice Updates value of string
     * @param _valueOfString value of string to be updated
     */
    function setValueOfString(string memory _valueOfString) public onlyCurrentOwnerOfHarberger {
        harbergerInfo.valueOfString = _valueOfString;
        emit ValueOfStringChangedEvent(_valueOfString);
    }

    /**
     * @notice Updates settings
     * @param _ownershipPeriod value of string to be updated
     * @param _harbergerHike value of Harberger Hike
     * @param _harbergerTax value of Harberger Tax
     * @param _initialPrice value of Initial Price
     * @param _valueOfString value of string to be updated
     */
    function setValueOfSettings(
        uint32 _ownershipPeriod,
        uint16 _harbergerHike,
        uint16 _harbergerTax,
        uint256 _initialPrice,
        string memory _valueOfString
        ) public onlyIssuer {
            harbergerInfo.ownershipPeriod = _ownershipPeriod * SECONDS_IN_DAY;
            harbergerInfo.harbergerHike = _harbergerHike;
            harbergerInfo.harbergerTax = _harbergerTax;
            harbergerInfo.initialPrice = _initialPrice;
            if (keccak256(abi.encodePacked((_valueOfString))) != keccak256(abi.encodePacked(('Current owner is not the issuer'))))
            // if (_valueOfString != 'Current owner is not the issuer') 
                harbergerInfo.valueOfString = _valueOfString;

            emit ValueOfSettingsChangedEvent();
    }
}
