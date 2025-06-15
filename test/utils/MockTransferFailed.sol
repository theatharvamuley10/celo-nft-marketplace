// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

contract MockTransferFailed {
    receive() external payable {
        revert("I don't accept ETH");
    }
}
