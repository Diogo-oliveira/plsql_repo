CREATE OR REPLACE TYPE t_rec_allergy_unawareness AS OBJECT
(
    data NUMBER(24),-- these fields contains or the id_pat_allergy or the  id_allergy_unawareness
    label VARCHAR2(255 CHAR), -- the descriptive of allergy or allergy unawareness.
    flg_search VARCHAR2(1 char),
    extra_data VARCHAR2(255 char),
    flg_exclusive VARCHAR2(1 char),
    flg_type VARCHAR2(2 char),-- necessary for allergy unawareness
    flg_enabled VARCHAR2(1 char),-- necessary for allergy unawareness
    flg_default VARCHAR2(1 char),
    rank NUMBER(2)
)
