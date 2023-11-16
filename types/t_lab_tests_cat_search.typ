CREATE OR REPLACE TYPE t_lab_tests_cat_search force AS OBJECT
(
    id_exam_cat        NUMBER(12),
    desc_category      VARCHAR2(200 CHAR),
    id_sample_type     NUMBER(12),
    id_exam_cat_parent NUMBER(12)
);
/