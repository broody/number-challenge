import { Box, Button, HStack, Heading } from "@chakra-ui/react";
import { useBurner } from "@dojoengine/create-burner";
import { ArrowLeftIcon } from "@chakra-ui/icons";
import { formatAddress } from "../utils";
import { useLocation, useNavigate } from "react-router-dom";
import { ACTIONS_CONTRACT } from "../constants";
import { useEffect, useState } from "react";
import { graphql } from "gql.tada";
import { useSubscription } from "urql";

const CreatedEvent = graphql(`
  subscription Created($player: String) {
    eventEmitted(keys: ["*", $player]) {
      keys
      data
    }
  }
`);

const Header = ({
  title,
  onNewGame,
}: {
  title: string;
  onNewGame?: () => void;
}) => {
  const { account, create, isDeploying } = useBurner();
  const [creating, setCreating] = useState(false);
  const location = useLocation();
  const navigate = useNavigate();

  const [createdEvent] = useSubscription({
    query: CreatedEvent,
    pause: !account,
    variables: {
      player: account?.address,
    },
  });

  useEffect(() => {
    const gameId = createdEvent.data?.eventEmitted?.keys?.[0];
    if (!gameId) {
      console.error("gameId not found in emitted event");
      return;
    }

    setCreating(false);
    navigate(`/${gameId}`);
  }, [createdEvent]);

  const newGame = async () => {
    if (!account) return;

    if (onNewGame) {
      onNewGame();
    }

    const { transaction_hash } = await account.execute({
      contractAddress: ACTIONS_CONTRACT,
      entrypoint: "create",
      calldata: {},
    });
    console.log(transaction_hash);
  };

  return (
    <HStack justify="space-between" px="20px">
      <HStack gap="30px">
        <ArrowLeftIcon
          visibility={location.pathname === "/" ? "hidden" : "visible"}
          cursor="pointer"
          onClick={() => {
            navigate("/");
          }}
        />
        <Button
          onClick={() => {
            setCreating(true);
            newGame();
          }}
          isLoading={creating}
          visibility={account ? "visible" : "hidden"}
        >
          New Game
        </Button>
      </HStack>
      <Heading>{title}</Heading>
      <HStack w="200px">
        {!account ? (
          <Button h="30px" onClick={create} isLoading={isDeploying}>
            Create Account
          </Button>
        ) : (
          <Box alignContent="right">
            Player: <strong>{formatAddress(account.address)}</strong>
          </Box>
        )}
      </HStack>
    </HStack>
  );
};

export default Header;
