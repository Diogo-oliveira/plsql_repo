-->t_rec_product_search|type
CREATE OR REPLACE TYPE t_rec_product_search AS OBJECT
(
    desc_translation VARCHAR2(4000),
    code_translation VARCHAR2(200 CHAR),
    myrank           NUMBER,
    position         NUMBER,
    id_product VARCHAR2(30 CHAR),
    id_product_supplier VARCHAR2(30 CHAR), 
     MAP MEMBER FUNCTION sort_key RETURN VARCHAR2 );
/

 
CREATE OR REPLACE TYPE BODY t_rec_product_search AS
     MAP MEMBER FUNCTION sort_key RETURN VARCHAR2 IS
     BEGIN
        RETURN LPAD(desc_translation,10) ||
               LPAD(code_translation,10) ||
               TO_CHAR(myrank,'fm000')||
               TO_CHAR(position,'fm000')||               
               LPAD(id_product,10) ||
               LPAD(id_product_supplier,10);
       
							 
     END;
END;
/
/
