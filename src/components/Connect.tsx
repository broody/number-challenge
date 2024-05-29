import { Button, HStack, Link, Text, VStack } from "@chakra-ui/react";
import { ArrowLeftIcon, ArrowRightIcon } from "@chakra-ui/icons";
import { formatAddress, removeZeros } from "../utils";
import { useNavigate } from "react-router-dom";
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

const Connect = () => {
  const { connect, connectors } = useConnect();
  const { address, account } = useAccount();
  const [creating, setCreating] = useState<boolean>(false);
  const explorer = useExplorer();
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

    await account.execute([
      {
        contractAddress: import.meta.env.VITE_ACTIONS_CONTRACT,
        entrypoint: "create",
        calldata: [],
      },
    ], undefined, {
      maxFee: "0x100"
    });
  };

  return (
    <>
      <VStack w="100%" h="120px" spacing="20px" justify="center">
        <Text>
          Hello,{" "}
          {address ? (
            <Link href={explorer.contract(address)} isExternal>
              <strong>{formatAddress(address)}</strong>
            </Link>
          ) : (
            "anon"
          )}
          .
        </Text>
        <HStack spacing="20px">
          <ArrowRightIcon />
          {address ? (
            <Button
              isLoading={creating}
              onClick={() => {
                setCreating(true);
                newGame();
              }}
            >
              Create Game
            </Button>
          ) : (
            <Button
              onClick={() => {
                connect({ connector });
              }}
            >
              Connect
            </Button>
          )}

          <ArrowLeftIcon />
        </HStack>
      </VStack>
    </>
  );
};

export default Connect;