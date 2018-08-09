pragma solidity ^0.4.18;

import "./ExternalInterfaces/GeneScienceInterface.sol";
import "./KittyOwnership.sol";


//无锡魔乐科技有限公司技术提供
//宠物繁殖合约
contract KittyBreeding is KittyOwnership {

    //怀孕事件
    event Pregnant(address owner, uint256 matronId, uint256 sireId,uint256 mcooldownEndTime,uint16 mcooldownIndex,uint256 scooldownEndTime,uint16 scooldownIndex);

    //自动分娩
    // event AutoBirth(uint256 matronId, uint256 cooldownEndTime);

    //自动分娩gas费用
    // uint256 public autoBirthFee = 1000000 * 1000000000; // (1M * 1 gwei)

    //基因控制合约
    GeneScienceInterface public geneScience;

    //检查宠物能否生育
    function _isReadyToBreed(Kitty _kit) internal view returns (bool) {
        return (_kit.siringWithId == 0) && (_kit.cooldownEndTime <= now);
    }

    //检查两只宠物是否有交配许可证
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = kittyIndexToOwner[_matronId];
        address sireOwner = kittyIndexToOwner[_sireId];

        //如果是玩家拥有两只猫交配 或者 母的宠物已经被授权
        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

    //触发宠物冷却
    function _triggerCooldown(Kitty storage _kitten) internal {
        //设定冷却时间
        _kitten.cooldownEndTime = uint64(now + cooldowns[_kitten.cooldownIndex]);

        //13代以上都会增加代数
        if (_kitten.cooldownIndex < 13) {
            _kitten.cooldownIndex += 1;
        }
    }

    //宠物授权出去交配
    function approveSiring(address _addr, uint256 _sireId)
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

    //设置自动生产gas费用
    // function setAutoBirthFee(uint256 val) public onlyCOO {
    //     autoBirthFee = val;
    // }

    //判断宠物是否可以分娩
    function _isReadyToGiveBirth(Kitty _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndTime <= now);
    }

    //判断指定id的宠物是否可以分娩
    function isReadyToBreed(uint256 _kittyId)
        public
        view
        returns (bool)
    {
        require(_kittyId > 0);
        Kitty storage kit = kitties[_kittyId];
        return _isReadyToBreed(kit);
    }

    //判断两只宠物能否合法交配
    function _isValidMatingPair(
        Kitty storage _matron,
        uint256 _matronId,
        Kitty storage _sire,
        uint256 _sireId
    )
        private
        view
        returns(bool)
    {
        //不能自我交配
        if (_matronId == _sireId) {
            return false;
        }

        //不能和父母交配
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        //0代马
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        //兄弟姐妹不能交配
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        return true;
    }

    //两只宠物能否合法交配
    // function isValidMatingPair(uint256 _matronId, uint256 _sireId)
    //     public
    //     view
    //     returns(bool)
    // {
    //     require(_matronId > 0);
    //     require(_sireId > 0);
    //     Kitty storage matron = kitties[_matronId];
    //     Kitty storage sire = kitties[_sireId];
    //     return _isValidMatingPair(matron, _matronId, sire, _sireId);
    // }

    //两只宠物能否合法交配
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        Kitty storage matron = kitties[_matronId];
        Kitty storage sire = kitties[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    //两只宠物能否交配
    function canBreedWith(uint256 _matronId, uint256 _sireId)
        public
        view
        returns(bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Kitty storage matron = kitties[_matronId];
        Kitty storage sire = kitties[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId); //&&
           // _isSiringPermitted(_sireId, _matronId);
    }

    //将两只宠物进行交配
    function breedWith(uint256 _matronId, uint256 _sireId) public whenNotPaused {
        require(_owns(msg.sender, _matronId));
        require(_isSiringPermitted(_sireId, _matronId));

        //检测母宠物能否交配
        Kitty storage matron = kitties[_matronId];
        require(_isReadyToBreed(matron));

        //检测公宠物能否交配
        Kitty storage sire = kitties[_sireId];
        require(_isReadyToBreed(sire));

        //检测双方能否合法交配
        require(_isValidMatingPair(matron,_matronId,sire,_sireId));

        //开始交配
        _breedWith(_matronId, _sireId);
    }

    //交配函数-内部函数
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        //获取宠物内容
        Kitty storage sire = kitties[_sireId];
        Kitty storage matron = kitties[_matronId];

        //设置配偶id
        matron.siringWithId = uint32(_sireId);

        //设置冷却时间
        _triggerCooldown(sire);
        _triggerCooldown(matron);

        //删除授权
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

        //出发怀孕事件
        Pregnant(kittyIndexToOwner[_matronId], _matronId, _sireId, matron.cooldownEndTime,matron.cooldownIndex,sire.cooldownEndTime,sire.cooldownIndex);
    }

    //自动分娩
    // function breedWithAuto(uint256 _matronId, uint256 _sireId)
    //     public
    //     payable
    //     whenNotPaused
    // {
    //     //检查汽油费
    //     require(msg.value >= autoBirthFee);

    //     //正常交配流程
    //     breedWith(_matronId, _sireId);

    //     //触发自动分娩
    //     Kitty storage matron = kitties[_matronId];
    //     AutoBirth(_matronId, matron.cooldownEndTime);
    // }

    //母宠物诞生一只新宠物
    function giveBirth(uint256 _matronId)
        public
        whenNotPaused
        returns(uint256)
    {
        Kitty storage matron = kitties[_matronId];

        require(matron.birthTime != 0);
        require(_isReadyToGiveBirth(matron));

        uint256 sireId = matron.siringWithId;
        Kitty storage sire = kitties[sireId];

        //确定新宠物代数
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        //混合基因
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes);

        //产生新的宠物
        address owner = kittyIndexToOwner[_matronId];
        uint256 kittenId = _createKitty(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);

        //删除配偶id
        delete matron.siringWithId;

        //返回新宠物id
        return kittenId;
    }
}
