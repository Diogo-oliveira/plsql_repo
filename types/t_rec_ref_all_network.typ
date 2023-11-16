CREATE OR REPLACE TYPE t_rec_ref_all_network AS OBJECT
(
    id_inst_orig          NUMBER(24), -- orig institution
    orig_desc_institution VARCHAR2(1000 CHAR),
    orig_ext_code         VARCHAR2(50 CHAR),
    id_speciality         NUMBER(24), -- ref speciality
    desc_speciality       VARCHAR2(1000 CHAR),
    id_institution        NUMBER(24), -- dest institution
    description           VARCHAR2(1000 CHAR),
    ext_code              VARCHAR2(50 CHAR),
    institution_type_desc VARCHAR2(1000 CHAR),
    flg_inside_ref_area   VARCHAR2(1 CHAR), -- ref
    flg_ref_line          VARCHAR2(30 CHAR),
    wait_time_dd          NUMBER,

    CONSTRUCTOR FUNCTION t_rec_ref_all_network RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_all_network IS
    CONSTRUCTOR FUNCTION t_rec_ref_all_network RETURN SELF AS RESULT IS
    BEGIN
    
        self.id_inst_orig          := NULL;
        self.orig_desc_institution := NULL;
        self.orig_ext_code         := NULL;
        self.id_speciality         := NULL;
        self.desc_speciality       := NULL;
        self.id_institution        := NULL;
        self.description           := NULL;
        self.ext_code              := NULL;
        self.institution_type_desc := NULL;
        self.flg_inside_ref_area   := NULL;
        self.flg_ref_line          := NULL;
        self.wait_time_dd          := NULL;
    
        RETURN;
    END;
END;
/