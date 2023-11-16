create or replace type tr_fluid_balance_med as object (
  id_fluid number,
  desc_fluid varchar2(4000),
  unit number,
  route varchar2(4000),
  takes_string table_varchar
);
/