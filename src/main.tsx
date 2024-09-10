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
import { getGraphqlUrl } from "./network.ts";

const wsClient = createWSClient({
  url: getGraphqlUrl().wsUrl,
});

const client = new Client({
  url: getGraphqlUrl().url,
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
