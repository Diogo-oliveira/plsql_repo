-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 29/Jun/2011
-- CHANGE REASON: [ALERT-189104 ]
CREATE OR REPLACE TYPE t_rec_score_formula AS OBJECT(id_scales_formula number(24), formula VARCHAR2(1000 CHAR),formula_alias varchar2(50 char), formula_to_calc CLOB, id_scales NUMBER(24), 
id_scales_group NUMBER(24), id_documentation NUMBER(24), id_doc_element NUMBER(24), flg_formula_type VARCHAR2(2 CHAR), description VARCHAR2(4000), rank NUMBER(24),
score_value NUMBER(30, 15), flg_visible VARCHAR2(1 char), flg_summary varchar2(1char)
);
/