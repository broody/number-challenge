import { type ThemeConfig, extendTheme } from "@chakra-ui/react";

const config: ThemeConfig = {
  initialColorMode: "dark",
  useSystemColorMode: false,
};

const theme = extendTheme({
  config,
  fonts: {
    heading: `'Kode Mono', monospace`,
    body: `'Kode Mono', monospace`,
  },
});

export default theme;
