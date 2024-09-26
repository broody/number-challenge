import { ArrowBackIcon, ChevronDownIcon } from "@chakra-ui/icons";
import {
  Button,
  HStack,
  Menu,
  MenuButton,
  MenuItem,
  MenuList,
  Spacer,
} from "@chakra-ui/react";
import CartridgeConnector from "@cartridge/connector";
import { Chain, getCurrentChain, onClickChain } from "../network";
import { useAccount, useConnect, useDisconnect } from "@starknet-react/core";
import { formatAddress } from "../utils";
import { useMemo } from "react";

const Header = ({
  showBack,
  lockChain,
}: {
  showBack?: boolean;
  lockChain?: boolean;
}) => {
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { address, connector } = useAccount();
  const cartridgeConnector = connector as never as CartridgeConnector;

  const chains = [
    { name: "Mainnet", id: "mainnet" },
    { name: "Sepolia (Testnet)", id: "sepolia" },
    { name: "Slot (L3)", id: "slot" },
  ];

  const chainName = useMemo(() => {
    return chains.find((c) => c.id === getCurrentChain())?.name;
  }, [chains, getCurrentChain]);

  return (
    <HStack w="full" position="absolute" top="0" left="0" p="20px">
      {showBack && (
        <ArrowBackIcon
          position="absolute"
          top="20px"
          left="20px"
          boxSize="24px"
          cursor="pointer"
          onClick={() => {
            window.history.back();
          }}
        />
      )}
      <Spacer />
      <Menu autoSelect={false}>
        <MenuButton
          as={Button}
          rightIcon={<ChevronDownIcon />}
          isDisabled={lockChain}
        >
          {chainName}
        </MenuButton>
        <MenuList>
          {chains.map((c) => (
            <MenuItem onClick={() => onClickChain(c.id as Chain)}>
              {c.name}
            </MenuItem>
          ))}
        </MenuList>
      </Menu>
      {address ? (
        <Menu autoSelect={false}>
          <MenuButton as={Button} rightIcon={<ChevronDownIcon />}>
            <strong>{formatAddress(address)}</strong>
          </MenuButton>
          <MenuList>
            <MenuItem
              onClick={() => cartridgeConnector.controller.openProfile()}
            >
              Profile
            </MenuItem>
            <MenuItem
              onClick={() => cartridgeConnector.controller.openSettings()}
            >
              Settings
            </MenuItem>
            <MenuItem onClick={() => disconnect()}>Disconnect</MenuItem>
          </MenuList>
        </Menu>
      ) : (
        <Button
          onClick={() => {
            connect({ connector: connectors[0] });
          }}
        >
          Connect
        </Button>
      )}
    </HStack>
  );
};

export default Header;
