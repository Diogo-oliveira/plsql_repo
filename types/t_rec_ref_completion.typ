CREATE OR REPLACE TYPE t_rec_ref_completion AS OBJECT
(
    id_ref_completion    NUMBER(24),
    code_ref_completion  VARCHAR2(4000),
    code_ref_compl_short VARCHAR2(4000),
    code_warning         VARCHAR2(4000),
    id_reports           NUMBER(24),
    flg_type             VARCHAR2(1 CHAR),
    flg_default          VARCHAR2(1 CHAR),
    flg_active           VARCHAR2(1 CHAR),
    flg_available        VARCHAR2(1 CHAR),
    id_mcdt              NUMBER(24),
    flg_ald              VARCHAR2(1 CHAR),
    flg_bdnp             VARCHAR2(1 CHAR),
    CONSTRUCTOR FUNCTION t_rec_ref_completion RETURN SELF AS RESULT,
    MEMBER FUNCTION to_string RETURN VARCHAR2
)
;
/

CREATE OR REPLACE TYPE BODY t_rec_ref_completion IS
    CONSTRUCTOR FUNCTION t_rec_ref_completion RETURN SELF AS RESULT IS
    BEGIN
        self.id_ref_completion    := NULL;
        self.code_ref_completion  := NULL;
        self.code_ref_compl_short := NULL;
        self.code_warning         := NULL;
        self.id_reports           := NULL;
        self.flg_type             := NULL;
        self.flg_default          := NULL;
        self.flg_active           := NULL;
        self.flg_available        := NULL;
        self.id_mcdt              := NULL;
        self.flg_ald              := NULL;
        self.flg_bdnp             := NULL;
        RETURN;
    END;

    MEMBER FUNCTION to_string RETURN VARCHAR2 IS
    BEGIN
        RETURN 'id_ref_completion=' || self.id_ref_completion || ' id_reports=' || self.id_reports || ' flg_type=' || self.flg_type || ' flg_default=' || self.flg_default || ' flg_active=' || self.flg_active || ' flg_available=' || self.flg_available || ' id_mcdt=' || self.id_mcdt || ' flg_ald=' || self.flg_ald || ' flg_bdnp=' || self.flg_bdnp;
    END to_string;
END;
/