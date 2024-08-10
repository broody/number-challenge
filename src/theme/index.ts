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
  styles: {
    global: {
      "html, body": {
        userSelect: "none", // Disable text selection for the entire app
      },
    },
  },
});

export default theme;
