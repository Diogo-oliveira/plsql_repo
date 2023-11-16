CREATE OR REPLACE TYPE t_lt_graph_values force AS OBJECT
(
    id_analysis           NUMBER(12),
    id_sample_type        NUMBER(12),
    desc_analysis         VARCHAR2(200 CHAR),
    id_analysis_parameter NUMBER(24),
    desc_parameter        VARCHAR2(200 CHAR),
    dt_harvest_date       VARCHAR2(200 CHAR),
    dt_harvest_hour       VARCHAR2(200 CHAR),
    id_unit_measure       NUMBER(24),
    result                VARCHAR2(1000 CHAR),
    desc_result           VARCHAR2(1000 CHAR),
    flg_result_origin     VARCHAR2(200 CHAR),
    result_color          VARCHAR2(200 CHAR),
    num_ord               NUMBER(24),
    dt_ord                VARCHAR2(200 CHAR)
);
/
-- CHANGE END: Pedro Maia 
