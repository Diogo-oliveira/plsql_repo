create or replace type T_REC_DRUG_UNIT_MEA_INT as object
(
  id number(24),
  flg_default varchar(1),
  label varchar2(4000),
  id_software number,
  desc_software varchar2(4000)
);