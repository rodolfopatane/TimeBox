// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract TimeBox is Ownable {
    event Withdraw(address recipient, uint256 amount);
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

    function renounceOwnership() public override virtual onlyOwner {
        /* disable renounce function to don't loss funds */
    }

    function withdraw(address payable recipient) public onlyOwner {
        require(block.timestamp >= lockedAt, "Too early, be patient padawan.");
        require(
            recipient != address(0),
            "You crazy?, you really want burn you ether?"
        );
        require(
            address(this).balance > 0,
            "You can't reap what you didn't sow"
        );
        recipient.transfer(address(this).balance);
        emit Withdraw(recipient, address(this).balance);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
