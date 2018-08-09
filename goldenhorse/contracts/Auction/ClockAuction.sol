pragma solidity ^0.4.18;

import "./../ERC721Draft.sol";
import "./ClockAuctionBase.sol";
import "./Pausable.sol";

//无锡魔乐科技有限公司技术提供
//拍卖所智能合约
contract ClockAuction is Pausable, ClockAuctionBase {

    function ClockAuction(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;
        
        KittyCore candidateContract = KittyCore(_nftAddress);
        require(candidateContract.implementsERC721());
        nonFungibleContract = candidateContract;
    }

    //提取手续费
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress    
        );
        
        uint256 balance = moneyContract.balanceOf(this);
        moneyContract.transfer(nftAddress,balance);
    }

    //结束交易
    function cancelAuction(uint256 _tokenId)
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    //交易结束回调事件
    function cancelAuctionWhenPaused(uint256 _tokenId)
        whenPaused
        onlyOwner
        public
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    //获取交易信息
    function getAuction(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    //获取当前交易价格
    function getCurrentPrice(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }

    //设置手续费比例
    function setOwnerCut(uint256 _cut) public {
        require(msg.sender ==  address(nonFungibleContract.ceoAddress()) || msg.sender ==  address(nonFungibleContract.cooAddress()));
        require(_cut <= 10000);
        ownerCut = _cut;
    }
}
