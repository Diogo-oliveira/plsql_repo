CREATE OR REPLACE TYPE t_rec_ds_get_value force AS OBJECT
(
    id_ds_cmpt_mkt_rel NUMBER,
    id_ds_component    NUMBER,
    internal_name      VARCHAR2(0200 CHAR),
    VALUE              VARCHAR2(4000),
    value_clob         CLOB,
    min_value          number(10,4),
    max_value          number(10,4),
    desc_value         VARCHAR2(4000),
    desc_clob          CLOB,
    id_unit_measure    NUMBER,
    desc_unit_measure  VARCHAR2(1000 CHAR),
    flg_validation     VARCHAR2(5 CHAR),
    err_msg            VARCHAR2(4000),
    flg_event_type     VARCHAR2(5 CHAR),
	flg_multi_status   VARCHAR2(1 CHAR),
    idx           	   number
)
;
/




