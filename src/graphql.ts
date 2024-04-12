import { initGraphQLTada } from 'gql.tada';
import type { introspection } from './graphql-env.d.ts';

export const graphql = initGraphQLTada<{
  introspection: introspection;
  scalars: {
    DateTime: string;
    Boolean: boolean;
    ID: string;
    Cursor: string;
    Float: number;
    Int: number;
    String: string;
    felt252: string;
    u64: number;
    u32: number;
    u16: number;
    u8: number;
  }
}>();

export type { FragmentOf, ResultOf, VariablesOf } from 'gql.tada';
export { readFragment } from 'gql.tada';