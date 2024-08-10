import { Link, useToast as useChakraToast } from "@chakra-ui/react";
import { formatAddress } from "../utils";
import { useExplorer } from "@starknet-react/core";

const useToast = () => {
  const toast = useChakraToast();
  const explorer = useExplorer();

  const showTxn = (hash: string) => {
    toast({
      title: "Transaction Submitted",
      description: (
        <Link href={explorer.transaction(hash)} isExternal>
          <strong>{formatAddress(hash)}</strong>
        </Link>
      ),
      duration: 1500,
      isClosable: true,
      position: "bottom-left"
    });
  };
  return {
    showTxn,
  };
};

export default useToast;
