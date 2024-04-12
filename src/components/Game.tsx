import { useParams } from "react-router-dom";
import { graphql } from '../graphql'
import { useQuery } from 'urql'

const GameQuery = graphql(`
  query GameQuery($gameId: u32) {
    gameModels (where: { game_id: $gameId}) {
      totalCount
      edges {
        node {
          game_id
          player
          max_slots
          remaining_slots
          max_number
          next_number
        }
      }
    }
    slotModels (where: { game_id: $gameId }) {
      totalCount
      edges {
        node {
          slot
          number
        }
      }
    }
  }
`)

const Game = () => {
  const { gameId } = useParams();
  if (!gameId) {
    return <></>
  }

  const [result] = useQuery({
    query: GameQuery,
    variables: { gameId: parseInt(gameId) },
    pause: !gameId
  })

  console.log(result.data);

  return (
    <div>
      <h1>Game {gameId}</h1>
    </div>
  )
}

export default Game;