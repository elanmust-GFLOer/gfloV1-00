import { ethers } from "ethers";
import fs from "fs";

// Example: create an EIP-712 signed grant for PIECore.grantXPWithSig
// Usage: node scripts/sign_grant.js <rpcUrl> <privateKey> <contractAddress> <recipient> <amount>

async function main() {
  const rpcUrl = process.argv[2] || "http://localhost:8545";
  const pk = process.argv[3];
  const contractAddress = process.argv[4];
  const recipient = process.argv[5];
  const amount = process.argv[6] || "100";
  const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
  const nonce = Number(process.argv[7] || 0);

  if (!pk || !contractAddress || !recipient) {
    console.error("Usage: node scripts/sign_grant.js <rpcUrl> <privateKey> <contractAddress> <recipient> <amount> [nonce]");
    process.exit(1);
  }

  const provider = new ethers.JsonRpcProvider(rpcUrl);
  const signer = new ethers.Wallet(pk, provider);

  const domain = {
    name: "PIECore",
    version: "1",
    chainId: (await provider.getNetwork()).chainId,
    verifyingContract: contractAddress,
  };

  const types = {
    Grant: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
  };

  const value = {
    to: recipient,
    amount: ethers.parseUnits(amount, 0).toString(),
    nonce: nonce,
    deadline: deadline,
  };

  // ethers v6: _signTypedData(domain, types, value)
  const signature = await signer._signTypedData(domain, types, value);

  console.log("signature:", signature);
  console.log("payload:", JSON.stringify({ ...value }, null, 2));

  // Optionally write to file
  const out = {
    domain,
    types,
    value,
    signature,
  };
  fs.writeFileSync("signed_grant.json", JSON.stringify(out, null, 2));
  console.log("Saved signed_grant.json");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
