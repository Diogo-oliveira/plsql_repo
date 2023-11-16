/*-- Last Change Revision: $Rev: 2055401 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:43:55 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_events AS
    TYPE cr_events_rec IS RECORD(
        idpatient                NUMBER(24),
        iddepclinserv            NUMBER(24),
        idservice                NUMBER(24),
        idspeciality             NUMBER(24),
        idcontent                VARCHAR2(200 CHAR),
        flgtype                  VARCHAR2(4 CHAR),
        idrequisition            NUMBER(24),
        dtcreation               TIMESTAMP WITH LOCAL TIME ZONE,
        idusercreation           NUMBER(24),
        idinstitution            NUMBER(24),
        idresource               NUMBER(24),
        resourcetype             VARCHAR2(4 CHAR),
        dtsugested               TIMESTAMP WITH LOCAL TIME ZONE,
        dtbeginmin               TIMESTAMP WITH LOCAL TIME ZONE,
        dtbeginmax               TIMESTAMP WITH LOCAL TIME ZONE,
        flgcontacttype           VARCHAR2(4 CHAR),
        priority                 VARCHAR2(4 CHAR),
        idlanguage               NUMBER(24),
        idmotive                 NUMBER(24),
        motivetype               VARCHAR2(4000 CHAR),
        motivedescription        VARCHAR2(4000 CHAR),
        daylynumberdays          NUMBER(24),
        flgweeklyfriday          VARCHAR2(4 CHAR),
        flgweeklymonday          VARCHAR2(4 CHAR),
        flgweeklysaturday        VARCHAR2(4 CHAR),
        flgweeklysunday          VARCHAR2(4 CHAR),
        flgweeklythursday        VARCHAR2(4 CHAR),
        flgweeklytuesday         VARCHAR2(4 CHAR),
        flgweeklywednesday       VARCHAR2(4 CHAR),
        weeklynumberweeks        VARCHAR2(4 CHAR),
        monthlynumbermonths      NUMBER(24),
        monthlydaynumber         NUMBER(24),
        monthlyweekday           NUMBER(24),
        monthlyweeknumber        NUMBER(24),
        yearlyyearnumber         NUMBER(24),
        yearlymonthdaynumber     NUMBER(24),
        yearlymonthnumber        NUMBER(24),
        yearlyweekday            NUMBER(24),
        yearlyweeknumber         NUMBER(24),
        yearlyweekdaymonthnumber NUMBER(24),
        flgreccurencepattern     VARCHAR2(4 CHAR),
        recurrencebegindate      TIMESTAMP WITH LOCAL TIME ZONE,
        recurrenceenddate        TIMESTAMP WITH LOCAL TIME ZONE,
        recurrenceendnumber      NUMBER(24),
        sessionnumber            VARCHAR2(4 CHAR),
        frequencyunit            VARCHAR2(4 CHAR),
        frequency                VARCHAR2(4 CHAR),
        totalrecordnumber        NUMBER(24));

    TYPE cr_events_cur IS REF CURSOR RETURN cr_events_rec;

    TYPE future_events_dif IS RECORD(
        inst_req_to_b    VARCHAR2(4000 CHAR),
        inst_req_to_a    VARCHAR2(4000 CHAR),
        dep_clin_serv_b  VARCHAR2(4000 CHAR),
        dep_clin_serv_a  VARCHAR2(4000 CHAR),
        sch_event_b      VARCHAR2(4000 CHAR),
        sch_event_a      VARCHAR2(4000 CHAR),
        prof_req_to_b    VARCHAR2(4000 CHAR),
        prof_req_to_a    VARCHAR2(4000 CHAR),
        complaint_b      VARCHAR2(4000 CHAR),
        complaint_a      VARCHAR2(4000 CHAR),
        event_date_b     VARCHAR2(4000 CHAR),
        event_date_a     VARCHAR2(4000 CHAR),
        priority_b       VARCHAR2(4000 CHAR),
        priority_a       VARCHAR2(4000 CHAR),
        contact_type_b   VARCHAR2(4000 CHAR),
        contact_type_a   VARCHAR2(4000 CHAR),
        notes_b          VARCHAR2(4000 CHAR),
        notes_a          VARCHAR2(4000 CHAR),
        instructions_b   VARCHAR2(4000 CHAR),
        instructions_a   VARCHAR2(4000 CHAR),
        room_b           VARCHAR2(4000 CHAR),
        room_a           VARCHAR2(4000 CHAR),
        request_type_b   VARCHAR2(4000 CHAR),
        request_type_a   VARCHAR2(4000 CHAR),
        req_resp_b       VARCHAR2(4000 CHAR),
        req_resp_a       VARCHAR2(4000 CHAR),
        lang_b           VARCHAR2(4000 CHAR),
        lang_a           VARCHAR2(4000 CHAR),
        approval_prof_b  VARCHAR2(4000 CHAR),
        approval_prof_a  VARCHAR2(4000 CHAR),
        request_reason_b VARCHAR2(4000 CHAR),
        request_reason_a VARCHAR2(4000 CHAR),
        recurrence_b     VARCHAR2(4000 CHAR),
        recurrence_a     VARCHAR2(4000 CHAR),
        frequency_b      VARCHAR2(4000 CHAR),
        frequency_a      VARCHAR2(4000 CHAR),
        dt_rec_begin_b   VARCHAR2(4000 CHAR),
        dt_rec_begin_a   VARCHAR2(4000 CHAR),
        dt_rec_end_b     VARCHAR2(4000 CHAR),
        dt_rec_end_a     VARCHAR2(4000 CHAR),
        nr_event_b       VARCHAR2(4000 CHAR),
        nr_event_a       VARCHAR2(4000 CHAR),
        week_day_b       VARCHAR2(4000 CHAR),
        week_day_a       VARCHAR2(4000 CHAR),
        week_nr_b        VARCHAR2(4000 CHAR),
        week_nr_a        VARCHAR2(4000 CHAR),
        month_day_b      VARCHAR2(4000 CHAR),
        month_day_a      VARCHAR2(4000 CHAR),
        month_nr_b       VARCHAR2(4000 CHAR),
        month_nr_a       VARCHAR2(4000 CHAR),
        status_b         VARCHAR2(4000 CHAR),
        status_a         VARCHAR2(4000 CHAR),
        cancel_notes_b   VARCHAR2(4000 CHAR),
        cancel_notes_a   VARCHAR2(4000 CHAR),
        cancel_reason_b  VARCHAR2(4000 CHAR),
        cancel_reason_a  VARCHAR2(4000 CHAR),
        registered       VARCHAR2(4000 CHAR),
        create_time      VARCHAR2(4000 CHAR));

    TYPE future_events_dif_table IS TABLE OF future_events_dif INDEX BY BINARY_INTEGER;

    TYPE future_events_type IS RECORD(
        inst_req_to    VARCHAR2(4000 CHAR),
        dep_clin_serv  VARCHAR2(4000 CHAR),
        sch_event      VARCHAR2(4000 CHAR),
        prof_req_to    VARCHAR2(4000 CHAR),
        complaint      VARCHAR2(4000 CHAR),
        event_date     VARCHAR2(4000 CHAR),
        priority       VARCHAR2(4000 CHAR),
        contact_type   VARCHAR2(4000 CHAR),
        notes          VARCHAR2(4000 CHAR),
        instructions   CLOB,
        room           VARCHAR2(4000 CHAR),
        request_type   VARCHAR2(4000 CHAR),
        req_resp       VARCHAR2(4000 CHAR),
        lang           VARCHAR2(4000 CHAR),
        approval_prof  VARCHAR2(4000 CHAR),
        request_reason VARCHAR2(4000 CHAR),
        recurrence     VARCHAR2(4000 CHAR),
        frequency      VARCHAR2(4000 CHAR),
        dt_rec_begin   VARCHAR2(4000 CHAR),
        dt_rec_end     VARCHAR2(4000 CHAR),
        nr_event       VARCHAR2(4000 CHAR),
        week_day       VARCHAR2(4000 CHAR),
        week_nr        VARCHAR2(4000 CHAR),
        month_day      VARCHAR2(4000 CHAR),
        month_nr       VARCHAR2(4000 CHAR),
        status         VARCHAR2(4000 CHAR),
        cancel_notes   VARCHAR2(4000 CHAR),
        cancel_reason  VARCHAR2(4000 CHAR),
        registered     VARCHAR2(4000 CHAR),
        create_time    VARCHAR2(4000 CHAR));

    TYPE prof_list_type IS RECORD(
        id_professional professional.id_professional%TYPE,
        prof_name       VARCHAR2(4000 CHAR));

    TYPE t_rec_future_event IS RECORD(
        id_event                    NUMBER(24),
        id_episode                  NUMBER(24),
        id_schedule                 NUMBER(24),
        id_exam_req_det             NUMBER(24),
        id_exam_req                 NUMBER(24),
        event_type                  VARCHAR2(4000 CHAR),
        event_type_icon             VARCHAR2(4000 CHAR),
        event_type_name_title       VARCHAR2(4000 CHAR),
        event_type_clinical_service VARCHAR2(4000 CHAR),
        event_type_procedure        VARCHAR2(4000 CHAR),
        desc_dependency             VARCHAR2(4000 CHAR),
        request_date                VARCHAR2(4000 CHAR),
        request_status_desc         VARCHAR2(4000 CHAR),
        requested_by                VARCHAR2(4000 CHAR),
        professional                VARCHAR2(4000 CHAR),
        id_prof_resp                NUMBER(24),
        id_first_nurse_resp         NUMBER(24),
        event_date                  VARCHAR2(4000 CHAR),
        status                      VARCHAR2(4000 CHAR),
        flg_status                  VARCHAR2(4000 CHAR),
        location                    VARCHAR2(4000 CHAR),
        id_location                 NUMBER(24),
        status_icon                 VARCHAR2(4000 CHAR),
        order_date                  VARCHAR2(4000 CHAR),
        id_future_event_type        NUMBER(24),
        id_fet_parent               NUMBER(24),
        flg_can_approve             VARCHAR2(4000 CHAR),
        flg_can_reject              VARCHAR2(4000 CHAR),
        flg_can_cancel              VARCHAR2(4000 CHAR),
        flg_can_schedule            VARCHAR2(4000 CHAR),
        flg_can_admit               VARCHAR2(4000 CHAR),
        flg_ok                      VARCHAR2(4000 CHAR),
        time_state                  VARCHAR2(4000 CHAR),
        dep_clin_serv               VARCHAR2(4000 CHAR),
        sch_event                   VARCHAR2(4000 CHAR),
        show_report                 VARCHAR2(4000 CHAR),
        id_software                 NUMBER(24),
        reopen_episode              VARCHAR2(4000 CHAR),
        dt_sched                    VARCHAR2(4000 CHAR),
        dt_req_begin                VARCHAR2(4000 CHAR),
        dt_req_end                  VARCHAR2(4000 CHAR),
        icon_name                   VARCHAR2(4000 CHAR),
        registered                  VARCHAR2(4000 CHAR),
        approval_prof               VARCHAR2(4000 CHAR),
        request_reason              VARCHAR2(4000 CHAR),
        id_exam                     NUMBER(24),
        id_dest_professional        NUMBER(24),
        id_sched_professional       NUMBER(24),
        dt_sched_event              VARCHAR2(4000 CHAR),
        dt_sched_event_str          VARCHAR2(4000 CHAR),
        id_created_professional     NUMBER(24),
        notes                       VARCHAR2(4000 CHAR),
        flg_contact_type            VARCHAR2(4000 CHAR),
        id_content                  VARCHAR2(4000 CHAR),
        id_workflow                 NUMBER(24),
        id_complaint                NUMBER(24),
        desc_complaint              VARCHAR2(4000 CHAR), --
        
        flg_type_of_external_resource VARCHAR2(200 CHAR), --
        id_external_resource          NUMBER(24), --
        id_efect_episode              NUMBER(24),
        id_waiting_list               NUMBER(24),
        status_icon_c                 VARCHAR2(4000 CHAR),
        id_epis_hhc_req               NUMBER(24));

    TYPE t_coll_future_event IS TABLE OF t_rec_future_event;

    /********************************************************************************************
    * get epis type from consult_req
    *
    * @param      i_consult_req       id consult req
    *
    * @return  id_epis_type
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/09/30
    **********************************************************************************************/
    FUNCTION get_epis_type_consult_req(i_consult_req IN consult_req.id_consult_req%TYPE) RETURN VARCHAR2;
    /********************************************************************************************
    * get event type icon
    *
    * @param      i_event_type       event type
    *
    * @return  event type  description
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION get_event_type_icon(i_event_type IN future_event_type.id_epis_type%TYPE) RETURN VARCHAR2;
    /********************************************************************************************
    * get event type by episisode type
    *
    * @param      i_epis_type       episode type
    *
    * @return  event type  description
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION get_event_type_by_epis_type(i_epis_type IN future_event_type.id_epis_type%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * get event type name
    *
    * @param      i_lang       language identifier
    * @param      i_epis_type        episode type
    *
    * @return  event type  description
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION get_event_type_name
    (
        i_lang              IN language.id_language%TYPE,
        i_future_event_type IN future_event_type.id_future_event_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get event type title
    *
    * @param      i_lang       language identifier
    * @param      i_epis_type        episode type
    *
    * @return  event type  description
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION get_event_type_title
    (
        i_lang              IN language.id_language%TYPE,
        i_future_event_type IN future_event_type.id_future_event_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get event type name using task type
    *
    * @param      i_lang         language identifier
    * @param      id_task_type   Task type identifier
    *
    * @return  event type  description
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/25
    **********************************************************************************************/
    FUNCTION get_fe_desc_by_tk
    (
        i_lang      IN language.id_language%TYPE,
        i_task_type IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get event detail
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_consult_req    future_events id
    * @param o_event            return cursor
    * @param o_error            error
    *
    * @author                 Paulo Teixeira
    * @version                2.6.0.1
    * @since                  2010/05/26
    **********************************************************************************************/
    FUNCTION get_event_general
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_event       OUT pk_types.cursor_type,
        o_req_det     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get event detail for html grid
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_consult_req      future_events id
    * @param o_detail           return cursor
    * @param o_error            error
    **********************************************************************************************/

    FUNCTION get_event_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get event detail history for html grid
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_consult_req      future_events id
    * @param o_detail           return cursor
    * @param o_error            error
    **********************************************************************************************/

    FUNCTION get_event_detail_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get event detail
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_consult_req    future_events id
    * @param o_event            return cursor
    * @param o_event_hist       return cursor
    * @param o_error            error
    *
    * @author                 Paulo Teixeira
    * @version                2.6.0.1
    * @since                  2010/05/26
    **********************************************************************************************/
    FUNCTION get_event_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_event       OUT pk_types.cursor_type,
        o_event_hist  OUT table_table_clob,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * result search patient
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_id_sys_btn_crit    criteria identifier
    * @param      i_crit_val           criteria value
    * @param      i_patient            patient identifier
    * @param      o_all_patients       patients
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/04
    **********************************************************************************************/
    FUNCTION get_search_patients
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_patient         IN consult_req.id_patient%TYPE,
        o_all_patients    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * result search patient
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_id_sys_btn_crit    criteria identifier
    * @param      i_crit_val           criteria value
    * @param      o_all_patients       patients
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/04
    **********************************************************************************************/
    FUNCTION get_search_patients
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_all_patients    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * result patient events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_patient            patient identifier
    * @param      o_events             events
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/05
    **********************************************************************************************/
    FUNCTION get_patient_events_pl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN consult_req.id_patient%TYPE
    ) RETURN t_coll_future_event
        PIPELINED;

    /********************************************************************************************
    * result patient future events only
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_patient            patient identifier
    * @param      o_events             events
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/05
    **********************************************************************************************/
    FUNCTION get_patient_future_events_pl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN consult_req.id_patient%TYPE
    ) RETURN t_coll_future_event
        PIPELINED;

    /********************************************************************************************
    * result patient's events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_type               type of select
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/28
    **********************************************************************************************/
    FUNCTION get_adm_patient_events_pl
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_type IN VARCHAR2
    ) RETURN t_coll_adm_future_event
        PIPELINED;

    FUNCTION get_adm_patient_comb_events_pl
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_id_combination_spec IN combination_spec.id_combination_spec%TYPE
    ) RETURN t_coll_adm_future_event
        PIPELINED;

    /********************************************************************************************
    * result patient events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_patient            patient identifier
    * @param      o_events             events
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/05
    **********************************************************************************************/
    FUNCTION get_patient_events
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN consult_req.id_patient%TYPE,
        o_events  OUT pk_types.cursor_type,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * result patient future events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_patient            patient identifier
    * @param      o_events             events
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/05
    **********************************************************************************************/
    FUNCTION get_patient_future_events
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN consult_req.id_patient%TYPE,
        i_episode IN consult_req.id_episode%TYPE,
        i_report  IN VARCHAR2,
        o_events  OUT pk_types.cursor_type,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * result patient events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_type               type of select
    * @param      o_events             events
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/08
    **********************************************************************************************/
    FUNCTION get_adm_patient_events
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN VARCHAR2,
        o_events OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_adm_patient_comb_events
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_id_combination_spec IN combination_spec.id_combination_spec%TYPE,
        o_events              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert patient events
    *
    * @param i_lang              language identifier
    * @param i_prof              professional registered by identifier
    * @param i_patient           patient identifier
    * @param i_episode             episode identifier
    * @param i_epis_type           episode type identifier
    * @param i_request_prof       list of professionals requested
    * @param i_inst_req_to      institution registered to identifier
    * @param i_sch_event        episode type identifier
    * @param i_dep_clin_serv    clinical service identifier
    * @param i_complaint        complaint identifier
    * @param i_dt_begin_event      begin date
    * @param i_dt_end_event        end date
    * @param i_priority            priority
    * @param i_contact_type        contact_type
    * @param i_notes               notes
    * @param i_instructions        instructions
    * @param i_room             room identifier
    * @param i_request_type        request type
    * @param i_request_responsable request responsable
    * @param i_request_reason      request reason
    * @param i_prof_approval       list of professionals that can approve
    * @param i_language         language
    * @param i_recurrence          recurrence
    * @param i_status              status
    * @param i_frequency           frequency
    * @param i_dt_rec_begin          begin recurrence date
    * @param i_dt_rec_end          end recurrence date
    * @param i_nr_events           number of events
    * @param i_week_day            week day
    * @param i_week_nr             week number
    * @param i_month_day           month day
    * @param i_month_nr            month number
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/12
    **********************************************************************************************/
    FUNCTION insert_future_events
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN VARCHAR2,
        i_dt_end_event        IN VARCHAR2,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN VARCHAR2,
        i_dt_rec_end          IN VARCHAR2,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        o_consult_req_id      OUT consult_req.id_consult_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * insert patient events
    *
    * @param i_lang              language identifier
    * @param i_prof              professional registered by identifier
    * @param i_patient           patient identifier
    * @param i_episode             episode identifier
    * @param i_epis_type           episode type identifier
    * @param i_request_prof       list of professionals requested
    * @param i_inst_req_to      institution registered to identifier
    * @param i_sch_event        episode type identifier
    * @param i_dep_clin_serv    clinical service identifier
    * @param i_complaint        complaint identifier
    * @param i_dt_begin_event      begin date
    * @param i_dt_end_event        end date
    * @param i_priority            priority
    * @param i_contact_type        contact_type
    * @param i_notes               notes
    * @param i_instructions        instructions
    * @param i_room             room identifier
    * @param i_request_type        request type
    * @param i_request_responsable request responsable
    * @param i_request_reason      request reason
    * @param i_prof_approval       list of professionals that can approve
    * @param i_language         language
    * @param i_recurrence          recurrence
    * @param i_status              status
    * @param i_frequency           frequency
    * @param i_dt_rec_begin          begin recurrence date
    * @param i_dt_rec_end          end recurrence date
    * @param i_nr_events           number of events
    * @param i_week_day            week day
    * @param i_week_nr             week number
    * @param i_month_day           month day
    * @param i_month_nr            month number
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/12
    **********************************************************************************************/
    FUNCTION insert_future_events_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN VARCHAR2,
        i_dt_end_event        IN VARCHAR2,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN VARCHAR2,
        i_dt_rec_end          IN VARCHAR2,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        o_consult_req_id      OUT consult_req.id_consult_req%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update patient events
    *
    * @param i_consult_req       future events identifier
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_patient             patient identifier
    * @param i_episode             episode identifier
    * @param i_epis_type           episode type identifier
    * @param i_request_prof        list of requested professionals
    * @param i_inst_req_to         institution registered to identifier
    * @param i_sch_event           episode type identifier
    * @param i_dep_clin_serv       clinical service identifier
    * @param i_complaint           complaint identifier
    * @param i_dt_begin_event      begin date
    * @param i_dt_end_event        end date
    * @param i_priority            priority
    * @param i_contact_type        contact_type
    * @param i_notes               notes
    * @param i_instructions        instructions
    * @param i_room                room identifier
    * @param i_request_type        request type
    * @param i_request_responsable request responsable
    * @param i_request_reason      request reason
    * @param i_prof_approval       list of professionals that can approve
    * @param i_language         language
    * @param i_recurrence          recurrence
    * @param i_status              status
    * @param i_frequency           frequency
    * @param i_dt_rec_begin          begin recurrence date
    * @param i_dt_rec_end          end recurrence date
    * @param i_nr_events           number of events
    * @param i_week_day            week day
    * @param i_week_nr             week number
    * @param i_month_day           month day
    * @param i_month_nr            month number
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/12
    **********************************************************************************************/
    FUNCTION update_future_events
    (
        i_consult_req         IN consult_req.id_consult_req%TYPE,
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_episode             IN consult_req.id_episode%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN VARCHAR2,
        i_dt_end_event        IN VARCHAR2,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN VARCHAR2,
        i_dt_rec_end          IN VARCHAR2,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get default values
    *
    * @param      i_lang      Língua registada como preferência do profissional
    * @param      i_prof      profissional identifier
    * @param      i_patient   patient identifier
    * @param      i_episode   episode identifier
    * @param     o_default_values  return values
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/14
    **********************************************************************************************/
    FUNCTION get_default_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN consult_req.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_dep_type   IN sch_department.flg_dep_type%TYPE,
        i_epis_type      IN epis_type.id_epis_type%TYPE,
        i_origin_area    IN VARCHAR2,
        o_default_values OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get execute values
    *
    * @param      i_lang      Língua registada como preferência do profissional
    * @param     o_execute_values  return values
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/20
    **********************************************************************************************/
    FUNCTION get_execute_values
    (
        i_lang           IN language.id_language%TYPE,
        o_execute_values OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get execute values
    *
    * @param      i_lang             Língua registada como preferência do profissional
    * @param      i_prof             profissional identifier
    * @param      i_id_dep_clin_serv clinical service identifier
    *
    * @param     o_sql  return values
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/21
    **********************************************************************************************/
    FUNCTION get_reason_of_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * result FUTURE events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req            patient identifier
    * @param      o_events             events
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/05
    **********************************************************************************************/
    FUNCTION get_future_events
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_events      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if an specific future event type is available
    *
    * @param i_future_event_type         Lens identifier.
    * @param i_prof         The professional record.
    *
    * @return  'Y' is available, 'N' otherwise
    *
    * @author   Sérgio Santos
    * @version  2.5
    * @since    2010/Jun/18
    */
    FUNCTION is_fe_available
    (
        i_future_event_type future_event_type.id_future_event_type%TYPE,
        i_prof              profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the actions associated to the PLUS button
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      o_actions            actions list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/05/24
    **********************************************************************************************/
    FUNCTION get_plus_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get approval professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      o_prof_list          professional list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_approval_professionals
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_prof_list   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_approval_professionals
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * insert professional approval
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      i_prof_approval      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION insert_prof_approval_nc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_prof_approval IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * insert requested professional
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      i_prof_list      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION insert_request_prof_nc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof_list   IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert combination specifications
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_patient            patient identifier
    * @param      i_comb_name          combination name
    * @param      i_dt_suggest_begin   suggested date begin
    * @param      i_dt_suggest_end     suggested date end
    * @param      i_flg_status         flag status
    * @param      i_single_visit       single visit Y/N
    * @param      i_flg_freq_origin_module flaq origin module
    *
    * @param      o_id_combination_spec  combination specification identifier
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION insert_combination_spec_nc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN patient.id_patient%TYPE,
        i_comb_name              IN combination_spec.comb_name%TYPE,
        i_dt_suggest_begin       IN combination_spec.dt_suggest_begin%TYPE,
        i_dt_suggest_end         IN combination_spec.dt_suggest_end%TYPE,
        i_flg_status             IN combination_spec.flg_status%TYPE,
        i_single_visit           IN combination_spec.flg_single_visit%TYPE,
        i_flg_freq_origin_module IN combination_spec.flg_freq_origin_module%TYPE,
        i_episode                IN combination_spec.id_episode%TYPE,
        o_id_combination_spec    OUT combination_spec.id_combination_spec%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update combination specifications history
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_combination_spec   combination specification
    * @param      i_patient            patient identifier
    * @param      i_comb_name          combination name
    * @param      i_dt_suggest_begin   suggested date begin
    * @param      i_dt_suggest_end     suggested date end
    * @param      i_flg_status         flag status
    * @param      i_single_visit       single visit Y/N
    * @param      i_flg_freq_origin_module flaq origin module
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION update_combination_spec_nc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_combination_spec       IN combination_spec.id_combination_spec%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_comb_name              IN combination_spec.comb_name%TYPE,
        i_dt_suggest_begin       IN combination_spec.dt_suggest_begin%TYPE,
        i_dt_suggest_end         IN combination_spec.dt_suggest_end%TYPE,
        i_flg_status             IN combination_spec.flg_status%TYPE,
        i_single_visit           IN combination_spec.flg_single_visit%TYPE,
        i_flg_freq_origin_module IN combination_spec.flg_freq_origin_module%TYPE,
        i_episode                IN combination_spec.id_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * update professional approval
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      i_prof_approval      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION update_prof_approval_nc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_consult_req   IN consult_req.id_consult_req%TYPE,
        i_prof_approval IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update requested professional
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      i_prof_list      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION update_request_prof_nc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_prof_list   IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get future events approval professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      i_hist
    * @param      o_id_prof_list          professional list
    * @param      o_name_prof_list          professional list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_fe_approval_professionals
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_consult_req    IN consult_req.id_consult_req%TYPE,
        i_hist           IN VARCHAR2,
        o_id_prof_list   OUT table_number,
        o_name_prof_list OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get future events requested professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      i_hist
    * @param      o_id_prof_list          professional list
    * @param      o_name_prof_list          professional list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_fe_request_professionals
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_consult_req    IN consult_req.id_consult_req%TYPE,
        i_hist           IN VARCHAR2,
        o_id_prof_list   OUT table_number,
        o_name_prof_list OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get future events approval professionals (ids only)
    *
    * @param      i_consult_req      future events identifier
    *
    * @return  table_number with the professional ids
    * @author  Sérgio Santos
    * @version 1.0
    * @since   2010/Jun/03
    **********************************************************************************************/
    FUNCTION get_fe_approval_prof_ids(i_consult_req IN consult_req.id_consult_req%TYPE) RETURN table_number;

    /********************************************************************************************
    * get future events requested professionals (ids only)
    *
    * @param      i_consult_req      future events identifier
    *
    * @return  table_number with the professional ids
    * @author  Sérgio Santos
    * @version 1.0
    * @since   2010/Jun/03
    **********************************************************************************************/
    FUNCTION get_fe_request_prof_ids(i_consult_req IN consult_req.id_consult_req%TYPE) RETURN table_number;

    /********************************************************************************************
    * get future events approval professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_fe_approval_prof_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_hist        IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get future events requested professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_fe_request_prof_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_hist        IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get week number
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_week_nr            week number
    * @return   week number string
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_week_nr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_week_nr IN consult_req.week_nr%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get week day
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_week_day            week day
    * @return   week day string
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_week_day
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_week_day IN consult_req.week_day%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get month
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_month           month
    * @return   month string
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_month
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_month_nr IN consult_req.month_nr%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * insert professional approval hist
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req_hist      future events identifier
    * @param      i_prof_approval      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION insert_prof_approval_hist_nc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_consult_req_hist IN consult_req_hist.id_consult_req_hist%TYPE,
        i_prof_approval    IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert requested professional hist
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req_hist      future events identifier
    * @param      i_prof_list      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION insert_request_prof_hist_nc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_consult_req_hist IN consult_req_hist.id_consult_req_hist%TYPE,
        i_prof_list        IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get approval professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      o_prof_list          professional list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_approval_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_prof_list   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get requested professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      o_prof_list          professional list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_request_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        o_prof_list   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get approval professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      o_prof_list          professional list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_approval_prof_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_consult_req_hist IN consult_req_hist.id_consult_req_hist%TYPE,
        o_prof_list        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get requested professionals
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      future events identifier
    * @param      o_prof_list          professional list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_request_prof_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_consult_req_hist IN consult_req_hist.id_consult_req_hist%TYPE,
        o_prof_list        OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * check requires approval
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_event_type
    * @param      o_need_approval
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION check_requires_approval
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_event_type    IN future_event_approval.id_future_event_type%TYPE,
        o_need_approval OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns future appointments with an episode ID
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_patient             patient identifier
    * @param i_episode             episode type identifier
    * @param i_full_select         Y/N if full select or not
    
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/01
    **********************************************************************************************/
    FUNCTION get_fe_to_assoc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN consult_req.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_full_select   IN VARCHAR2,
        o_future_events OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_fe_to_assoc_by_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN consult_req.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_full_select      IN VARCHAR2,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE,
        o_future_events    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert patient events
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_patient             patient identifier
    * @param i_epis_type           episode type identifier
    * @param i_request_prof        list of requested professioanal
    * @param i_inst_req_to         institution registered to identifier
    * @param i_sch_event           episode type identifier
    * @param i_dep_clin_serv       clinical service identifier
    * @param i_complaint           complaint identifier
    * @param i_dt_begin_event      begin date
    * @param i_dt_end_event        end date
    * @param i_priority            priority
    * @param i_contact_type        contact_type
    * @param i_notes               notes
    * @param i_instructions        instructions
    * @param i_room                room identifier
    * @param i_request_type        request type
    * @param i_request_responsable request responsable
    * @param i_prof_approval       list of professionals that can approve
    * @param i_language         language
    * @param i_recurrence          recurrence
    * @param i_status              status
    * @param i_frequency           frequency
    * @param i_dt_rec_begin          begin recurrence date
    * @param i_dt_rec_end          end recurrence date
    * @param i_nr_events           number of events
    * @param i_week_day            week day
    * @param i_week_nr             week number
    * @param i_month_day           month day
    * @param i_month_nr            month number
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/01
    **********************************************************************************************/
    FUNCTION create_follow_up_appointment
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN consult_req.id_patient%TYPE,
        i_epis_type           IN consult_req.id_epis_type%TYPE,
        i_request_prof        IN table_number,
        i_inst_req_to         IN consult_req.id_inst_requested%TYPE,
        i_sch_event           IN consult_req.id_sch_event%TYPE,
        i_dep_clin_serv       IN consult_req.id_dep_clin_serv%TYPE,
        i_complaint           IN consult_req.id_complaint%TYPE,
        i_dt_begin_event      IN VARCHAR2,
        i_dt_end_event        IN VARCHAR2,
        i_priority            IN consult_req.flg_priority%TYPE,
        i_contact_type        IN consult_req.flg_contact_type%TYPE,
        i_notes               IN consult_req.notes%TYPE,
        i_instructions        IN consult_req.instructions%TYPE,
        i_room                IN consult_req.id_room%TYPE,
        i_request_type        IN consult_req.flg_request_type%TYPE,
        i_request_responsable IN consult_req.flg_req_resp%TYPE,
        i_request_reason      IN consult_req.request_reason%TYPE,
        i_prof_approval       IN table_number,
        i_language            IN consult_req.id_language%TYPE,
        i_recurrence          IN consult_req.flg_recurrence%TYPE,
        i_status              IN consult_req.flg_status%TYPE,
        i_frequency           IN consult_req.frequency%TYPE,
        i_dt_rec_begin        IN VARCHAR2,
        i_dt_rec_end          IN VARCHAR2,
        i_nr_events           IN consult_req.nr_events%TYPE,
        i_week_day            IN consult_req.week_day%TYPE,
        i_week_nr             IN consult_req.week_nr%TYPE,
        i_month_day           IN consult_req.month_day%TYPE,
        i_month_nr            IN consult_req.month_nr%TYPE,
        i_reason_for_visit    IN consult_req.reason_for_visit%TYPE,
        i_flg_origin_module   IN VARCHAR2,
        i_task_dependency     IN tde_task_dependency.id_task_dependency%TYPE,
        i_flg_start_depending IN VARCHAR2,
        i_episode_to_exec     IN consult_req.id_episode_to_exec%TYPE,
        i_transaction_id      IN VARCHAR2,
        o_id_consult_req      OUT consult_req.id_consult_req%TYPE,
        o_id_episode          OUT episode.id_episode%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_follow_up_appointment
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_tbl_val_mea          IN table_varchar,
        i_tbl_val_clob         IN table_clob DEFAULT NULL,
        o_id_consult_req       OUT consult_req.id_consult_req%TYPE,
        o_id_episode           OUT episode.id_episode%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates an Task -> Episode combination
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_patient                patient identifier
    * @param      i_comb_origin            combination origin (OE - other exam; IE - Imaging exam)
    * @param      i_task_suggest_date      task suggested date
    * @param      i_epis_suggest_date      episode suggested date
    * @param      i_task_type_from         task type id (where the dependecy comes from)
    * @param      i_task_request_from      task request id (where the dependecy comes from)
    * @param      i_id_event               consult requisition identifier
    * @param      i_id_schedule            schedule identifier
    * @param      i_id_episode             episode identifier
    *
    * @param      o_task_dependency_from created dependency id for i_task_type_from and i_task_request_from pair
    * @param      o_task_dependency_to   created dependency id for i_task_type_to and i_task_request_to pair
    *
    * @param      o_error                  error message
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 2.6.0.3
    * @since  2010/07/02
    **********************************************************************************************/
    FUNCTION create_task_epis_combination
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_task_suggest_date    IN combination_spec.dt_suggest_begin%TYPE,
        i_task_type_from       IN task_type.id_task_type%TYPE,
        i_task_request_from    IN tde_task_dependency.id_task_request%TYPE,
        i_id_event             IN consult_req.id_consult_req%TYPE,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        o_id_combination_spec  OUT combination_spec.id_combination_spec%TYPE,
        o_task_dependency_from OUT tde_task_dependency.id_task_dependency%TYPE,
        o_task_dependency_to   OUT tde_task_dependency.id_task_dependency%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates an Order Set future event with an associeted episode with flg_ehr = 'O'
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_patient             Consult Req identifier
    * @param i_id_schedule         The schedule episode
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 2.6.0.3
    * @since  2010/Jun/19
    **********************************************************************************************/
    FUNCTION schedule_consult_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN consult_req.id_consult_req%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the actions associated to the PLUS button on the all events grid
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    *
    * @param o_areas               cursor containing actions available
    *
    * @return              true if sucess, false otherwise
    *
    * @since 2010-Jun-11
    * @version v2.6.0.3
    * @author sergio.santos
    */
    FUNCTION get_plus_actions_grid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get future event type
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      o_fut_eve_type      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/14
    **********************************************************************************************/
    FUNCTION get_future_events_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_fut_eve_type OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get future event status
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      o_fut_eve_type      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/14
    **********************************************************************************************/
    FUNCTION get_future_events_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_fut_eve_status OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get priority's
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      o_sql      professional identifier list
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/14
    **********************************************************************************************/
    FUNCTION get_priority
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_sql   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *   OBJECTIVO:   Registar leitura e aceitação / rejeição do pedido INTERNO de consulta
    *
    *
    * @param      i_lang         Língua registada como preferência do profissional
    * @param      i_consult_req     ID do pedido de exame / consulta
    * @param      i_prof            Profissional lê e aceita / rejeita
    * @param      i_deny_acc        aceitar / não aceitar o pedido
    * @param      i_denial_justif   Justificação de rejeição do pedido
    * @param      i_approve_justif  Justificação da aprovação do pedido
    * @param      i_dt_scheduled_str Data / hora da consulta
    * @param      i_notes_admin     Notas para o administrativo
    * @param      i_flg_type_date
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/18
    **********************************************************************************************/
    FUNCTION set_consult_req_decide
    (
        i_lang             IN language.id_language%TYPE,
        i_consult_req      IN consult_req.id_consult_req%TYPE,
        i_prof             IN profissional,
        i_deny_acc         IN consult_req_prof.flg_status%TYPE,
        i_denial_justif    IN consult_req_prof.denial_justif%TYPE,
        i_approve_justif   IN consult_req_prof.approve_justif%TYPE,
        i_dt_scheduled_str IN VARCHAR2,
        i_notes_admin      IN consult_req.notes_admin%TYPE,
        i_flg_type_date    IN consult_req.flg_type_date%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Send a combination to history
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_combination_spec       future events identifier
    *
    * @param  o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION send_comb_to_history
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_combination_spec IN combination_spec.id_combination_spec%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert combination events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_combination_spec   combination_specification identifier
    * @param      i_future_event_type  future event type
    * @param      i_event              event identifier
    * @param      i_flg_status         flag status
    * @param      i_RANK               RANK
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION insert_combination_events_nc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_combination_spec  IN combination_events.id_combination_spec%TYPE,
        i_future_event_type IN combination_events.id_future_event_type%TYPE,
        i_event             IN combination_events.id_event%TYPE,
        i_flg_status        IN combination_events.flg_status%TYPE,
        i_rank              IN combination_events.rank%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update combination events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_combination_event  combination event identifier
    * @param      i_combination_spec   combination_specification identifier
    * @param      i_future_event_type  future event type
    * @param      i_event              event identifier
    * @param      i_flg_status         flag status
    * @param      i_rank               rank
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION update_combination_events_nc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_combination_event IN combination_events.id_combination_events%TYPE,
        i_combination_spec  IN combination_events.id_combination_spec%TYPE,
        i_future_event_type IN combination_events.id_future_event_type%TYPE,
        i_event             IN combination_events.id_event%TYPE,
        i_flg_status        IN combination_events.flg_status%TYPE,
        i_rank              IN combination_events.rank%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert combination
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_patient                patient identifier
    * @param      i_comb_name              combination name
    * @param      i_dt_suggest_begin       suggest date begin
    * @param      i_dt_suggest_end         suggest date end
    * @param      i_single_visit           single visit
    * @param      i_flg_freq_origin_module flag origin module
    * @param      i_future_event_type_list future event type list identifiers
    * @param      i_event_list             event list identifiers
    * @param      i_dependencies           grid of existing dependencies
    * @param      i_lag_min                grid of minimum values
    * @param      i_lag_max                grid of max values
    * @param      i_lag_unit_meas      grid of max unit measures
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION insert_combination
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN combination_spec.id_patient%TYPE,
        i_comb_name              IN combination_spec.comb_name%TYPE,
        i_dt_suggest_begin       IN VARCHAR2,
        i_dt_suggest_end         IN VARCHAR2,
        i_single_visit           IN combination_spec.flg_single_visit%TYPE,
        i_flg_freq_origin_module IN combination_spec.flg_freq_origin_module%TYPE,
        i_future_event_type_list IN table_number,
        i_event_list             IN table_number,
        i_dependencies           IN table_table_number,
        i_lag_min                IN table_table_number,
        i_lag_max                IN table_table_number,
        i_lag_unit_meas          IN table_table_number,
        i_episode                IN combination_spec.id_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update combination
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_combination_spec       combination specification identifier
    * @param      i_patient                patient identifier
    * @param      i_comb_name              combination name
    * @param      i_dt_suggest_begin       suggest date begin
    * @param      i_dt_suggest_end         suggest date end
    * @param      i_single_visit           single visit
    * @param      i_flg_freq_origin_module flag origin module
    * @param      i_future_event_type_list future event type list identifiers
    * @param      i_event_list             event list identifiers
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION update_combination
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_combination_spec       IN combination_spec.id_combination_spec%TYPE,
        i_patient                IN combination_spec.id_patient%TYPE,
        i_comb_name              IN combination_spec.comb_name%TYPE,
        i_dt_suggest_begin       IN VARCHAR2,
        i_dt_suggest_end         IN VARCHAR2,
        i_single_visit           IN combination_spec.flg_single_visit%TYPE,
        i_flg_freq_origin_module IN combination_spec.flg_freq_origin_module%TYPE,
        i_future_event_type_list IN table_number,
        i_event_list             IN table_number,
        i_lag_min                IN table_table_number,
        i_lag_max                IN table_table_number,
        i_lag_unit_meas          IN table_table_number,
        i_episode                IN combination_spec.id_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * ungroup combination
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_combination_spec       combination specification identifier
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/28
    **********************************************************************************************/
    FUNCTION ungroup_combination
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_combination_spec IN combination_spec.id_combination_spec%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * result patient future events
    *
    * @param      i_future_event_type  future event type identifier
    * @param      i_event              events identifier
    *
    * @return  combination specification identifier
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/22
    **********************************************************************************************/
    FUNCTION get_id_combination_spec
    (
        i_future_event_type IN combination_events.id_future_event_type%TYPE,
        i_event             IN combination_events.id_event%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * get id_combination_events
    *
    * @param      i_future_event_type  future event type identifier
    * @param      i_event              events identifier
    *
    * @return  combination specification identifier
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/22
    **********************************************************************************************/
    FUNCTION get_id_combination_events
    (
        i_future_event_type IN combination_events.id_future_event_type%TYPE,
        i_event             IN combination_events.id_event%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * result patient future events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_patient            patient identifier
    * @param      i_combination_spec   combination specification identifier
    * @param      o_events             events
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/22
    **********************************************************************************************/
    FUNCTION get_combination_events
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN consult_req.id_patient%TYPE,
        i_combination_spec IN combination_spec.id_combination_spec%TYPE,
        o_events           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check combination
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_type_list              list of types of events
    * @param      i_events_list            list of id's of events
    * @param      i_grid                   grid of existing dependencies
    * @param      o_dependencies           return cursor
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/22
    **********************************************************************************************/
    FUNCTION check_combination
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_type_list  IN table_number,
        i_event_list IN table_number,
        i_grid       IN table_table_number,
        o_flg_can_ok OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get combination_events_rank
    *
    * @param      i_future_event_type  future event type identifier
    * @param      i_event              events identifier
    *
    * @return  combination specification identifier
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/22
    **********************************************************************************************/
    FUNCTION get_combination_events_rank
    (
        i_future_event_type IN combination_events.id_future_event_type%TYPE,
        i_event             IN combination_events.id_event%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * count combination events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_combination_spec  combination specification identifier
    * @param      i_type              string or number
    *
    * @return  combination specification identifier
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/23
    **********************************************************************************************/
    FUNCTION count_combination_events
    (
        i_lang             IN language.id_language%TYPE,
        i_combination_spec IN combination_events.id_combination_spec%TYPE,
        i_type             IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * insert dependency
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_task_type              task_type identifier
    * @param      i_task_request           task request identifier
    * @param      i_task_state             task state
    * @param      o_task_dependency        task dependency identifier
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/29
    **********************************************************************************************/
    FUNCTION insert_dependency_nc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task_type       IN tde_task_dependency.id_task_type%TYPE,
        i_task_request    IN tde_task_dependency.id_task_request%TYPE,
        i_task_state      IN tde_task_dependency.flg_task_state%TYPE,
        i_task_schedule   IN tde_task_dependency.flg_schedule%TYPE,
        o_task_dependency OUT tde_task_dependency.id_task_dependency%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert dependency  relationshi
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_relationship_type
    * @param      i_task_dependency_from
    * @param      i_task_dependency_to
    * @param      i_lag_min
    * @param      i_lag_max
    * @param      i_lag_unit_meas
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/29
    **********************************************************************************************/
    FUNCTION insert_dependency_rel_nc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_relationship_type    IN tde_relationship_type.id_relationship_type%TYPE,
        i_task_dependency_from IN tde_task_dependency.id_task_dependency%TYPE,
        i_task_dependency_to   IN tde_task_dependency.id_task_dependency%TYPE,
        i_lag_min              IN tde_task_rel_dependency.lag_min%TYPE,
        i_lag_max              IN tde_task_rel_dependency.lag_max%TYPE,
        i_lag_unit_meas        IN tde_task_rel_dependency.id_unit_measure_lag%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get task type by future_event_type
    *
    * @param      i_future_event_type       episode type
    *
    * @return  event type  description
    * @author  paulo teixeira
    * @version 1.0
    * @since  2010/06/29
    **********************************************************************************************/
    FUNCTION get_task_type_by_fet(i_future_event_type IN future_event_type.id_future_event_type%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * get fe using task type
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_task_type      task type identifier
    *
    * @return  future event type
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/29
    **********************************************************************************************/
    FUNCTION get_fet_by_task_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_type.id_task_type%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * DESTROY DEPENDENCIES
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_combination_spec       combination specification identifier
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/28
    **********************************************************************************************/
    FUNCTION destroy_dependencies_nc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_combination_spec IN combination_spec.id_combination_spec%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get dependencies list
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_type_list              list of types of events
    * @param      i_events_list            list of id's of events
    * @param      i_grid                   grid of existing dependencies
    * @param      i_position               position of select event to test
    * @param      o_dependencies           return cursor
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/01
    **********************************************************************************************/
    FUNCTION get_dependencies
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_type_list    IN table_number,
        i_event_list   IN table_number,
        i_grid         IN table_table_number,
        i_position     IN NUMBER,
        o_dependencies OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get dependencies list
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_dt_suggest_begin       suggest date begin
    * @param      i_dt_suggest_end         suggest date end
    * @param      i_type_list              future event type list identifiers
    * @param      i_event_list             event list identifiers
    * @param      i_grid                   grid of existing dependencies
    * @param      i_lag_min                grid of minimum values
    * @param      i_lag_max                grid of max values
    * @param      i_lag_unit_meas      grid of unit measures
    * @param      o_flg_conflict           conflict flag to indicate incompatible dependencies network
    * @param      o_msg_title              pop up message title for warnings
    * @param      o_msg_body               pop up message body for warnings
    * @param      o_msg_text               pop up message text for warnings
    * @param      o_template               template pop up
    * @param      o_code                   error code
    * @param      o_dt_suggest_end         suggested end date
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/01
    **********************************************************************************************/
    FUNCTION check_dependencies
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_type_list        IN table_number,
        i_event_list       IN table_number,
        i_grid             IN table_table_number,
        i_lag_min          IN table_table_number,
        i_lag_max          IN table_table_number,
        i_lag_unit_meas    IN table_table_number,
        i_dt_suggest_begin IN VARCHAR2,
        i_dt_suggest_end   IN VARCHAR2,
        i_flg_single_visit IN combination_spec.flg_single_visit%TYPE,
        o_flg_conflict     OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_body         OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_template         OUT VARCHAR2,
        o_code             OUT VARCHAR2,
        o_dt_suggest_end   OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get dependencies str
    *
    * @param      i_lang                    Língua registada como preferência do profissional
    * @param      i_prof                    profissional identifier
    * @param      i_combination_events      combinattion events identifier
    *
    * @return  dependencies string
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/01
    **********************************************************************************************/
    FUNCTION get_dependencies_str
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_combination_events IN combination_events.id_combination_events%TYPE
    ) RETURN VARCHAR;

    /********************************************************************************************
    * get dependencies list
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_type_list              future event type list identifiers
    * @param      i_event_list             event list identifiers
    * @param      i_grid                   grid of existing dependencies
    * @param      i_lag_min                grid of minimum values
    * @param      i_lag_max                grid of max values
    * @param      i_lag_unit_meas      grid of max unit measures
    * @param      o_dependencies           return cursor
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/02
    **********************************************************************************************/
    FUNCTION get_dependencies_str_field
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_list     IN table_number,
        i_event_list    IN table_number,
        i_grid          IN table_table_number,
        i_lag_min       IN table_table_number,
        i_lag_max       IN table_table_number,
        i_lag_unit_meas IN table_table_number,
        o_dependencies  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_unit_measure_desc
    *
    * @param      i_lang                    Língua registada como preferência do profissional
    * @param      i_unit_measure            unit measure
    *
    * @return  dependencies string
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/01
    **********************************************************************************************/

    FUNCTION get_unit_measure_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_unit_measure unit_measure.id_unit_measure%TYPE
    ) RETURN VARCHAR;

    /*****************************************************************************
    * Checks if a professional has records in the FUTURE_EVENT_SPEC_APPROVAL table
    *
    * @param i_prof         The professional record.
    *
    * @return  'Y' is available, 'N' otherwise
    *
    * @author   Paulo teixeira
    * @version  1.0
    * @since    2010/07/02
    *****************************************************************************/
    FUNCTION is_sa_available(i_prof profissional) RETURN VARCHAR2;

    /********************************************************************************************
    * get dependencies str
    *
    * @param      i_combination_events      combinattion events identifier
    *
    * @return  dependencies string
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/01
    **********************************************************************************************/
    FUNCTION get_dependencies_info
    (
        i_lang               IN language.id_language%TYPE,
        i_combination_events IN combination_events.id_combination_events%TYPE,
        i_position           IN NUMBER
    ) RETURN table_varchar;
    /********************************************************************************************
    * get dependencies detail
    *
    * @param      i_lang       language identifier
    * @param      i_lag_min
    * @param      i_lag_max
    * @param      i_lag_unit_meas
    *
    * @return  dependencies detail description
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/05
    **********************************************************************************************/
    FUNCTION get_dependencies_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_lag_min       IN tde_task_rel_dependency.lag_min%TYPE,
        i_lag_max       IN tde_task_rel_dependency.lag_max%TYPE,
        i_lag_unit_meas IN tde_task_rel_dependency.id_unit_measure_lag%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * This function returns  the ocorrences of a given consult req to use in the New Scheduler
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_consult_req      consult req identifier
    * @param      o_recurrence           occorence information
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/27
    **********************************************************************************************/
    FUNCTION get_cr_recurrence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_consult_req IN table_number,
        o_recurrence  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if an specific future event type is available
    *
    * @param i_TASK_TYPE TASK TYPE IDENTIFIER
    * @param i_prof         The professional record.
    *
    * @return  'Y' is available, 'N' otherwise
    *
    * @author   Paulo Teixeira
    * @version  1.0
    * @since    2010/07/06
    */
    FUNCTION is_fe_available_by_tk
    (
        i_task_type future_event_type.id_task_type%TYPE,
        i_prof      profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get future_event_type and epis_type using task type
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_id_task_type       id_task_type
    * @param      o_future_event_type  cfuture_event_type
    * @param      o_epis_type          epis_type
    * @param      o_flg_type           flg_type
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/29
    **********************************************************************************************/
    FUNCTION get_fet_ep_by_task_type
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_task_type      IN task_type.id_task_type%TYPE,
        o_future_event_type OUT future_event_type.id_future_event_type%TYPE,
        o_epis_type         OUT future_event_type.id_epis_type%TYPE,
        o_flg_type          OUT future_event_type.flg_type%TYPE,
        o_title             OUT pk_translation.t_desc_translation,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check_total_lag
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_dt_suggest_begin       suggest date begin
    * @param      i_dt_suggest_end         suggest date end
    * @param      i_grid                   grid of existing dependencies
    * @param      i_lag_min                grid of minimum values
    * @param      i_lag_max                grid of max values
    * @param      i_lag_unit_meas      grid of unit measures
    * @param      o_flg_conflict           conflict flag to indicate incompatible dependencies network
    * @param      o_msg_title              pop up message title for warnings
    * @param      o_msg_body               pop up message body for warnings
    * @param      o_msg_text               pop up message text for warnings
    * @param      o_template               template pop up
    * @param      o_code                   error code
    * @param      o_dt_suggest_end         suggested end date
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/01
    **********************************************************************************************/

    FUNCTION check_total_lag
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dt_suggest_begin IN VARCHAR2,
        i_dt_suggest_end   IN VARCHAR2,
        i_flg_single_visit IN combination_spec.flg_single_visit%TYPE,
        i_grid             IN table_table_number,
        i_lag_min          IN table_table_number,
        i_lag_max          IN table_table_number,
        i_lag_unit_meas    IN table_table_number,
        o_flg_conflict     OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_body         OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_template         OUT VARCHAR2,
        o_code             OUT VARCHAR2,
        o_dt_suggest_end   OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the list of type of visit related to the destination epis_type and institution
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_epis_type          dstination epis_type identifier
    * @param      i_institution        destination institution
    * @param      o_type_of_visit      list of type of visits
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/07/11
    **********************************************************************************************/
    FUNCTION get_type_of_visit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_type     IN epis_type.id_epis_type%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        o_type_of_visit OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_type_of_visit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institution  IN institution.id_institution%TYPE,
        i_id_task_type IN task_type.id_task_type%TYPE
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * Get type of visit description for a task type
    *
    * @param    i_lang                preferred language ID
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_opinion_prof        opinion professional ID
    * @param    i_task_type           task type ID
    *
    * @return   varchar2              type of visit description
    *
    * @author                         Tiago Silva
    * @since                          2010/08/06
    ********************************************************************************************/
    FUNCTION get_type_of_visit_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_task_type     IN task_type.id_task_type%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /********************************************************************************************
    * Returns destination professionals to schedule
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_epis_type          dstination epis_type identifier
    * @param      i_institution        destination institution
    * @param      i_dep_clin_serv      destination dep_clin_serv identifier
    * @param      i_sch_event          sch_event identifier
    * @param      o_professionals      list of type of visits
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/07/11
    **********************************************************************************************/
    FUNCTION get_dest_professionals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_type     IN epis_type.id_epis_type%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sch_event     IN sch_event.id_sch_event%TYPE,
        o_professionals OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dest_professionals
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_institution   IN institution.id_institution%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_sch_event     IN sch_event.id_sch_event%TYPE,
        i_id_task_type  IN task_type.id_task_type%TYPE DEFAULT 30
    ) RETURN t_tbl_core_domain;

    /**********************************************************************************************
    * returns the status of an episode
    *
    * @param   i_lang                  language id
    * @param   i_prof                  professional's details
    * @param   i_patient               patient ID
    * @param   i_episode               episode ID
    * @param   o_status_string         episode status string
    * @param   o_flag_canceled         indicates if it is canceled
    * @param   o_flag_finished         indicates if it is finished
    * @param   o_error                 error structure
    *
    * @return  BOOLEAN                 false in case of error and true otherwise
    *
    * @author  Tiago Silva
    * @since   2010/08/03
    **********************************************************************************************/
    FUNCTION get_epis_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN consult_req.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        o_status_string OUT VARCHAR2,
        o_flag_canceled OUT VARCHAR2,
        o_flag_finished OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns future appointments with an episode ID
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_patient             patient identifier
    * @param i_episode          episode type identifier
    
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Sérgio Santos
    * @version 1.0
    * @since  2010/06/01
    **********************************************************************************************/
    FUNCTION get_epis_short_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN consult_req.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        o_future_events OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get shortpath
    *
    * @param      i_graph                   graph to test
    * @param      i_source                  source node
    *
    * @return  shortest path value
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/13
    **********************************************************************************************/
    FUNCTION get_shortpath
    (
        i_graph  IN table_table_number,
        i_source IN NUMBER
    ) RETURN NUMBER;

    /**
    * Returns a list of rooms.
    *
    * @param      i_lang             professional default language
    * @param      i_prof             professional object which refers the identity of the function caller
    * @param      i_id_dep           Department(s)
    * @param      i_flg_search       Whether or not should the 'All' value be shown
    * @param      o_rooms            Rooms
    * @param      o_error            error coming right at you!!!! data to return
    *
    * @return     boolean type   , "False" on error or "True" if success
    * @author     Nuno Guerreiro (Ricardo Pinho)
    * @version    alpha
    * @since      2007/04/26
    */
    FUNCTION get_rooms
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_dep     IN department.id_department%TYPE,
        i_flg_search IN VARCHAR2,
        o_rooms      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rooms
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_search       IN VARCHAR2
    ) RETURN t_tbl_core_domain;

    FUNCTION get_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_type      IN sch_dep_type.dep_type%TYPE,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        o_events        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_id_task_type  IN task_type.id_task_type%TYPE DEFAULT 30
    ) RETURN t_tbl_core_domain;
    ----------------

    /********************************************************************************************
    * get the description of future event
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_episode             episode type identifier
    * @param o_get_description     cursor
    * @param o_error               error message
    *
    * @author  Filipe Silva
    * @version 2.6.0.3
    * @since  2010/07/27
    **********************************************************************************************/

    FUNCTION get_fe_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN table_number,
        o_get_description OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_family_doctor
    *
    * @param      i_PATIENT
    *
    * @return  ID_FAMILY DOCTOR
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/07/28
    **********************************************************************************************/
    FUNCTION get_family_doctor(i_id_patient IN patient.id_patient%TYPE) RETURN NUMBER;

    /********************************************************************************************
    * get episode list
    *
    * @param i_lang                language identifier
    * @param i_prof                professional registered by identifier
    * @param i_patient             patient identifier
    * @param i_task_type
    * @param i_dep_clin_serv
    * @param i_inst_requested
    * @param o_list                return cursor
    *
    * @param o_error               mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/08/16
    **********************************************************************************************/
    FUNCTION get_episode_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN consult_req.id_patient%TYPE,
        i_task_type      IN future_event_type.id_task_type%TYPE,
        i_dep_clin_serv  IN consult_req.id_dep_clin_serv%TYPE,
        i_inst_requested IN consult_req.id_inst_requested%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * insert order_se combination
    *
    * @param      i_lang                   Língua registada como preferência do profissional
    * @param      i_prof                   profissional identifier
    * @param      i_patient                patient identifier
    * @param      i_comb_name              combination name
    * @param      i_dt_suggest_begin       suggest date begin
    * @param      i_dt_suggest_end         suggest date end
    * @param      i_single_visit           single visit
    * @param      i_flg_freq_origin_module flag origin module
    * @param      i_future_event_type_list future event type list identifiers
    * @param      i_event_list             event list identifiers
    * @param      i_dependencies_from           list of existing dependencies from
    * @param      i_dependencies_to           list of existing dependencies to
    * @param      i_lag_min                grid of minimum values
    * @param      i_lag_max                grid of max values
    * @param      i_lag_unit_meas      grid of max unit measures
    *
    * @param      o_error                  mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/08/17
    **********************************************************************************************/
    FUNCTION insert_order_set_combination
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN combination_spec.id_patient%TYPE,
        i_comb_name              IN combination_spec.comb_name%TYPE,
        i_dt_suggest_begin       IN VARCHAR2,
        i_dt_suggest_end         IN VARCHAR2,
        i_single_visit           IN combination_spec.flg_single_visit%TYPE,
        i_flg_freq_origin_module IN combination_spec.flg_freq_origin_module%TYPE,
        i_task_type_list         IN table_number,
        i_event_list             IN table_number,
        i_dependencies_from      IN table_number,
        i_dependencies_to        IN table_number,
        i_lag_min                IN table_number,
        i_lag_max                IN table_number,
        i_lag_unit_meas          IN table_number,
        i_episode                IN combination_spec.id_episode%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the professionals names
    *
    * @param   i_lang             language
    * @param   i_prof             professional, institution and software ids
    * @param   i_schedule         schedule id
    *
    * @author  Paulo Teixeira
    * @version 2.6
    * @since   2010/08/20
    **********************************************************************************************/
    FUNCTION get_multi_name_signature
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        i_sep      IN VARCHAR2 DEFAULT ';'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get execute values
    *
    * @param      i_lang             Língua registada como preferência do profissional  
    * @param      i_prof             profissional identifier   
    * @param      i_id_dep_clin_serv clinical service identifier
    * @param      i_patient          patient identifier 
    * @param      i_episode          episode identifier
    *     
    * @param     o_sql  return values
    *
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/05/21
    **********************************************************************************************/

    FUNCTION get_reason_of_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_sch_event        IN sch_event.id_sch_event%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_professional     IN professional.id_professional%TYPE,
        i_epis_type        IN epis_type.id_epis_type%TYPE,
        o_sql              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reason_of_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_sch_event        IN sch_event.id_sch_event%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_professional     IN professional.id_professional%TYPE,
        i_id_task_type     IN task_type.id_task_type%TYPE DEFAULT 30
    ) RETURN t_tbl_core_domain;

    FUNCTION get_locations
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_locations
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * get professional that created the appointment request
    *
    * @param      i_consult_req       id_consult_req
    *
    * @return  event type  description 
    * @author  Paulo Teixeira
    * @version 2.6.0.5.1.3
    * @since  2011/01/12
    **********************************************************************************************/
    FUNCTION get_id_prof_create_consult_req(i_consult_req IN consult_req.id_consult_req%TYPE) RETURN NUMBER;
    /********************************************************************************************
    * get event type by episisode type
    *
    * @param      i_epis_type       episode type   
    *
    * @return  event type  description 
    * @author  Paulo teixeira
    * @version 1.0
    * @since  2011/09/27
    **********************************************************************************************/
    FUNCTION get_flg_type_by_epis_type(i_epis_type IN future_event_type.id_epis_type%TYPE) RETURN VARCHAR2;

    /**
    * search function to the scheduler
    *
    * @param    i_lang           Language
    * @param    i_prof           Professional
    * @param    i_id_inst_requested   requested institution identifier, not null
    * @param    i_id_patient         patient identifier
    * @param    i_id_department       department identifier
    * @param    i_id_clinical_service clinical service identifier
    * @param    i_id_appointment     appointment identifier
    * @param    i_dep_type           dep_type
    * @param    i_id_prof_requested  requested professional identifier
    * @param    i_dt_begin_event     begin event date
    * @param    i_dt_end_event       end event date
    * @param    i_flg_priority       flag priority
    * @param    i_age_min            miminum age
    * @param    i_age_max            max age
    * @param    i_gender             gender
    * @param    i_start_pag          start page
    * @param    i_offset_pag         number of records per page
    *   
    * @param    o_list           Cursor with output info    
    * @param    o_error           Error message if something goes wrong
    *
    * @author  Paulo Teixeira
    * @version 2.6.1.6
    * @since   2011/12/02    
    */
    FUNCTION search_events
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_inst_requested   IN table_number,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_department       IN department.id_department%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_id_appointment      IN appointment.id_appointment%TYPE,
        i_dep_type            IN sch_event.dep_type%TYPE,
        i_id_prof_requested   IN consult_req.id_prof_requested%TYPE,
        i_dt_begin_event      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end_event        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_priority        IN consult_req.flg_priority%TYPE,
        i_age_min             IN NUMBER,
        i_age_max             IN NUMBER,
        i_gender              IN patient.gender%TYPE,
        i_start_pag           IN NUMBER,
        i_offset_pag          IN NUMBER,
        o_list                OUT cr_events_cur,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Result lab patient's events
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier       
    * @param      i_type               type of select    
    * @param      i_origin             origin (Future events (FE), Patient events (PE))
    *
    * @return  true or false on success or error
    * @author  Teresa Coutinho
    * @version 1.0
    * @since  2014/09/25
    **********************************************************************************************/

    FUNCTION get_lab_events_pl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN consult_req.id_patient%TYPE,
        i_origin  IN VARCHAR2
    ) RETURN t_coll_future_event
        PIPELINED;

    FUNCTION get_events_task_is_draft
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_fut_evt_type IN future_event_type.flg_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_event_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    /********************************************************************************************
    * get id_consult_req
    *
    * @param   i_episode       
    *
    * @return  id_consult_req
    * @author  Teresa Coutinho
    * @version 1.0
    * @since  2014/09/30
    **********************************************************************************************/

    FUNCTION get_id_consult_req(i_episode IN consult_req.id_episode_to_exec%TYPE) RETURN NUMBER;

    FUNCTION get_id_fet_parent(id_fet IN future_event_type.id_future_event_type%TYPE)
        RETURN future_event_type.id_parent%TYPE;

    g_exception EXCEPTION;
    g_error        VARCHAR2(4000 CHAR);
    g_found        BOOLEAN;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_package_name VARCHAR2(32);

    g_grid_date_format CONSTANT VARCHAR2(20) := 'DATE_FORMAT_M006';

    --FUTURE EVENTS SCHEDULE STATUS
    g_status_requested   CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_status_pending     CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_status_finish      CONSTANT VARCHAR2(2 CHAR) := 'EA';
    g_status_in_progress CONSTANT VARCHAR2(2 CHAR) := 'EP';

    --FUTURE EVENTS TYPES

    g_event_type_sched   CONSTANT NUMBER := 1;
    g_event_type_mfr     CONSTANT NUMBER := 6;
    g_event_type_harvest CONSTANT NUMBER := 14;

    g_event_type_iexam     CONSTANT NUMBER := 4;
    g_event_type_oexam     CONSTANT NUMBER := 5;
    g_event_type_adm_cir   CONSTANT NUMBER := 2;
    g_event_type_ehr_event CONSTANT NUMBER := 19;
    g_event_type_referral  CONSTANT future_event_type.id_future_event_type%TYPE := 24;
    g_event_type_lab       CONSTANT NUMBER := 26;

    --ICONS
    g_icon_current CONSTANT VARCHAR2(30) := 'WorkflowIcon';
    g_icon_past    CONSTANT VARCHAR2(30) := 'CheckIcon';

    g_pk_owner             CONSTANT VARCHAR2(6) := 'ALERT';
    g_inst_grp_flg_rel_adt CONSTANT institution_group.flg_relation%TYPE := 'ADT';
    g_software_care        CONSTANT software.id_software%TYPE := 3;
    g_oris_soft            CONSTANT NUMBER(2) := 2;
    g_flg_normal           CONSTANT VARCHAR2(1) := 'N';
    g_flg_cancel           CONSTANT VARCHAR2(1) := 'C';
    g_tl_report            CONSTANT VARCHAR2(10) := 'TL_REPORT';
    g_cancel               CONSTANT VARCHAR2(1) := 'C';
    g_catg_surg_resp       CONSTANT category_sub.id_category%TYPE := 1;
    g_cont_type_present    CONSTANT consult_req.flg_contact_type%TYPE := 'D';
    g_cont_type_absent     CONSTANT consult_req.flg_contact_type%TYPE := 'I';
    g_soft_outp            CONSTANT software.id_software%TYPE := 1;
    g_soft_pp              CONSTANT software.id_software%TYPE := 12;
    g_soft_care            CONSTANT software.id_software%TYPE := 3;
    g_default_contact_type CONSTANT sys_config.id_sys_config%TYPE := 'FLG_CONTACT_TYPE';
    g_flg_priority         CONSTANT VARCHAR2(30) := 'CONSULT_REQ.FLG_PRIORITY';
    g_sched_flg_req_type   CONSTANT VARCHAR2(36) := 'SCHEDULE.FLG_REQUEST_TYPE';
    g_sched_flg_sch_via    CONSTANT VARCHAR2(32) := 'SCHEDULE.FLG_SCHEDULE_VIA';
    g_default_priority     CONSTANT VARCHAR2(30) := 'FLG_PRIORITY';
    g_msg_not_repeat       CONSTANT VARCHAR2(30) := 'SCH_T624';
    g_msg_daily            CONSTANT VARCHAR2(30) := 'SCH_T625';
    g_msg_weekly           CONSTANT VARCHAR2(30) := 'SCH_T626';
    g_msg_monthly          CONSTANT VARCHAR2(30) := 'SCH_T627';
    g_msg_yearly           CONSTANT VARCHAR2(30) := 'SCH_T628';
    g_flg_not_repeat       CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_flg_daily            CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_flg_weekly           CONSTANT VARCHAR2(1 CHAR) := 'W';
    g_flg_monthly          CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_flg_yearly           CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_semicolon            CONSTANT sys_message.desc_message%TYPE := '; ';
    g_msg_day_st_week      CONSTANT VARCHAR2(30) := 'SCH_T632';
    g_msg_day_nd_week      CONSTANT VARCHAR2(30) := 'SCH_T633';
    g_msg_day_tr_week      CONSTANT VARCHAR2(30) := 'SCH_T634';
    g_msg_day_ft_week      CONSTANT VARCHAR2(30) := 'SCH_T635';
    g_msg_ls_week          CONSTANT VARCHAR2(30) := 'SCH_T636';
    g_sch_event_therap_decision sch_event.id_sch_event%TYPE := 20;
    g_flg_type_a                 CONSTANT category.flg_type%TYPE := 'A';
    g_epis_type_nurse            CONSTANT VARCHAR2(1) := 'N';
    g_epis_type_nutri            CONSTANT VARCHAR2(1) := 'U';
    g_epis_type_consult          CONSTANT VARCHAR2(1) := 'C';
    g_visit_sched_stat_cancelled CONSTANT VARCHAR2(1) := 'C';
    g_visit_sched_stat_requested CONSTANT VARCHAR2(1) := 'R';
    g_visit_sched_stat_scheduled CONSTANT VARCHAR2(1) := 'S';
    g_flg_status_domain          CONSTANT VARCHAR2(32) := 'SCHEDULE_PP.FLG_STATUS';
    g_flg_type_n                 CONSTANT category.flg_type%TYPE := 'N';
    g_cons_req_prof_read   consult_req_prof.flg_status%TYPE := 'R';
    g_cons_req_prof_accept consult_req_prof.flg_status%TYPE := 'A';
    g_cons_req_prof_deny   consult_req_prof.flg_status%TYPE := 'D';
    g_flg_ehr_normal        CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_n;
    g_flg_ehr_ehr           CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_e;
    g_flg_ehr_scheduled     CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_s;
    g_flg_ehr_order_set     CONSTANT VARCHAR2(1) := 'O';
    g_epis_active           CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_cancelled        CONSTANT episode.flg_status%TYPE := 'C';
    g_epis_inactive         CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_pending          CONSTANT episode.flg_status%TYPE := 'P';
    g_space                 CONSTANT VARCHAR2(1 CHAR) := ' ';
    g_flg_comb_state_active CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_flg_comb_state_cancel CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_flg_task_state        CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_relationship_type     CONSTANT NUMBER(2) := 2;
    g_task_episode          CONSTANT task_type.id_task_type%TYPE := 30;

    g_id_minute unit_measure.id_unit_measure%TYPE := 10374;
    g_id_hour   unit_measure.id_unit_measure%TYPE := 1041;
    g_id_day    unit_measure.id_unit_measure%TYPE := 1039;
    g_id_week   unit_measure.id_unit_measure%TYPE := 10375;
    g_id_month  unit_measure.id_unit_measure%TYPE := 1127;
    g_id_year   unit_measure.id_unit_measure%TYPE := 10373;
    g_complaint_sample_text_type CONSTANT VARCHAR2(6) := 'QUEIXA';
    g_all                        CONSTANT NUMBER(2) := -10;
    g_flg_type_ct                CONSTANT doc_template_context.flg_type%TYPE := 'CT';
    g_selected                   CONSTANT VARCHAR2(1) := 'S';
    g_active                     CONSTANT VARCHAR2(1) := 'A';
    g_report_p                   CONSTANT VARCHAR2(1) := 'P';
    g_report_v                   CONSTANT VARCHAR2(1) := 'V';
    g_report_e                   CONSTANT VARCHAR2(1) := 'E';
    g_complaint                  CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_sch_complaint_origin       CONSTANT VARCHAR2(32) := 'SCH_COMPLAINT_ORIGIN';
    g_resourcetype               CONSTANT VARCHAR2(1 CHAR) := 'H';
    g_flgtype                    CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_free_text                  CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_origin_fe                  CONSTANT VARCHAR2(2 CHAR) := 'FE';
    g_origin_pe                  CONSTANT VARCHAR2(2 CHAR) := 'PE';

END pk_events;
/
