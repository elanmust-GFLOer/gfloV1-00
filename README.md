# GFLO consolidated workspace

This repository consolidates the working components from multiple GFLO-related repos.

Structure:
- backend/: Flask-based backend (API, faucet, scheduler)
- core/: core scripts and CLI (GasFeeLoop)
- contracts/: Solidity contracts (PIECore)
- wallet/: wallet CLI scripts

See commits for details.

---

## Security & Governance (Multisig / Timelock)

To keep admin operations safe and aligned with project philosophy, follow these rules on deployment and governance:

- Ownership/administration must be transferred to a multisig (e.g. Gnosis Safe) immediately after contract deployment. Do NOT keep a single raw private key as owner.
  - Recommended pattern: multisig threshold 3-of-5 (adjust to team size).
  - Example placeholder: multisig address = 0x... (replace at deploy time).

- Critical admin actions (changing authorizedCallers, updating parameters that affect burns/XP thresholds, transferring ownership) MUST be executed via a timelock or via multisig governance with a delay. Recommended timelock delay: 48–72 hours.

- Deployment checklist (suggested):
  1. Deploy contracts using your deploy script.
  2. Transfer ownership to the multisig address immediately.
  3. Configure multisig signers and threshold, store governance docs off-chain (links in repo or team wiki).
  4. Use timelock for parameter changes when possible.

- Rationale: multisig + timelock prevents a single-key compromise from making instant, irreversible changes (e.g., setting an attacker as an authorized caller or changing burn amounts).

See PHILOSOPHY.md for the project's core principles — every PR should state whether it adheres to those principles.
