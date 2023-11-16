CREATE OR REPLACE TYPE t_rec_ref_dcs AS OBJECT
(
    id_dep_clin_serv NUMBER(24),
    desc_clin_serv      VARCHAR2(1000 CHAR),

    CONSTRUCTOR FUNCTION t_rec_ref_dcs RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_dcs IS
    CONSTRUCTOR FUNCTION t_rec_ref_dcs RETURN SELF AS RESULT IS
    BEGIN

        self.id_dep_clin_serv := NULL;
        self.desc_clin_serv      := NULL;

        RETURN;
    END;
END;
/