CREATE OR REPLACE TYPE t_rec_p1_request AS OBJECT
(
    id_external_request      NUMBER(24),
    num_req                  VARCHAR2(50),
    flg_type                 VARCHAR2(1),
    dt_requested             TIMESTAMP(6) WITH LOCAL TIME ZONE,
    flg_status               VARCHAR2(1),
    dt_status_tstz           TIMESTAMP(6) WITH LOCAL TIME ZONE,
    flg_priority             VARCHAR2(1),
    id_speciality         NUMBER(6),
    code_speciality       VARCHAR2(200),
    decision_urg_level       NUMBER,
    id_prof_requested        NUMBER(24),
    id_inst_orig             NUMBER(24),
    code_inst_orig           VARCHAR2(200),
    id_inst_dest             NUMBER(24),
    code_inst_dest           VARCHAR2(200),
    inst_dest_abbrev         VARCHAR2(200), -- 30
    id_dep_clin_serv         NUMBER(24),
    id_prof_redirected       NUMBER(24),
    id_schedule              NUMBER(24),
    id_prof_schedule         NUMBER(24),
    dt_schedule_tstz         TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_efectiv_tstz          TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_patient               NUMBER(24),
    pat_name                 VARCHAR2(800), -- 200
    pat_gender               VARCHAR2(1),
    dep_abbreviation         VARCHAR2(100), -- 30
    code_department          VARCHAR2(200),
    code_clinical_service    VARCHAR2(200),
    id_match                 NUMBER(24),
    id_prof_status           NUMBER(24),
    dt_issued                TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_prof_triage           NUMBER(24),
    dt_triage                TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_forwarded             TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_acknowledge           TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_new                   TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_last_interaction_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_workflow              NUMBER(24),
    abbrev_inst_orig         VARCHAR2(800),
	institution_name_roda    VARCHAR2(200),
    tr_dt_update             TIMESTAMP(6) WITH LOCAL TIME ZONE,
    tr_id_prof_dest          NUMBER(24),
    tr_id_prof_transf_owner  NUMBER(24),
    tr_id_status             NUMBER(24),
    tr_id_trans_resp         NUMBER(24),
    tr_id_workflow           NUMBER(24),
    id_prof_orig             NUMBER(24),
    id_external_sys          NUMBER(12),
    prof_name_roda           VARCHAR2(800),
	flg_migrated             VARCHAR2(1),
	
	CONSTRUCTOR FUNCTION t_rec_p1_request RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_p1_request IS
    CONSTRUCTOR FUNCTION t_rec_p1_request RETURN SELF AS RESULT IS
    BEGIN

        self.id_external_request      := null;
        self.num_req                  := null;
        self.flg_type                 := null;
        self.dt_requested             := null;
        self.flg_status               := null;
        self.dt_status_tstz           := null;
        self.flg_priority             := null;
        self.id_speciality         := null;
        self.code_speciality       := null;
        self.decision_urg_level       := null;
        self.id_prof_requested        := null;
        self.id_inst_orig             := null;
        self.code_inst_orig           := null;
        self.id_inst_dest             := null;
        self.code_inst_dest           := null;
        self.inst_dest_abbrev         := null;
        self.id_dep_clin_serv         := null;
        self.id_prof_redirected       := null;
        self.id_schedule              := null;
        self.id_prof_schedule         := null;
        self.dt_schedule_tstz         := null;
        self.dt_efectiv_tstz          := null;
        self.id_patient               := null;
        self.pat_name                 := null;
        self.pat_gender               := null;
        self.dep_abbreviation         := null;
        self.code_department          := null;
        self.code_clinical_service    := null;
        self.id_match                 := null;
        self.id_prof_status           := null;
        self.dt_issued                := null;
        self.id_prof_triage           := null;
        self.dt_triage                := null;
        self.dt_forwarded             := null;
        self.dt_acknowledge           := null;
        self.dt_new                   := null;
        self.dt_last_interaction_tstz := null;
        self.id_workflow              := null;
        self.abbrev_inst_orig         := null;
        self.tr_dt_update             := null;
        self.tr_id_prof_dest          := null;
        self.tr_id_prof_transf_owner  := null;
        self.tr_id_status             := null;
        self.tr_id_trans_resp         := null;
        self.tr_id_workflow           := null;
        self.id_prof_orig             := null;
        self.id_external_sys          := null;
        self.prof_name_roda           := null;
				self.flg_migrated           := null;

        RETURN;
    END;
END;
/