import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'
import { Provider, Client, cacheExchange, fetchExchange } from 'urql'

const client = new Client({
  url: "http://localhost:8080/graphql",
  exchanges: [cacheExchange, fetchExchange]
})


ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <Provider value={client}>
      <App />
    </Provider>
  </React.StrictMode>,
)
