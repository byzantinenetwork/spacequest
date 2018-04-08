pragma solidity ^0.4.17;
import "./ByzantineTileOwnership.sol";
import "./SafeMath.sol";

/// @title all functions related to creating tiles
contract ByzantineTileMinting is ByzantineTileOwnership {

    // Tiles purchased event
    event TilesPurchased(address indexed purchaser, uint256 value, uint256 quantity);

    // Constants for ByzantineTiles:

    // total number of genesis tiles that can be minted before the sale starts
    uint256 constant public BYZANTINE_TILE_GENESIS_TILES_NUMBER = 1000;

    // tile count for sale pause 1 to trigger
    uint256 constant public BYZANTINE_TILE_SALE_PAUSE_1 = 1100;

    // tile count for sale pause 2 to trigger
    uint256 constant public BYZANTINE_TILE_SALE_PAUSE_2 = 2000;

    // Limits the number of ByzantineTiles the contract owner can ever create.
    uint256 constant public BYZANTINE_TILE_CREATION_LIMIT = 10000;

    // starting price for tiles, all genesis tiles have this originalValue 0.0201 ETH
    uint256 constant public BYZANTINE_TILE_STARTING_PRICE = 0.0201 ether;

    // Purchased tiles cannot be resold until 30 days after the last tile has been sold
    uint256 constant public BYZANTINE_TILE_AUCTION_COOLDOWN_DURATION = 30 days;

    // The increase rate for tile price as more tiles are purchased 0.001011 ETH
    uint256 constant public INCREASE_RATE = 0.001011 ether;

    // Number of tiles that can be bought all at once in one transaction
    uint256 constant public BULK_QUANTITY = 3;

    // Number of tiles that can be bought all at once in one transaction
    uint256 constant public BULK_MINTING_QUANTITY = 50;

    // Counts the total number of sales, for use with increase rate
    uint256 public byzantineTileSalesCount = 0;

    using SafeMath for uint256;

    /// @dev we can create a single Genesis ByzantineTile. Only callable by COO
    /// @param _owner the future owner of the created ByzantineTile. Default to contract COO
    function mintGenesisByzantineTiles(address _owner) external onlyCOO whenNotPausedPresale {
      // COO can create an initial tile, only once, which then begins the sale of the remaining 9,999 (i.e. 10,000-1) tiles
      require (byzantineSaleStarted == false);
      // Don't mint a Genesis tile if the sale has ended, with the maximum number of tiles alredy sold
      require (byzantineSaleEnded == false);
      // Must be a valid owner address
      require (_owner != address(0));
      for (uint256 i = 0; i < BULK_MINTING_QUANTITY; i++) {
        // Mint the Byzantine Tile and assign it to the specified owner, with the starting price as its original value
        _mintByzantineTile(_owner, BYZANTINE_TILE_STARTING_PRICE);
      }
      if (totalSupply() >= BYZANTINE_TILE_GENESIS_TILES_NUMBER) {
        // All genesis tiles are now minted, so let's start the sale of the rest
        byzantineSaleStarted = true;
      }
    }

    // Mint a single non-Genesis tile
    function mintRegularByzantineTile(address _owner, uint256 value) private whenNotPausedPresale {
      // Only create more tiles once the sale has started. COO must have created the prime tile.
      require (byzantineSaleStarted == true);
      // Don't mint any more tiles if the sale has ended, with the maximum number of tiles alredy sold
      require (byzantineSaleEnded == false);
      // Must be valid purchaser adrdess
      require (_owner != address(0));
      // Only mint tiles up to the maximum amount
      require (totalSupply() < BYZANTINE_TILE_CREATION_LIMIT);
      // Mint the Byzantine Tile and assign it to the specified owner
      _mintByzantineTile(_owner, value);
      // If we reached the maximum number of tiles to be sold in the sale, then end the sale
      if (totalSupply() >= BYZANTINE_TILE_CREATION_LIMIT)
      {
        // sale has ended
        byzantineSaleEnded = true;
        // Auctions begin after the cooldown period
        byzantineTileAuctionDate = now + BYZANTINE_TILE_AUCTION_COOLDOWN_DURATION;
      }
    }

      // Purchase a single tile at one time
    function purchaseTile() payable public whenNotPausedPresale {
        // sale must have started
        require(byzantineSaleStarted == true);
        // Don't sell any more tiles if the sale has ended, with the maximum number of tiles alredy sold
        require (byzantineSaleEnded == false);
        // Must be valid sender address
        require(msg.sender != address(0));
        // must be correct purchase price
        require(msg.value >= tilePrice());
        // Mint a new tile and assign it to the new owner, with a value of the current tile price
        mintRegularByzantineTile(msg.sender, tilePrice());
        // Check for over payment and return the excess to the buyer
        uint256 paymentExcess = msg.value.sub(tilePrice());
        // Return the funds.
        if (paymentExcess > 0) {
          msg.sender.transfer(paymentExcess);
        }
        // update purchasers purchased tile count
        ownershipTokenCount[msg.sender] = ownershipTokenCount[msg.sender].add(1);
        // update the total sales count
        byzantineTileSalesCount = byzantineTileSalesCount.add(1);
        // emit the TilesPurchased event
        TilesPurchased(msg.sender, msg.value, 1);
        // check for sale pause 1 tile supply
        if (totalSupply() == BYZANTINE_TILE_SALE_PAUSE_1) {
          // pause the sale automatically now
          pausedPresale = true;
        }
        // check for sale pause 2 tile supply
        else if (totalSupply() == BYZANTINE_TILE_SALE_PAUSE_2) {
          // pause the sale automatically now
          pausedPresale = true;
        }
    }

    // Purchase several tiles at once
    function bulkPurchaseTile() payable public whenNotPausedPresale {
        // sale must have started
        require(byzantineSaleStarted == true);
        // Don't sell any more tiles if the sale has ended, with the maximum number of tiles alredy sold
        require (byzantineSaleEnded == false);
        // Must be valid sender address
        require(msg.sender != address(0));
        uint256 newTotal = totalSupply() + BULK_QUANTITY;
        // Only allow a bulk purchase if there are enough tiles left
        require(newTotal <= BYZANTINE_TILE_CREATION_LIMIT);
        // if this bulk purchase will not overshoot the a sale pause, let it happen
        if ((newTotal > BYZANTINE_TILE_SALE_PAUSE_1) && (newTotal < BYZANTINE_TILE_SALE_PAUSE_1.add(BULK_QUANTITY)) ||
            (newTotal > BYZANTINE_TILE_SALE_PAUSE_2) && (newTotal < BYZANTINE_TILE_SALE_PAUSE_2.add(BULK_QUANTITY))) {
        // sale will overshoot a sale pause , stop this bulk sale
        revert();
        }
        // must be correct purchase price
        require(msg.value >= (tilePrice().mul(BULK_QUANTITY)));
        // Mint the bulk quantity of tiles for the sender, with the value set to the current tile price
        for (uint256 i = 0; i < BULK_QUANTITY; i++) {
          mintRegularByzantineTile(msg.sender, tilePrice());
        }
        // Check for over payment and return the excess to the buyer
        uint256 paymentExcess = msg.value.sub(tilePrice().mul(BULK_QUANTITY));
        // Return the funds.
        if (paymentExcess > 0) {
          msg.sender.transfer(paymentExcess);
        }
        // update purchasers purchased tile count
        ownershipTokenCount[msg.sender] = ownershipTokenCount[msg.sender].add(BULK_QUANTITY);
        // update the total sales count, BULK_QUANTITY counts as one sale
        byzantineTileSalesCount = byzantineTileSalesCount.add(1);
        // emit the TilesPurchased event
        TilesPurchased(msg.sender, msg.value, BULK_QUANTITY);
        // since we allowed a bulk sale we can now test to see if it hit one of the sale pause totals
        // check for sale pause 1 tile supply
        if (totalSupply() == BYZANTINE_TILE_SALE_PAUSE_1) {
          // pause the sale automatically now
          pausedPresale = true;
        }
        // check for sale pause 2 tile supply
        else if (totalSupply() == BYZANTINE_TILE_SALE_PAUSE_2) {
          // pause the sale automatically now
          pausedPresale = true;
        }
    }

    // Return the current price for tiles
    function tilePrice() view public returns(uint256) {
        return (BYZANTINE_TILE_STARTING_PRICE + byzantineTileSalesCount.add(1).mul(INCREASE_RATE));
    }
}
