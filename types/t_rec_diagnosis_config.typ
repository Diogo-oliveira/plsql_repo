CREATE OR REPLACE TYPE t_rec_diagnosis_config FORCE AS OBJECT
(
    id_diagnosis            NUMBER(24),
    id_diagnosis_parent     NUMBER(24),
    id_epis_diagnosis       NUMBER(24),
    desc_diagnosis          VARCHAR2(1000 CHAR),
    code_icd                VARCHAR2(100 CHAR),
    flg_other               VARCHAR2(1 CHAR),
    status_diagnosis        VARCHAR2(1 CHAR),
    icon_status             VARCHAR2(200 CHAR),
    avail_for_select        VARCHAR2(1 CHAR),
    default_new_status      VARCHAR2(1 CHAR),
    default_new_status_desc VARCHAR2(1000 CHAR),
    id_alert_diagnosis      NUMBER(24),
    desc_epis_diagnosis     VARCHAR2(1000 CHAR),
    flg_terminology         VARCHAR2(200 CHAR),
    flg_diag_type           VARCHAR2(1 CHAR),
    rank                    NUMBER,
    code_diagnosis          VARCHAR2(200 CHAR),
    flg_icd9                VARCHAR2(30 CHAR),
    flg_show_term_code      VARCHAR2(1 CHAR),
    id_language             NUMBER(24),
    flg_status              VARCHAR2(2 CHAR),
    flg_type                VARCHAR2(2 CHAR),
    id_tvr_msi              NUMBER(12),
    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2
    ) RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2,
        rank                    NUMBER
    ) RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2,
        flg_diag_type           VARCHAR2,
        rank                    NUMBER
    ) RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2,
        flg_diag_type           VARCHAR2,
        rank                    NUMBER,
        code_diagnosis          VARCHAR2,
        flg_icd9                VARCHAR2,
        flg_show_term_code      VARCHAR2,
        id_language             NUMBER
    ) RETURN SELF AS RESULT,
    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2,
        flg_diag_type           VARCHAR2,
        rank                    NUMBER,
        code_diagnosis          VARCHAR2,
        flg_icd9                VARCHAR2,
        flg_show_term_code      VARCHAR2,
        id_language             NUMBER,
        flg_status              VARCHAR2,
        flg_type                VARCHAR2
    ) RETURN SELF AS RESULT
)
INSTANTIABLE NOT FINAL;
/
CREATE OR REPLACE TYPE BODY t_rec_diagnosis_config AS   
    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_diagnosis            := id_diagnosis;
        self.id_diagnosis_parent     := id_diagnosis_parent;
        self.id_epis_diagnosis       := id_epis_diagnosis;
        self.desc_diagnosis          := desc_diagnosis;
        self.code_icd                := code_icd;
        self.flg_other               := flg_other;
        self.status_diagnosis        := status_diagnosis;
        self.icon_status             := icon_status;
        self.avail_for_select        := avail_for_select;
        self.default_new_status      := default_new_status;
        self.default_new_status_desc := default_new_status_desc;
        self.id_alert_diagnosis      := id_alert_diagnosis;
        self.desc_epis_diagnosis     := desc_epis_diagnosis;
        self.flg_terminology         := flg_terminology;
        self.rank                    := NULL;

        self.flg_diag_type := pk_diagnosis_core.get_diag_type(i_lang         => NULL,
                                                              i_prof         => NULL,
                                                              i_concept_type => NULL,
                                                              i_diagnosis    => id_diagnosis);
        self.id_tvr_msi              := NULL;

        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2,
        rank                    NUMBER
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_diagnosis            := id_diagnosis;
        self.id_diagnosis_parent     := id_diagnosis_parent;
        self.id_epis_diagnosis       := id_epis_diagnosis;
        self.desc_diagnosis          := desc_diagnosis;
        self.code_icd                := code_icd;
        self.flg_other               := flg_other;
        self.status_diagnosis        := status_diagnosis;
        self.icon_status             := icon_status;
        self.avail_for_select        := avail_for_select;
        self.default_new_status      := default_new_status;
        self.default_new_status_desc := default_new_status_desc;
        self.id_alert_diagnosis      := id_alert_diagnosis;
        self.desc_epis_diagnosis     := desc_epis_diagnosis;
        self.flg_terminology         := flg_terminology;
        self.rank                    := rank;

        self.flg_diag_type := pk_diagnosis_core.get_diag_type(i_lang         => NULL,
                                                              i_prof         => NULL,
                                                              i_concept_type => NULL,
                                                              i_diagnosis    => id_diagnosis);
        self.id_tvr_msi              := NULL;

        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2,
        flg_diag_type           VARCHAR2,
        rank                    NUMBER
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_diagnosis            := id_diagnosis;
        self.id_diagnosis_parent     := id_diagnosis_parent;
        self.id_epis_diagnosis       := id_epis_diagnosis;
        self.desc_diagnosis          := desc_diagnosis;
        self.code_icd                := code_icd;
        self.flg_other               := flg_other;
        self.status_diagnosis        := status_diagnosis;
        self.icon_status             := icon_status;
        self.avail_for_select        := avail_for_select;
        self.default_new_status      := default_new_status;
        self.default_new_status_desc := default_new_status_desc;
        self.id_alert_diagnosis      := id_alert_diagnosis;
        self.desc_epis_diagnosis     := desc_epis_diagnosis;
        self.flg_terminology         := flg_terminology;
        self.flg_diag_type           := flg_diag_type;
        self.rank                    := rank;
        self.id_tvr_msi              := NULL;

        RETURN;
    END;

    CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2,
        flg_diag_type           VARCHAR2,
        rank                    NUMBER,
        code_diagnosis          VARCHAR2,
        flg_icd9                VARCHAR2,
        flg_show_term_code      VARCHAR2,
        id_language             NUMBER
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_diagnosis            := id_diagnosis;
        self.id_diagnosis_parent     := id_diagnosis_parent;
        self.id_epis_diagnosis       := id_epis_diagnosis;
        self.desc_diagnosis          := desc_diagnosis;
        self.code_icd                := code_icd;
        self.flg_other               := flg_other;
        self.status_diagnosis        := status_diagnosis;
        self.icon_status             := icon_status;
        self.avail_for_select        := avail_for_select;
        self.default_new_status      := default_new_status;
        self.default_new_status_desc := default_new_status_desc;
        self.id_alert_diagnosis      := id_alert_diagnosis;
        self.desc_epis_diagnosis     := desc_epis_diagnosis;
        self.flg_terminology         := flg_terminology;
        self.flg_diag_type           := flg_diag_type;
        self.rank                    := rank;
        self.code_diagnosis          := code_diagnosis;
        self.flg_icd9                := flg_icd9;
        self.flg_show_term_code      := flg_show_term_code;
        self.id_language             := id_language;
        self.id_tvr_msi              := NULL;

        RETURN;
    END;

   CONSTRUCTOR FUNCTION t_rec_diagnosis_config
    (
        SELF                    IN OUT NOCOPY t_rec_diagnosis_config,
        id_diagnosis            NUMBER,
        id_diagnosis_parent     NUMBER,
        id_epis_diagnosis       NUMBER,
        desc_diagnosis          VARCHAR2,
        code_icd                VARCHAR2,
        flg_other               VARCHAR2,
        status_diagnosis        VARCHAR2,
        icon_status             VARCHAR2,
        avail_for_select        VARCHAR2,
        default_new_status      VARCHAR2,
        default_new_status_desc VARCHAR2,
        id_alert_diagnosis      NUMBER,
        desc_epis_diagnosis     VARCHAR2,
        flg_terminology         VARCHAR2,
        flg_diag_type           VARCHAR2,
        rank                    NUMBER,
        code_diagnosis          VARCHAR2,
        flg_icd9                VARCHAR2,
        flg_show_term_code      VARCHAR2,
        id_language             NUMBER,
        flg_status VARCHAR2,
        flg_type VARCHAR2
    ) RETURN SELF AS RESULT IS
    BEGIN
        self.id_diagnosis            := id_diagnosis;
        self.id_diagnosis_parent     := id_diagnosis_parent;
        self.id_epis_diagnosis       := id_epis_diagnosis;
        self.desc_diagnosis          := desc_diagnosis;
        self.code_icd                := code_icd;
        self.flg_other               := flg_other;
        self.status_diagnosis        := status_diagnosis;
        self.icon_status             := icon_status;
        self.avail_for_select        := avail_for_select;
        self.default_new_status      := default_new_status;
        self.default_new_status_desc := default_new_status_desc;
        self.id_alert_diagnosis      := id_alert_diagnosis;
        self.desc_epis_diagnosis     := desc_epis_diagnosis;
        self.flg_terminology         := flg_terminology;
        self.flg_diag_type           := flg_diag_type;
        self.rank                    := rank;
        self.code_diagnosis          := code_diagnosis;
        self.flg_icd9                := flg_icd9;
        self.flg_show_term_code      := flg_show_term_code;
        self.id_language             := id_language;
        self.flg_status              := flg_status;
        self.flg_type                := flg_type;
        self.id_tvr_msi              := NULL;

        RETURN;
    END;
END;
/