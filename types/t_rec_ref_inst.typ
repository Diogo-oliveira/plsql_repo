CREATE OR REPLACE TYPE t_rec_ref_inst AS OBJECT
(
    id_institution        NUMBER(24),
    description           VARCHAR2(1000 CHAR),
    ext_code              VARCHAR2(50 CHAR),    

    CONSTRUCTOR FUNCTION t_rec_ref_inst RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_inst IS
    CONSTRUCTOR FUNCTION t_rec_ref_inst RETURN SELF AS RESULT IS
    BEGIN

        self.id_institution        := NULL;
        self.description           := NULL;
        self.ext_code              := NULL;        

        RETURN;
    END;
END;
/