CREATE OR REPLACE TYPE t_rec_ref_search AS OBJECT
(
    id_external_request   number(24),
    num_req               VARCHAR2(50 CHAR),
    flg_type              VARCHAR2(1 CHAR),
    id_speciality         NUMBER(24),
    code_speciality       VARCHAR2(200 CHAR),
    id_inst_orig          NUMBER(24),
    code_inst_orig        VARCHAR2(200 CHAR),
    abbrev_inst_orig      VARCHAR2(200 CHAR),
    id_inst_dest          NUMBER(24),
    code_inst_dest        VARCHAR2(200 CHAR),
    inst_dest_abbrev      VARCHAR2(200 CHAR),
    --id_department         NUMBER(24),
    code_department       VARCHAR2(200 CHAR),
    --id_clinical_service   NUMBER(24),
    code_clinical_service VARCHAR2(200 CHAR),
    id_dep_clin_serv      NUMBER(24),
    id_prof_redirected    NUMBER(24),
    id_prof_status        NUMBER(24),
    flg_status            VARCHAR2(1 CHAR),
    dt_status_tstz        TIMESTAMP(6) WITH LOCAL TIME ZONE,
    flg_priority          VARCHAR2(1 CHAR),
    decision_urg_level    NUMBER(24),
    id_schedule           NUMBER(24),
    dt_schedule_tstz      TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_patient            NUMBER(24),
    pat_gender            VARCHAR2(1 CHAR),
    pat_dt_birth          DATE,
    pat_address           VARCHAR2(600 CHAR),
    pat_zip_code          VARCHAR2(30 CHAR),
    pat_location          VARCHAR2(600 CHAR),
    pat_num_sns           VARCHAR2(100 CHAR),
    pat_num_clin_record   VARCHAR2(100 CHAR),
    sequential_number     VARCHAR2(200 CHAR),
    id_prof_requested     NUMBER(24),
		id_prof_roda          NUMBER(24),
    --prof_name_roda        VARCHAR2(200 CHAR),
		institution_name_roda VARCHAR2(1000 CHAR),
    id_workflow           NUMBER(24),
    id_match              NUMBER(24),
    id_external_sys       NUMBER(24),
    rut                   VARCHAR2(30 CHAR),
    run_number            VARCHAR2(30 CHAR),
    id_prof_triage        NUMBER(24),
		id_prof_sch_sugg NUMBER(24),

    CONSTRUCTOR FUNCTION t_rec_ref_search RETURN SELF AS RESULT
)
/

CREATE OR REPLACE TYPE BODY t_rec_ref_search IS
    CONSTRUCTOR FUNCTION t_rec_ref_search RETURN SELF AS RESULT IS
    BEGIN

        self.id_external_request   := NULL;
        self.num_req               := NULL;
        self.flg_type              := NULL;
        self.id_speciality         := NULL;
        self.code_speciality       := NULL;
        self.id_inst_orig          := NULL;
        self.code_inst_orig        := NULL;
        self.abbrev_inst_orig      := NULL;
        self.id_inst_dest          := NULL;
        self.code_inst_dest        := NULL;
        self.inst_dest_abbrev      := NULL;
        --self.id_department         := NULL;
        self.code_department       := NULL;
        --self.id_clinical_service   := NULL;
        self.code_clinical_service := NULL;
        self.id_dep_clin_serv      := NULL;
        self.id_prof_redirected    := NULL;
        self.id_prof_status        := NULL;
        self.flg_status            := NULL;
        self.dt_status_tstz        := NULL;
        self.flg_priority          := NULL;
        self.decision_urg_level    := NULL;
        self.id_schedule           := NULL;
        self.dt_schedule_tstz      := NULL;
        self.id_patient            := NULL;
        self.pat_gender            := NULL;
        self.pat_dt_birth          := NULL;
        self.pat_address           := NULL;
        self.pat_zip_code          := NULL;
        self.pat_location          := NULL;
        self.pat_num_sns           := NULL;
        self.pat_num_clin_record   := NULL;
        self.sequential_number     := NULL;
        self.id_prof_requested     := NULL;				
				self.id_prof_roda        := NULL;
        --self.prof_name_roda        := NULL;
				self.institution_name_roda := NULL;
        self.id_workflow           := NULL;
        self.id_match              := NULL;
        self.id_external_sys       := NULL;
        self.rut                   := NULL;
        self.run_number            := NULL;
        self.id_prof_triage        := NULL;
				self.id_prof_sch_sugg := NULL;

        RETURN;
    END;
END;
/