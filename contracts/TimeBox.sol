// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TimeBox is Ownable {
    event Withdraw(address recipient, uint256 amount);
    event WithdrawToken(address recipient, uint256 amount, address token);
    event SetupTimeBox(uint256 block, uint256 lockedAt);
    event Received(address, uint256);

    uint256 public lockedAt;

    constructor(uint256 _lockedAtInDays) payable {
        lockedAt = SafeMath.add(
            block.timestamp,
            SafeMath.mul(
                SafeMath.mul(SafeMath.mul(_lockedAtInDays, 24), 60),
                60
            )
        );
        emit SetupTimeBox(block.number, lockedAt);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function renounceOwnership() public virtual override onlyOwner {
        /* disable renounce function to don't loss funds */
    }

    modifier checkRequirements(address recipient) {
        require(block.timestamp >= lockedAt, "Too early, be patient padawan.");
        require(
            recipient != address(0),
            "You crazy?, you really want burn you money?"
        );
        _;
    }

    function withdraw(address payable recipient)
        public
        onlyOwner
        checkRequirements(recipient)
    {
        require(
            address(this).balance > 0,
            "You can't reap what you didn't sow"
        );
        emit Withdraw(recipient, address(this).balance);
        recipient.transfer(address(this).balance);
    }

    function withdrawToken(address payable recipient, address _token)
        public
        onlyOwner
        checkRequirements(recipient)
    {
        require(
            ERC20(_token).balanceOf(address(this)) > 0,
            "You can't reap what you didn't sow"
        );
        emit WithdrawToken(
            recipient,
            ERC20(_token).balanceOf(address(this)),
            _token
        );
        ERC20(_token).transfer(
            recipient,
            ERC20(_token).balanceOf(address(this))
        );
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return ERC20(_address).balanceOf(address(this));
    }
}
