CREATE OR REPLACE TYPE t_rec_cdr_out FORCE AS OBJECT
(
    ret          VARCHAR2(1 CHAR), -- return value (Y/N)
    info         table_number, -- functionality specific data
    id_user_elem VARCHAR2(255 CHAR), -- related user element identifier

    CONSTRUCTOR FUNCTION t_rec_cdr_out RETURN SELF AS RESULT
)
/
