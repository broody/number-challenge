import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Game from "./components/Game";
import Home from "./components/Home";
import {
  StarknetConfig,
  starkscan,
  jsonRpcProvider,
} from "@starknet-react/core";
import { shortString } from "starknet";
import { Chain, sepolia } from "@starknet-react/chains";
import { ControllerOptions } from "@cartridge/controller"
import CartridgeConnector from "@cartridge/connector";

function rpc(_chain: Chain) {
  return {
    nodeUrl: "http://localhost:8000/x/starknet/sepolia",
  };
}

const policies = [
  {
    target: import.meta.env.VITE_ACTIONS_CONTRACT,
    method: "create",
  },
  {
    target: import.meta.env.VITE_ACTIONS_CONTRACT,
    method: "set_slot",
  },
];

const options: ControllerOptions = {
  url: "http://localhost:3001",
  rpc: "http://localhost:8000/x/starknet/sepolia"
};

const connectors = [new CartridgeConnector(policies, options)];

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
