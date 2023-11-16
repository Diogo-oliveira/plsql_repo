CREATE OR REPLACE TYPE t_rec_ref_network AS OBJECT
(
    id_institution        NUMBER(24),
    description           VARCHAR2(1000 CHAR),
    ext_code              VARCHAR2(50 CHAR),
    flg_inside_ref_area   VARCHAR2(1 CHAR),
    flg_ref_line          VARCHAR2(30 CHAR),
    wait_time_dd           NUMBER,
    institution_type_desc VARCHAR2(1000 CHAR),

    CONSTRUCTOR FUNCTION t_rec_ref_network RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_network IS
    CONSTRUCTOR FUNCTION t_rec_ref_network RETURN SELF AS RESULT IS
    BEGIN
    
        self.id_institution        := NULL;
        self.description           := NULL;
        self.ext_code              := NULL;
        self.flg_inside_ref_area   := NULL;
        self.flg_ref_line          := NULL;
        self.wait_time_dd          := NULL;
        self.institution_type_desc := NULL;
		
        RETURN;
    END;
END;
/