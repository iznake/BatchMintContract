// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Deployed {
    function mint(uint256 amount) public payable {}

    function tokenOfOwnerByIndex(address user, uint256 id)
        public
        view
        returns (uint256)
    {}
}

contract contractMint is IERC721Receiver , Ownable {
    Deployed dc;
    address target;
    uint256 public MAX_SUPPLY;
    uint256 public NFT_PRICE;
    uint256 public MAX_PER_WALLET;
    event log(address user, uint256 id);

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override returns (bytes4) {
        return 0x150b7a02;
    }

    constructor(
        address _target,
        uint256 _max_supply,
        uint256 _nft_price,
        uint256 _max_per_wallet
    ) payable {
        target = _target;
        dc = Deployed(_target);
        MAX_SUPPLY = _max_supply;
        NFT_PRICE = _nft_price;
        MAX_PER_WALLET = _max_per_wallet;

        //mint
        (bool success, ) = address(_target).call{value: MAX_PER_WALLET * NFT_PRICE}(
            abi.encodePacked(bytes4(keccak256("mint(uint256)")), MAX_PER_WALLET)
        ); // D's storage is set, E is not modified        

        //transfer NFTs
        ERC721 token = ERC721(_target);
        for (uint256 i = 0; i < MAX_PER_WALLET; i++) {
            if (token.balanceOf(address(this)) > 0) {
                //TODO : use call instead of interface
                // (bool success, bytes memory returnData) = target.call(bytes4(keccak256(abi.encodePacked("tokenOfOwnerByIndex(address,uint256)")),address(this), i));
                // require(success);
                uint256 tokenId = dc.tokenOfOwnerByIndex(address(this), 0);
                require(
                    token.ownerOf(tokenId) == address(this),
                    "You must own the token"
                );
                token.transferFrom(address(this), address(tx.origin), tokenId);
            }
        }

        //withdraw money
       selfdestruct(payable(address(tx.origin)));
    }   
}

contract myMintFactory is Ownable {
    contractMint[] public _mint;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant NFT_PRICE = 0.001 ether;
    uint256 public constant MAX_PER_WALLET = 2;
    

    function call(address _t,uint256 times) external   payable onlyOwner {
        for(uint i=0;i<times;++i){
            new contractMint{ value: (MAX_PER_WALLET + 1) * NFT_PRICE  }
            (_t, MAX_SUPPLY, NFT_PRICE, MAX_PER_WALLET);
        }
    }
}
