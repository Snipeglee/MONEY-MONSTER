pragma solidity ^0.4.18;

import "./KittyAccessControl.sol";

//无锡魔乐科技有限公司技术提供
//数据计算安全
library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

}

//宠物基础类合约
contract KittyBase is KittyAccessControl {
    using SafeMath for uint;
    /*** EVENTS ***/

    //宠物诞生事件
    event Birth(address indexed owner, uint256 kittyId, uint256 matronId, uint256 sireId, uint256 genes,uint64 birthTime,uint16 generation);

    //宠物转移事件
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /*** DATA TYPES ***/

    struct Kitty {
        //基因
        uint256 genes;
        // 出生时间
        uint64 birthTime;
        //冷却结束时间
        uint64 cooldownEndTime;
        //母亲id
        uint32 matronId;
        //父亲id
        uint32 sireId;
        //配偶id
        uint32 siringWithId;
        //繁殖冷却时间
        uint16 cooldownIndex;
        //出生代数 规则:max(matron.generation, sire.generation) + 1)
        uint16 generation;
        //属性加成部分
        uint[5] addprop;    //增加的属性
        uint  feedtimes;    //喂养的次数
        bool isTreasure;    //是否在寻宝
        bool isMatch;       //是否在比赛中
    }

    /*** CONSTANTS ***/
    uint32[14] public cooldowns = [
        uint32(1 days), 
        uint32(6 days),
        uint32(11 days),
        uint32(16 days),
        uint32(21 days),
        uint32(26 days),
        uint32(31 days),
        uint32(36 days),
        uint32(41 days),
        uint32(46 days),
        uint32(51 days),
        uint32(56 days),
        uint32(61 days),
        uint32(66 days)
    ];

    //宠物数组
    Kitty[] kitties;

    //宠物id => 拥有者地址 印射
    mapping (uint256 => address) public kittyIndexToOwner;

    //宠物数量记录
    mapping (address => uint256) ownershipTokenCount;

    //交易中id => 交易合约地址
    mapping (uint256 => address) public kittyIndexToApproved;

    //交易中id => 繁殖交易合约地址 
    mapping (uint256 => address) public sireAllowedToAddress;

    //宠物转移
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        //拥有数量增减
        ownershipTokenCount[_to]++;
        kittyIndexToOwner[_tokenId] = _to;

        //地址判断,不能转移到空地址
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            //删除正在交易中的宠物
            delete sireAllowedToAddress[_tokenId];
            //删除正在繁殖交易的宠物
            delete kittyIndexToApproved[_tokenId];
        }
        //事件记录
        Transfer(_from, _to, _tokenId); 
    }

    //创建宠物
    function _createKitty(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        // 保证代数不会溢出
        require(_matronId <= 4294967295);
        require(_sireId <= 4294967295);
        require(_generation <= 65535);
        
        uint[5] memory addprop;
        for (uint index = 0; index < 5; index++) {
            addprop[index] = 0;
        }
        Kitty memory _kitty = Kitty({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndTime: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: 0,
            generation: uint16(_generation),
            addprop:addprop,
            feedtimes:0,
            isTreasure:false,
            isMatch:false
        });

        uint256 newKittenId = kitties.push(_kitty) - 1;

        //上限42亿只宠物
        require(newKittenId <= 4294967295);

        //触发事件
        Birth(
            _owner,
            newKittenId,
            uint256(_kitty.matronId),
            uint256(_kitty.sireId),
            _kitty.genes,
            _kitty.birthTime,
            _kitty.generation
        );

        //转移宠物给拥有者
        _transfer(0, _owner, newKittenId);

        return newKittenId;
    }
}
