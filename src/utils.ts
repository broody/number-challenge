import { BigNumberish, num } from "starknet";
import { getCurrentChain } from "./network";

export function formatAddress(addr: BigNumberish) {
  if (typeof addr === "number") {
    addr = "0x" + addr.toString(16);
  } else {
    addr = num.toHex(BigInt(addr));
  }

  return addr.substr(0, 6) + "..." + addr.substr(-4);
}

export function removeZeros(addr: string) {
  if (addr.startsWith("0x")) {
    addr = addr.slice(2);
  }

  return "0x" + addr.replace(/^0+/, "");
}

export function numsErc20Link() {
  switch (getCurrentChain()) {
    case "sepolia":
      return (
        "https://sepolia.voyager.online/token/" +
        import.meta.env.VITE_NUMS_ERC20
      );
    case "mainnet":
      return "https://voyager.online/token/" + import.meta.env.VITE_NUMS_ERC20;
    case "slot":
      return (
        "https://sepolia.voyager.online/token/" +
        import.meta.env.VITE_NUMS_ERC20
      );
  }
}
