CREATE OR REPLACE TYPE t_rec_ref_all_dcs AS OBJECT
(
    id_dep_clin_serv    NUMBER(24),
    id_institution      NUMBER(24),
    desc_institution    VARCHAR2(1000 CHAR),
    id_department       NUMBER(24),
    desc_department     VARCHAR2(1000 CHAR),
    id_clinical_service NUMBER(24),
    desc_clin_serv      VARCHAR2(1000 CHAR),

    CONSTRUCTOR FUNCTION t_rec_ref_all_dcs RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_all_dcs IS
    CONSTRUCTOR FUNCTION t_rec_ref_all_dcs RETURN SELF AS RESULT IS
    BEGIN

        self.id_dep_clin_serv    := NULL;
        self.id_institution      := NULL;
        self.desc_institution    := NULL;
        self.id_department       := NULL;
        self.desc_department     := NULL;
        self.id_clinical_service := NULL;
        self.desc_clin_serv      := NULL;

        RETURN;
    END;
END;
/