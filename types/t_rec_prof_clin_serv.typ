CREATE OR REPLACE TYPE t_rec_prof_clin_serv AS OBJECT
(
    id_clinical_service NUMBER(24),
    desc_clin_serv      VARCHAR2(1000 CHAR),
    flg_default         VARCHAR2(1 CHAR),
    rank                NUMBER(6)
)
/
