CREATE OR REPLACE TYPE t_consult_ds FORCE AS OBJECT(
        id_ds_cmpt_mkt_rel number(24),
        id_ds_component    number(24),
        internal_name      varchar2(200),
        flg_data_type      varchar2(3) );
/
