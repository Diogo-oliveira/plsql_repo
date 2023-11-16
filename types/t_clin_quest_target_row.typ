CREATE OR REPLACE TYPE t_clin_quest_target_row force AS OBJECT
(
    id_cmpt_mkt_origin    NUMBER(24),
    id_cmpt_origin        NUMBER(24),
    id_ds_event           NUMBER(24),
    flg_type              VARCHAR2(200 CHAR),
    VALUE                 VARCHAR2(200 CHAR),
    id_cmpt_mkt_dest      NUMBER(24),
    id_cmpt_dest          NUMBER(24),
    field_mask            VARCHAR2(200 CHAR),
    flg_event_target_type VARCHAR2(200 CHAR),
    validation_message    VARCHAR2(200 CHAR),
    rn                    NUMBER(24)
)
