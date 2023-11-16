-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/08/2011
-- CHANGE REASON: ALERT-69406 Single page note for Discharge Summary
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_area AS OBJECT (
        id_pn_area            NUMBER(24),
        nr_rec_page_summary   NUMBER(6),
        data_sort_summary     VARCHAR2(50 CHAR),
        nr_rec_page_hist      NUMBER(6),
        flg_report_title_type VARCHAR2(1 CHAR),
        summary_default_filter VARCHAR2(1 CHAR),
        time_to_close_note       NUMBER(24),
        time_to_start_docum      NUMBER(24),
        flg_task                 VARCHAR2(2 char)
)';
end;
/
--CHANGE END: Sofia Mendes


-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 11/09/2014 14:58
-- CHANGE REASON: [ALERT-295101] 
BEGIN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TYPE t_rec_area AS OBJECT (
        id_pn_area            NUMBER(24),
        nr_rec_page_summary   NUMBER(6),
        data_sort_summary     VARCHAR2(50 CHAR),
        nr_rec_page_hist      NUMBER(6),
        flg_report_title_type VARCHAR2(1 CHAR),
        summary_default_filter VARCHAR2(1 CHAR),
        time_to_close_note       NUMBER(24),
        time_to_start_docum      NUMBER(24),
        flg_task                 VARCHAR2(2 char),
id_report NUMBER(24)
)';
end;
/
-- CHANGE END: Paulo Teixeira