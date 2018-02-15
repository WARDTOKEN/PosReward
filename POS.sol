pragma solidity 0.4.19;


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


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime; //when staking start to count
    uint256 public stakeMinAge; //minimum valid staking time
    uint256 public stakeMaxAge; //maximum valid staking time
    function mint() public returns (bool);
    function coinAge() constant public returns (uint256);
    function annualInterest() constant public returns (uint256);
    event Mint(address indexed _address, uint _reward);
}


contract PoSToken is ERC20,PoSTokenStandard,Ownable {
    using SafeMath for uint256;

    string public name = "PosReward";
    string public symbol = "WARD";
    uint public decimals = 8;

    uint public chainStartTime; //chain start time
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 3 days; // minimum age for coin age: 3 Days
    uint public stakeMaxAge = 90 days; // stake age of full weight: 90 Days
    uint public baseIntCalc = 10**uint256(decimals - 1); // default 10% annual interest

    uint public totalSupply; //actual supply
    uint public maxTotalSupply; //maximum supply ever 
    uint public totalInitialSupply; //initial supply on deployment

    //struct to define stake stacks
    struct transferInStruct{
    uint128 amount;
    uint64 time;
    }

    //HardCodedAddresses
    address TokenHoldersReward = 0xdd489eB68aDbdc658a19d323e2b104508be696cB;
    address CashBackPlatform = 0x0529CD2B0124eF3D3Fa0f6aEF85470Fc06EDF62C;
    address ICO = 0xd006fed6F4F3176C7c9d8fca19bA2c1CF40bFa36;
    address Team = 0x1B5dcF71E602b0722BA74A04d5786A2497032A18;
    address AirdropMobileAppUsers = 0xdFf83897987030083Fc70BA37E2B98C0E304ee72;
    address Bounty = 0xe99DbFe23963b710082836A97Ba0CCE0B6DeeC5a;
    address Partners = 0xF06A44d68247617A73697cEe30BB6B40E8cccF91;
    address EthereumCommunity = 0x5fd20C0Ae4de0a5EA1c577621a1037b0Dc1A4BEA;
    address BitcoinCommunity = 0xe7D069cC9c060c478D78FcCb3B3052ce0310CaF1;
    address DashCommunity = 0x2591Ba1F37a105Afc935C3591c3d1bC46E71679D;
    address PoSTokenCommunity = 0xE323941B245868Dd4F111D0d96cBD4860D0f1D26; 
    address DogecoinCommunity = 0x744B709F4beD578F65a29B4940CD011c3dfEc7d3;
    address LitecoinCommunity = 0x4737D6D84a209614ABc695AE009C35BfFb2Ea57f;
    address AcceleratorCommunity = 0xdfCc95E3049760f7a0bcDFD776D36cb75575679E;
    address XXXCommunity = 0xD7D2AF58C3717C401DF741a02d57205d6a3bf941;
    address ElectroleumCommunity = 0xfc29090569Eb162a661890B13C9c3EFBe28cB768;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns; //mapping to stake stacks

    event Burn(address indexed burner, uint256 value);


    //modifier to limit the minting to not exceed maximum supply limit
    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    function PoSToken() public {

        maxTotalSupply = 27000000000 * 10 ** uint256(decimals); // 27 Bil. maximum supply
        totalInitialSupply = 6750000000 * 10 ** uint256(decimals); // 6.75 Bil. initial supply

        chainStartTime = now; //when contract is deployed

        balances[TokenHoldersReward] = 700000000 * 10 ** uint256(decimals);
        balances[CashBackPlatform] = 1300000000 * 10 ** uint256(decimals);
        balances[ICO] = 4000000000 * 10 ** uint256(decimals);
        balances[Team] = 250000000 * 10 ** uint256(decimals); 
        balances[AirdropMobileAppUsers] =  200000000 * 10 ** uint256(decimals);
        balances[Bounty] = 100000000 * 10 ** uint256(decimals);
        balances[Partners] = 20000000 * 10 ** uint256(decimals);
        balances[EthereumCommunity] = 49000000 * 10 ** uint256(decimals);
        balances[BitcoinCommunity] = 35000000 * 10 ** uint256(decimals);
        balances[DashCommunity] = 18000000 * 10 ** uint256(decimals);
        balances[PoSTokenCommunity] = 2500000 * 10 ** uint256(decimals); 
        balances[DogecoinCommunity] = 24000000 * 10 ** uint256(decimals);
        balances[LitecoinCommunity] = 28500000 * 10 ** uint256(decimals);
        balances[AcceleratorCommunity] = 2000000 * 10 ** uint256(decimals);
        balances[XXXCommunity] = 1000000 * 10 ** uint256(decimals);
        balances[ElectroleumCommunity] = 20000000 * 10 ** uint256(decimals);
        
        //initial logs
        Transfer(address(0), this, totalSupply);
        Transfer(this, TokenHoldersReward, 700000000 * 10 ** uint256(decimals));
        Transfer(this, CashBackPlatform, 1300000000 * 10 ** uint256(decimals));
        Transfer(this, ICO, 4000000000 * 10 ** uint256(decimals));
        Transfer(this, Team, 250000000 * 10 ** uint256(decimals)); 
        Transfer(this, AirdropMobileAppUsers,  200000000 * 10 ** uint256(decimals));
        Transfer(this, Bounty, 100000000 * 10 ** uint256(decimals));
        Transfer(this, Partners, 20000000 * 10 ** uint256(decimals));
        Transfer(this, EthereumCommunity, 49000000 * 10 ** uint256(decimals));
        Transfer(this, BitcoinCommunity, 35000000 * 10 ** uint256(decimals));
        Transfer(this, DashCommunity, 18000000 * 10 ** uint256(decimals));
        Transfer(this, PoSTokenCommunity, 2500000 * 10 ** uint256(decimals)); 
        Transfer(this, DogecoinCommunity, 24000000 * 10 ** uint256(decimals));
        Transfer(this, LitecoinCommunity, 28500000 * 10 ** uint256(decimals));
        Transfer(this, AcceleratorCommunity, 2000000 * 10 ** uint256(decimals));
        Transfer(this, XXXCommunity, 1000000 * 10 ** uint256(decimals));
        Transfer(this, ElectroleumCommunity, 20000000 * 10 ** uint256(decimals));
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        if(msg.sender == _to || msg.sender == address(0)) return mint(); //if self/zero transfer, trigger stake claim
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        Transfer(msg.sender, _to, _value);
        
        //if there is any stake on stack, delete the stack
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        //take actual time
        uint64 _now = uint64(now);
        //reset counter for sender
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        //add counter to stack for receiver
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        
        return true;
    }

    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); //empty/zero address send is not allowed
        //check
        var _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        //if there is any stake on stack, delete the stack
        if(transferIns[_from].length > 0) delete transferIns[_from];
        //take actual time
        uint64 _now = uint64(now);
        //reset counter for sender
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
         //add counter to stack for receiver
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0)); //exploit mitigation

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    //funtion to claim stake reward
    function mint() canPoSMint public returns (bool) {        
        if(balances[msg.sender] <= 0) return false;//no balance = no stake
        if(transferIns[msg.sender].length <= 0) return false;//no stake = no reward

        uint reward = getProofOfStakeReward(msg.sender);

        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward); //supply is increased
        balances[msg.sender] = balances[msg.sender].add(reward); //assigned to holder
        delete transferIns[msg.sender]; //stake stack get reset
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        //Logs
        Mint(msg.sender, reward);
        return true;
    }

    function coinAge() constant public returns (uint myCoinAge) {
        return myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() constant public returns(uint interest) {
        uint _now = now;
        interest = 0; // After 7 years no PoS
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (770 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            // 2nd year effective annual interest rate is 50%
            interest = (435 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 2){
            // 3nd year effective annual interest rate is 10%
            interest = (98 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 3){
            // 4nd year effective annual interest rate is 5%
            interest = (50 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 4){
            // 5nd year effective annual interest rate is 5%
            interest = (50 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 5){
            // 6nd year effective annual interest rate is 5%
            interest = (50 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 6){
            // 7nd year effective annual interest rate is 4%
            interest = (40 * baseIntCalc).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge == 0) return 0;

        uint interest = 0; // After 7 years no PoS
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime)).div(1 years) == 0) {
            // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (770 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 1){
            // 2nd year effective annual interest rate is 50%
            interest = (435 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 2){
            // 3nd year effective annual interest rate is 10%
            interest = (98 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 3){
            // 4nd year effective annual interest rate is 5%
            interest = (50 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 4){
            // 5nd year effective annual interest rate is 5%
            interest = (50 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 5){
            // 6nd year effective annual interest rate is 5%
            interest = (50 * baseIntCalc).div(100);
        } else if((_now.sub(stakeStartTime)).div(1 years) == 6){
            // 7nd year effective annual interest rate is 4%
            interest = (40 * baseIntCalc).div(100);
        }

        return (_coinAge * interest).div(365 * (10**uint256(decimals)));
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function ownerSetStakeStartTime(uint timestamp) onlyOwner public {
        require((stakeStartTime == 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }

    function ownerBurnToken(uint _value) onlyOwner public {
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        maxTotalSupply = maxTotalSupply.sub(_value*10);

        Burn(msg.sender, _value);
    }

    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for(uint j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
            Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        if(balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    }
}