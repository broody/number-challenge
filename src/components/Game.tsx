import { useParams } from "react-router-dom";
import { graphql } from "../graphql";
import { useQuery, useSubscription } from "urql";
import { useEffect, useState } from "react";
import { formatAddress, removeZeros } from "../utils";
import {
  Box,
  Button,
  Container,
  HStack,
  Heading,
  Link,
  SimpleGrid,
  Text,
  VStack,
  useColorMode,
} from "@chakra-ui/react";
import { useAccount, useExplorer } from "@starknet-react/core";
import { ArrowBackIcon, ArrowLeftIcon, ArrowRightIcon } from "@chakra-ui/icons";

const GameQuery = graphql(`
  query GameQuery($gameId: u32) {
    numsGameModels(where: { game_id: $gameId }) {
      edges {
        node {
          player
          max_number
          remaining_slots
          next_number
        }
      }
    }
    numsSlotModels(
      where: { game_id: $gameId }
      order: { direction: ASC, field: NUMBER }
      limit: 20
    ) {
      edges {
        node {
          index
          number
        }
      }
    }
  }
`);

const EventSubscription = graphql(`
  subscription EventEmitted($gameId: String) {
    eventEmitted(keys: ["*", $gameId]) {
      keys
      data
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
  const explorer = useExplorer();
  const { account } = useAccount();
  const { gameId } = useParams();
  if (!gameId) {
    return <></>;
  }
  window.scrollTo(0, 0);

  const [queryResult] = useQuery({
    query: GameQuery,
    variables: { gameId: parseInt(gameId) },
    pause: !gameId,
  });

  const [eventEmitted] = useSubscription({
    query: EventSubscription,
    variables: { gameId },
  });

  useEffect(() => {
    if (eventEmitted.data?.eventEmitted) {
      const { data } = eventEmitted.data?.eventEmitted;
      setNext(parseInt(data?.[2] || "0", 16));
      setRemaining(parseInt(data?.[3] || "0", 16));
      const newSlots = [...slots];
      newSlots[parseInt(data?.[0] || "0", 16)] = parseInt(data?.[1] || "0", 16);
      setSlots(newSlots);
      setDisableAll(false);
    }
  }, [eventEmitted]);

  useEffect(() => {
    queryResult.data?.numsGameModels?.edges?.forEach((edge: any) => {
      setRemaining(edge.node.remaining_slots);
      setNext(edge.node.next_number);
      setPlayer(edge.node.player);
      setMaxNum(edge.node.max_number);

      if (edge.node.player === removeZeros(account?.address || "")) {
        setIsOwner(true);
      }
    });

    const newSlots: number[] = Array.from({ length: 20 });
    queryResult.data?.numsSlotModels?.edges?.forEach((edge: any) => {
      newSlots[edge.node.index] = edge.node.number;
    });
    setSlots(newSlots);
  }, [queryResult, account]);

  const setSlot = async (slot: number): Promise<boolean> => {
    if (!account) return false;

    try {
      const { transaction_hash } = await account.execute([
        {
          contractAddress: import.meta.env.VITE_ACTIONS_CONTRACT,
          entrypoint: "set_slot",
          calldata: [gameId, slot.toString()],
        },
      ]);

      console.log(transaction_hash);
    } catch (e) {
      console.error(e);
      setDisableAll(false);
      return false;
    }

    return true;
  };

  return (
    <Container h="100vh">
      <ArrowBackIcon
        position="absolute"
        top="20px"
        left="20px"
        boxSize="24px"
        cursor="pointer"
        onClick={() => {
          window.history.back();
        }}
      />
      <VStack h="100%" justify={["none", "none", "center"]}>
        <VStack w="100%" mt="40px" display={["flex", "flex", "none"]}>
          <Heading fontSize="24px">Next Number</Heading>
          <HStack spacing="20px">
            <ArrowRightIcon />
            <Text fontSize="20px">
              <strong>{next}</strong>
            </Text>
            <ArrowLeftIcon />
          </HStack>
        </VStack>
        <SimpleGrid
          columns={[1, 1, 2]}
          h={["auto", "auto", "700px"]}
          w={["100%", "100%", "1200px"]}
          spacing={"20px"}
          py="50px"
        >
          <HStack justify={["center", "center", "flex-end"]}>
            <VStack mr="40px">
              {slots.slice(0, 10).map((number, index) => {
                return (
                  <Slot
                    index={index}
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
                    index={index + 10}
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
          <VStack
            align="center"
            justify="center"
            display={["none", "none", "flex"]}
          >
            <VStack align="flex-start">
              <Text>
                Player:{" "}
                <Link href={explorer.contract(player)} isExternal>
                  <strong>{formatAddress(player)}</strong>
                </Link>
                {isOwner && " (you)"}
              </Text>
              <Text>
                Game ID: <strong>{gameId}</strong>
              </Text>
              <Text>
                Number Range: {maxNum && <strong>1 - {maxNum}</strong>}
              </Text>
              <Text>
                Remaining: <strong>{remaining}</strong>
              </Text>
              <VStack w="100%" mt="40px">
                <Heading fontSize="24px">Next Number</Heading>
                <HStack spacing="20px">
                  <ArrowRightIcon />
                  <Text fontSize="20px">
                    <strong>{next}</strong>
                  </Text>
                  <ArrowLeftIcon />
                </HStack>
              </VStack>
            </VStack>
          </VStack>
        </SimpleGrid>
      </VStack>
    </Container>
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
  const { colorMode } = useColorMode();
  return (
    <HStack key={index} justify="space-between" width="150px">
      <Text>{index + 1}:</Text>
      <Box w="100px">
        {number ? (
          <Button
            w="100%"
            pointerEvents="none"
            bgColor={colorMode === "light" ? "green.100" : "green.400"}
          >
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
