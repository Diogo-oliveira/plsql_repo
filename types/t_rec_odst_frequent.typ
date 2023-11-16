CREATE OR REPLACE TYPE t_rec_odst_frequent AS OBJECT
(
    id_order_set    NUMBER(24),
    order_set_desc  VARCHAR2(1000 CHAR),
    order_set_title VARCHAR2(1000 CHAR),

    CONSTRUCTOR FUNCTION t_rec_odst_frequent RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_odst_frequent IS
    CONSTRUCTOR FUNCTION t_rec_odst_frequent RETURN SELF AS RESULT IS
    BEGIN
    
        self.id_order_set    := NULL;
        self.order_set_desc  := NULL;
        self.order_set_title := NULL;
    
        RETURN;
    END;
END;
/