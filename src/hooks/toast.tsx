import { Link, useToast as useChakraToast } from "@chakra-ui/react";
import { formatAddress } from "../utils";
import { useExplorer } from "@starknet-react/core";

const AUTO_DISMISS_SEC = 10000;

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
      duration: AUTO_DISMISS_SEC,
      isClosable: true,
      position: "bottom-left",
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
      duration: AUTO_DISMISS_SEC,
      isClosable: true,
      position: "bottom-left",
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
