-- CHANGED BY: Rui Duarte
-- CHANGE DATE: 22/11/2010 15:26
-- CHANGE REASON: [ALERT-143418] PK_REPORTS issue replication
alter table rep_scope_inst_soft_market move tablespace TABLE_M;
-- CHANGE END: Rui Duarte