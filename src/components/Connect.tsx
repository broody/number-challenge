import { Button, HStack, Link, Text, VStack } from "@chakra-ui/react";
import { ArrowLeftIcon, ArrowRightIcon } from "@chakra-ui/icons";
import { formatAddress, removeZeros } from "../utils";
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { graphql } from "gql.tada";
import { useSubscription } from "urql";
import {
  useAccount,
  useConnect,
  useDisconnect,
  useExplorer,
} from "@starknet-react/core";

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
  const { disconnect } = useDisconnect();
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

    navigate(`/${gameId}`);
  }, [createdEvent]);

  const newGame = async () => {
    if (!account) return;

    try {
      setCreating(true);
      await account.execute([
        {
          contractAddress: import.meta.env.VITE_ACTIONS_CONTRACT,
          entrypoint: "create",
          calldata: [],
        },
      ]);
    } catch (e) {
      setCreating(false);
    }
  };

  return (
    <>
      <VStack w="100%" h="120px" spacing="20px" justify="center">
        <HStack>
          <Text>
            Hello,{" "}
            {address ? (
              <>
                <Link href={explorer.contract(address)} isExternal>
                  <strong>{formatAddress(address)}</strong>
                </Link>
              </>
            ) : (
              "anon"
            )}
            .
          </Text>
          <Link
            display={address ? "block" : "none"}
            onClick={() => disconnect()}
          >
            [Disconnect]
          </Link>
        </HStack>
        <HStack spacing="20px">
          <ArrowRightIcon />
          {address ? (
            <Button
              isLoading={creating}
              onClick={() => newGame()}
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
