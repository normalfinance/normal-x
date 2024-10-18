pragma solidity ^0.8.0;

interface IVault {
    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event LockedAndMessageSent(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint64 sequence
    );
    event WormholeUpdated(address indexed newWormhole);
    event Paused(bool status);
}
