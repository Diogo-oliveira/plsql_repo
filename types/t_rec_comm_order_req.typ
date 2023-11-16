CREATE OR REPLACE TYPE t_rec_comm_order_req force AS OBJECT
(
    id_comm_order_req       NUMBER(24),
    id_workflow             NUMBER(24),
    id_status               NUMBER(24),
    id_patient              NUMBER(24),
    id_episode              NUMBER(24),
    id_concept_type         NUMBER(24),
    id_concept_version      NUMBER(24),
    id_cncpt_vrs_inst_owner NUMBER(24),
    id_concept_term         NUMBER(24),
    id_cncpt_trm_inst_owner NUMBER(24),
    flg_free_text           VARCHAR2(1 CHAR),
    desc_concept_term       CLOB,
    id_prof_req             NUMBER(24),
    id_inst_req             NUMBER(24),
    dt_req                  TIMESTAMP(6) WITH LOCAL TIME ZONE,
    notes                   CLOB,
    clinical_indication     CLOB,
    flg_clinical_purpose    VARCHAR2(2 CHAR),
    clinical_purpose_desc   CLOB,
    flg_priority            VARCHAR2(1 CHAR),
    flg_prn                 VARCHAR2(1 CHAR),
    prn_condition           CLOB,
    dt_begin                TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_professional         NUMBER(24),
    id_institution          NUMBER(24),
    dt_status               TIMESTAMP(6) WITH LOCAL TIME ZONE,
    notes_cancel            CLOB,
    id_cancel_reason        NUMBER(24),
    flg_need_ack            VARCHAR2(1 CHAR),
    flg_action              VARCHAR2(30 CHAR),
    id_previous_status      NUMBER(24),
    task_duration           NUMBER(24),
    id_order_recurr         NUMBER(24),
    id_task_type            NUMBER(24),     
    co_sign_data            t_table_co_sign,

    CONSTRUCTOR FUNCTION t_rec_comm_order_req RETURN SELF AS RESULT
);
/

CREATE OR REPLACE TYPE BODY t_rec_comm_order_req IS
    CONSTRUCTOR FUNCTION t_rec_comm_order_req RETURN SELF AS RESULT IS
    BEGIN
    
        self.id_comm_order_req       := NULL;
        self.id_workflow             := NULL;
        self.id_status               := NULL;
        self.id_patient              := NULL;
        self.id_episode              := NULL;
        self.id_concept_type         := NULL;
        self.id_concept_version      := NULL;
        self.id_cncpt_vrs_inst_owner := NULL;
        self.id_concept_term         := NULL;
        self.id_cncpt_trm_inst_owner := NULL;
        self.flg_free_text           := NULL;
        self.desc_concept_term       := NULL;
        self.id_prof_req             := NULL;
        self.id_inst_req             := NULL;
        self.dt_req                  := NULL;
        self.notes                   := NULL;
        self.clinical_indication     := NULL;
        self.flg_clinical_purpose    := NULL;
        self.clinical_purpose_desc   := NULL;
        self.flg_priority            := NULL;
        self.flg_prn                 := NULL;
        self.prn_condition           := NULL;
        self.dt_begin                := NULL;
        self.id_professional         := NULL;
        self.id_institution          := NULL;
        self.dt_status               := NULL;
        self.notes_cancel            := NULL;
        self.id_cancel_reason        := NULL;
        self.flg_need_ack            := NULL;
        self.flg_action              := NULL;
        self.id_previous_status      := NULL;
        self.co_sign_data            := t_table_co_sign();
        self.task_duration           := NULL;
        self.id_order_recurr         := NULL;
        self.id_task_type            := NULL;
    
        RETURN;
    END;
END;
/