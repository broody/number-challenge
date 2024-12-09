import { VStack, Text, Input, Button, Link } from "@chakra-ui/react";
import { useAccount, useExplorer } from "@starknet-react/core";
import { useCallback, useEffect, useState } from "react";
import { constants } from "starknet";

const Transfer = () => {
  const { account } = useAccount();
  const explorer = useExplorer();
  const [contractAddress, setContractAddress] = useState<string>("");
  const [transaction_hash, setTransactionHash] = useState<string>("");
  const [to, setTo] = useState<string>("");
  const [id, setId] = useState<string>("");
  const [chainId, setChainId] = useState<constants.StarknetChainId>();

  const onTransfer = useCallback(async () => {
    if (!account) return;
    const { transaction_hash } = await account.execute([
      {
        contractAddress,
        entrypoint: "transfer_from",
        calldata: [account.address, to, id, "0x0"],
      },
    ]);
    setTransactionHash(transaction_hash);
  }, [account]);

  useEffect(()=> {
    if (account) {
        account.getChainId().then((chainId) => {
            setChainId(chainId);
        })
    }
  },[account])
  return (
    <>
      <VStack align="flex-start" p="20px">
        <Text>Chain ID: {chainId}</Text>
        <Text>NFT Contract Address</Text>
        <Input
          placeholder="Contract Address"
          onChange={(e) => setContractAddress(e.target.value)}
        ></Input>
        <Text>Transfer To</Text>
        <Input
          placeholder="New Owner Address"
          onChange={(e) => setTo(e.target.value)}
        ></Input>
        <Text>ID</Text>
        <Input
          placeholder="ID"
          onChange={(e) => setId(e.target.value)}
          type="number"
        ></Input>
        <Button isDisabled={!account} onClick={onTransfer}>
          Transfer
        </Button>
        <Link href={explorer.transaction(transaction_hash)} isExternal>
          <Text>{transaction_hash}</Text>
        </Link>
      </VStack>
    </>
  );
};

export default Transfer;
