import {
  VStack,
  Table,
  Thead,
  Tbody,
  Tr,
  Th,
  Td,
  TableContainer,
  Spacer,
  HStack,
  Button,
  useColorMode,
} from "@chakra-ui/react";
import { graphql } from "../graphql";
import { useQuery } from "urql";
import { useNavigate } from "react-router-dom";
import Header from "./Header";
import { useState } from "react";
import { formatAddress } from "../utils";
import { useAccount } from "@starknet-react/core";
import { addAddressPadding } from "starknet";

const GamesQuery = graphql(`
  query Games($offset: Int) {
    gameModels(
      order: { direction: ASC, field: REMAINING_SLOTS }
      limit: 20
      offset: $offset
    ) {
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
  const [result, reexecuteQuery] = useQuery({
    query: GamesQuery,
    variables: {
      offset,
    },
  });

  const totalResult = result.data?.gameModels?.edges
    ? result.data.gameModels?.edges.length
    : 0;
  return (
    <>
      <Header title={"NUMBER CHALLENGE LEADERBOARD"} />
      <Spacer minH="40px" />
      <VStack w="100%" px="40px" gap="40px">
        <TableContainer w="100%">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>Ranking</Th>
                <Th>Player</Th>
                <Th>Remaining Numbers</Th>
                <Th display={["none", "none", "block"]}>Game ID</Th>
              </Tr>
            </Thead>
            <Tbody>
              {result.data?.gameModels?.edges?.map((edge: any, index) => (
                <Tr
                  key={edge.node.game_id}
                  cursor="pointer"
                  _hover={{
                    bgColor: colorMode === "light" ? "gray.100" : "gray.700",
                  }}
                  onClick={() => {
                    navigate(`/0x${edge.node.game_id.toString(16)}`);
                  }}
                  bgColor={
                    account?.address === addAddressPadding(edge.node.player)
                      ? colorMode === "light"
                        ? "green.100"
                        : "green.400"
                      : ""
                  }
                >
                  <Td>{index + offset + 1}</Td>
                  <Td>
                    {formatAddress(edge.node.player)}{" "}
                    {account?.address === edge.node.player && <>(you)</>}
                  </Td>
                  <Td>{edge.node.remaining_slots}</Td>
                  <Td>0x{edge.node.game_id.toString(16)}</Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
        </TableContainer>
        <HStack w="100%" justify="space-between">
          <Button
            isDisabled={offset === 0}
            onClick={() => {
              setOffset(offset - 20);
              reexecuteQuery({ requestPolicy: "network-only" });
            }}
          >
            Prev
          </Button>
          <Button
            isDisabled={totalResult < 20}
            onClick={() => {
              setOffset(offset + 20);
              reexecuteQuery({ requestPolicy: "network-only" });
            }}
          >
            Next
          </Button>
        </HStack>
      </VStack>
    </>
  );
};

export default Leaderboard;
