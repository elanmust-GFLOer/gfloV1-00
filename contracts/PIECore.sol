// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGFLO {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract PIECore {
    enum Path { None, Sovereign, Reformer, Praxis }

    struct Identity {
        uint256 xp;
        Path path;
        uint8 tier;
    }

    mapping(address => Identity) public identities;
    IGFLO public gfloToken;
    address public owner;
    mapping(address => bool) public authorizedCallers;

    // Nonces for signed grants (per recipient)
    mapping(address => uint256) public nonces;

    // EIP-712 domain separator
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public constant GRANT_TYPEHASH = keccak256("Grant(address to,uint256 amount,uint256 nonce,uint256 deadline)");

    uint256 public constant SOVEREIGN_TIER1_XP = 1000;
    uint256 public constant REFORMER_BURN_AMOUNT = 5000 * 10**18;

    event PathChosen(address indexed user, Path path);
    event XPGained(address indexed user, uint256 amount);
    event TierUpgraded(address indexed user, uint8 newTier);
    event CommitmentBurned(address indexed user, uint256 amount);
    event XpGrantedSigned(address indexed signer, address indexed to, uint256 amount);

    constructor(address _gfloAddress) {
        gfloToken = IGFLO(_gfloAddress);
        owner = msg.sender;

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("PIECore")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender] || msg.sender == owner, "Not authorized");
        _;
    }

    function setAuthorizedCaller(address caller, bool status) external onlyOwner {
        authorizedCallers[caller] = status;
    }

    // Only allow initial choice of Sovereign to prevent skipping progression
    function choosePath(Path _path) external {
        require(_path == Path.Sovereign, "Initial path must be Sovereign");
        require(identities[msg.sender].path == Path.None, "Already chosen");
        identities[msg.sender].path = _path;
        identities[msg.sender].tier = 0;
        emit PathChosen(msg.sender, _path);
    }

    // Protect XP grants behind authorization; use addXP for external grantors
    function gainXP(uint256 amount) external onlyAuthorized {
        require(identities[msg.sender].path != Path.None, "Choose path first");
        identities[msg.sender].xp += amount;
        emit XPGained(msg.sender, amount);
    }

    function addXP(address user, uint256 amount) external onlyAuthorized {
        identities[user].xp += amount;
        emit XPGained(user, amount);
    }

    // Grant XP via an off-chain EIP-712 signature from an authorized signer
    // This allows governance/leadership to sign attestations off-chain
    function grantXPWithSig(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature
    ) external {
        if (deadline != 0) {
            require(block.timestamp <= deadline, "Signature expired");
        }

        bytes32 structHash = keccak256(abi.encode(
            GRANT_TYPEHASH,
            to,
            amount,
            nonce,
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        address signer = _recoverSigner(digest, signature);
        require(signer != address(0), "Invalid signature");
        require(authorizedCallers[signer] || signer == owner, "Signer not authorized");
        require(nonce == nonces[to], "Invalid nonce");

        nonces[to]++;
        identities[to].xp += amount;
        emit XPGained(to, amount);
        emit XpGrantedSigned(signer, to, amount);
    }

    // Upgrade path functions remain unchanged, they enforce progression and burns
    function upgradeToReformer() external {
        Identity storage user = identities[msg.sender];
        require(user.path == Path.Sovereign, "Must be Sovereign first");
        require(user.xp >= SOVEREIGN_TIER1_XP, "Insufficient XP");
        require(gfloToken.transferFrom(msg.sender, address(this), REFORMER_BURN_AMOUNT), "Transfer failed");
        gfloToken.burn(REFORMER_BURN_AMOUNT);
        user.path = Path.Reformer;
        user.tier = 1;
        emit CommitmentBurned(msg.sender, REFORMER_BURN_AMOUNT);
        emit PathChosen(msg.sender, Path.Reformer);
    }

    function upgradeToPraxis() external {
        Identity storage user = identities[msg.sender];
        require(user.path == Path.Reformer, "Must be Reformer first");
        require(user.xp >= 5000, "Insufficient XP for Praxis");
        uint256 PRAXIS_BURN = 10000 * 10**18;
        require(gfloToken.transferFrom(msg.sender, address(this), PRAXIS_BURN), "Transfer failed");
        gfloToken.burn(PRAXIS_BURN);
        user.path = Path.Praxis;
        user.tier = 2;
        emit CommitmentBurned(msg.sender, PRAXIS_BURN);
        emit PathChosen(msg.sender, Path.Praxis);
    }

    function getTier(address user) external view returns (uint8) {
        return identities[user].tier;
    }

    function getXP(address user) external view returns (uint256) {
        return identities[user].xp;
    }

    // --- internal helpers ---
    function _recoverSigner(bytes32 digest, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) return address(0);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // EIP-2 still requires v to be 27 or 28
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        // solhint-disable-next-line avoid-low-level-calls
        address signer = ecrecover(digest, v, r, s);
        return signer;
    }
}
