import { graphql } from "../graphql";
import { useQuery } from "urql";

const GamesQuery = graphql(`
  query Games {
    gameModels {
      totalCount
      edges {
        node {
          game_id
          player
          remaining_slots
        }
      }
    }
  }
`);

const Leaderboard = () => {
  const [result] = useQuery({
    query: GamesQuery,
  });

  return (
    <div>
      <h1>Leaderboard</h1>
    </div>
  );
};

export default Leaderboard;
