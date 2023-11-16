CREATE OR REPLACE TYPE t_rec_ref_group FORCE AS OBJECT
(
    id_group                  NUMBER,
    id_exr_temp               NUMBER(24),
    exr_code                  VARCHAR2(30 CHAR),
    id                        NUMBER(24),
    id_req                    NUMBER(24),
    name                      VARCHAR2(1000 CHAR),
    standard_desc             VARCHAR2(200 CHAR),
    barcode                   VARCHAR2(30 CHAR),
    mcdt_notes                VARCHAR2(1000 CHAR),
    clinical_indication       VARCHAR2(1000 CHAR),
    id_institution            NUMBER(24),
    flg_priority              VARCHAR2(1 CHAR),
    priority_desc             VARCHAR2(1000 CHAR),
    flg_home                  VARCHAR2(1 CHAR),
    sample_type_desc          VARCHAR2(1000 CHAR),
    id_sample_type            NUMBER(24),
    id_content_sample_type    VARCHAR2(100 CHAR),
    mcdt_cat                  NUMBER(24),
    mcdt_nature               VARCHAR2(10 CHAR),
    mcdt_nature_desc          VARCHAR2(100 CHAR),
    isencao                   VARCHAR(1 CHAR),
    amount                    NUMBER(2),
    laterality_desc           VARCHAR2(1000 CHAR),
    flg_laterality            VARCHAR2(1 CHAR),
    flg_ald                   VARCHAR2(1 CHAR),
    flg_type                  VARCHAR2(1 CHAR),
    desc_type                 VARCHAR2(1000 CHAR),
    consent                   VARCHAR2(1 CHAR),
    complementary_information VARCHAR2(1000 CHAR),
    reason                    VARCHAR2(1000 CHAR),
    p1_notes                  VARCHAR2(1000 CHAR),

    CONSTRUCTOR FUNCTION t_rec_ref_group RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY t_rec_ref_group IS
    CONSTRUCTOR FUNCTION t_rec_ref_group RETURN SELF AS RESULT IS
    BEGIN
    
        self.id_group                  := NULL;
        self.id_exr_temp               := NULL;
        self.exr_code                  := NULL;
        self.id                        := NULL;
        self.id_req                    := NULL;
        self.name                      := NULL;
        self.standard_desc             := NULL;
        self.barcode                   := NULL;
        self.mcdt_notes                := NULL;
        self.clinical_indication       := NULL;
        self.id_institution            := NULL;
        self.flg_priority              := NULL;
        self.priority_desc             := NULL;
        self.flg_home                  := NULL;
        self.sample_type_desc          := NULL;
        self.id_sample_type            := NULL;
        self.id_content_sample_type    := NULL;
        self.mcdt_cat                  := NULL;
        self.mcdt_nature               := NULL;
        self.mcdt_nature_desc          := NULL;
        self.isencao                   := NULL;
        self.amount                    := NULL;
        self.laterality_desc           := NULL;
        self.flg_laterality            := NULL;
        self.flg_ald                   := NULL;
        self.flg_type                  := NULL;
        self.desc_type                 := NULL;
        self.consent                   := NULL;
        self.complementary_information := NULL;
        self.reason                    := NULL;
        self.p1_notes                  := NULL;
    
        RETURN;
    END;
END;
/
