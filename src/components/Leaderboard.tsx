import {
  VStack,
  Table,
  Thead,
  Tbody,
  Tfoot,
  Tr,
  Th,
  Td,
  TableCaption,
  TableContainer,
} from "@chakra-ui/react";
import { graphql } from "../graphql";
import { useQuery, useSubscription } from "urql";
import { useNavigate } from "react-router-dom";
import Header from "./Header";

const GamesQuery = graphql(`
  query Games {
    gameModels(order: { direction: ASC, field: REMAINING_SLOTS }) {
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
  const [result] = useQuery({
    query: GamesQuery,
  });

  return (
    <>
      <Header title={"Leaderbord"} />
      <VStack></VStack>
    </>
  );
};

export default Leaderboard;
