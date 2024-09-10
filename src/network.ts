export type Chain = "sepolia" | "mainnet" | "slot";

export const getCurrentCHain = (): Chain => {
  const hostname = window.location.hostname;
  if (hostname.startsWith("mainnet.")) {
    return "mainnet";
  }
  if (hostname.startsWith("slot.")) {
    return "slot";
  }
  return "sepolia";
};

export const onClickChain = (chain: Chain) => {
  switch (chain) {
    case "mainnet":
      window.location.href = "https://mainnet.nums.gg";
      break;
    case "sepolia":
      window.location.href = "https://nums.gg";
      break;
    case "slot":
      window.location.href = "https://slot.nums.gg";
      break;
  }
};

type GraphqlUrl = {
  url: string;
  wsUrl: string;
};

export const getGraphqlUrl = (): GraphqlUrl => {
  const hostname = window.location.hostname;
  if (hostname.startsWith("mainnet.")) {
    return {
      url: import.meta.env.VITE_MAINNET_GRAPHQL_URL,
      wsUrl: import.meta.env.VITE_MAINNET_GRAPHQL_WS_URL,
    };
  }

  if (hostname.startsWith("slot.")) {
    return {
      url: import.meta.env.VITE_SLOT_GRAPHQL_URL,
      wsUrl: import.meta.env.VITE_SLOT_GRAPHQL_WS_URL,
    };
  }

  return {
    url: import.meta.env.VITE_SEPOLIA_GRAPHQL_URL,
    wsUrl: import.meta.env.VITE_SEPOLIA_GRAPHQL_WS_URL,
  };
};

export const getRpc = (): string => {
  const hostname = window.location.hostname;
  if (hostname.startsWith("mainnet.")) {
    return import.meta.env.VITE_MAINNET_RPC_URL;
  }

  if (hostname.startsWith("slot.")) {
    return import.meta.env.VITE_SLOT_RPC_URL;
  }

  return import.meta.env.VITE_SEPOLIA_RPC_URL;
};
