-- ADDED BY: Jose Castro
-- ADDED DATE: 02/03/2011
-- ADDED REASON: ALERT-842
-- Create table
create table ANALYSIS_HARVEST_HIST
(
  dt_analysis_harvest TIMESTAMP(6) WITH LOCAL TIME ZONE,
  id_analysis_harvest NUMBER(24) not null,
  id_analysis_req_det NUMBER(24) not null,
  id_harvest          NUMBER(24) not null,
  id_analysis_req_par NUMBER(24),
  id_sample_recipient NUMBER(24),
  num_recipient       NUMBER(6),
  flg_status          VARCHAR2(1 CHAR),
  create_user         VARCHAR2(24 CHAR),
  create_time         TIMESTAMP(6) WITH LOCAL TIME ZONE,
  create_institution  NUMBER(24),
  update_user         VARCHAR2(24 CHAR),
  update_time         TIMESTAMP(6) WITH LOCAL TIME ZONE,
  update_institution  NUMBER(24)
);

