CREATE OR REPLACE TYPE t_harvest_sample_recipient AS OBJECT
(
    id_sample_recipient NUMBER,
    description         VARCHAR2(200 CHAR),
    id_harvest          NUMBER
)
;
/