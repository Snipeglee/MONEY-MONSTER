pragma solidity ^0.4.21;

import "./KittyMinting.sol";
import "./ERC20Draft.sol";

//无锡魔乐科技有限公司技术提供
//宠物法定货币合约 && 定制化修改
contract KittyMoney is KittyMinting {
    //仓库货币
    mapping (address => uint256) ownershipMMONCount;

    //喂养全局通知
    event Feed(address indexed owner, uint256 kittyId, uint256 propindex, uint256 num,uint256 isadd,uint[5] addprop);
    event TreasureHunt(address indexed owner,uint kittyId,uint cooldownEndTime);
    event TreasureOver(address indexed owner,uint kittyId,uint money);

    //宠物喂养
    function feed(uint256 _id,uint8 _index,uint food,uint num) public {
        uint8 index = _index;
        require(index>=1 && index<=5);
        require(food>=1 && food<=4);
        require(num>=1 && num<=5);
        require(_owns(msg.sender, _id));
        Kitty storage kit = kitties[_id];
        uint[10] memory horseprop = geneScience.getHorseProp(kit.genes);
        //基础价格 & 增加的属性
        uint[4] memory addlist=[uint(20),uint(40),uint(40),uint(80)];
        uint[4] memory moneylist=[uint(30),uint(60),uint(50) ,uint(100)];
        uint256 money = moneylist[food-1]*1000000;
        uint add = addlist[food-1]*num;
        //恶魔果实特殊处理
        if(food>=3 && food<=4){
            add =  (food ==3?20:40) + (add- (food ==3?20:40))*((uint256(keccak256(block.timestamp, msg.sender, uint(55)))) % 101)/100;
            add = add*num;
        }
        uint256 finalmoney = 0;
        uint8 i=0;
        for(i=0;i<num;i++){
            finalmoney+=(11**(kit.feedtimes+i))*money/(10**(kit.feedtimes+i));
        }
        //收取喂养获得的怪兽币
        moneyContract.transferFrom(msg.sender,this,finalmoney);
        //恶魔果实结果 60%是好  40%是差
        uint isgood = uint256(keccak256(block.timestamp, msg.sender, 1)) % 10;
        isgood = isgood<=5?1:0;
        index--;
        if(isgood==1 || food<3){
            isgood=1;
            kit.addprop[index]+=add;
            //属性封顶
            if(kit.addprop[index]>horseprop[index+4]){
                kit.addprop[index]=horseprop[index+4];
                add=0;
            }
        }
        else{
            if(kit.addprop[index]>add)
                kit.addprop[index]-=add;
            else{
                add=kit.addprop[index];
                kit.addprop[index]=0;
            }
        }
        kit.feedtimes+=num;
        Feed(msg.sender,_id,index,add,isgood,kit.addprop);
    }

    //查看仓库库存
    function balanceOfDepot(address owner) public view returns(uint){
        return ownershipMMONCount[owner];
    }

    //提现仓库
    function withDrawDepot() public {
        require(ownershipMMONCount[msg.sender] > 0);
        uint money= ownershipMMONCount[msg.sender];
        ownershipMMONCount[msg.sender]=0;
        moneyContract.transfer(msg.sender,money);
    }

    //设置所有合约地址
    function setAuctionAddress(address gene,address money,address sale,address siring,address treasure,address arena) public onlyCLevel {
        //设置基因地址
        geneScience = GeneScienceInterface(gene);
        // require(geneScience.isGeneScience());
        //设置法定货币合约地址
        moneyContract = ERC20Token(money);
        //寻宝地址
        treasureContract = Treasure(treasure);
        // require(treasureContract.isTreasure());
        //交易合约地址
        saleAuction = SaleClockAuction(sale);
        saleAuction.setMoneyAddress(money);
        // require(saleAuction.isSaleClockAuction());
        //设置新合约地址
        siringAuction = SiringClockAuction(siring);
        siringAuction.setMoneyAddress(money);
        // require(siringAuction.isSiringClockAuction());
        //设置竞技场合约
        arenaContract = Arena(arena);
    }

    //收取用户费用||增加用户库存(限信任用户)
    function changeMoney(address owner,uint mmon,uint depot) public{
        require(msg.sender == address(treasureContract) || msg.sender == address(arenaContract));
        if(mmon>0){
            transferMMON(owner,this,mmon);
        }
        if(depot>0){
            ownershipMMONCount[owner]+=depot;
        }
    }

    //改变宠物状态||增加用户库存(限信任用户)
    function changeHorse(uint _id,uint8 isTreasure,uint treasure,uint8 isMatch,uint64 cooldownEndTime) public{
        require(msg.sender == address(treasureContract) || msg.sender == address(arenaContract));
        Kitty storage kit = kitties[_id];
        kit.cooldownEndTime=cooldownEndTime;
        //寻宝
        if(isTreasure == 1){
            kit.isTreasure = true;
            TreasureHunt(ownerOf(_id),_id,cooldownEndTime);
        }
        else if(isTreasure == 2){
            kit.isTreasure = false;
            TreasureOver(ownerOf(_id),_id,treasure);
        }
        //比赛
        if(isMatch == 1){
            kit.isMatch = true;
        }
        else if(isMatch == 2){
            kit.isMatch = false;
        }
    }
}
