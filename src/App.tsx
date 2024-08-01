import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Game from "./components/Game";
import Home from "./components/Home";
import {
  StarknetConfig,
  Connector,
  starkscan,
  jsonRpcProvider,
} from "@starknet-react/core";
import { Chain, sepolia } from "@starknet-react/chains";
import CartridgeConnector from "@cartridge/connector";
import { shortString } from "starknet";

const ETH_TOKEN_ADDRESS =
  "0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7";

function rpc(_chain: Chain) {
  return {
    nodeUrl: import.meta.env.VITE_RPC_URL,
  };
}

const connectors = [
  new CartridgeConnector(
    [
      {
        target: import.meta.env.VITE_ACTIONS_CONTRACT,
        method: "create",
      },
      {
        target: import.meta.env.VITE_ACTIONS_CONTRACT,
        method: "set_slot",
      },
    ],
    {
      paymaster: {
        caller: shortString.encodeShortString("ANY_CALLER"),
      },
      prefunds: [
        {
          address: ETH_TOKEN_ADDRESS,
          min: "300000000000000",
        },
      ]
    },
  ) as never as Connector,
];

function App() {
  return (
    <StarknetConfig
      autoConnect
      chains={[sepolia]}
      connectors={connectors}
      explorer={starkscan}
      provider={jsonRpcProvider({ rpc })}
    >
      <Router>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/:gameId" element={<Game />} />
        </Routes>
      </Router>
    </StarknetConfig>
  );
}

export default App;
