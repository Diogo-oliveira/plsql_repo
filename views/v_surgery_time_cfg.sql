create or replace view alert.v_surgery_time_cfg as
select
SST.ID_SR_SURGERY_TIME       ID_RECORD,
SST.code_sr_surgery_time     CODE_SST,
SST.FLG_TYPE     FLG_TYPE,
SSt.flg_val_prev flg_val_prev,
CT.ID_CONFIG     ID_CONFIG,
CT.id_inst_owner id_inst_owner,
coalesce(to_number(CT.FIELD_01),0)      RANK,
CT.FIELD_02      DESC_SST,
CT.FIELD_03      FLG_PAT_STATUS
FROM CONFIG_TABLE CT
JOIN SR_SURGERY_TIME SST ON SST.ID_SR_SURGERY_TIME = CT.ID_RECORD
WHERE CT.CONFIG_TABLE = 'SR_SURGERY_TIME';
