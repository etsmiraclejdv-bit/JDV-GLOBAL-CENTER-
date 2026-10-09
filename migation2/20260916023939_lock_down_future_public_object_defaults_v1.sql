-- BLOCK 12: future objects in public must be explicitly exposed.
-- This prevents a future table/function migration from silently becoming
-- reachable through the Data API.
alter default privileges in schema public revoke all on tables from public;
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public grant all on tables to service_role;

alter default privileges in schema public revoke all on sequences from public;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
alter default privileges in schema public grant all on sequences to service_role;

alter default privileges in schema public revoke all on functions from public;
alter default privileges in schema public revoke all on functions from anon, authenticated;
