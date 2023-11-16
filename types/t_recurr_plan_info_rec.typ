-- CHANGED BY: Nuno Neves
-- CHANGED DATE: 2011-11-10
-- CHANGED REASON: ALERT-199095

CREATE OR REPLACE TYPE t_recurr_plan_info_rec AS OBJECT
( 
    
        order_recurr_desc   VARCHAR2(1000 CHAR),
        order_recurr_option float,
        start_date          VARCHAR2(1000 CHAR),
        occurrences         integer,
        duration            integer,
        o_duration_desc     VARCHAR2(1000 CHAR),
        unit_meas_duration  float,
        end_date            VARCHAR2(1000 CHAR),
        flg_end_by_editable VARCHAR2(1000 CHAR));
/
-- CHANGE END: Nuno Neves
