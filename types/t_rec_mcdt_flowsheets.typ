CREATE OR REPLACE TYPE t_rec_mcdt_flowsheets AS OBJECT
(
    id_alert    NUMBER(24),
    id_content  VARCHAR2(200 CHAR),
    description VARCHAR2(4000 CHAR),
    flg_stattus VARCHAR2(2 CHAR)
);
/
