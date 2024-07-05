import { Button, HStack, Link, Text, VStack } from "@chakra-ui/react";
import { ArrowLeftIcon, ArrowRightIcon } from "@chakra-ui/icons";
import { formatAddress } from "../utils";
import { useNavigate } from "react-router-dom";
import { useState } from "react";
import {
  useAccount,
  useConnect,
  useDisconnect,
  useExplorer,
} from "@starknet-react/core";

const Connect = () => {
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { address, account } = useAccount();
  const [creating, setCreating] = useState<boolean>(false);
  const explorer = useExplorer();
  const navigate = useNavigate();
  const connector = connectors[0];

  const newGame = async () => {
    if (!account) return;

    try {
      const { transaction_hash } = await account.execute([
        {
          contractAddress: import.meta.env.VITE_ACTIONS_CONTRACT,
          entrypoint: "create",
          calldata: [],
        },
      ]);

      const receipt = await account.waitForTransaction(transaction_hash, {
        retryInterval: 1000,
      });
      if (receipt.isSuccess()) {
        const gameId = receipt.events[1].keys[0];
        navigate(`/${gameId}`);
      } else {
        throw new Error("Transaction rejected/reverted.");
      }
    } catch (e) {
      console.error(e);
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
