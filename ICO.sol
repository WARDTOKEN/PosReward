pragma solidity 0.4.19;
/**
* @title ICO CONTRACT
* @dev ERC-20 Token Standard Compliant
*/

/**
 * @title SafeMath by OpenZepelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

    }

/**
 * @title admined
 * @notice This contract is administered
 */
contract admined {
    address public admin; //Admin address is public
    
    /**
    * @dev This contructor takes the msg.sender as the first administer
    */
    function admined() internal {
        admin = msg.sender; //Set initial admin to contract creator
        Admined(admin);
    }

    /**
    * @dev This modifier limits function execution to the admin
    */
    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    /**
    * @notice This function transfer the adminship of the contract to _newAdmin
    * @param _newAdmin The new admin of the contract
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        admin = _newAdmin;
        TransferAdminship(admin);
    }

    /**
    * @dev Log Events
    */
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}

contract FiatContract {
    
    function USD(uint _id) constant returns (uint256);

}

contract ICO is admined {

    FiatContract price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591); // MAINNET ADDRESS
    //FiatContract price = FiatContract(0x2CDe56E5c8235D6360CCbb0c57Ce248Ca9C80909); // TESTNET ADDRESS (ROPSTEN)

    using SafeMath for uint256;
    //This ico have 5 states
    enum State {
        stage1, //PreIco
        stage2, //ICO round1
        stage3, //ICO round2
        Paused,
        Successful
    }
    //public variables
    State public state = State.stage1; //Set initial stage
    uint256 public startTime = now; //block-time when it was deployed
    uint256 public stage1Deadline = startTime.add(2 weeks);
    uint256 public stage2Deadline = stage1Deadline.add(2 weeks);
    uint256 public stage3Deadline = stage2Deadline.add(2 weeks);
    uint256 public totalRaised; //eth in wei
    uint256 public totalDistributed; //tokens
    uint256 public stageDistributed;
    uint256 public totalContributors;
    uint256 public completedAt;
    token public tokenReward;
    address public creator;
    string public campaignUrl;
    string public version = '1';

    uint256 pauseTime;
    uint256 remainingActualState;
    State laststate;

    //events for log
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(address _creator,string _url);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogSalePaused(bool _paused);
    event LogStageFinish(State _state, uint256 _distributed);

    modifier notFinished() {
        require(state != State.Successful && state != State.Paused);
        _;
    }
    /**
    * @notice ICO constructor
    * @param _campaignUrl is the ICO _url
    * @param _addressOfTokenUsedAsReward is the token totalDistributed
    */
    function ICO (
        string _campaignUrl,
        token _addressOfTokenUsedAsReward ) public {
        
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = _addressOfTokenUsedAsReward;

        LogFunderInitialized(
            creator,
            campaignUrl);
    }

    /**
    * @notice contribution handler
    */
    function contribute(address _ref) public notFinished payable {

        address referral = _ref;
        uint256 referralTokens = 0;
        uint256 tokenBought = 0;
        uint256 USDRate = price.USD(0); //USD Cent in wei so its 18 decimals base - 0.01$
        
        USDRate = USDRate.div(10 ** 9); //Base 18 to Base 9

        totalRaised = totalRaised.add(msg.value);
        totalContributors = totalContributors.add(1);

        //Rate of exchange depends on stage
        if (state == State.stage1){

            // 0.001$ calc
            tokenBought = msg.value.div(USDRate); //Base 18 / Base 9 = Base 9

            //Bonus Calc
            tokenBought = tokenBought.mul(13);
            tokenBought = tokenBought.div(10); //1.3 = 130%

            require(stageDistributed.add(tokenBought) < 1300000000 * (10 ** 8)); //1.3Bil
        
        } else if (state == State.stage2){
        
            USDRate = USDRate.mul(25);
            USDRate = USDRate.div(10); //0.0025$ calc
            tokenBought = msg.value.div(USDRate); //Base 18 / Base 9 = Base 9
            //Bonus Calc
            tokenBought = tokenBought.mul(12);
            tokenBought = tokenBought.div(10); //1.2 = 120%

            require(stageDistributed.add(tokenBought) < 1200000000 * (10 ** 8)); //1.2Bil
        
        } else if (state == State.stage3){
        
            USDRate = USDRate.mul(35);
            USDRate = USDRate.div(10); //0.0035$ calc
            tokenBought = msg.value.div(USDRate); //Base 18 / Base 9 = Base 9
            //Bonus Calc
            tokenBought = tokenBought.mul(11);
            tokenBought = tokenBought.div(10); //1.1 = 110%

            require(stageDistributed.add(tokenBought) < 1100000000 * (10 ** 8)); //1.1Bil
        }

        totalDistributed = totalDistributed.add(tokenBought);
        stageDistributed = stageDistributed.add(tokenBought)
        
        tokenReward.transfer(msg.sender, tokenBought);

        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        

        if (referral != address(0) && referral != msg.sender){

            referralTokens = tokenBought.div(5); // 100% / 5 = 20%
            totalDistributed = totalDistributed.add(referralTokens);
            stageDistributed = stageDistributed.add(referralTokens)

            tokenReward.transfer(referral, referralTokens);
            
            LogContributorsPayout(referral, referralTokens);
        }
        
        checkIfFundingCompleteOrExpired();
    }

    /**
    * @notice check status
    */
    function checkIfFundingCompleteOrExpired() public {

        if(state == State.stage1 && now > stage1Deadline){

            LogStageFinish(state,stageDistributed);

            state = State.stage2;
            stageDistributed = 0;

        } else if(state == State.stage2 && now > stage2Deadline){

            LogStageFinish(state,stageDistributed);

            state = State.stage3;
            stageDistributed = 0;
          
        } else if(now > stage3Deadline && state!=State.Successful ){ //if we reach ico deadline and its not Successful yet

            LogStageFinish(state,stageDistributed);

            state = State.Successful; //ico becomes Successful
            completedAt = now; //ICO is complete

            LogFundingSuccessful(totalRaised); //we log the finish
            finished(); //and execute closure

        }
    }

    function pauseSale(bool _flag) public {
        require(state != State.Successful);

        if(_flag == true){
            require(state != State.Paused);
            laststate = state;
            if(state == State.stage1){
                remainingActualState = stage1Deadline.sub(now);
            } else if(state == State.stage2){
                remainingActualState = stage2Deadline.sub(now);
            } else if(state == State.stage3){
                remainingActualState = stage3Deadline.sub(now);
            } 
            state = State.Paused;
            LogSalePaused(true);
        } else {
            require(state == State.Paused);
            state = laststate;
            if(state == State.stage1){
                stage1Deadline = now.add(remainingActualState);
                stage2Deadline = stage1Deadline.add(2 weeks);
                stage3Deadline = stage2Deadline.add(2 weeks);
            } else if(state == State.stage2){
                stage2Deadline = now.add(remainingActualState);
                stage3Deadline = stage2Deadline.add(2 weeks);
            } else if(state == State.stage3){
                stage3Deadline = now.add(remainingActualState);
            }
            LogSalePaused(false);
        }
    }

    /**
    * @notice closure handler
    */
    function finished() public { //When finished eth are transfered to creator

        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        require(creator.send(this.balance));
        tokenReward.transfer(creator,remanent);

        LogBeneficiaryPaid(creator);
        LogContributorsPayout(creator, remanent);

    }

    /*
    * @dev direct payments doesn't handle referral system
    * so it call contribute with referral 0x0000000000000000000000000000000000000000
    */

    function () public payable {
        
        contribute(address(0));

    }
}