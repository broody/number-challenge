import { Box, Button, HStack, Heading, Link } from "@chakra-ui/react";
import { ArrowLeftIcon } from "@chakra-ui/icons";
import { formatAddress, removeZeros } from "../utils";
import { useLocation, useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { graphql } from "gql.tada";
import { useSubscription } from "urql";
import { useAccount, useConnect, useExplorer } from "@starknet-react/core";

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
  const { connect, connectors } = useConnect();
  const { address, account } = useAccount();
  const [creating, setCreating] = useState<boolean>(false);
  const explorer = useExplorer();
  const location = useLocation();
  const navigate = useNavigate();

  const connector = connectors[0];

  const [createdEvent] = useSubscription({
    query: CreatedEvent,
    pause: !account,
    variables: {
      player: removeZeros(account?.address || ""),
    },
  });

  useEffect(() => {
    const gameId = createdEvent.data?.eventEmitted?.keys?.[0];
    if (!gameId) {
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

    const { transaction_hash } = await account.execute([
      {
        contractAddress: import.meta.env.VITE_ACTIONS_CONTRACT,
        entrypoint: "create",
        calldata: [],
      },
    ]);
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
        {!address ? (
          <Button
            h="30px"
            onClick={() => {
              connect({ connector });
            }}
          >
            Connect
          </Button>
        ) : (
          <Box alignContent="right">
            <Link href={explorer.contract(account?.address || "")} isExternal>
              <strong>{formatAddress(address)}</strong>
            </Link>
          </Box>
        )}
      </HStack>
    </HStack>
  );
};

export default Header;
