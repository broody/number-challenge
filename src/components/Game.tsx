import { useParams } from "react-router-dom";
import { graphql } from "../graphql";
import { useQuery, useSubscription } from "urql";
import { useEffect, useState } from "react";
import { formatAddress } from "../utils";

const GameQuery = graphql(`
  query GameQuery($gameId: u32) {
    gameModels(where: { game_id: $gameId }) {
      edges {
        node {
          player
          next_number
        }
      }
    }
    slotModels(
      where: { game_id: $gameId }
      order: { direction: ASC, field: SLOT }
    ) {
      edges {
        node {
          slot
          number
        }
      }
    }
  }
`);

const EventSubscription = graphql(`
  subscription EntityUpdated {
    entityUpdated {
      models {
        __typename
        ... on Game {
          game_id
          next_number
        }
        ... on Slot {
          game_id
          slot
          number
        }
      }
    }
  }
`);

const Game = () => {
  const [slots, setSlots] = useState<number[]>(Array.from({ length: 10 }));
  const [next, setNext] = useState<number>();
  const [player, setPlayer] = useState<string>("");
  const { gameId } = useParams();
  if (!gameId) {
    return <></>;
  }

  const [queryResult] = useQuery({
    query: GameQuery,
    variables: { gameId: parseInt(gameId) },
    pause: !gameId,
  });

  const [updatedResult] = useSubscription({
    query: EventSubscription,
    pause: !gameId,
  });

  useEffect(() => {
    if (queryResult.data) {
      queryResult.data?.gameModels?.edges?.forEach((edge: any) => {
        setNext(edge.node.next_number);
        setPlayer(edge.node.player);
      });

      const newSlots: number[] = Array.from({ length: 10 });
      queryResult.data?.slotModels?.edges?.forEach((edge: any) => {
        newSlots[edge.node.slot - 1] = edge.node.number;
      });
      setSlots(newSlots);
    }
  }, [queryResult]);

  useEffect(() => {
    if (updatedResult.data) {
      updatedResult.data?.entityUpdated?.models?.forEach((model: any) => {
        if (parseInt(model.game_id) === parseInt(gameId)) {
          if (model.__typename === "Game") {
            setNext(model.next_number);
          }
          if (model.__typename === "Slot") {
            const newSlots = [...slots];
            newSlots[model.slot - 1] = model.number;
            setSlots(newSlots);
          }
        }
      });
    }
  }, [updatedResult]);

  return (
    <div>
      <h1>Number Challenge Game ({gameId})</h1>
      <div>
        <div>
          Player: <strong>{formatAddress(player)}</strong>
        </div>
        <p>
          Place number: <strong>{next}</strong>
        </p>
      </div>
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
        }}
      >
        {slots.map((slot, index) => {
          return (
            <div
              key={index}
              style={{
                gap: "10px",
                width: "100px",
                display: "flex",
                flexDirection: "row",
                alignItems: "center",
                justifyContent: "space-between",
              }}
            >
              <div>
                <p>{index + 1}: </p>
              </div>
              <div>
                {slot ? (
                  <button style={{ height: "40px", width: "60px" }} disabled>
                    {slot}
                  </button>
                ) : (
                  <button style={{ height: "40px", width: "60px" }}>Set</button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default Game;
