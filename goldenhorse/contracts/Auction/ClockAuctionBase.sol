pragma solidity ^0.4.18;

import "./../ERC721Draft.sol";
import "./../KittyCore.sol";
import "./../ERC20Draft.sol";

//无锡魔乐科技有限公司技术提供
//拍卖所智能合约
contract ClockAuctionBase {

    //交易数据结构
    struct Auction {
        //当前非同质代币拥有者
        address seller;
        // Price (in wei) at beginning of auction
        uint128 startingPrice;
        // Price (in wei) at end of auction
        uint128 endingPrice;
        //持续时间
        uint64 duration;
        //拍卖时间
        uint64 startedAt;
    }

    //非同质代币合约(宠物合约)
    KittyCore public nonFungibleContract;
     //货币合约地址
    ERC20Token public moneyContract;


    //交易手续费比例
    // 0-10,000 对应  0%-100%
    uint256 public ownerCut;

    //宠物id=>交易合约
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration,address seller);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

    /// @dev DON'T give me your money.
    function() external {}

    //函数修改器-检查参数
    //限定输入来节省gas费用
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= 18446744073709551615);
        _;
    }

    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value < 340282366920938463463374607431768211455);
        _;
    }

    //判断用户地址是否拥有指定代币
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    //托管宠物到交易的合约地址
    function _escrow(address _owner, uint256 _tokenId) internal {
        //失败会抛出异常
        nonFungibleContract.transferFrom(_owner, this, _tokenId);
    }

    //转移宠物给接收者
    function _transfer(address _receiver, uint256 _tokenId) internal {
        //失败会抛出异常
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

    //内部创建一个交易
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        //拍卖时间至少有一分钟
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;
        
        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration),
            address(_auction.seller)
        );
    }

    //无条件终止交易
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

    //投标
    function _bid(uint256 _tokenId) internal returns (uint256) {
        //获取交易内容
        Auction storage auction = tokenIdToAuction[_tokenId];
        //是否存在交易
        require(_isOnAuction(auction));
        //获取当前价格
        uint256 price = _currentPrice(auction);
        //出售者
        address seller = auction.seller;
        //删除交易
        _removeAuction(_tokenId);
        // //转移出售金给玩家
        if (price > 0) {
            //扣除手续费
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;
            //转移金币给卖家
            // moneyContract.transferFrom(msg.sender,seller, sellerProceeds);
            // moneyContract.transferFrom(msg.sender,this, auctioneerCut);
        }

        //触发全局事件
        AuctionSuccessful(_tokenId, price, msg.sender);
        return price;
    }

    //获取合约费用及手续费
    function getAuctioninfo(uint256 _tokenId) public view returns (address seller,uint sellerProceeds,uint auctioneerCut) {
        //获取交易内容
        Auction storage auction = tokenIdToAuction[_tokenId];
        seller = auction.seller;
        uint price = _currentPrice(auction); 
        auctioneerCut = _computeCut(price);
        sellerProceeds = price - auctioneerCut;
    }


    //删除交易
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    //查看是否在交易上
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    //查看当前的价格
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        uint256 secondsPassed = 0;
        
        //上架时间计算
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
            secondsPassed
        );
    }

    //计算当前价格
    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
    
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
            //起拍价通常比成交价高
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);
            
            //当前变化价格
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);
            
            //当前价格
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;
            
            return uint256(currentPrice);
        }
    }

    //计算手续费
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }

    //设置新的拍卖合约
    function setMoneyAddress(address _address) public {
        require(msg.sender == address(nonFungibleContract));
        ERC20Token candidateContract = ERC20Token(_address);
        //设置法定货币合约地址
        moneyContract = candidateContract;
    }

}
