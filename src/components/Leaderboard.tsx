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
} from "@chakra-ui/react";
import { graphql } from "../graphql";
import { useQuery} from "urql";
import { useNavigate } from "react-router-dom";
import Header from "./Header";
import { useState } from "react";

const GamesQuery = graphql(`
  query Games($offset: Int) {
    gameModels(
      order: { direction: ASC, field: REMAINING_SLOTS }
      limit: 10
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
  const [result, reexecuteQuery] = useQuery({
    query: GamesQuery,
    variables: {
      offset,
    },
  });

  const totalResult = result.data?.gameModels?.edges ? result.data.gameModels?.edges.length : 0;
  return (
    <>
      <Header title={"Leader Board"} />
      <Spacer minH="40px" />
      <VStack w="100%" px="40px" gap="40px">
        <TableContainer w="100%">
          <Table variant="simple">
            <Thead>
              <Tr>
                <Th>Game ID</Th>
                <Th>Player</Th>
                <Th>Remaining</Th>
              </Tr>
            </Thead>
            <Tbody>
              {result.data?.gameModels?.edges?.map((edge: any) => (
                <Tr
                  key={edge.node.game_id}
                  cursor="pointer"
                  _hover={{ bgColor: "gray.100" }}
                  onClick={() => {
                    navigate(`/${edge.node.game_id}`);
                  }}
                >
                  <Td>{edge.node.game_id}</Td>
                  <Td>{edge.node.player}</Td>
                  <Td>{edge.node.remaining_slots}</Td>
                </Tr>
              ))}
            </Tbody>
          </Table>
        </TableContainer>
        <HStack w="100%" justify="space-between">
          <Button isDisabled={offset === 0} onClick={() => {
            setOffset(offset - 10);
            reexecuteQuery({ requestPolicy: "network-only" });
          }}>Prev</Button>
          <Button
            isDisabled={ totalResult < 10 }
            onClick={() => {
              setOffset(offset + 10);
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
