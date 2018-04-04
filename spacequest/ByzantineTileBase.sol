pragma solidity ^0.4.17;
import "./ByzantineTileAccessControl.sol";
//import "./Byzantine_07_SaleClockAuction.sol";
/// @title Base contract for ByzantineTiles. Holds all common structs, events and base variables.
/// @author Byzantine (https://byzantine.network)
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the ByzantineTileCore contract documentation to understand how the various contract facets are arranged.
contract ByzantineTileBase is ByzantineTileAccessControl {
    /*** EVENTS ***/

    /// @dev The Mint event is fired whenever a new ByzantineTile comes into existence.
    event MintByzantineTile(address owner);

    /// @dev Transfer event as defined in current draft of ERC721. Emitted every time a ByzantineTile
    ///  ownership is assigned, including when newly minted.
    event Transfer(address from, address to, uint256 tokenId);

    /*** DATA TYPES ***/

    /// @dev The main ByzantineTile struct.
    /// This is just the Mint time of the ByzantineTile and the original value
    ///  Ref: http://solidity.readthedocs.io/en/develop/miscellaneous.html
    struct ByzantineTile {
      uint256 mintTime;
      uint256 originalValue;
    }

    /*** STORAGE ***/

    /// @dev An array containing the ByzantineTile struct for all ByzantineTiles in existence. The ID
    ///  of each tile is actually an index into this array.
    ByzantineTile[] byzantineTiles;

    /// @dev A mapping from tile IDs to the address that owns them. All tiles have
    ///  some valid owner address.
    mapping (uint256 => address) public byzantineTileIndexToOwner;

    // @dev A mapping from owner address to count of tokens that address owns.
    //  Used internally inside balanceOf() to resolve ownership count.
    mapping (address => uint256) ownershipTokenCount;

    /// @dev A mapping from ByzantineTileIDs to an address that has been approved to call
    ///  transferFrom(). Each tile can only have one approved address for transfer
    ///  at any time. A zero value means no approval is outstanding.
    mapping (uint256 => address) public byzantineTileIndexToApproved;

    /// @dev The address of the ClockAuction contract that handles sales of ByzantineTiles. This
    ///  contract handles peer-to-peer sales.
    //SaleClockAuction public saleAuction;

    /// @dev Assigns ownership of a specific tile to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        // Since the number of tiles is capped to 2^32 we can't overflow this
        ownershipTokenCount[_to]++;
        // transfer ownership
        byzantineTileIndexToOwner[_tokenId] = _to;
        // When creating new tiles _from is 0x0, but we can't account that address.
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            // clear any previously approved ownership exchange
            delete byzantineTileIndexToApproved[_tokenId];
        }
        // Emit the transfer event.
        Transfer(_from, _to, _tokenId);
    }

    /// @dev An internal method that creates a new ByzantineTile and stores it. This
    ///  method doesn't do any checking and should only be called when the
    ///  input data is known to be valid. Will generate both a Mint event
    ///  and a Transfer event.
    /// @param _owner The inital owner of this ByzantineTile, must be non-zero
    function _mintByzantineTile(address _owner, uint256 value) internal returns (uint256) {

        ByzantineTile memory _byzantineTile = ByzantineTile({
            mintTime: uint256(now),
            originalValue: uint256(value)
        });
        uint256 newByzantineTileId = byzantineTiles.push(_byzantineTile) - 1;

        // It's probably never going to happen, 4 billion tiles is A LOT, but
        // let's just be 100% sure we never let this happen.
        require(newByzantineTileId == uint256(uint32(newByzantineTileId)));

        // emit the Mint event
        MintByzantineTile(_owner);

        // This will assign ownership, and also emit the Transfer event as
        // per ERC721 draft
        _transfer(0, _owner, newByzantineTileId);

        return newByzantineTileId;
    }
}
