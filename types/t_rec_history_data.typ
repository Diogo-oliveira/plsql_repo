-- CHANGED BY: António Neto
-- CHANGE DATE: 19/04/2011 16:37
-- CHANGE REASON: [ALERT-174012] Creation of Columns and Types - Update functionality positionings to function with detail and history

begin
EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_history_data AS OBJECT
(
    id_rec          NUMBER(24),
    flg_status      VARCHAR2(1),
    date_rec        TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    tbl_labels      table_varchar,
    tbl_values      table_varchar,
    tbl_types       table_varchar,
    tbl_info_labels table_varchar,
    tbl_info_values table_varchar,
		table_origin    varchar2(30 char)
)';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
end;
/

-- CHANGE END: António Neto