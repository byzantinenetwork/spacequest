// Byzantine Tiles Source code
// Derived from CryptoKitties source code: https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code

pragma solidity ^0.4.17;
import "./ByzantineTileMinting.sol";

/// @title Byzantine Tiles: tiles that can be bought, and then auctioned/traded on the Ethereum blockchain.
/// @author Byzantine (https://byzantine.network)
/// @author for CryptoKitties Axiom Zen (https://www.axiomzen.co)
/// @dev The main Tiles (for Byzantine) contract, keeps track of the tiles.
contract ByzantineTileCore is ByzantineTileMinting {

    // This is the main Byzantine Tiles contract. In order to keep our code separated into logical sections,
    // we've broken it up in two ways. First, we have several seperately-instantiated contracts
    // that handle auctions. The auctions are seperate since their logic is somewhat complex and there's
    // always a risk of subtle bugs. By keeping them in their own contracts, we can upgrade them without
    // disrupting the main contract that tracks tile ownership.
    //
    // Secondly, we break the core contract into multiple files using inheritence, one for each major
    // facet of functionality of BT. This allows us to keep related code bundled together while still
    // avoiding a single giant file with everything in it. The breakdown is as follows:
    //
    //      - ByzantineTileMinting: This contains the functionality we use for creating new tiles.
    //             There is a hard limit of 10,000 tiles. Sale of the first 1000 tiles starts the sale, the first tiles can only
    //             be bought by the COO. Sale ends when all 10,000 tiles have been bought.
    //
    //      - ByzantineTileOwnership: This provides the methods required for basic non-fungible token
    //             transactions, following the draft ERC-721 spec (https://github.com/ethereum/EIPs/issues/721).
    //
    //      - ByzantineTileBase: This is where we define the most fundamental code shared throughout the core
    //             functionality. This includes our main data storage, constants and data types, plus
    //             internal functions for managing these items.
    //
    //      - ByzantineTileAccessControl: This contract manages the various addresses and constraints for operations
    //             that can be executed only by specific roles. Namely CEO, CFO and COO.

    // Set in case the core contract is broken and an upgrade is required
    address public newContractAddress;

    /// @notice Creates the main Tiles smart contract instance.
    function ByzantineTileCore() public {
        // Starts paused.
        pausedPresale = true;

        // date at whic the resale of tiles is permitted (30 days after the last tile is sold)
        byzantineTileAuctionDate = 0;

        // Sale has not begun, will be true once Prime ByzantineTile has been created
        byzantineSaleStarted = false;

        // Sale has not ended, will be true once final ByzantineTile has been created
        byzantineSaleEnded = false;

        // the creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // the creator of the contract is also the initial COO
        cooAddress = msg.sender;

        // the creator of the contract is also the initial CFO
        cfoAddress = msg.sender;
    }

    /// @dev Used to mark the smart contract as upgraded, in case there is a serious
    ///  breaking bug. This method does nothing but keep track of the new contract and
    ///  emit a message indicating that the new address is set. It's up to clients of this
    ///  contract to update to the new contract address in that case. (This contract will
    ///  be paused indefinitely if such an upgrade takes place.)
    /// @param _v2Address new address
    function setNewAddress(address _v2Address) external onlyCEO whenPausedPresale {
        // See README.md for updgrade plan
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

    /// @notice Returns all the relevant information about a specific tile.
    /// @param _id The ID of the tile of interest.
    function getByzantineTile (uint256 _id)
        external
        view
        returns (uint256 mintTime, uint256 originalValue) {
        // make sure _id is within current array bounds, i.e. not higher than the total supply of tiles as of right now
        require(_id < totalSupply());
        ByzantineTile storage byzantineTile = byzantineTiles[_id];
        mintTime = uint256(byzantineTile.mintTime);
        originalValue = uint256(byzantineTile.originalValue);
    }

    /// @dev Override unpause so it requires all external contract addresses
    ///  to be set before contract can be unpaused. Also, we can't have
    ///  newContractAddress set either, because then the contract was upgraded.
    /// @notice This is public rather than external so we can call super.unpause
    ///  without using an expensive CALL.
    function unpausePresale() public onlyCEO whenPausedPresale {
        require(newContractAddress == address(0));

        // Actually unpause the contract.
        super.unpausePresale();
    }

    // @dev Allows the CFO to capture the balance available to the contract.
    function withdrawBalance() external onlyCFO {
        uint256 balance = this.balance;
        if (balance > 0) {
          cfoAddress.transfer(balance);
        }
    }
}
