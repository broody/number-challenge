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
import useToast from "../hooks/toast";

const Connect = () => {
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { address, account } = useAccount();
  const { showTxn } = useToast();
  const [creating, setCreating] = useState<boolean>(false);
  const explorer = useExplorer();
  const navigate = useNavigate();
  const connector = connectors[0];

  const newGame = async () => {
    if (!account) return;

    try {
      setCreating(true);
      const { transaction_hash } = await account.execute([
        {
          contractAddress: import.meta.env.VITE_ACTIONS_CONTRACT,
          entrypoint: "create_game",
          calldata: [1],
        },
      ]);

      showTxn(transaction_hash);

      const receipt = await account.waitForTransaction(transaction_hash, {
        retryInterval: 500,
      });

      // Parses for game idea from `Created` event
      if (receipt.isSuccess()) {
        navigate(`/${receipt.events[1].keys[1]}`);
        return;
      }
    } catch (e) {
      console.error(e);
    } finally {
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
            <Button isLoading={creating} onClick={newGame}>
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
