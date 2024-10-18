// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IWormhole.sol";

contract Vault is
    IVault,
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuard
{
    IWormhole public wormhole;

    // user => token => balance
    mapping(address => mapping(address => uint256)) public userBalances;

    bool public paused;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        address _wormhole
    ) public initializer {
        __Pausable_init();
        __Ownable_init(_initialOwner);

        wormhole = IWormhole(_wormhole);
        paused = false;
    }

    function deposit(
        address token,
        uint256 amount
    ) external nonReentrant notPaused {
        require(amount > 0, "Amount must be greater than zero");

        // Transfer tokens from user to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Update user's balance
        userBalances[msg.sender][token] += amount;

        // Approve and deposit tokens into Aave lending pool
        IERC20(token).approve(address(aavePool), amount);
        // aavePool.supply(token, amount, address(this), 0);

        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(
        address token,
        uint256 amount
    ) external nonReentrant notPaused {
        require(
            userBalances[msg.sender][token] >= amount,
            "Insufficient balance"
        );

        // Update user's balance
        userBalances[msg.sender][token] -= amount;

        // Withdraw tokens from Aave lending pool
        // aavePool.withdraw(token, amount, address(this));

        // Transfer the tokens back to the user
        IERC20(token).transfer(msg.sender, amount);

        emit Withdraw(msg.sender, token, amount);
    }

    function lockAndSendMessage(
        address token,
        uint256 amount,
        uint32 nonce
    ) external nonReentrant notPaused {
        require(
            userBalances[msg.sender][token] >= amount,
            "Insufficient balance"
        );

        // Update user's balance to lock the tokens
        userBalances[msg.sender][token] -= amount;

        // Prepare the payload for Wormhole message
        bytes memory payload = abi.encode(msg.sender, token, amount);

        // Publish message to Wormhole to initiate the mint on Solana
        uint64 sequence = wormhole.publishMessage(nonce, payload, 1);

        emit LockedAndMessageSent(msg.sender, token, amount, sequence);
    }

    // Admin functions
    function updateWormhole(address _newWormhole) external onlyOwner {
        require(_newWormhole != address(0), "Invalid Wormhole address");
        wormhole = IWormhole(_newWormhole);
        emit WormholeUpdated(_newWormhole);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}
