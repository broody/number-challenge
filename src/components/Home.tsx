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
  Box,
} from "@chakra-ui/react";
import { graphql } from "../graphql";
import { useQuery } from "urql";
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { formatAddress } from "../utils";
import { useAccount } from "@starknet-react/core";
import { addAddressPadding } from "starknet";
import Connect from "./Connect";
import { Chain, getCurrentCHain, onClickChain } from "../network";
import { DojoIcon } from "./icons/Dojo";
import { StarknetIcon } from "./icons/Starknet";
import { GithubIcon } from "./icons/Github";

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

  const totalResult = gameResult.data?.numsGameModels?.edges
    ? gameResult.data.numsGameModels?.edges.length
    : 0;

  return (
    <>
      <Container h="100vh">
        <VStack h="100%" justify={["none", "none", "center"]}>
          <SimpleGrid
            columns={[1, 1, 1, 2]}
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
                    Welcome to <strong>Number Challenge</strong>, a fully{" "}
                    <strong>onchain</strong> game!
                  </Text>
                  <Text>
                    The goal is <strong>simple</strong>: place randomly
                    generated numbers in ascending order.
                  </Text>
                  <VStack w="full" align="flex-start">
                    <HStack w="full">
                      <Text flex="1">Built with</Text>
                      <Box flex="2">
                        <Link href="https://www.dojoengine.org" isExternal fontWeight="bold">
                          <DojoIcon /> Dojo Engine
                        </Link>
                      </Box>
                    </HStack>
                    <HStack w="full">
                      <Text flex="1">Lives on</Text>
                      <Box flex="2">
                        <Link href="https://www.starknet.io" isExternal fontWeight="bold">
                          <StarknetIcon /> Starknet
                        </Link>
                      </Box>
                    </HStack>
                    <HStack w="full">
                      <Text flex="1">Opensourced</Text>
                      <Box flex="2">
                        <Link
                          fontWeight="bold"
                          href="https://github.com/broody/number-challenge"
                          isExternal
                        >
                          <GithubIcon /> Github
                        </Link>
                      </Box>
                    </HStack>
                  </VStack>
                  {NetworkSelection()}
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

const NetworkSelection = () => {
  const [selectedChain, setSelectedChain] = useState<Chain>();
  useEffect(() => {
    const chain = getCurrentCHain();
    if (chain === "mainnet" || chain === "sepolia") {
      setSelectedChain(chain);
      return;
    }

    setSelectedChain("slot");
  }, []);

  const chains = [
    { name: "Mainnet", id: "mainnet" },
    { name: "Sepolia (Testnet)", id: "sepolia" },
    { name: "Slot (L3)", id: "slot" },
  ];

  return (
    <VStack w="full" align="flex-start">
      {chains.map((chain) => (
        <Text
          key={chain.id}
          cursor={selectedChain !== chain.id ? "pointer" : "default"}
          color={selectedChain === chain.id ? "white" : "gray.500"}
          fontWeight={selectedChain === chain.id ? "bold" : "normal"}
          _hover={{
            color: "white",
          }}
          onClick={() => onClickChain(chain.id as Chain)}
        >
          {chain.name} {selectedChain === chain.id && "<<<"}
        </Text>
      ))}
    </VStack>
  );
};

export default Leaderboard;
