-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 29/Jun/2011
-- CHANGE REASON: [ALERT-189104 ]
CREATE OR REPLACE TYPE t_rec_score_value AS OBJECT
(
    VALUE          NUMBER(26, 2),
    id_doc_element NUMBER(24)
);
/