import "./App.css";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import Game from "./components/Game";
import Leaderboard from "./components/Leaderboard";

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Leaderboard />} />
        <Route path="/:gameId" element={<Game />} />
      </Routes>
    </Router>
  );
}

export default App;
