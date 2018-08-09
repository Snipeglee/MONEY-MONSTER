pragma solidity ^0.4.18;

import "./KittyMoney.sol";

contract KittyCore is KittyMoney {
    // KittyBase：这是我们定义整个核心共享最基本代码的地方
    //功能。这包括我们的主要数据存储，常量和数据类型，另外
    //管理这些项目的内部函数。
    //
    // - KittyAccessControl：该合同管理各种地址和操作约束
    //只能由特定角色执行。即首席执行官，首席财务官和首席运营官。
    //
    // - KittyOwnership：这提供了基本的不可互换的标记所需的方法
    //交易，遵循ERC-721规范草案（https://github.com/ethereum/EIPs/issues/721）。
    //
    // - KittyBreeding：此文件包含将猫一起繁殖所必需的方法，包括
    //跟踪提供的优惠，并依靠外部基因组合合同。
    //
    // - KittyAuctions：在这里，我们有公开的方法来拍卖或招标猫或招标
    // 服务。实际拍卖功能是在两个兄弟合约（一个
    //销售和拍卖），而拍卖的创建和出价主要是中介
    //通过核心合同的这一方面。
    //
    // - KittyMinting：这个最后一个方面包含了我们用来创建新的gen0猫的功能。
    //我们可以制作多达5000个可以放弃的“促销”猫（特别重要的时候
    //社区是新的），所有其他人只能创建，然后立即提出
    //通过算法确定的起始价格进行拍卖。不管他们如何
    //创建时，有50k gen0猫的硬性限制。之后，这一切都取决于
    //社区繁殖，繁殖，繁殖！
    //
    // - KittyMoney： 整个游戏运行依赖的代币。
    //我门可以在这个合约设置代币的地址。一切货币流通都以该代币为游戏法定货币

    
    //新的合约地址
    // address public newContractAddress;
        
    //宠物合约初始化
    function KittyCore() public {
        // Starts paused.
        paused = true;
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;

        //生产第一只创始宠物
        _createKitty(0, 0, 0, uint256(-1), address(0));

    }

    //设置新的合约地址
    // function setNewAddress(address _v2Address) public onlyCEO whenPaused {
    //     newContractAddress = _v2Address;
    //     ContractUpgrade(_v2Address);
    // }

    //只有交易合约地址可以发送货币过来
    // function() external payable {
    //     require(
    //         msg.sender == address(saleAuction) ||
    //         msg.sender == address(siringAuction)
    //     );
    // }

    //获取一只宠物的具体信息
    function getKitty(uint256 _id)
        public
        view
        returns (
        bool isGestating,
        bool isReady,
        uint256 cooldownIndex,
        uint256 nextActionAt,
        uint256 siringWithId,
        uint256 birthTime,
        uint256 matronId,
        uint256 sireId,
        uint256 generation,
        uint256 genes,
        uint[5] addprop,
        uint feedtimes,
        bool isTreasure
    ) {
        Kitty storage kit = kitties[_id];

        // if this variable is 0 then it's not gestating
        isGestating = (kit.siringWithId != 0);
        isReady = (kit.cooldownEndTime <= now);
        cooldownIndex = uint256(kit.cooldownIndex);
        nextActionAt = uint256(kit.cooldownEndTime);
        siringWithId = uint256(kit.siringWithId);
        birthTime = uint256(kit.birthTime);
        matronId = uint256(kit.matronId);
        sireId = uint256(kit.sireId);
        generation = uint256(kit.generation);
        genes = kit.genes;
        addprop = kit.addprop;
        feedtimes = kit.feedtimes;
        isTreasure = kit.isTreasure;
    }

    //获取宠物基因
    function getKittyGenes(uint256 _id) public view returns (uint genes,uint[5] addprop,uint siringWithId,bool isTreasure,bool isMatch,uint cooldownEndTime){
        Kitty memory kit = kitties[_id];
        genes = kit.genes;
        addprop = kit.addprop;
        siringWithId = kit.siringWithId;
        isTreasure = kit.isTreasure;
        isMatch = kit.isMatch;
        cooldownEndTime = uint256(kit.cooldownEndTime);
    }

     //批量生产马
    function batchHorses(address owner,uint level,uint num) public onlyCLevel {
        for(uint i=0;i<num;i++){
            uint genes = geneScience.genSpecGenes(level,i);
            _createKitty(0, 0, 0, genes, owner);
        }
    }
}
