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
      duration: null,
      isClosable: true,
      position: "bottom-right",
    });
  };

  const showError = (hash: string) => {
    toast({
      title: "Transaction Error",
      description: (
        <Link href={explorer.transaction(hash)} isExternal>
          <strong>{formatAddress(hash)}</strong>
        </Link>
      ),
      duration: null,
      isClosable: true,
      position: "bottom-right",
      status: "error",
    });
  };

  const dismiss = () => {
    toast.closeAll();
  };
  return {
    showTxn,
    showError,
    dismiss,
  };
};

export default useToast;
