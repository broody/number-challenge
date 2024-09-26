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
  Flex,
  Spacer,
} from "@chakra-ui/react";
import { graphql } from "../graphql";
import { useQuery } from "urql";
import { useNavigate } from "react-router-dom";
import { useState } from "react";
import { formatAddress } from "../utils";
import { useAccount } from "@starknet-react/core";
import { addAddressPadding } from "starknet";
import Connect from "./Create";
import { DojoIcon } from "./icons/Dojo";
import { StarknetIcon } from "./icons/Starknet";
import { GithubIcon } from "./icons/Github";
import Header from "./Header";

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
        <Header />
        <VStack h="100%" justify={["none", "none", "center"]}>
          <SimpleGrid
            columns={[1, 1, 1, 2]}
            h={["auto", "auto", "700px"]}
            w={["100%", "100%", "1200px"]}
            spacing={["80px", "80px", "140px"]}
            mt={["100px", "100px", "30px"]}
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
                  {/* <Text>
                    Earn{" "}
                    <Link href={numsErc20Link()} isExternal>
                      $NUMS
                    </Link>{" "}
                    and purchase powerups to better your odds!
                  </Text> */}
                  <VStack w="full" mt="30px">
                    <ContentWithDots
                      leftContent={<Text>Framework</Text>}
                      rightContent={
                        <Box>
                          <Link
                            href="https://www.dojoengine.org"
                            isExternal
                            fontWeight="bold"
                          >
                            Dojo Engine <DojoIcon />
                          </Link>
                        </Box>
                      }
                    />
                    <ContentWithDots
                      leftContent={<Text>Blockchain</Text>}
                      rightContent={
                        <Box>
                          <Link
                            href="https://www.starknet.io"
                            isExternal
                            fontWeight="bold"
                          >
                            Starknet <StarknetIcon />
                          </Link>
                        </Box>
                      }
                    />
                    <ContentWithDots
                      leftContent={<Text>Source Code</Text>}
                      rightContent={
                        <Box>
                          <Link
                            fontWeight="bold"
                            href="https://github.com/broody/number-challenge"
                            isExternal
                          >
                            Github <GithubIcon />
                          </Link>
                        </Box>
                      }
                    />
                  </VStack>
                </VStack>
                <Spacer minH="20px" />
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

const DottedSeparator = () => (
  <Box
    flex="1"
    height="1em"
    backgroundImage="radial-gradient(circle, gray 1px, transparent 1px)"
    backgroundSize="5px 5px"
    backgroundPosition="bottom"
    backgroundRepeat="repeat-x"
  />
);

const ContentWithDots = ({
  leftContent,
  rightContent,
}: {
  leftContent: React.ReactNode;
  rightContent: React.ReactNode;
}) => {
  return (
    <Flex alignItems="baseline" width="100%">
      <Text marginRight="10px">{leftContent}</Text>
      <DottedSeparator />
      <Text marginLeft="10px">{rightContent}</Text>
    </Flex>
  );
};

export default Leaderboard;
