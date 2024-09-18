import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Game from "./components/Game";
import Home from "./components/Home";
import {
  StarknetConfig,
  voyager,
  jsonRpcProvider,
  Connector,
} from "@starknet-react/core";
import { Chain, mainnet } from "@starknet-react/chains";
import { ControllerOptions } from "@cartridge/controller";
import CartridgeConnector from "@cartridge/connector";
//import { shortString } from "starknet";

function rpc(_chain: Chain) {
  return {
    nodeUrl: "https://api.cartridge.gg/x/starknet/mainnet",
  };
}

// const policies = [
//   {
//     target: import.meta.env.VITE_ACTIONS_CONTRACT,
//     method: "create_game",
//   },
//   {
//     target: import.meta.env.VITE_ACTIONS_CONTRACT,
//     method: "set_slot",
//   },
// ];

const options: ControllerOptions = {
  // policies,
  // paymaster: {
  //   caller: shortString.encodeShortString("ANY_CALLER"),
  // },
  rpc: "https://api.cartridge.gg/x/starknet/mainnet"
};

const connectors = [
  new CartridgeConnector(options) as never as Connector,
];

function App() {
  return (
    <StarknetConfig
      autoConnect
      chains={[mainnet]}
      connectors={connectors}
      explorer={voyager}
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
