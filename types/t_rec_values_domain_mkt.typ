CREATE OR REPLACE TYPE t_rec_values_domain_mkt AS OBJECT
(
    desc_val VARCHAR2(200),
    val      VARCHAR2(30),
    img_name VARCHAR2(200),
    rank     NUMBER(6),
		code_domain VARCHAR2(200)
)
/