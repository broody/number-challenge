import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.tsx";
import {
  Provider,
  Client,
  cacheExchange,
  fetchExchange,
  subscriptionExchange,
} from "urql";
import { createClient as createWSClient } from "graphql-ws";
import { ChakraProvider } from "@chakra-ui/react";
import theme from "./theme/index.ts";

const wsClient = createWSClient({
  url: import.meta.env.VITE_GRAPHQL_WS_URL,
});

const client = new Client({
  url: import.meta.env.VITE_GRAPHQL_URL,
  exchanges: [
    cacheExchange,
    fetchExchange,
    subscriptionExchange({
      forwardSubscription(request) {
        const input = { ...request, query: request.query || "" };
        return {
          subscribe(sink) {
            const unsubscribe = wsClient.subscribe(input, sink);
            return { unsubscribe };
          },
        };
      },
    }),
  ],
});

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <Provider value={client}>
      <ChakraProvider theme={theme}>
        <App />
      </ChakraProvider>
    </Provider>
  </React.StrictMode>,
);
