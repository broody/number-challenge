import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Game from "./components/Game";
import Leaderboard from "./components/Leaderboard";
import { BurnerProvider } from "@dojoengine/create-burner";
import { Account, RpcProvider } from "starknet";

const rpcProvider = new RpcProvider({
  nodeUrl: import.meta.env.VITE_RPC_URL,
});

const masterAccount = new Account(
  rpcProvider,
  "0x6162896d1d7ab204c7ccac6dd5f8e9e7c25ecd5ae4fcb4ad32e57786bb46e03",
  "0x1800000000300000180000000000030000000000003006001800006600",
);
const accountClassHash =
  "0x05400e90f7e0ae78bd02c77cd75527280470e2fe19c54970dd79dc37a9d3645c";
const feeTokenAddress =
  "0x49d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7";

function App() {
  return (
    <BurnerProvider
      initOptions={{
        masterAccount,
        accountClassHash,
        feeTokenAddress,
        rpcProvider,
      }}
    >
      <Router>
        <Routes>
          <Route path="/" element={<Leaderboard />} />
          <Route path="/:gameId" element={<Game />} />
        </Routes>
      </Router>
    </BurnerProvider>
  );
}

export default App;
