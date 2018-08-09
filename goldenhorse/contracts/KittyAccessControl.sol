pragma solidity ^0.4.18;

//无锡魔乐科技有限公司技术提供
//权限控制合约
contract KittyAccessControl {
    //合约升级
    event ContractUpgrade(address newContract);

    //管理员地址权限
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    //合约是否暂停的状态变量
    bool public paused = false;

    //限定ceo访问
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    //限定cfo访问
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    //限定coo访问
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    //限定管理员访问
    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    //设置管理者
    function setManager(address _newCEO,address _newCFO,address _newCOO) public onlyCEO {
        ceoAddress = _newCEO;
        cfoAddress = _newCFO;
        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/
    //判断未暂停
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    //判断暂停
    modifier whenPaused {
        require(paused);
        _;
    }

    //管理员可以暂停合约
    function pause() public onlyCLevel  {
        paused = true;
    }

       //管理恢复合约
    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}
