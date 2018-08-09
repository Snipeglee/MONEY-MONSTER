pragma solidity ^0.4.18;

import "./../ERC721Draft.sol";
import "./../KittyCore.sol";
import "./../ERC20Draft.sol";
import "./Pausable.sol";
import "../ExternalInterfaces/GeneScienceInterface.sol";
//无锡魔乐科技有限公司技术提供
//寻宝合约
contract Treasure is Pausable{
    //非同质代币合约(宠物合约)
    KittyCore public nonFungibleContract;
    //是否是寻宝合约
    bool public isTreasure = true;
    //2018-06-01 00:00:00
    uint64 public ts = 1527782400;

    //交易数据结构
    struct Auction {
        //寻宝能力值
        uint128 ability;
        //开始寻宝时间
        uint64 startedAt;
        //结束寻宝时间
        uint64 endAt;
    }
    //挖矿结算间隔
    uint public interval = uint32(24 hours);
    //单次挖矿的奖励MMON总额
    uint public interval_reward = 3000*10**6;
    //挖矿发奖点的能力总值
    mapping (uint64 => uint256) public timeforce;
    //单个宠物的寻宝信息
    mapping (uint256 => Auction) public tokenIdToAuction;
    
    function Treasure(address _nftAddress) public {
        //宠物合约地址
        KittyCore candidateContract = KittyCore(_nftAddress);
        require(candidateContract.implementsERC721());
        nonFungibleContract = candidateContract;
    }
    
    function speed2duration(uint64 speed) public view returns(uint64){
        uint64 duration = uint64(9000*interval/speed+interval/2);
        return duration;
    }

    //查看寻宝信息
    function treasureInfo(uint256 tokenId) public view returns(uint128,uint64,uint64){
        Auction storage auction = tokenIdToAuction[tokenId];
        return(auction.ability,auction.startedAt,auction.endAt);
    }

    //发起寻宝
    function treasureHunt(uint256 tokenId) public {
        uint genes;
        uint siringWithId;
        bool isTreasure;
        uint cooldownEndTime;
        uint[5] memory addprop;
        (genes, addprop, siringWithId, isTreasure, cooldownEndTime) = getKitty(tokenId);
        //参数判断
        require(msg.sender == nonFungibleContract.ownerOf(tokenId));
        require(genes>0);
        require(siringWithId == 0) ;
        require(cooldownEndTime <= now);
        require(tokenIdToAuction[tokenId].startedAt == 0);
        GeneScienceInterface geneScience = GeneScienceInterface(nonFungibleContract.geneScience());

        //计算能力值和寻宝速度
        uint[10] memory horseprop = geneScience.getHorseProp(genes);
        uint128 ability = uint128(30*(horseprop[0]+addprop[0]) + 40*(horseprop[1]+addprop[1]) + 30*(horseprop[2]+addprop[2]))/100;
        uint64 speed = uint64(15*(horseprop[3]+addprop[3]) + 15*(horseprop[4]+addprop[4]));

        //修改主合约宠物状态
        nonFungibleContract.changeHorse(tokenId,1,0,0,uint64(now+speed2duration(speed)));

        //创建寻宝记录
        uint64 endtime = uint64(ts+((uint64(now)+speed2duration(speed)-ts)/interval+1)*interval);
        Auction memory auction = Auction(
            ability,
            uint64(now),
            endtime
        );
        tokenIdToAuction[tokenId]=auction; 
        timeforce[endtime] += ability;
    }

    //收获宝藏
    function getTreasure(uint256 tokenId) public{
        uint genes;
        uint siringWithId;
        bool isTreasure;
        uint cooldownEndTime;
        uint[5] memory addprop;
        (genes, addprop, siringWithId, isTreasure, cooldownEndTime) = getKitty(tokenId);
        //参数判断
        require(cooldownEndTime <= now);
        //确认玩家是否拥有
        require(nonFungibleContract.ownerOf(tokenId) == msg.sender);
        //确认宠物是否在寻宝中
        require(tokenIdToAuction[tokenId].startedAt > 0 && tokenIdToAuction[tokenId].ability > 0);
        //确认该时间点有人寻宝
        require(timeforce[tokenIdToAuction[tokenId].endAt] > 0);
        
        //删除交易
        uint reward = interval_reward*tokenIdToAuction[tokenId].ability/timeforce[tokenIdToAuction[tokenId].endAt];
        delete tokenIdToAuction[tokenId];
        //发放奖励
        nonFungibleContract.changeMoney(msg.sender,0,reward);
        nonFungibleContract.changeHorse(tokenId,2,reward,0,uint64(cooldownEndTime));
    }

    //设置寻宝参数
    function setParams(uint _interval,uint _interval_reward) public {
        require(msg.sender ==  address(nonFungibleContract.cooAddress()));
        require(_interval > uint32(1 minutes));
        require(_interval_reward > uint256(10**6));
        interval = _interval;
        interval_reward = _interval_reward;
    }

    function getKitty(uint _id) public view returns(uint genes,uint[5] addprop,uint siringWithId,bool isTreasure,uint cooldownEndTime){
        bool isMatch;
        (genes, addprop,siringWithId, isTreasure, isMatch, cooldownEndTime) = nonFungibleContract.getKittyGenes(_id);
    }
}