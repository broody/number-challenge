import { Button, HStack, Link, Text, VStack } from "@chakra-ui/react";
import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import CartridgeConnector from "@cartridge/connector";
import { useAccount, useExplorer } from "@starknet-react/core";
import useToast from "../hooks/toast";

const Create = () => {
  const { address, account, connector } = useAccount();
  const { showTxn } = useToast();
  const [creating, setCreating] = useState<boolean>(false);
  const explorer = useExplorer();
  const navigate = useNavigate();
  const [username, setUsername] = useState<string>("");
  const cartridgeConnector = connector as never as CartridgeConnector;

  useEffect(() => {
    cartridgeConnector?.username()?.then(setUsername);
  }, [cartridgeConnector]);

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
        const createdEvent = receipt.events.find(
          //({ keys }) => keys[0] === hash.getSelector("Created"),
          ({ keys }) =>
            keys[0] ===
            "0x11db61a792d4cf77b4eb15fbbb09fdd57607f317a5eed4ac066ea8b0750bbb",
        );

        navigate(`/${createdEvent?.keys[1]}`);
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
      <VStack w="100%" h="120px" spacing="20px">
        <HStack>
          <Text>
            Hello,{" "}
            {address ? (
              <>
                <Link href={explorer.contract(address)} isExternal>
                  <strong>{username}</strong>
                </Link>
              </>
            ) : (
              "anon"
            )}
            .
          </Text>
        </HStack>
        <HStack spacing="20px">
          {address && (
            <Button isLoading={creating} onClick={newGame}>
              Create Game
            </Button>
          )}
        </HStack>
      </VStack>
    </>
  );
};

export default Create;
