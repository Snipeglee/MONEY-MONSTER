pragma solidity ^0.4.18;

import "./KittyBase.sol";
import "./ERC721Draft.sol";

//无锡魔乐科技有限公司技术提供
//宠物所有权合约
contract KittyOwnership is KittyBase, ERC721 {

    //非同质货币 ERC721.
    string public name = "CryptoPony";
    string public symbol = "CP";


    //(ERC-721协议标准函数)
    function implementsERC721() public pure returns (bool)
    {
        return true;
    }
    
    //查看用户是否拥有指定的宠物
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return kittyIndexToOwner[_tokenId] == _claimant;
    }

    //查看宠物是否被授权到指定的合约地址
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return kittyIndexToApproved[_tokenId] == _claimant;
    }

    //授权宠物到指定合约地址(交易合约|繁殖交易合约)
    function _approve(uint256 _tokenId, address _approved) internal {
        kittyIndexToApproved[_tokenId] = _approved;
    }

    //coo分配宠物给指定用户
    function rescueLostKitty(uint256 _kittyId, address _recipient) public onlyCOO whenNotPaused {
        require(_owns(this, _kittyId));
        _transfer(this, _recipient, _kittyId);
    }

    //返回宠物数量(ERC-721协议标准函数)
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

    //宠物赠送 (ERC-721协议标准函数)
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        //接受者地址不能为空
        require(_to != address(0));
        //发送者必须拥有这只宠物
        require(_owns(msg.sender, _tokenId));
        //宠物转移
        _transfer(msg.sender, _to, _tokenId);
    }

    //授权合约地址 (ERC-721协议标准函数)
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        //只有拥有者才能授权
        require(_owns(msg.sender, _tokenId));

        //调用内部方法授权
        _approve(_tokenId, _to);

        //记录授权日志
        Approval(msg.sender, _to, _tokenId);
    }

    //合约方发动交易 (ERC-721协议标准函数)
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        //检查合约方,检查拥有方
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        //转移宠物
        _transfer(_from, _to, _tokenId);
    }

    //获取当前宠物数量 (ERC-721协议标准函数)
    function totalSupply() public view returns (uint) {
        return kitties.length - 1;
    }

    //返回宠物拥有者地址
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = kittyIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    //获取拥有者第_index只宠物
    function tokensOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 tokenId)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (kittyIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }
}
