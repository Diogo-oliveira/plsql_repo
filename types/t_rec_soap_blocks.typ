-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 19/08/2011
-- CHANGE REASON: ALERT-168848 
CREATE OR REPLACE TYPE t_rec_soap_blocks force AS OBJECT
(
    id_pn_soap_block   NUMBER(24),
    id_institution     NUMBER(24),
    id_software        NUMBER(24),
    id_department      NUMBER(24),
    id_dep_clin_serv   NUMBER(24),
    rank               NUMBER(6),
    flg_execute_import VARCHAR2(1 CHAR), -- Indicate if the soap block is empty on click goes directly to import screen. otherwise remains on the page
    flg_show_title     VARCHAR2(1 CHAR),
    value_viewer VARCHAR2(200 CHAR),
    file_name          VARCHAR2(200 CHAR),
    file_extension     VARCHAR2(3 CHAR)
);
/
--CHANGE END: Sofia Mendes
