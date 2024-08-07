import {
  VStack,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  TableContainer,
  HStack,
  Button,
  useColorMode,
  Text,
  Heading,
  SimpleGrid,
  Container,
  Link,
  RadioGroup,
  Stack,
  Radio,
} from "@chakra-ui/react";
import { graphql } from "../graphql";
import { useQuery } from "urql";
import { useNavigate } from "react-router-dom";
import { useMemo, useState } from "react";
import { formatAddress } from "../utils";
import { useAccount } from "@starknet-react/core";
import { addAddressPadding } from "starknet";
import Connect from "./Connect";
import { formatEther } from "viem";

const GamesQuery = graphql(`
  query Games($offset: Int) {
    numsGameModels(
      order: { direction: ASC, field: REMAINING_SLOTS }
      limit: 10
      offset: $offset
    ) {
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

const StatsQuery = graphql(`
  query Stats {
    transactions(limit: 5) {
      totalCount
      edges {
        node {
          maxFee
        }
      }
    }
  }
`);

const Leaderboard = () => {
  const navigate = useNavigate();
  const [offset, setOffset] = useState<number>(0);
  const { account } = useAccount();
  const { colorMode } = useColorMode();
  const [gameResult, reexecuteQuery] = useQuery({
    query: GamesQuery,
    variables: {
      offset,
    },
  });

  const [statsResult] = useQuery({
    query: StatsQuery,
  });

  const totalResult = gameResult.data?.numsGameModels?.edges
    ? gameResult.data.numsGameModels?.edges.length
    : 0;

  const avgMaxFee = useMemo(() => {
    if (!statsResult.data?.transactions?.edges) return BigInt(0);

    const fees = statsResult.data.transactions.edges.map((edge: any) =>
      BigInt(edge.node.maxFee),
    );
    const sum = fees.reduce((a: bigint, b: bigint) => a + b, BigInt(0));
    return sum / BigInt(fees.length);
  }, [statsResult]);

  return (
    <>
      <Container h="100vh">
        <VStack h="100%" justify={["none", "none", "center"]}>
          <SimpleGrid
            columns={[1, 1, 2]}
            h={["auto", "auto", "700px"]}
            w={["100%", "100%", "1200px"]}
            spacing={["80px", "80px", "30px"]}
            py="50px"
          >
            <VStack justifyItems="center" spacing="80px">
              <VStack spacing="30px">
                <Heading>Number Challenge</Heading>
                <VStack spacing="30px" align="flex-start">
                  <Text>
                    Welcome to <strong>Number Challenge.</strong> A fully{" "}
                    <strong>on-chain</strong> game built using{" "}
                    <Link href="https://www.dojoengine.org" isExternal>
                      [Dojo Engine]
                    </Link>{" "}
                    on{" "}
                    <Link href="https://www.starknet.io" isExternal>
                      [Starknet]
                    </Link>
                    .
                  </Text>
                  <Text>
                    The goal of the game is <strong>simple</strong> - given
                    randomly generated numbers, players must place each number
                    in a <strong>slot</strong> in ascending order.
                  </Text>
                  <VStack w="full" align="flex-start">
                    <HStack>
                      <Text>Chain: </Text>
                      <RadioGroup
                        defaultValue="1"
                        onChange={(network) => {
                          switch (network) {
                            case "1":
                              window.location.href = "https://nums.gg";
                              break;
                            case "2":
                              window.location.href = "https://mainnet.nums.gg";
                              break;
                            case "3":
                              window.location.href = "https://slot.nums.gg";
                              break;
                          }
                        }}
                      >
                        <Stack direction="row">
                          <Radio value="3">
                            Slot
                          </Radio>
                          <Radio value="2">
                            Mainnet
                          </Radio>
                          <Radio value="1">
                            Sepolia
                          </Radio>
                        </Stack>
                      </RadioGroup>
                    </HStack>
                    <Text>
                      Total Games: {gameResult.data?.numsGameModels?.totalCount}
                    </Text>
                    <Text>
                      Total Transactions:{" "}
                      {statsResult.data?.transactions?.totalCount}
                    </Text>
                    <Text>
                      Avg Txn Max Fee:{" "}
                      {parseFloat(formatEther(avgMaxFee)).toFixed(6)} ETH
                    </Text>
                  </VStack>
                </VStack>
                <Connect />
              </VStack>
            </VStack>
            <VStack spacing="20px">
              <Heading>Leaderboard</Heading>
              <TableContainer w="100%">
                <Table variant="simple">
                  <Thead>
                    <Tr>
                      <Th>Ranking</Th>
                      <Th>Player</Th>
                      <Th>Remaining</Th>
                    </Tr>
                  </Thead>
                  <Tbody>
                    {gameResult.data?.numsGameModels?.edges?.map(
                      (edge: any, index) => (
                        <Tr
                          key={edge.node.game_id}
                          cursor="pointer"
                          _hover={{
                            bgColor:
                              colorMode === "light" ? "gray.100" : "gray.700",
                          }}
                          onClick={() => {
                            navigate(`/0x${edge.node.game_id.toString(16)}`);
                          }}
                          bgColor={
                            account?.address ===
                            addAddressPadding(edge.node.player)
                              ? colorMode === "light"
                                ? "green.100"
                                : "green.400"
                              : ""
                          }
                        >
                          <Td>{index + offset + 1}</Td>
                          <Td>
                            {formatAddress(edge.node.player)}{" "}
                            {account?.address === edge.node.player && (
                              <>(you)</>
                            )}
                          </Td>
                          <Td>{edge.node.remaining_slots}</Td>
                        </Tr>
                      ),
                    )}
                  </Tbody>
                </Table>
              </TableContainer>
              <HStack w="100%" justify="space-between">
                <Button
                  isDisabled={offset === 0}
                  onClick={() => {
                    setOffset(offset - 10);
                    reexecuteQuery({ requestPolicy: "network-only" });
                  }}
                >
                  Prev
                </Button>
                <Button
                  isDisabled={totalResult < 10}
                  onClick={() => {
                    setOffset(offset + 10);
                    reexecuteQuery({ requestPolicy: "network-only" });
                  }}
                >
                  Next
                </Button>
              </HStack>
            </VStack>
          </SimpleGrid>
        </VStack>
      </Container>
    </>
  );
};

export default Leaderboard;
