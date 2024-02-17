// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
  // VARIABLES
  /// External contract that will hold staked funds if threshold reached
  ExampleExternalContract public exampleExternalContract;

  /// Balances of user's staked funds
  mapping (address => uint256) public balances;

  /// Staking threshold
  uint256 public constant threshold = 1 ether;

  /// Staking deadline
  uint256 public deadline = block.timestamp + 60 seconds;

  /// Boolean set if threshold is not reached by the deadline
  bool public openForWithdraw;

  // EVENTS
  /// Emit when stake() is called
  event Stake(address sender, uint256 value);

  // MODIFIERS
  /// Modifier that checks whether the required deadline has passed
  modifier deadlinePassed(bool requireDeadlinePassed) {
    uint256 timeRemaining = timeLeft();
    if (requireDeadlinePassed) {
      require(timeRemaining <= 0, "Deadline has not been passed yet");
    } else {
      require(timeRemaining > 0, "Deadline is already passed");
    }
    _;
  }

  modifier deadlineReached( bool requireReached ) {
    uint256 timeRemaining = timeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Deadline is already reached");
    }
    _;
  }

  /// Modifier that checks whether the external contract is completed
  modifier stakingNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Staking period has completed");
    _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() public payable deadlinePassed(false) stakingNotCompleted {
    // update the sender's balance
    balances[msg.sender] += msg.value;
  
    // emit Stake event to notify the UI
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public stakingNotCompleted {
    uint256 contractBalance = address(this).balance;
    if (contractBalance >= threshold) {
      // if the `threshold` is met, send the balance to the externalContract
      exampleExternalContract.complete{value: contractBalance}();
    } else {
      // if the `threshold` was not met, allow everyone to call a `withdraw()` function
      openForWithdraw = true;
    }
  }



  function withdraw() public deadlineReached(true) stakingNotCompleted {
    uint256 userBalance = balances[msg.sender];

    // check if the user has balance to withdraw
    require(userBalance > 0, "You don't have balance to withdraw");

    // reset the balance of the user
    balances[msg.sender] = 0;

    // Transfer balance back to the user
    (bool sent,) = msg.sender.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }

  /// Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
      if (block.timestamp >= deadline) {
          return 0;
      } else {
          return deadline - block.timestamp;
      }
  }


  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
      stake();
  }
}

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`


  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()}
