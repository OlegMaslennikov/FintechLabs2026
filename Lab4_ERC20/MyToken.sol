// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LabToken.sol";

contract MyToken is LabToken {
    constructor() LabToken("My Token", "MTK") {}
}