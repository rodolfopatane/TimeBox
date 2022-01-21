// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

struct TokenBalance {
    address token;
    uint256 amount;
}

contract TimeBox is Ownable {
    event WithdrawETH(address recipient, uint256 amount);
    event WithdrawUnknowToken(address recipient, uint256 amount, address token);
    event WithdrawTokens(address recipient, TokenBalance[]);
    event SetupTimeBox(uint256 block, uint256 lockedAt);
    event Received(address, uint256);
    event AddFromToken(address recipient, address _newToken, uint256 amount);

    uint256 public lockedAt;
    mapping(address => uint256) private _tokensFunds;
    address[] private _tokens;

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

    modifier checkRequirements() {
        require(block.timestamp >= lockedAt, "Too early, be patient padawan.");
        _;
    }

    /* send all eth to ownder */
    function withdraw() public onlyOwner checkRequirements {
        require(
            address(this).balance > 0,
            "You can't reap what you didn't sow"
        );
        emit WithdrawETH(msg.sender, address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }

    /* send token to owner by address if this have balance */
    function withdrawUnknowToken(address _token)
        public
        onlyOwner
        checkRequirements
    {
        require(
            ERC20(_token).balanceOf(address(this)) > 0,
            "You can't reap what you didn't sow"
        );
        emit WithdrawUnknowToken(
            msg.sender,
            ERC20(_token).balanceOf(address(this)),
            _token
        );
        ERC20(_token).transfer(
            msg.sender,
            ERC20(_token).balanceOf(address(this))
        );
    }

    /* transfer all listed tokens */
    function withdrawTokens() private onlyOwner checkRequirements {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (ERC20(_tokens[i]).balanceOf(address(this)) > 0) {
                ERC20(_tokens[i]).transfer(
                    msg.sender,
                    ERC20(_tokens[i]).balanceOf(address(this))
                );
            }
        }
        emit WithdrawTokens(msg.sender, getBalanceOfTokens());
        delete _tokens;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalanceOfUnknowToken(address _address)
        public
        view
        returns (uint256)
    {
        return ERC20(_address).balanceOf(address(this));
    }

    /* array with all tokens listed */
    function getBalanceOfTokens() public view returns (TokenBalance[] memory) {
        uint256 size = _tokens.length;
        require(size > 0, "No tokens");
        TokenBalance[] memory _tokenBalances = new TokenBalance[](size);

        for (uint256 i = 0; i < size; i++) {
            TokenBalance memory tokenBalance = TokenBalance(
                _tokens[i],
                _tokensFunds[_tokens[i]]
            );
            _tokenBalances[i] = tokenBalance;
        }
        return _tokenBalances;
    }

    function getTokens() public view returns (address[] memory) {
        return _tokens;
    }

    /* add previous unknow token on list if exist update balance */
    function indexUnknowToken(address _token) public {
        require(
            ERC20(_token).balanceOf(address(this)) > 0,
            "You dont't have balance"
        );

        if (_tokensFunds[_token] <= 0) {
            _tokens.push(_token);
        }
        _tokensFunds[_token] = ERC20(_token).balanceOf(address(this));
    }

    /* this function add allowence and after move token */
    function addFromToken(address _newToken, uint256 amount) public onlyOwner {
        require(
            ERC20(_newToken).balanceOf(msg.sender) > 0 &&
                ERC20(_newToken).balanceOf(msg.sender) >= amount,
            "You dont't have balance"
        );

        if (_tokensFunds[_newToken] <= 0) {
            _tokens.push(_newToken);
        }
        ERC20(_newToken).increaseAllowance(address(this), amount);
        ERC20(_newToken).transferFrom(msg.sender, address(this), amount);
        emit AddFromToken(msg.sender, _newToken, amount);
        _tokensFunds[_newToken] = ERC20(_newToken).balanceOf(address(this));
    }
}
