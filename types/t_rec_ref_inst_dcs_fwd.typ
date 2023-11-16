CREATE OR REPLACE TYPE t_rec_ref_inst_dcs_fwd AS OBJECT
(
    id_institution        NUMBER(24),
    id_department         NUMBER(24),
    code_department       VARCHAR2(1000 CHAR),
    id_dep_clin_serv      NUMBER(24),
    id_clinical_service   NUMBER(24),
    code_clinical_service VARCHAR2(1000 CHAR),
    flg_inst_forward_type VARCHAR2(1 CHAR),

    CONSTRUCTOR FUNCTION t_rec_ref_inst_dcs_fwd RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_inst_dcs_fwd IS
    CONSTRUCTOR FUNCTION t_rec_ref_inst_dcs_fwd RETURN SELF AS RESULT IS
    BEGIN
    
        self.id_institution        := NULL;
        self.id_department         := NULL;
        self.code_department       := NULL;
        self.id_dep_clin_serv      := NULL;
        self.id_clinical_service   := NULL;
        self.code_clinical_service := NULL;
        self.flg_inst_forward_type := NULL;
    
        RETURN;
    END;
END;
/