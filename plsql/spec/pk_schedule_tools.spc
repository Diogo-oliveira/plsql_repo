/*-- Last Change Revision: $Rev: 2028962 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_schedule_tools IS
    -- This package provides some utilities used throughout the Scheduler's development process.
    -- @author Nuno Guerreiro
    -- @version alpha    

    /* 
    * Generates the code (using dbms_output) for a function that creates a new record on the given table.
    *
    * @param i_table     Table name.
    * @param i_author    Author.      
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/17
    */
    PROCEDURE generate_new_function
    (
        i_table  VARCHAR2,
        i_author VARCHAR2
    );

    /* 
    * Generates the code (using dbms_output) for a function that alters a record on the given table.
    *
    * @param i_table     Table name.
    * @param i_author    Author.      
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/17
    */
    PROCEDURE generate_alter_function
    (
        i_table  VARCHAR2,
        i_author VARCHAR2
    );

    /*
    * Generates random consult vacancies.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   Event identifier.
    * @param i_id_room                    Room identifier.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    */
    PROCEDURE generate_vacancies
    (
        i_prof             profissional,
        i_slot_interval    NUMBER,
        i_max_vacancies    NUMBER,
        i_start_date       TIMESTAMP WITH TIME ZONE,
        i_end_date         TIMESTAMP WITH TIME ZONE,
        i_start_hour       NUMBER,
        i_end_hour         NUMBER,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event         sch_event.id_sch_event%TYPE,
        i_id_room          room.id_room%TYPE
    );

    /*
    * Generates random exam vacancies.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   Event identifier.
    * @param i_id_exam                    Exam identifier.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since
    */
    PROCEDURE generate_exam_vacancies
    (
        i_prof             profissional,
        i_slot_interval    NUMBER,
        i_max_vacancies    NUMBER,
        i_start_date       TIMESTAMP WITH TIME ZONE,
        i_end_date         TIMESTAMP WITH TIME ZONE,
        i_start_hour       NUMBER,
        i_end_hour         NUMBER,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event         sch_event.id_sch_event%TYPE,
        i_id_exam          exam.id_exam%TYPE
    );

    /*
    * Generates random exam vacancies.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   Event identifier.
    * @param i_weekdays                   list of weekday in csv format in which vacancies should be created. 1=monday, 7=sunday, null=all
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since
    *
    * alert-8202. exam vacancies are now exam-id-independent. Also, new parameter i_weekdays for creating vacancies only in specified week days
    * @author Telmo
    * @version 2.5.0.7
    * @date    12-10-2009
    */
    PROCEDURE generate_exam_vacancies
    (
        i_prof             profissional,
        i_slot_interval    NUMBER,
        i_max_vacancies    NUMBER,
        i_start_date       TIMESTAMP WITH TIME ZONE,
        i_end_date         TIMESTAMP WITH TIME ZONE,
        i_start_hour       NUMBER,
        i_end_hour         NUMBER,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event         sch_event.id_sch_event%TYPE DEFAULT pk_schedule.g_event_exam,
        i_weekdays         VARCHAR2 DEFAULT NULL
    );

    /*
    * Generates random exam vacancies.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   Event identifier.
    * @param i_id_analysis                Analysis identifier.
    *
    * @author Nuno Guerreiro
    * @version alpha
    * @since 2007/05/18
    */
    PROCEDURE generate_analysis_vacancies
    (
        i_prof             profissional,
        i_slot_interval    NUMBER,
        i_max_vacancies    NUMBER,
        i_start_date       TIMESTAMP WITH TIME ZONE,
        i_end_date         TIMESTAMP WITH TIME ZONE,
        i_start_hour       NUMBER,
        i_end_hour         NUMBER,
        i_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event         sch_event.id_sch_event%TYPE,
        i_id_analysis      analysis.id_analysis%TYPE
    );

    /*
    * Generates random mfr vacancies and slots.
    * For development purposes only.
    *
    * @param i_prof                       Professional.
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_max_vacancies              Maximum number of vacancies per date/hour.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_phys_area               Physiatry area identifier
    *
    * @author José Antunes
    * @version alpha
    * @since 2008/11/27
    */
    PROCEDURE generate_mfr_vacancies
    (
        i_prof          profissional,
        i_slot_interval NUMBER,
        i_start_date    TIMESTAMP WITH TIME ZONE,
        i_end_date      TIMESTAMP WITH TIME ZONE,
        i_start_hour    NUMBER,
        i_end_hour      NUMBER,
        i_id_event      sch_event.id_sch_event%TYPE,
        i_id_phys_area  physiatry_area.id_physiatry_area%TYPE
    );

    /*
    * Generates continuous oris vacancies and their inicial slots.
    *
    * @param i_prof                       Professional to whom these vacancies are for(if i_profless=N). otherwise its used in date funtions
    * @param i_slot_interval              Number of minutes for each slot.
    * @param i_start_date                 Start date.
    * @param i_end_date                   End date.
    * @param i_start_hour                 Hour of the first slot of the day.
    * @param i_end_hour                   Hour of the last slot of the day.
    * @param i_id_dep_clin_serv           Department-Clinical Service identifier.
    * @param i_id_event                   event must be 14 or other proper event created by configurations.
    * @param i_id_room                    Room identifier
    * @param i_flg_urgent                 Y = vacancies are created for emergency surgeries. N = for elective surgeries
    * @param i_weekdays                   list of weekday in csv format in which vacancies should be created. 1=monday, 7=sunday, null=all
    * @param i_id_prof_generator          prof. who's creating the vacancies. Can be null
    * @param i_profless                   Y = generated vacancies are professional-less. N= gen. vacancies are assigned to i_prof
    *
    * @author  Telmo
    * @version 2.5
    * @date    06-04-2009
    */
    PROCEDURE generate_oris_vacancies
    (
        i_prof              profissional,
        i_slot_interval     NUMBER,
        i_start_date        TIMESTAMP WITH TIME ZONE,
        i_end_date          TIMESTAMP WITH TIME ZONE,
        i_start_hour        NUMBER,
        i_end_hour          NUMBER,
        i_id_dep_clin_serv  dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_event          sch_event.id_sch_event%TYPE,
        i_id_room           sch_consult_vacancy.id_room%TYPE,
        i_flg_urgent        sch_consult_vac_oris.flg_urgency%TYPE DEFAULT 'N',
        i_weekdays          VARCHAR2 DEFAULT NULL,
        i_id_prof_generator professional.id_professional%TYPE DEFAULT NULL,
        i_profless          VARCHAR2 DEFAULT 'N'
    );

    /* gerador de registos na appointment. Para ser usado quando se criam novos eventos.
    * COM O S.A.R.A. E O C.O.E.N, ISTO FICA OBSOLETO. NAO USAR.
    *
    */
    FUNCTION generate_appointments
    (
        i_lang          NUMBER,
        i_ids_sch_event table_number, -- deve conter os ids dos eventos novos
        i_ids_cs        table_number, -- se nao vazia, vai gerar apenas para esta lista
        i_upd_lb_transl BOOLEAN DEFAULT TRUE, -- TRUE = actualiza traducoes das appointments na agenda(tabela lb_translation)
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *  insere/actualiza na alert_basecomp.lb_translation as traducoes das chaves presentes em i_codes.
    *  exemplo de chaves: 
    * 'APPOINTMENT.CODE_APPOINTMENT.APP.291.'
    * 'APPOINTMENT.CODE_APPOINTMENT.'
    *
    * isto escreve para o standard output
    */
    PROCEDURE generate_lb_translations
    (
        i_lang  NUMBER,
        i_codes table_varchar
    );

    /* gerador de registo na appointment. 
    * Se registo existe, actualiza flg_available respetiva com valor de i_flg_avail.
    * Tambem pode actualizar traducoes na agenda(tabela lb_translation), apenas se existir apointment na alert_apsschdlr_tr.procedure.
    * Usada pelo backoffice da agenda, funcao set_sch_events_dcs
    */
    FUNCTION generate_appointment
    (
        i_lang          NUMBER,
        i_id_sch_event  appointment.id_sch_event%TYPE,
        i_id_cs         appointment.id_clinical_service%TYPE,
        i_id_inst       institution.id_institution%TYPE,
        i_upd_lb_transl BOOLEAN DEFAULT TRUE, -- TRUE = actualiza traducoes na agenda
        i_flg_avail     appointment.flg_available%TYPE DEFAULT pk_alert_constant.g_yes,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /* gerador de registo na appointment_alias. 
    * Tambem actualiza traducoes na agenda(tabela lb_translation).
    * Usada por 
    */
    PROCEDURE generate_appt_alias
    (
        i_id_sch_event_alias sch_event_alias.id_sch_event_alias%TYPE,
        i_upd_lb_transl      BOOLEAN DEFAULT TRUE
    );

    /* regenerador de traducoes de appointments. 
    * DEVE-SE CORRER ISTO QUANDO SE ALTERA O NOME DE EVENTOS EM UMA OU MAIS LINGUAS.
    * idem para o nome de clinical services.
    */
    PROCEDURE regen_app_translations
    (
        i_ids_inst      table_number, -- used to pick events in case i_ids_sch_event is empty
        i_ids_sch_event table_number, -- ids dos eventos a que se alterou o nome...
        i_ids_cs        table_number, -- e/ou ids dos clinical services a que se alterou o nome
        i_upd_lb_transl BOOLEAN DEFAULT TRUE, -- TRUE = actualiza traducoes das appointments na agenda(tabela lb_translation)
        o_error         OUT t_error_out
    );

    -------------------------------
    -- PUBLIC VARIABLE DECLARATIONS
    -------------------------------
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(30);
    g_error         VARCHAR2(4000);

END pk_schedule_tools;
/
