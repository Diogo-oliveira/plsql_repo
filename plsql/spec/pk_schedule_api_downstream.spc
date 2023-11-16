/*-- Last Change Revision: $Rev: 2028947 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:54 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_schedule_api_downstream IS

    /* PACKAGE API para ser usado por DL-Development Interfaces.
    * DOWNLOAD significa operacoes iniciadas pela agenda 3.0 que são repercutidas nas tabelas da agenda 2.5.
    * A finalidade é carregar as tabelas SCHEDULE_* da 2.5 de forma a que o código do PFH continue a
    * ser servido sem que para isso tenha de ser alterado. Com isto todos os selects a tabelas SCHEDULE_* mantem-se inalterados.
    * DL-Development Interfaces sera quem fara' o transporte (download) dos dados.
    * Para comecar, as 3 grandes operaçoes create update e cancel estao aqui representadas.
    * @author  Telmo
    * @since   10-11-2009
    * @version 2.6
    */

    -------------------------------
    -- PUBLIC CONSTANT DECLARATIONS
    -------------------------------
    g_sysdate_tstz CONSTANT TIMESTAMP WITH TIME ZONE := current_timestamp;

    g_res_type_prof   CONSTANT VARCHAR2(1) := 'P';
    g_res_type_room   CONSTANT VARCHAR2(1) := 'R';
    g_res_type_bed    CONSTANT VARCHAR2(1) := 'B';
    g_res_type_nch    CONSTANT VARCHAR2(1) := 'N';
    g_res_type_rgroup CONSTANT VARCHAR2(1) := 'G';

    g_datetimeformat CONSTANT VARCHAR2(20) := 'YYYYMMDDHH24MISS'; --'YYYYMMDDHH24MISS TZR';
    /* Date date mask. */
    g_default_date_mask CONSTANT VARCHAR2(16) := 'yyyymmddhh24mi';
    /* Date date mask with no time. */
    g_default_date_no_time_mask CONSTANT VARCHAR2(16) := 'yyyymmdd';
    /* Date time mask. */
    g_default_time_mask CONSTANT VARCHAR2(16) := 'hh24mi';
    /* Default time mask for presentation */
    g_default_time_mask_msg CONSTANT VARCHAR2(16) := 'hh24:mi';
    /* Date day mask. */
    g_default_day_mask CONSTANT VARCHAR2(2) := 'dd';
    /* Date month mask. */
    g_default_month_mask CONSTANT VARCHAR2(2) := 'mm';
    /* Date year mask. */
    g_default_year_mask CONSTANT VARCHAR2(4) := 'yyyy';
    /* Hour mask */
    g_default_hour_mask CONSTANT VARCHAR2(4) := 'hh24';
    /* Minute mask */
    g_default_minute_mask CONSTANT VARCHAR2(2) := 'mi';

    g_sched_msg_no_appointment     CONSTANT VARCHAR2(8) := 'SCH_T810';
    g_sched_msg_max_pat_violated   CONSTANT VARCHAR2(8) := 'SCH_T812';
    g_sched_msg_max_prof_violated  CONSTANT VARCHAR2(8) := 'SCH_T814';
    g_sched_msg_min_prof_violated  CONSTANT VARCHAR2(8) := 'SCH_T813';
    g_sched_msg_no_prof_violated   CONSTANT VARCHAR2(8) := 'SCH_T815';
    g_sched_msg_mixed_surg_procs   CONSTANT VARCHAR2(8) := 'SCH_T816';
    g_event_not_config             CONSTANT VARCHAR2(8) := 'SCH_T819';
    g_sched_msg_multi_bad_dates    CONSTANT VARCHAR2(8) := 'SCH_T820';
    g_sched_msg_no_room            CONSTANT VARCHAR2(8) := 'SCH_T823';
    g_sched_msg_harv_patient       CONSTANT VARCHAR2(8) := 'SCH_T824';
    g_sched_msg_miss_bed_resource  CONSTANT VARCHAR2(8) := 'SCH_T830'; --Missing bed resource
    g_sched_msg_miss_room_resource CONSTANT VARCHAR2(8) := 'SCH_T831'; --Missing room resource
    g_sched_msg_miss_sch_id        CONSTANT VARCHAR2(8) := 'SCH_T832'; --Scheduler ID is mandatory
    g_sched_msg_miss_status        CONSTANT VARCHAR2(8) := 'SCH_T833'; --Status is mandatory
    g_sched_msg_miss_req_inst      CONSTANT VARCHAR2(8) := 'SCH_T834'; --Requested institution is mandatory
    g_sched_msg_miss_req_service   CONSTANT VARCHAR2(8) := 'SCH_T835'; --Requested service is mandatory
    g_sched_msg_one_room_only      CONSTANT VARCHAR2(8) := 'SCH_T836'; --Only one room allowed in a surgery schedule
    g_sched_msg_miss_proc_req      CONSTANT VARCHAR2(8) := 'SCH_T837'; --Surgery/Inpatient appointment - one procedure request is needed
    g_sched_msg_miss_wl_proc_req   CONSTANT VARCHAR2(8) := 'SCH_T838'; --Surgery/Inpatient appointment - waiting list procedure request is needed
    g_sched_msg_event_not_avail    CONSTANT VARCHAR2(8) := 'SCH_T839'; --procedure nao disponivel (flg_available = N)
    g_sched_msg_event_not_exist    CONSTANT VARCHAR2(8) := 'SCH_T840'; --procedure nao existe
    g_sched_msg_exam_req_mismatch  CONSTANT VARCHAR2(8) := 'SCH_T841'; --o exame a agendar nao corresponde ao da requisicao

    /* external flg_status */
    g_ext_flg_status_available CONSTANT VARCHAR2(1) := 'A';
    g_ext_flg_status_scheduled CONSTANT VARCHAR2(1) := 'S';
    g_ext_flg_status_temporary CONSTANT VARCHAR2(1) := 'T';
    g_ext_flg_status_planned   CONSTANT VARCHAR2(1) := 'P';
    g_ext_flg_status_canceled  CONSTANT VARCHAR2(1) := 'C';
    g_ext_flg_status_pending   CONSTANT VARCHAR2(1) := 'W';
    /* Yes */
    g_yes CONSTANT VARCHAR2(1) := 'Y';
    /* No */
    g_no CONSTANT VARCHAR2(1) := 'N';

    /* search scopes for the get_search_xxxxxx functions */
    g_search_scope_inp  CONSTANT VARCHAR2(2) := 'IN';
    g_search_scope_surg CONSTANT VARCHAR2(2) := 'S';
    g_search_scope_cons CONSTANT VARCHAR2(2) := 'C';
    g_search_scope_exam CONSTANT VARCHAR2(2) := 'E'; -- tambem serve para os outros exames
    g_search_scope_phys CONSTANT VARCHAR2(2) := 'M'; -- physiotherapy

    /* procedure_request id types */
    g_proc_req_type_wl  CONSTANT VARCHAR2(1) := 'W'; -- waiting list
    g_proc_req_type_req CONSTANT VARCHAR2(1) := 'R'; -- requisicoes de consulta, exame, lab, mfr
    g_proc_req_type_ref CONSTANT VARCHAR2(1) := 'P'; -- referral id for association 

    /* requisition detail types */
    g_req_det_waiting_list CONSTANT VARCHAR2(2) := 'W';
    g_req_det_consult      CONSTANT VARCHAR2(2) := 'C';
    g_req_det_exam         CONSTANT VARCHAR2(2) := 'E';
    g_req_det_otherexam    CONSTANT VARCHAR2(2) := 'X';
    g_req_det_referral     CONSTANT VARCHAR2(2) := 'P';
    g_req_det_trial        CONSTANT VARCHAR2(2) := 'T';
    g_req_det_lab          CONSTANT VARCHAR2(2) := 'A';

    /* rehab prescription procedure type */
    g_proc_type_rehab_presc CONSTANT VARCHAR2(2) := 'TR';

    /* alert ids for cancel and reschedule operations */
    g_id_sys_alert_cancel  CONSTANT NUMBER(3) := '102';
    g_id_sys_alert_resched CONSTANT NUMBER(3) := '103';

    /* dep types */
    g_dep_type_phys_app CONSTANT VARCHAR2(2) := 'C';

    /* schedule reasons origins*/
    g_sch_reason_type_req CONSTANT VARCHAR2(2) := 'RQ'; -- this reason is extracted from the requisition, if it exists and supplied
    g_sch_reason_type_epi CONSTANT VARCHAR2(2) := 'RE'; -- this reason is extracted from the episode, if it exists and supplied
    g_sch_reason_type_r   CONSTANT VARCHAR2(2) := 'R'; -- reasons from table sample_text
    g_sch_reason_type_rp  CONSTANT VARCHAR2(2) := 'RP'; -- reasons from table sample_text_prof
    g_sch_reason_type_c   CONSTANT VARCHAR2(2) := 'C'; -- reasons from table complaints
    g_sch_reasons_config  CONSTANT sys_config.id_sys_config%TYPE := 'SCH_COMPLAINT_ORIGIN';

    /* get_schedule_reasons max number of rows returned and warning message*/
    g_sch_reasons_max_rows_safe CONSTANT INTEGER := 150;
    g_sch_reasons_max_rows      CONSTANT VARCHAR2(20) := 'SCH_REASONS_MAX_ROWS';
    g_sched_msg_max_rows        CONSTANT VARCHAR2(20) := 'SEARCH_CRITERIA_M007';

    -------------------------------
    -- PUBLIC VARIABLE DECLARATIONS
    -------------------------------
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(30);
    g_error         VARCHAR2(4000);

    ----------------------------
    -- PUBLIC TYPE DECLARATIONS
    ----------------------------

    -- for create_schedule e update_schedule
    TYPE t_person IS RECORD(
        id_schedule_person   NUMBER, -- map to SCHEDULE_PERSON.ID_SCHEDULE_PERSON
        id_patient           NUMBER, -- map to SCHEDULE_PERSON.ID_PERSON
        id_instit_requests   NUMBER, -- map to SCHEDULE_PERSON.SERVICE_REQUEST.ID_FACILITY
        id_dcs_requests      NUMBER, -- map to SCHEDULE_PERSON.ID_SERVICE_REQUEST + SCHEDULE_PERSON.ID_SPECIALITY_REQUEST
        id_prof_requests     NUMBER, -- map to SCHEDULE_PERSON.ID_USER_REQUEST
        id_prof_schedules    NUMBER, -- map to SCHEDULE_PERSON.ID_USER_SCHEDULES
        notes                VARCHAR2(4000 CHAR), -- map to SCHEDULE_PERSON.NOTES
        id_lang_translator   NUMBER, -- map to SCHEDULE_PERSON.ID_LANG_TRANSLATOR
        id_reason            NUMBER, -- map to SCHEDULE_PERSON.ID_SCHEDULE_REASON
        id_origin            NUMBER, -- map to SCHEDULE_PERSON.ID_ORIGIN
        flg_notification     VARCHAR2(1), -- map to SCHEDULE_PERSON.FLG_NOTIFICATION
        dt_notification      TIMESTAMP WITH LOCAL TIME ZONE, -- map to SCHEDULE_PERSON.DT_NOTIFICATION
        id_prof_notification NUMBER, -- map to SCHEDULE_PERSON.ID_USER_NOTIFICATION
        flg_notification_via VARCHAR2(1), -- map to SCHEDULE_PERSON.FLG_NOTIFICATION_TYPE
        reason_notes         VARCHAR2(4000 CHAR), -- map to SCHEDULE_PERSON.REASON_NOTES
        dt_schedule          TIMESTAMP WITH LOCAL TIME ZONE, -- map to SCHEDULE_PERSON.DT_SCHEDULE
        dt_request           TIMESTAMP WITH LOCAL TIME ZONE, -- map to SCHEDULE_PERSON.DT_REQUEST
        flg_request_type     VARCHAR2(1), -- map to SCHEDULE_PERSON.FLG_REQUEST_TYPE
        flg_schedule_via     VARCHAR2(1), -- map to SCHEDULE_PERSON.FLG_SCHEDULE_VIA
        flg_ref_type         VARCHAR2(1), -- external referrer type. I-External Institution, P-External Professional, R-Internal request, S-Self Referrer
        id_prof_referrer_ext NUMBER, -- external prof that referred 
        id_inst_referrer_ext NUMBER, -- external inst that referred
        id_noshow_reason     NUMBER(24),
        noshow_notes         VARCHAR2(4000 CHAR),
        flg_contact_type     VARCHAR2(1 CHAR),
        id_trial             NUMBER,
        id_health_plan       NUMBER,
        auth_code            VARCHAR2(200),
        dt_auth_code_exp     TIMESTAMP WITH LOCAL TIME ZONE,
        flg_reason_type      VARCHAR2(2),
        pat_instructions     CLOB);
    TYPE t_persons IS TABLE OF t_person;

    TYPE t_procedure IS RECORD(
        id_schedule_procedure NUMBER, -- map to SCHEDULE_PROCEDURE.ID_SCHEDULE_PROCEDURE
        id_content            VARCHAR2(200), -- map to SCHEDULE_PROCEDURE.ID_PROCEDURE
        flg_sch_type          VARCHAR2(2), -- map to SCHEDULE_PROCEDURE.CHARACTERISTIC
        id_dcs_requested      NUMBER, -- MAP TO SCHEDULE.ID_SERVICE + PROCEDURE.ID_SPECIALITY
        flg_main_proc         VARCHAR2(1) -- Y = this is the main procedure. 
        );

    TYPE t_procedures IS TABLE OF t_procedure;

    TYPE t_resource IS RECORD(
        id_schedule_procedure NUMBER, -- map to SCHEDULE_PROCEDURE.ID_SCHEDULE_PROCEDURE MASTER KEY
        id_resource           NUMBER, -- map to SCHEDULE_RESOURCE.ID_RESOURCE_BASE
        id_resource_type      VARCHAR2(1), -- map to SCHEDULE_RESOURCE.ID_RESOURCE_TYPE
        dt_begin              TIMESTAMP WITH LOCAL TIME ZONE, -- map to SCHEDULE_RESOURCE.DT_BEGIN
        dt_end                TIMESTAMP WITH LOCAL TIME ZONE, -- map to SCHEDULE_RESOURCE.DT_END
        flg_leader            VARCHAR2(1) -- map to SCHEDULE_RESOURCE.FLG_LEADER
        );

    TYPE t_resources IS TABLE OF t_resource;

    TYPE t_procedure_req IS RECORD(
        id_schedule_procedure NUMBER, -- map to SCHEDULE_REQ_INFO.ID_SCHEDULE_PROCEDURE MASTER KEY
        id_schedule_person    NUMBER, -- map to SCHEDULE_REQ_INFO.ID_SCHEDULE_PERSON
        id_patient            NUMBER, -- not present in SCHEDULE_REQ_INFO but needed here
        id_type               VARCHAR2(2), -- W=waiting list id;  R= req id (consult or exam); P= referral id (id_external_request)
        id                    NUMBER -- generic id holder. its meaning is given by id_type
        );

    TYPE t_procedure_reqs IS TABLE OF t_procedure_req;
	
	TYPE t_schedule IS RECORD(
        id_lang                language.id_language%TYPE, -- i_lang
        prof                profissional, -- i_prof
        id_sch_ext_old      NUMBER,
        id_sch_ext          NUMBER, -- SCHEDULE.ID_SCHEDULE
        flg_status          schedule.flg_status%TYPE,
        id_instit_requested institution.id_institution%TYPE, -- SERVICE.ID_FACILITY
        id_dep_requested    dep_clin_serv.id_department%TYPE,
        flg_vacancy         schedule.flg_vacancy%TYPE, -- ? SCHEDULE_FLG_VACANCY ?
        procedures          t_procedures,
        resources           t_resources,
        persons             t_persons,
        procedure_reqs      t_procedure_reqs,
        id_episode          schedule.id_episode%TYPE,
        id_prof_resched     professional.id_professional%TYPE,
        id_resched_reason   sch_resched_reason.id_resched_reason%TYPE,
        resched_notes       VARCHAR2(4000 CHAR),
        resched_date        TIMESTAMP WITH LOCAL TIME ZONE,
        id_sch_ref          schedule.id_schedule_ref%TYPE DEFAULT NULL,
        dt_begin            schedule.dt_begin_tstz%TYPE,
        dt_end              schedule.dt_end_tstz%TYPE,
        dt_referral         TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        prof_resp           epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        video_link          schedule.video_link%TYPE DEFAULT NULL -- map to schedule.video_link
    );
    
    TYPE t_schedules is Table of t_schedule;

    -- record type for use in function get_search_status
    TYPE t_search_status IS RECORD(
        id          VARCHAR2(20),
        description VARCHAR2(4000));

    -- container for result list of search status
    TYPE t_search_statuses IS TABLE OF t_search_status;

    -- record type for use in function get_search_services
    TYPE t_search_service IS RECORD(
        id          NUMBER(24),
        description VARCHAR2(4000));

    -- container for result list of search profs
    TYPE t_search_services IS TABLE OF t_search_service;

    -- record type for use in function get_search_adm_indics
    TYPE t_search_adm_indic IS RECORD(
        id          NUMBER(24),
        description VARCHAR2(4000));

    -- container for result list of search profs
    TYPE t_search_adm_indics IS TABLE OF t_search_adm_indic;

    -- types for the requisition details. Use in function get_req_detail
    -- t_detail ->> t_section ->> t_section_detail
    TYPE t_section_detail IS RECORD(
        col_name  VARCHAR2(4000),
        col_value VARCHAR2(4000));

    TYPE t_section_details IS TABLE OF t_section_detail;

    TYPE t_section IS RECORD(
        title           VARCHAR2(4000),
        section_details t_section_details);

    TYPE t_sections IS TABLE OF t_section;

    TYPE t_detail IS RECORD(
        title    VARCHAR2(4000),
        sections t_sections);

    TYPE t_sch_api_map_ids IS TABLE OF sch_api_map_ids%ROWTYPE;

    ----------------------------------------------
    -- PUBLIC FUNCTION AND PROCEDURE DECLARATIONS
    ----------------------------------------------

    /* create schedule to be used by scheduler 3. When a schedule is created there, it is propagated
    * in PFH. Scheduler 3 does that  by calling INTF_ALERT code that in turn calls this function.
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_sch_ext          external schedule id that will be mapped to the local schedule id
    * @param i_flg_status          initial schedule status
    * @param i_id_instit_requested target institution
    * @param i_id_dep_requested    target department
    * @param i_flg_vacancy         schedule type  can be routine, urgency or unplanned
    * @param i_procedures          procedures being scheduled
    * @param i_resources           procedures resources
    * @param i_persons             target patients
    * @param i_procedure_reqs      requisition or WL entry per procedure
    * @param i_id_episode          episode (optional) needed for pfh operations
    * @param i_id_sch_ref          this new schedule will refer to this existent schedule
    * @param i_dt_begin            schedule global start date
    * @param i_dt_end              schedule global end date
    * @param i_dt_referral         data operacao referral
    * @param o_ids_schedule        local schedule id created
    * @param o_error               error data
    *
    * return true /false
    *
    * @author  Telmo
    * @version 2.6
    * @date    11-12-2009
    */
    FUNCTION create_schedule
    (
        i_lang                IN language.id_language%TYPE, -- i_lang
        i_prof                IN profissional, -- i_prof
        i_id_sch_ext          IN NUMBER, -- SCHEDULE.ID_SCHEDULE
        i_flg_status          IN schedule.flg_status%TYPE, -- SCHEDULE.FLG_STATUS. DEVE ESTAR AQUI??
        i_id_instit_requested IN institution.id_institution%TYPE, -- SERVICE.ID_FACILITY
        i_id_dep_requested    IN dep_clin_serv.id_department%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE, -- ? SCHEDULE_FLG_VACANCY ?
        i_procedures          IN t_procedures,
        i_resources           IN t_resources,
        i_persons             IN t_persons,
        i_procedure_reqs      IN t_procedure_reqs,
        i_id_episode          IN schedule.id_episode%TYPE,
        i_id_sch_ref          IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_dt_begin            IN schedule.dt_begin_tstz%TYPE,
        i_dt_end              IN schedule.dt_end_tstz%TYPE,
        i_dt_referral         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_prof_resp           IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        i_video_link          IN schedule.video_link%TYPE DEFAULT NULL, -- map to schedule.video_link
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *  este cancel_schedule e' a mula de carga - aqui se processa efectivamente um cancelamento.
    * Recebe um id_schedule local (pfh) ao contrario do cancel_schedule que recebe um id externo. 
    * E' usado pelo cancel_schedule abaixo e tambem directamente por algumas funcoes do oris.
    * O Oris e' um caso especial. Ele cria agendamentos que so' passam para o scheduler quando se agenda
    * a requisicao na waiting list. Dai nasceu a necessidade de criar esta funcao. So' faz 
    * cancelamentos locais.
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_schedule         local schedule id
    * @param i_id_professional     professional responsible for the cancelation
    * @param i_id_cancel_reason    cancel reason id (see table sch_cancel_reason)
    * @param i_cancel_notes        cancel notes
    * @param i_cancel_date         cancel date. if null uses sys date  
    * @param i_cancel_exam_req     Y = for exam schedules also cancels their requisition. 
    * @param i_updating            Y = this cancel is part of (being called by) an update_Schedule. N = pure cancellation
    * @param i_dt_referral         data operacao referral
    * @param  i_referral_reason    ALERT-259898
    * @param o_error               error data
    * 
    * return true /false
    *
    * @author  Telmo
    * @version 2.6.0.5
    * @date    23-12-2010
    */
    FUNCTION cancel_schedule_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE,
        i_cancel_date      IN schedule.dt_cancel_tstz%TYPE,
        i_cancel_exam_req  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_updating         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_referral      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_referral_reason  IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * cancel schedule to be used by scheduler 3. When a schedule is cancelled there, it is propagated 
    * in PFH. Scheduler 3 does that  by calling INTF_ALERT code that in turn calls this function.
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_sch_ext          external schedule id that will be mapped to the local schedule id
    * @param i_ids_patient         lista dos pacientes. So' cancela o(s) agendamentos contendo um destes ids
    * @param i_id_professional     professional responsible for the cancelation
    * @param i_id_cancel_reason    cancel reason id (see table sch_cancel_reason)
    * @param i_cancel_notes        cancel notes
    * @param i_cancel_date         cancel date. if null uses sys date  
    * @param i_cancel_exam_req     Y = for exam schedules also cancels their requisition. 
    * @param i_updating            Y = this cancel is part of (being called by) an update_Schedule. N = pure cancellation
    * @param i_dt_referral         data operacao referral
    * @param o_error               error data
    * 
    * return true /false
    *
    * @author  Telmo
    * @version 2.6
    * @date    11-12-2009
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_ext       IN NUMBER,
        i_ids_patient      IN table_number,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE,
        i_cancel_date      IN schedule.dt_cancel_tstz%TYPE,
        i_cancel_exam_req  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_updating         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_referral      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * update schedule to be used by scheduler 3. When a schedule is update there, it is propagated
    * in PFH. Scheduler 3 does that  by calling INTF_ALERT code that in turn calls this function.
    * this update is used by a large spectrum of scheduler 3 actions. ex. adding/removing resources, changing procedure(s),
    * changing dates, etc.
    * This functions used to cancel the existing schedule and create a new one. Not anymore.
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_sch_ext          external schedule id that will be mapped to the local schedule id
    * @param i_flg_status          initial schedule status
    * @param i_id_instit_requested target institution
    * @param i_id_dep_requested    target department
    * @param i_flg_vacancy         schedule type  can be routine, urgency or unplanned
    * @param i_procedures          procedures being scheduled
    * @param i_resources           procedures resources
    * @param i_persons             target patients
    * @param i_procedure_reqs      requisition or WL entry per procedure
    * @param i_id_episode          episode (optional) needed for pfh operations
    * @param i_id_prof_cancel      professional responsible for the cancelation. Should be the one doing the update upstairs
    * @param i_id_cancel_reason    cancel reason id (see table sch_cancel_reason)
    * @param i_cancel_notes        cancel notes
    * @param i_cancel_date         cancel date. if null uses sys date
    * @param i_dt_begin            schedule global start date
    * @param i_dt_end              schedule global end date
    * @param o_ids_schedule        newly created schedule ids
    * @param o_error               error data
    *
    * return true /false
    *
    * @author  Telmo
    * @version 2.6
    * @date    12-12-2009
    */
    FUNCTION update_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sch_ext          IN NUMBER,
        i_flg_status          IN schedule.flg_status%TYPE,
        i_id_instit_requested IN institution.id_institution%TYPE,
        i_id_dep_requested    IN dep_clin_serv.id_department%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE,
        i_procedures          IN t_procedures,
        i_resources           IN t_resources,
        i_persons             IN t_persons,
        i_procedure_reqs      IN t_procedure_reqs,
        i_id_episode          IN schedule.id_episode%TYPE,
        i_id_prof_cancel      IN professional.id_professional%TYPE,
        i_id_cancel_reason    IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes        IN schedule.schedule_cancel_notes%TYPE,
        i_cancel_date         IN VARCHAR2,
        i_dt_begin            IN schedule.dt_begin_tstz%TYPE,
        i_dt_end              IN schedule.dt_end_tstz%TYPE,
        i_video_link          IN schedule.video_link%TYPE DEFAULT NULL, -- map to schedule.video_link
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Deletes the schedule from a temporary patient
    *
    * return true /false
    *
    * @author  Carlos Nogueira
    * @version 2.6
    * @date    04-02-2010
    */
    FUNCTION update_schedule_patient
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * updates the old schedule tables with proc and dates
    *
     * @param i_lang               Language identifier
     * @param i_id_schedule        Schedule identifier
     * @param i_dep_clin_serv      Id do servico a actualizar
     * @param i_dt_begin_tstz       Data de inicio a actualizar
     * @param i_dt_end_tstz         Data de fim a actualizar
     * @param i_flg_request
     * @param o_error               An error message, set when return=false
    * return true /false
    *
    * @author  Carlos Nogueira
    * @version 2.6
    * @date    04-02-2009
    */
    FUNCTION update_sch_proc_and_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_dt_begin_tstz    IN schedule.dt_begin_tstz%TYPE,
        i_dt_end_tszt      IN schedule.dt_end_tstz%TYPE,
        i_dep_clin_serv    IN dep_clin_serv.id_clinical_service%TYPE,
        i_flg_request_type IN schedule.flg_request_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /* new search function for surgery waiting list.
    * This function uses pk_wtl_pbl_core functions to do the job. 
    * To be used by inter_alert 
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_ids_inst->i_patid available search fields
    * @param i_page              pagination info. page is a relative number to the rows per page value
    * @param i_rows_per_page     pagination info. page size
    * @param o_result            output collection 
    * @param o_rowcount          absolute row count. Ignores i_start and i_offset
    * @param o_error             error info
    *
    *  @return                     true / false
    *
    *  @author                     Telmo
    *  @version                    2.6.1.2
    *  @since                      12-01-2012
    */
    FUNCTION search_wl_surg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ids_inst           IN table_number,
        i_id_department      IN NUMBER, -- id servico
        i_id_clinicalservice IN NUMBER, -- id_cs especialidade
        i_ids_content        IN table_varchar, -- ids content dos procedimentos cirurgicos
        i_ids_prefsurgeons   IN table_number, -- ids_surgeons
        i_dtbeginmin         IN TIMESTAMP WITH LOCAL TIME ZONE, -- dpb
        i_dtbeginmax         IN TIMESTAMP WITH LOCAL TIME ZONE, -- dpa
        i_ids_cancelreason   IN table_number, -- ids cancel reasons
        i_flgsstatus         IN table_varchar, -- admission status
        i_minexpecteddur     IN NUMBER, -- min expected duration (horas)
        i_maxexpecteddur     IN NUMBER, -- max expected duration (horas)
        i_flgpos             IN VARCHAR2, -- POS (Y/N)
        i_patminage          IN NUMBER, -- patient min age
        i_patmaxage          IN NUMBER, -- patient max age
        i_patgender          IN VARCHAR2, -- patient gender
        i_patid              IN NUMBER, -- patient id
        i_page               IN NUMBER DEFAULT 1,
        i_rows_per_page      IN NUMBER DEFAULT 20,
        o_result             OUT t_wl_search_row_coll,
        o_rowcount           OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /* new search function for admission waiting list.
    * This function uses pk_wtl_pbl_core functions to do the job. 
    * To be used by inter_alert 
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_ids_inst->i_patid available search fields
    * @param i_page              pagination info. page is a relative number to the rows per page value
    * @param i_rows_per_page     pagination info. page size
    * @param o_result            output collection 
    * @param o_rowcount          absolute row count. Ignores i_start and i_offset
    * @param o_error             error info
    *
    *  @return                     true / false
    *
    *  @author                     Telmo
    *  @version                    2.6.1.2
    *  @since                      12-01-2012
    */
    FUNCTION search_wl_adm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_idsinst            IN table_number,
        i_id_department      IN NUMBER, -- id servico
        i_id_clinicalservice IN NUMBER, -- id_cs especialidade
        i_ids_admprof        IN table_number, -- ids adm profs
        i_dtbeginmin         IN TIMESTAMP WITH LOCAL TIME ZONE, -- dpb
        i_dtbeginmax         IN TIMESTAMP WITH LOCAL TIME ZONE, -- dpa
        i_ids_cancelreason   IN table_number, -- ids cancel reasons
        i_flgsstatus         IN table_varchar, -- surg status
        i_idsindforadmission IN table_number, -- ids Indications for admission
        i_minexpecteddur     IN NUMBER, -- min expected duration (horas)
        i_maxexpecteddur     IN NUMBER, -- max expected duration (horas)
        i_patminage          IN NUMBER, -- patient min age
        i_patmaxage          IN NUMBER, -- patient max age
        i_patgender          IN VARCHAR2, -- patient gender
        i_patid              IN NUMBER, -- patient id
        i_page               IN NUMBER DEFAULT 1,
        i_rows_per_page      IN NUMBER DEFAULT 20,
        o_result             OUT t_wl_search_row_coll,
        o_rowcount           OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /*  set notification status to Confirmed
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_sch_ext         external schedule id
    * @param i_id_patient         patient id for when you just want to notify that specific patient
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      08-01-2010
    */
    FUNCTION set_notif_confirmed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN NUMBER,
        i_id_patient IN sch_group.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*  set notification status from confirmed back to notified
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_sch_ext         external schedule id
    * @param i_id_patient         patient id for when you just want to notify that specific patient
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      08-01-2010
    */
    FUNCTION set_notif_unconfirmed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN NUMBER,
        i_id_patient IN sch_group.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*  set notification status to notified 
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_sch_ext         external schedule id
    * @param i_id_patient         patient id for when you just want to notify that specific patient
    * @param i_flg_notif_via      notification via
    * @param i_notif_date         notification date
    * @param i_id_prof_notif      notification prof
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      08-01-2010
    */
    FUNCTION set_notif_notified
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_sch_ext    IN NUMBER,
        i_id_patient    IN sch_group.id_patient%TYPE,
        i_flg_notif_via IN schedule.flg_notification_via%TYPE DEFAULT NULL,
        i_notif_date    IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_id_prof_notif IN schedule.id_prof_notification%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*  set notification status to not notified
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_sch_ext         external schedule id
    * @param i_id_patient         patient id for when you just want to notify that specific patient
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      08-01-2010
    */
    FUNCTION set_notif_pending
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN NUMBER,
        i_id_patient IN sch_group.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_wl_profs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_wl_type  IN VARCHAR2,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        i_ids_dcs  IN table_number,
        o_result   OUT t_wl_profs,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Notify person of notification.
    * update old schedule tables
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 Schedule identifier
    * @param i_id_patient                  Patient identifier
    * @param i_flg_notification_via        Nitification via
    * @param i_flg_notification_via        Professional notification identifier (ID)
    * @param i_dt_notification             Date of notification
    * @param o_error                       An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sérgio Santos
    * @version 1.0
    * @since   11-12-2009      
    */
    FUNCTION notify_person
    (
        i_lang                 IN language.id_language%TYPE,
        i_flg_notification     IN schedule.flg_notification%TYPE,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_flg_notification_via IN sys_domain.val%TYPE,
        i_id_professional      IN professional.id_professional%TYPE,
        i_dt_notification      IN schedule.dt_notification_tstz%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /* To be used by UI functions or functions that need to retrieve a id_content
    * 
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_dep_type          sch. type. C=physician app, N=nurse app, etc.
    * @param i_flg_occurr        F= first appointment, S=subsequent,  O=both
    * @param i_id_dcs            dep clin serv id
    * @param i_flg_prof           Y = this is a consult req with a specific target prof.  N = no specific target prof (specialty appoint)
    * @param o_id_content        id content as needed by scheduler 3. comes from appointment table. Previously this came from column id_content, now gone
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg_title          Message title
    * @param o_msg                Message body to be displayed in flash
    * @param o_button             message popup buttons
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @date                       23-04-2010
    * 
    * UPDATE 19-10-2010: column appointment.id_content no longer exists, replaced by id_appointment. I opted to leave the function name unchanged
    * so as to not disturb UI layer
    */
    FUNCTION get_id_content
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dep_type       IN sch_event.dep_type%TYPE,
        i_flg_occurr     IN sch_event.flg_occurrence%TYPE,
        i_id_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_prof       IN VARCHAR2,
        i_domain_p1_type IN VARCHAR2 DEFAULT NULL,
        o_id_content     OUT appointment.id_appointment%TYPE,
        o_flg_proceed    OUT VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /* extract id_content from event id and dcs
    *
    */
    FUNCTION get_id_content
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_event IN appointment.id_sch_event%TYPE,
        i_id_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_id_content   OUT appointment.id_appointment%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /* extract id_content from event id and dcs
    *
    */
    FUNCTION get_id_content
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_event IN appointment.id_sch_event%TYPE,
        i_id_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_id_content   OUT appointment.id_appointment%TYPE,
        o_flg_proceed  OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /* returns list of schedule reasons to be shown when scheduling.
    * New 2014 MY model
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_patient         needed by the native function
    * @param i_id_software       search field. IF null then all softwares are game
    * @param i_text_search       search field. Used for text searches in the title and description fields
    * @param i_episode            needed by the native function
    * @param i_consult_req        needed by the native function
    * @param i_input_type         if not null, then this function only needs to return the translation for i_input_id
    * @param i_input_id           if not null, then this function only needs to return the translation for i_input_id
    * @param o_output            output collection 
    * @param o_output_type       R= reasons (sample texts + prof sample texts),  C= complaints
    * @param o_max_rows_exceeded if not null then the max rows limit was exceeded
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.3
    * @since                      11-09-2013
    */
    FUNCTION get_schedule_reasons
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_software       IN software.id_software%TYPE,
        i_text_search       IN VARCHAR2,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_consult_req    IN consult_req.id_consult_req%TYPE,
        i_input_type        IN VARCHAR2 DEFAULT NULL, -- R= reasons (sample texts),  C= complaints
        i_input_id          IN NUMBER DEFAULT NULL,
        o_output            OUT t_schedule_reasons,
        o_output_type       OUT VARCHAR2, -- R= reasons (sample texts),  C= complaints
        o_max_rows_exceeded OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets schedule details
    * @i_lang            Language ID
    * @i_prof            Profissional
    * i_id_schedule     Remote schedule id
    *
    *
    * @return           true/false
    *
    * @author           Carlos
    * @version          2.6
    * @since            29-02-2010
    */
    FUNCTION get_schedule_details
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        o_schedule_details OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pfh_ids(i_id_ext sch_api_map_ids.id_schedule_ext%TYPE) RETURN table_number;

    /*  finishes an exam/other exam schedule by setting the associated exam requisition.
    *    the workflow is: choose exams in imaging software -> choose to schedule them -> scheduler opens ->
    *    each schedule created is replicated in PFH via integration code, with status = V (temporary) ->
    *    close scheduler -> ok button pressed -> create requisitions -> confirm pending schedule up and down ->
    *    associate down schedule with requisitions
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_sch_ext          external schedule id
    * @param i_id_patient          scheduled patient
    * @param i_ids_exam            list of exam ids
    * @param i_ids_exam_req        list of exam req ids
    * @param o_error               error data
    *
    * return true /false
    *
    * @author  Telmo
    * @version 2.6
    * @date    20-04-2010
    */
    FUNCTION set_schedule_exam_reqs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_ext   IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_ids_exam     IN table_number,
        i_ids_exam_req IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /* check if there is a row in appointment table for specified event and clinical service
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_sch_event       event id
    * @param i_id_clin_service    clinical service id
    *
    * @RETURN  Y / N
    *
    * @author  Telmo
    * @version 2.6
    * @since   23-04-2010
    */
    FUNCTION get_appointment_exists
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sch_event    IN appointment.id_sch_event%TYPE,
        i_id_clin_service IN appointment.id_clinical_service%TYPE
    ) RETURN VARCHAR2;

    /* function to be used as data source for the intf_alert service that will feed the
    *  status combo box in the scheduler waiting list search window.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_search_scope       IN= inpatient statuses  S= surgery statuses
    * @param o_result             output collection made of t search_status cells
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      01-06-2010
    */
    FUNCTION get_search_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_search_scope IN VARCHAR2,
        o_result       OUT t_search_statuses,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /* function to be used as data source for the intf_alert service that will feed the
    *  responsible professional (inp=admission physicians; surg=pref surgeons) combo box in the scheduler waiting list search window.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_ids_inst           search in this institutions
    * @param i_id_dcs             dcs where to look. can be null
    * @param i_search_scope       IN= inpatient statuses  S= surgery statuses  C= outp appointments
    * @param o_result             output collection made of t search_status cells
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      04-06-2010
    */
    FUNCTION get_search_profs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_ids_inst     IN table_number,
        i_id_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_search_scope IN VARCHAR2,
        o_result       OUT t_search_profs,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /* function to be used as data source for the intf_alert service that will feed the
    *  services combo box in the scheduler waiting list search window. A service is a department
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_ids_inst           search in this institutions
    * @param i_search_scope       IN= inpatient statuses  S= surgery statuses  C= outp appointments
    * @param o_result             output collection made of t_search_prof cells
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      04-06-2010
    */
    FUNCTION get_search_services
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_ids_inst     IN table_number,
        i_search_scope IN VARCHAR2,
        o_result       OUT t_search_services,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /* function to be used as data source for the intf_alert service that will feed the
    *  admission indications (motivos de internamento) combo box in the scheduler waiting list search window.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_cs              clinical service required by the base function
    * @param o_result             output collection made of t_search_adm_indic cells
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      07-06-2010
    */
    FUNCTION get_search_adm_indics
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_cs  IN dep_clin_serv.id_clinical_service%TYPE,
        o_result OUT t_search_adm_indics,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*  universal function for returning the detail of a requisition. Requisitions can be of several types
    * and for that reason return different details. The waiting list is also present here.
    * Output is a collection of sections. Each one has its own detail - pairs field name - field value.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_req             requisition id. varchar because requisition come from several places and have different datatypes
    * @param i_req_type           req. type. Identifies where and how to get the data
    * @param o_result             output structured as a collection of types
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      06-07-2010
    */
    FUNCTION get_req_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_req   IN VARCHAR2,
        i_req_type IN VARCHAR2,
        o_result   OUT t_detail,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * scheduler 3 notifies PFH about a scheduled patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_id_patient                  patient id
    * @param i_id_cancel_reason            no-show reason id. Comes from table cancel_reason
    * @param i_notes                       optional notes
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.5.2
    * @date    25-02-2011
    */
    FUNCTION set_patient_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_ext       IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_cancel_reason IN sch_group.id_cancel_reason%TYPE,
        i_notes            IN sch_group.no_show_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * scheduler 3 notifies PFH to undo a patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_id_patient                  patient id
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.5.2
    * @date    01-03-2011
    */
    FUNCTION set_patient_undo_no_show
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN schedule.id_schedule%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * scheduler 3 wants to cancel a specific patient that is part of a group schedule
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_id_patient                  patient id
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1
    * @date    07-03-2011
    */
    FUNCTION cancel_group_schedule_patient
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_ext       IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_prof_cancel   IN schedule.id_prof_cancel%TYPE,
        i_id_cancel_reason IN sch_group.id_cancel_reason%TYPE,
        i_notes            IN sch_group.no_show_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * returns a list of all pfh schedule ids that are linked to the supplied scheduler external id
    * and patient id. This is a generic function that can have potentially many uses. Its first use
    * is to give support to the Scheduler patient registration (efectivacao)
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_id_patient                  patient id
    * @param o_result                      table_number with pfh schedule ids
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.5.3.1
    * @date    22-03-2011
    */
    FUNCTION get_pfh_ids
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN schedule.id_schedule%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_result     OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets scheduler external schedule id
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo Castro
    * @version 2.6.1.1
    * @since   13-05-2011
    */
    FUNCTION get_schedule_id_ext
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN sch_api_map_ids.id_schedule_pfh%TYPE,
        o_id_schedule OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * reschedule schedule to be called by scheduler 3. The reschedule in scheduler 3 is different than the update in that a new
    * record is created and the old one canceled. The update does not create a new record.
    * this functions allways cancels the existing schedule(s) and creates new ones. That is why it has same parameters 
    * as both create_schedule and cancel_schedule. 
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_sch_ext_old      external schedule id that's mapped to a local schedule id, this one to be canceled
    * @param i_id_sch_ext_new      newly created external schedule id, will be mapped to a new one here in pfh
    * @param i_flg_status          initial schedule status for the new one
    * @param i_id_instit_requested target institution for the new one
    * @param i_id_dep_requested    target department for the new one
    * @param i_flg_vacancy         schedule type  can be routine, urgency or unplanned for the new one
    * @param i_procedures          procedures being scheduled
    * @param i_resources           procedures resources
    * @param i_persons             target patients 
    * @param i_procedure_reqs      requisition or WL entry per procedure
    * @param i_id_episode          episode (optional) needed for pfh operations
    * @param i_id_prof_resched     professional doing the reschedule
    * @param i_id_resched_reason   reschedule reason id (see table sch_resched_reason)
    * @param i_resched_notes       reschedule notes
    * @param i_resched_date        reschedule date. if null uses sys date
    * @param i_dt_begin            new schedule global start date
    * @param i_dt_end              new schedule global end date
    * @param o_ids_schedule        newly created schedule ids
    * @param o_error               error data
    * 
    * return true /false
    *
    * @author  Telmo
    * @version 2.6.1.5
    * @date    09-11-2011
    */
    FUNCTION reschedule_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sch_ext_old      IN NUMBER,
        i_id_sch_ext_new      IN NUMBER,
        i_flg_status          IN schedule.flg_status%TYPE,
        i_id_instit_requested IN institution.id_institution%TYPE,
        i_id_dep_requested    IN dep_clin_serv.id_department%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE,
        i_procedures          IN t_procedures,
        i_resources           IN t_resources,
        i_persons             IN t_persons,
        i_procedure_reqs      IN t_procedure_reqs,
        i_id_episode          IN schedule.id_episode%TYPE,
        i_id_prof_resched     IN professional.id_professional%TYPE,
        i_id_resched_reason   IN sch_resched_reason.id_resched_reason%TYPE,
        i_resched_notes       IN VARCHAR2,
        i_resched_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_begin            IN schedule.dt_begin_tstz%TYPE,
        i_dt_end              IN schedule.dt_end_tstz%TYPE,
        i_video_link          IN schedule.video_link%TYPE DEFAULT NULL, -- map to schedule.video_link
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /* returns the same data as search_wl_bfs, but only for a specified id.
    * This is suposed to be used by the scheduler to retrieve data about the other not yet scheduled 
    * half of a waiting list entry.
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_req            ID to lookup for
    * @param i_wl_type           which half is needed? B=admission, S=surgery
    * @param o_result            returns a collection t_wl_search_row_coll, like search_wl_bfs
    * @param o_error             error info
    *
    *  @return                     true / false
    *
    *  @author                     Telmo
    *  @version                    2.6.1.6
    *  @date                       06-12-2011
    */
    FUNCTION get_wl_req_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_req  waiting_list.id_waiting_list%TYPE,
        i_wl_type waiting_list.flg_type%TYPE,
        o_result  OUT t_wl_search_row_coll,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * returns a list of all pfh schedule ids that are linked to the supplied scheduler external id
    * and one of the patient ids. Needed in ALERT-275305
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_ids_patient                 patient id list
    * @param o_result                      table_number with pfh schedule ids
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.3.11
    * @date    07-02-2014
    */
    FUNCTION get_pfh_ids
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_sch_ext  IN schedule.id_schedule%TYPE,
        i_ids_patient IN table_number,
        o_result      OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Gets id_schedule_resource
    *
    * @param i_lang                  Language identifier
    * @param i_prof                  Professional data: id, institution and software
    * @param i_id_schedule           Schedule (PFH) identifier
    * @param o_id_schedule_resource  Scheduler resource identifier              
    * @param o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Nuno Amorim
    * @since   28/11/2017
    */
    FUNCTION get_schedule_id_resource
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN sch_api_map_ids.id_schedule_pfh%TYPE,
        o_id_schedule_resource OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
	
	/*
    * Gets dep_clin_serv, service (department) and clinical_service
    *
    * @param i_lang                  Language identifier
    * @param i_prof                  Professional data: id, institution and software
    * @param i_software              Software Identifier
    * @param o_id_dep_clin_serv      Department Clinical Service identifier              
    * @param o_department            Department identifier 
    * @param o_clinical_service      Clinical Service identifier 
    * @param o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Nuno Amorim
    * @since   24/01/2019
    */
    FUNCTION get_prof_default_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_software         IN software.id_software%TYPE,
        o_id_dep_clin_serv OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_department       OUT department.id_department%TYPE,
        o_clinical_service OUT clinical_service.id_clinical_service%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
	
	/* create schedule to be used by scheduler 3. When a schedule is created there, it is propagated
    * in PFH. Scheduler 3 does that  by calling INTF_ALERT code that in turn calls this function.
    *
    * @param i_t_schedules          t_schedules
    *
    * return true /false
    *
    * @author  Miguel Monteiro
    * @version 2.8.2.1
    * @date    09-12-2020
    */
    FUNCTION create_schedule_collection
    (
        i_t_schedules         IN  t_schedules,
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    
    
    /*
    * reschedule schedule to be called by scheduler . The reschedule in scheduler  is different than the update in that a new
    * record is created and the old one canceled. The update does not create a new record.
    * this functions allways cancels the existing schedule(s) and creates new ones.
    * 
    * @param i_t_schedules          t_schedules
    *
    * return true /false
    *
    * @author  Miguel Monteiro
    * @version 2.8.2.1
    * @date    14-12-2020
    */
    FUNCTION reschedule_schedule_collection
    (
        i_t_schedules         IN  t_schedules,
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    
    /*
    * update schedule to be used by scheduler. When a schedule is update there, it is propagated
    * in PFH. Scheduler does that  by calling INTF_ALERT code that in turn calls this function.
    * this update is used by a large spectrum of scheduler actions. ex. adding/removing resources, changing procedure(s),
    * changing dates, etc.
    *
    * @param i_t_schedules          t_schedules
    *
    * return true /false
    *
    * @author  Miguel Monteiro
    * @version 2.8.2.1
    * @date    14-12-2020
    */
    FUNCTION update_schedule_collection(
       i_t_schedules         IN  t_schedules,
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

END pk_schedule_api_downstream;
/
