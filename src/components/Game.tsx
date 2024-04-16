import { useParams } from "react-router-dom";
import { graphql } from "../graphql";
import { useQuery, useSubscription } from "urql";
import { useEffect, useState } from "react";
import { formatAddress } from "../utils";
import { Box, Button, HStack, Spacer, Text, VStack } from "@chakra-ui/react";
import { useBurner } from "@dojoengine/create-burner";
import Header from "./Header";
import { ACTIONS_CONTRACT } from "../constants";

const GameQuery = graphql(`
  query GameQuery($gameId: u32) {
    gameModels(where: { game_id: $gameId }) {
      edges {
        node {
          player
          max_number
          remaining_slots
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
          remaining_slots
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
  const [isOwner, setIsOwner] = useState<boolean>(false);
  const [remaining, setRemaining] = useState<number>();
  const [disableAll, setDisableAll] = useState<boolean>(false);
  const [maxNum, setMaxNum] = useState<number>();
  const { account } = useBurner();
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
        setRemaining(edge.node.remaining_slots);
        setNext(edge.node.next_number);
        setPlayer(edge.node.player);
        setMaxNum(edge.node.max_number);

        if (edge.node.player === account?.address) {
          setIsOwner(true);
        }
      });

      const newSlots: number[] = Array.from({ length: 20 });
      queryResult.data?.slotModels?.edges?.forEach((edge: any) => {
        newSlots[edge.node.slot - 1] = edge.node.number;
      });
      setSlots(newSlots);
    }
  }, [queryResult, account]);

  useEffect(() => {
    if (updatedResult.data) {
      updatedResult.data?.entityUpdated?.models?.forEach((model: any) => {
        if (parseInt(model.game_id) === parseInt(gameId)) {
          if (model.__typename === "Game") {
            setRemaining(model.remaining_slots);
            setNext(model.next_number);
          }
          if (model.__typename === "Slot") {
            const newSlots = [...slots];
            newSlots[model.slot - 1] = model.number;
            setSlots(newSlots);
            setDisableAll(false);
          }
        }
      });
    }
  }, [updatedResult]);

  const setSlot = async (slot: number): Promise<boolean> => {
    if (!account) return false;

    try {
      const { transaction_hash } = await account.execute({
        contractAddress: ACTIONS_CONTRACT,
        entrypoint: "set_slot",
        calldata: [gameId, slot],
      });

      console.log(transaction_hash);
    } catch (e) {
      console.error(e);
      setDisableAll(false);
      return false;
    }

    return true;
  };

  return (
    <>
      <Header
        title={"Number Challnege"}
        onNewGame={() => setSlots([])}
      />
      <Spacer minH="80px" />
      <HStack align="flex-start" flexDir="row-reverse">
        <VStack w="100%" flex="1">
          <VStack align="flex-start">
            <Text>
              Player: <strong>{formatAddress(player)}</strong>{" "}
              {isOwner && "(you)"}
            </Text>
            <Text>
              Game ID: <strong>{gameId}</strong>
            </Text>
            <Text> 
              Number Range: {maxNum && <strong>1 - {maxNum - 1}</strong>}
            </Text>
            <Text>
              Next number: <strong>{next}</strong>
            </Text>
            <Text>
              Remaining: <strong>{remaining}</strong>
            </Text>
          </VStack>
        </VStack>
        <HStack flex="2" justify="space-around">
          <Box />
          <VStack>
            {slots.slice(0, 10).map((number, index) => {
              return (
                <Slot
                  index={index + 1}
                  number={number}
                  isOwner={isOwner}
                  disableAll={disableAll}
                  onClick={async (slot) => {
                    setDisableAll(true);
                    return await setSlot(slot);
                  }}
                />
              );
            })}
          </VStack>
          <VStack>
            {slots.slice(10, 20).map((number, index) => {
              return (
                <Slot
                  index={index + 11}
                  number={number}
                  isOwner={isOwner}
                  disableAll={disableAll}
                  onClick={async (slot) => {
                    setDisableAll(true);
                    return await setSlot(slot);
                  }}
                />
              );
            })}
          </VStack>
          <Box />
        </HStack>
      </HStack>
    </>
  );
};

const Slot = ({
  index,
  number,
  isOwner,
  disableAll,
  onClick,
}: {
  index: number;
  number: number;
  disableAll: boolean;
  isOwner: boolean;
  onClick: (slot: number) => Promise<boolean>;
}) => {
  const [loading, setLoading] = useState(false);
  return (
    <HStack key={index} gap="30px" justify="space-between" width="180px">
      <Text>{index}:</Text>
      <Box w="100px">
        {number ? (
          <Button w="100%" pointerEvents="none" bgColor="green.100">
            {number}
          </Button>
        ) : (
          <Button
            w="100%"
            isDisabled={!isOwner || disableAll}
            isLoading={loading}
            onClick={async () => {
              setLoading(true);
              const success = await onClick(index);

              if (!success) {
                setLoading(false);
              }
            }}
          >
            {isOwner ? "Set" : "Empty"}
          </Button>
        )}
      </Box>
    </HStack>
  );
};

export default Game;
