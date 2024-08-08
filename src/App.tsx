import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Game from "./components/Game";
import Home from "./components/Home";
import {
  StarknetConfig,
  starkscan,
  jsonRpcProvider,
  Connector,
} from "@starknet-react/core";
import { Chain, sepolia } from "@starknet-react/chains";
import { ControllerOptions } from "@cartridge/controller"
import CartridgeConnector from "@cartridge/connector";
import { shortString } from "starknet";

function rpc(_chain: Chain) {
  return {
    nodeUrl: "https://api.cartridge.gg/x/starknet/sepolia",
  };
}

const policies = [
  {
    target: import.meta.env.VITE_ACTIONS_CONTRACT,
    method: "create_game",
  },
  {
    target: import.meta.env.VITE_ACTIONS_CONTRACT,
    method: "set_slot",
  },
];

const options: ControllerOptions = {
  paymaster: {
     caller: shortString.encodeShortString("ANY_CALLER")
  }
};

const connectors = [new CartridgeConnector(policies, options) as never as Connector];

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
