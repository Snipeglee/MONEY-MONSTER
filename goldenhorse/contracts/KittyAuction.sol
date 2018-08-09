pragma solidity ^0.4.18;

import "./KittyBreeding.sol";
import "./Auction/ClockAuction.sol";
import "./Auction/SiringClockAuction.sol";
import "./Auction/SaleClockAuction.sol";
import "./Auction/Treasure.sol";
import "./Auction/Arena.sol";

//无锡魔乐科技有限公司技术提供
//宠物拍卖合约
contract KittyAuction is KittyBreeding {
    //货币合约地址
    ERC20Token public moneyContract;
    //寻宝合约地址
    Treasure public treasureContract;
    //竞技场合约
    Arena public arenaContract;
    //拍卖合约地址
    SaleClockAuction public saleAuction;
    //交配合约地址
    SiringClockAuction public siringAuction;

    //创建交易
    function createSaleAuction(
        uint256 _kittyId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
        //创建新的交易
        require(_owns(msg.sender, _kittyId));
        _approve(_kittyId, saleAuction);
        saleAuction.createAuction(
            _kittyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    //发起交易投标
    function bidOnSaleAuction(uint256 _tokenId) public {
        //获取合约信息并转账
        address seller;
        uint sellerProceeds;
        uint auctioneerCut;
        (seller,sellerProceeds,auctioneerCut) = saleAuction.getAuctioninfo(_tokenId);
        transferMMON(msg.sender,seller, sellerProceeds);
        transferMMON(msg.sender,this,auctioneerCut);
        //发起交易
        saleAuction.bid(_tokenId,msg.sender);
    }

    //创建繁殖拍卖
    function createSiringAuction(
        uint256 _kittyId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _kittyId));
        require(isReadyToBreed(_kittyId));
        _approve(_kittyId, siringAuction);
        siringAuction.createAuction(
            _kittyId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    //发起繁殖拍卖投标
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        public
        whenNotPaused
    {
        //检查投标参数
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

        //获取合约信息并转账
        address seller;
        uint sellerProceeds;
        uint auctioneerCut;
        (seller,sellerProceeds,auctioneerCut) = siringAuction.getAuctioninfo(_sireId);
        transferMMON(msg.sender,seller, sellerProceeds);
        transferMMON(msg.sender,this,auctioneerCut);

        //执行交易
        siringAuction.bid(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));

        // bool doAutoBirth = false;
        // if (doAutoBirth) {
        //     //触发自动分娩
        //     Kitty storage matron = kitties[_matronId];
        //     AutoBirth(_matronId, matron.cooldownEndTime);
        // }
    }

    //提取所有交易的手续费
    // function withdrawAuctionBalances() external onlyCOO {
    //     saleAuction.withdrawBalance();
    //     siringAuction.withdrawBalance();
    // }

    //转移MMON
    function transferMMON(address from,address to,uint mmon) internal {
        moneyContract.transferFrom(from, to,mmon);
    }

    //cfo提取手续费
    function withdrawBalance(uint money) external onlyCFO {
        // cfoAddress.transfer(this.balance);
        uint256 balance = moneyContract.balanceOf(this);
        require(money <= balance);
        moneyContract.transfer(cfoAddress,money);
    }
}
