import { useParams } from "react-router-dom";
import { graphql } from "../graphql";
import { useQuery } from "urql";
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
  useInterval,
} from "@chakra-ui/react";
import { useAccount, useExplorer } from "@starknet-react/core";
import useToast from "../hooks/toast";
import Header from "./Header";

const REFRESH_INTERVAL = 1000;

const GameQuery = graphql(`
  query GameQuery($gameId: u32) {
    numsGameModels(where: { game_id: $gameId }) {
      edges {
        node {
          player
          min_number
          max_number
          max_slots
          remaining_slots
          next_number
        }
      }
    }
    numsRewardModels(where: { game_id: $gameId }) {
      edges {
        node {
          total
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

const Game = () => {
  const [slots, setSlots] = useState<number[]>(Array.from({ length: 20 }));
  const [next, setNext] = useState<number | null>();
  const [player, setPlayer] = useState<string>("");
  const [remaining, setRemaining] = useState<number>(0);
  const [isOwner, setIsOwner] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [numRange, setNumRange] = useState<string>();
  const [isRewardsActive, setIsRewardsActive] = useState<boolean>(false);
  const [totalRewards, setTotalRewards] = useState<number | null>(null);
  const [nextReward] = useState<number | null>(null);
  const explorer = useExplorer();
  const { account } = useAccount();
  const { gameId } = useParams();
  const { showTxn, showError, dismiss } = useToast();
  if (!gameId) {
    return <></>;
  }

  const [queryResult, reexecuteQuery] = useQuery({
    query: GameQuery,
    variables: { gameId: parseInt(gameId) },
    requestPolicy: isOwner ? "network-only" : "cache-and-network",
  });

  useInterval(() => {
    isLoading && reexecuteQuery();
  }, REFRESH_INTERVAL);

  useEffect(() => {
    const gamesModel = queryResult.data?.numsGameModels?.edges?.[0]?.node;
    const rewardsModel = queryResult.data?.numsRewardModels?.edges?.[0]?.node;
    const slotsEdges = queryResult.data?.numsSlotModels?.edges;
    if (!gamesModel || !slotsEdges) {
      return;
    }

    setIsOwner(
      (account && gamesModel.player === removeZeros(account.address)) || false,
    );

    // update if game progressed
    if (slotsEdges.length === gamesModel.max_slots! - remaining) {
      return;
    }

    setRemaining(gamesModel.remaining_slots || 0);
    setNext(gamesModel.next_number);
    setNumRange(gamesModel.min_number + " - " + gamesModel.max_number);
    setPlayer(gamesModel.player as string);

    const newSlots: number[] = Array.from({ length: 20 });
    slotsEdges.forEach((edge: any) => {
      newSlots[edge.node.index] = edge.node.number;
    });

    setSlots(newSlots);

    if (rewardsModel) {
      setIsRewardsActive(true);
      setTotalRewards(rewardsModel.total as number);
    }

    setIsLoading(false);
    dismiss();
  }, [queryResult, account]);

  const setSlot = async (slot: number): Promise<boolean> => {
    if (!account) return false;

    try {
      setIsLoading(true);
      const { transaction_hash } = await account.execute([
        // {
        //   contractAddress: import.meta.env.VITE_VRF_CONTRACT,
        //   entrypoint: 'request_random',
        //   calldata: CallData.compile({
        //     caller: import.meta.env.VITE_GAME_CONTRACT,
        //     source: {source_type: 0, address: account.address}
        //   })
        // },
        {
          contractAddress: import.meta.env.VITE_GAME_CONTRACT,
          entrypoint: "set_slot",
          calldata: [gameId, slot.toString()],
        },
      ]);

      showTxn(transaction_hash);

      try {
        // catch any txn errors (nonce err, etc) and reset state
        await account.waitForTransaction(transaction_hash);
      } catch (e) {
        showError(transaction_hash);
        throw new Error("transaction error");
      }
    } catch (e) {
      console.log({ e });
      setIsLoading(false);
      return false;
    }

    return true;
  };

  return (
    <Container h="100vh">
      <Header showBack lockChain />
      <VStack h={["auto", "auto", "100%"]} justify={["none", "none", "center"]}>
        <VStack
          w="100%"
          mt={["100px", "100px", "40px"]}
          display={["flex", "flex", "none"]}
        >
          <Heading fontSize="24px">Next: {next}</Heading>
        </VStack>
        <SimpleGrid
          columns={[1, 1, 2]}
          h={["auto", "auto", "700px"]}
          w={["100%", "100%", "1200px"]}
          spacing={"20px"}
          py="25px"
        >
          <HStack justify={["center", "center", "flex-end"]}>
            <VStack mr="40px">
              {slots.slice(0, 10).map((number, index) => {
                return (
                  <Slot
                    key={index}
                    index={index}
                    number={number}
                    isOwner={isOwner}
                    disableAll={isLoading}
                    onClick={async (slot) => {
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
                    key={index + 10}
                    index={index + 10}
                    number={number}
                    isOwner={isOwner}
                    disableAll={isLoading}
                    onClick={async (slot) => {
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
              <Heading fontSize="24px" mb="10px">
                Next Number: <strong>{next}</strong>
              </Heading>
              <Text>
                Player:{" "}
                <Link href={explorer.contract(player)} isExternal>
                  <strong>{formatAddress(player)}</strong>
                </Link>
                {isOwner && " (you)"}
              </Text>
              <Text>Number Range: {numRange}</Text>
              <Text>
                Remaining Slots: <strong>{remaining}</strong>
              </Text>
              <br />
              {/*<HStack mb="10px">
                <Heading fontSize="18px">
                  <Link href={numsErc20Link()} isExternal>
                    $NUMS
                  </Link>{" "}
                  Rewards{" "}
                </Heading>
                 <Heading
                  fontSize="18px"
                  color={isRewardsActive ? "green.400" : "red.400"}
                >
                  [ {isRewardsActive ? "ACTIVE" : "INACTIVE"} ]
                </Heading> 
              </HStack>*/}
              {isRewardsActive && (
                <>
                  <Text>
                    Next: <strong>{nextReward}</strong>
                  </Text>
                  <Text>
                    Total Earned: <strong>{totalRewards}</strong>
                  </Text>
                </>
              )}
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
