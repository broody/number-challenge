import { Button, Link } from "@chakra-ui/react";
import { useAccount, useConnect, useExplorer } from "@starknet-react/core";
import { useCallback, useState } from "react";
import { CallData } from "starknet";

const Random = () => {
  const { account } = useAccount();
  const explorer = useExplorer();
  const { connect, connectors } = useConnect();
  const [transactionHash, setTransactionHash] = useState<string | null>(null);

  const onRandom = useCallback(async () => {
    if (!account) return;

    const { transaction_hash } = await account.execute([
      {
        contractAddress: import.meta.env.VITE_VRF_CONTRACT,
        entrypoint: "request_random",
        calldata: CallData.compile({
          caller: import.meta.env.VITE_RANDOM_CONTRACT,
          source: {
            type: 0,
            address: account.address,
          },
        }),
      },
      {
        contractAddress: import.meta.env.VITE_RANDOM_CONTRACT,
        entrypoint: "gimme_random",
      },
    ]);

    setTransactionHash(transaction_hash);
  }, [account]);

  return (
    <>
      {account ? (
        <>
          <Button onClick={onRandom}>Gimme Random</Button>
          {transactionHash && (
            <Link href={explorer.transaction(transactionHash)} isExternal>
              {transactionHash}
            </Link>
          )}
        </>
      ) : (
        <Button onClick={() => connect({ connector: connectors[0] })}>
          Connect
        </Button>
      )}
    </>
  );
};

export default Random;
