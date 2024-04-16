import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.tsx";
import "./index.css";
import {
  Provider,
  Client,
  cacheExchange,
  fetchExchange,
  subscriptionExchange,
} from "urql";
import { createClient as createWSClient } from "graphql-ws";

const wsClient = createWSClient({
  url: "ws://localhost:8080/graphql",
});

const client = new Client({
  url: "http://localhost:8080/graphql",
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
      <App />
    </Provider>
  </React.StrictMode>,
);
