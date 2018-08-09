pragma solidity ^0.4.18;

import "./KittyAuction.sol";

//无锡魔乐科技有限公司技术提供
//宠物创造协议
contract KittyMinting is KittyAuction {
    // 限制协约控制者创造宠物的数量
    uint256 public promoCreationLimit = 5000;
    uint256 public gen0CreationLimit = 50000;

    //零代宠物相关常量
    uint256 public gen0StartingPrice = 1*10**6;
    uint256 public gen0AuctionDuration = 1 days;

    //宠物数量变量
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    //创造特定基因的一只宠物
    function createPromoKitty(uint256 _genes,address _owner) public onlyCOO {
        address coo = _owner;
        if (_owner == address(0)) {
            coo = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit);
        require(gen0CreatedCount < gen0CreationLimit);

        promoCreatedCount++;
        gen0CreatedCount++;
        _createKitty(0, 0, 0, _genes, coo);
    }

    //创建零代宠物并挂到交易合约出售
    function createGen0Auction(uint256 _genes) public onlyCOO {
        require(gen0CreatedCount < gen0CreationLimit);

        uint256 kittyId = _createKitty(0, 0, 0, _genes, address(this));
        _approve(kittyId, saleAuction);

        saleAuction.createAuction(
            kittyId,
            _computeNextGen0Price(),
            _computeNextGen0Price(),
            gen0AuctionDuration,
            address(this)
        );

        gen0CreatedCount++;
    }

    //计算下一只零代宠物的价格
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 avePrice = saleAuction.averageGen0SalePrice();

        //防溢出 (this big number is 2^128-1).
        require(avePrice < 340282366920938463463374607431768211455);

        uint256 nextPrice = avePrice + (avePrice / 2);

        //销售价格不能低于起始价格
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}
