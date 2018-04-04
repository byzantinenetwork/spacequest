pragma solidity ^0.4.17;
/// @title A facet of ByzantineTileCore that manages special access privileges.
/// @author Byzantine (https://byzantine.network)
/// @author Axiom Zen (https://www.axiomzen.co)
/// @dev See the ByzantineTileCore contract documentation to understand how the various contract facets are arranged.
contract ByzantineTileAccessControl {
    // This facet controls access control for ByzantineTiles. There are four roles managed here:
    //
    //     - The CEO: The CEO can reassign other roles and change the addresses of our dependent smart
    //         contracts. It is also the only role that can unpause the smart contract. It is initially
    //         set to the address that created the smart contract in the ByzantineTileCore constructor.
    //
    //     - The CFO: The CFO can withdraw funds from ByzantineTileCore and its auction contracts.
    //
    //     - The COO: The COO can release ByzantineTiles to auction, and mint ByzantineTiles.
    //
    // It should be noted that these roles are distinct without overlap in their access abilities, the
    // abilities listed for each role above are exhaustive. In particular, while the CEO can assign any
    // address to any role, the CEO address itself doesn't have the ability to act in those roles. This
    // restriction is intentional so that we aren't tempted to use the CEO address frequently out of
    // convenience. The less we use an address, the less likely it is that we somehow compromise the
    // account.

    /// @dev Emited when contract is upgraded - See README.md for updgrade plan
    event ContractUpgrade(address newContract);

    // The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public pausedPresale;

    // @dev Set to true once the Prime ByzantineTile has been created by the COO, which marks the start of the sale.
    bool public byzantineSaleStarted;

    // Set to true when the last tile is minted in the sale
    bool public byzantineSaleEnded;

    // The date at which resale can commence, after the last tile has been minted/sold plus the cooldown period
    uint256 public byzantineTileAuctionDate;

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /// @dev Assigns a new address to act as the CFO. Only available to the current CEO.
    /// @param _newCFO The address of the new CFO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPausedPresale() {
        require(!pausedPresale);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPausedPresale {
        require(pausedPresale);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pausePresale() external onlyCLevel whenNotPausedPresale {
        pausedPresale = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpausePresale() public onlyCEO whenPausedPresale {
        // can't unpause if contract was upgraded
        pausedPresale = false;
    }

}
