CREATE OR REPLACE TYPE T_REC_ELEMENT_DOMAIN AS OBJECT
(
    id_doc_element NUMBER(24),
    data           VARCHAR(200),
    label          VARCHAR(200),
    icon           VARCHAR(200),
    rank           NUMBER(6)
);
/
