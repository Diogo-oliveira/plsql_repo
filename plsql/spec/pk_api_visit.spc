/*-- Last Change Revision: $Rev: 2014490 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-05-17 15:45:03 +0100 (ter, 17 mai 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_visit IS

    TYPE rec_epis_ext_sys IS RECORD(
        id_episode      epis_ext_sys.id_episode%TYPE,
        id_ext_episode  epis_ext_sys.value%TYPE,
        id_external_sys epis_ext_sys.id_external_sys%TYPE,
        id_institution  epis_ext_sys.id_institution%TYPE);

    TYPE t_tbl_epis_ext IS TABLE OF rec_epis_ext_sys INDEX BY VARCHAR2(50);

    TYPE rec_episode IS RECORD(
        id_episode           episode.id_episode%TYPE,
        id_epis_type         episode.id_epis_type%TYPE,
        id_institution       institution.id_institution%TYPE,
        id_software          software.id_software%TYPE,
        id_schedule          schedule.id_schedule%TYPE,
        id_professional      professional.id_professional%TYPE,
        id_external_cause    visit.id_external_cause%TYPE,
        id_prof_cancel       professional.id_professional%TYPE,
        dt_cancel            DATE,
        dt_cancel_tstz       episode.dt_cancel_tstz%TYPE,
        id_patient           patient.id_patient%TYPE,
        id_room              room.id_room%TYPE,
        id_origin            visit.id_origin%TYPE,
        flg_unknown          epis_info.flg_unknown%TYPE,
        nr_companion         epis_info.companion%TYPE,
        id_health_plan       health_plan.id_health_plan%TYPE,
        id_dep_clin_serv     dep_clin_serv.id_dep_clin_serv%TYPE,
        episode_ext          t_tbl_epis_ext,
        dt_begin_tstz        episode.dt_begin_tstz%TYPE,
        flg_ehr              episode.flg_ehr%TYPE,
        flg_appointment_type episode.flg_appointment_type%TYPE,
        dt_arrival           epis_intake_time.dt_intake_time%TYPE,
        id_prof_resp         epis_multi_prof_resp.id_professional%TYPE);

    /**
    * Prepares and creates the EHR access for a scheduled espisode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_institution      institution identification
    * @param i_id_patient          patient identification
    * @param i_id_schedule         schedule identification
    * @param i_id_epis_type        tpye of episode identification
    *
    * @param o_error               error message
    *
    * @return                      true if sucess, false otherwise
    *
    * @author  Eduardo Lourenco
    * @version 2.4.3
    * @since   2008/09/10
    */
    FUNCTION intf_create_scheduled_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_epis_type   IN epis_type.id_epis_type%TYPE,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * UPDATE epis_ext_sys with the real value and real id_epis_type of the external episode ID
    *
    * i_lang                Language ID,
    * i_id_professional     Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_id_institution      Institution ID,
    * i_epis_type_old       Episode Type ID,
    * i_epis_ext_value_old  External Episode ID
    * i_epis_type_new       Episode Type ID,
    * i_epis_ext_value_new  External Episode ID
    *
    * @author                      Luís Maia
    * @since                       2009/02/12
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION intf_set_epis_ext_sys
    (
        i_lang               IN language.id_language%TYPE,
        i_id_professional    IN profissional,
        i_id_institution     IN institution.id_institution%TYPE,
        i_epis_type_old      IN epis_ext_sys.id_epis_type%TYPE,
        i_epis_ext_value_old IN epis_ext_sys.value%TYPE,
        i_epis_type_new      IN epis_ext_sys.id_epis_type%TYPE,
        i_epis_ext_value_new IN epis_ext_sys.value%TYPE,
        o_error              OUT t_error_out
        
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * UPDATE epis_ext_sys with the real value and real id_epis_type of the external episode ID
    *
    * i_lang                   Language ID,
    * i_prof                   Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_id_institution         Institution ID,
    * i_id_episode             Episode ID,
    * i_epis_type_old          Episode Type ID,
    * i_cod_epis_type_ext_old  Episode code type,
    * i_epis_ext_value_old     External Episode ID
    * i_epis_type_new          Episode Type ID,
    * i_epis_ext_value_new     External Episode Type
    * i_cod_epis_type_ext_new  Episode code type,
    *
    * @author                      Rui Duarte
    * @since                       2010/09/14
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION intf_set_epis_ext_sys
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_episode            IN episode.id_episode%TYPE,
        i_epis_type_old         IN epis_ext_sys.value%TYPE,
        i_cod_epis_type_ext_old IN epis_ext_sys.cod_epis_type_ext%TYPE,
        i_epis_ext_value_old    IN epis_ext_sys.value%TYPE,
        i_epis_type_new         IN epis_ext_sys.id_epis_type%TYPE,
        i_cod_epis_type_ext_new IN epis_ext_sys.cod_epis_type_ext%TYPE,
        i_epis_ext_value_new    IN epis_ext_sys.value%TYPE,
        o_error                 OUT t_error_out
        
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Criar ou actualizar a informação do episódio
    *
    * @param i_lang                language id
    * @param i_rec_epis_ext        Registo dos dados do episódio externo
    * @param i_rec_episode         Registo dos dados do episódio
    * @param i_epis_type           Tipo de episódio
    * @param i_institution         ID da instituição onde é realizada a criação/actualização do episódio
    * @param i_transaction_id     SCH 3.0 transaction id
    * @param o_episode             ID do episódio associado ao ID_EPIS_EXT_SYS
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Emília Taborda
    * @since                       2007/01/09
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode_pfh
    (
        i_lang           IN language.id_language%TYPE,
        i_rec_epis_ext   IN rec_epis_ext_sys,
        i_rec_episode    IN rec_episode,
        i_epis_type      IN epis_type.id_epis_type%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --

    /********************************************************************************************
    * Criar ou actualizar a informação do episódio
    *
    * @param i_lang                language id
    * @param i_epis_type           Tipo de episodio
    * @param i_institution         ID da instituicao onde e realizada a criacao/actualizacao do episodio
    * @param i_professional        Professional ID
    * @param i_software            Software ID
    * @param i_patient             Patient ID
    * @param i_episode             Episode ID
    * @param i_ext_episode         External Episode ID
    * @param i_external_sys        External System ID
    * @param i_health_plan         Health Plan ID
    * @param i_schedule            Schedule ID
    * @param i_flg_ehr             Electronic Health Record Flag
    * @param i_origin              Origin of the episode
    * @param i_dt_begin            Begin date
    * @param i_dep_clin_serv       Department Clinical Service
    * @param i_external_cause      ID of external cause
    * @param i_dt_arrival          Arrival date
    * @param i_prof_resp           Responsible Professional
    * @param i_transaction_id      SCH 3.0 transaction id
    * @param o_episode             ID do episódio associado ao ID_EPIS_EXT_SYS
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Bruno Martins
    * @since                       2007/02/04
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode_pfh
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_type      IN epis_type.id_epis_type%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_professional   IN professional.id_professional%TYPE,
        i_software       IN software.id_software%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_ext_episode    IN epis_ext_sys.value%TYPE,
        i_external_sys   IN external_sys.id_external_sys%TYPE,
        i_health_plan    IN health_plan.id_health_plan%TYPE,
        i_schedule       IN epis_info.id_schedule%TYPE,
        i_flg_ehr        IN episode.flg_ehr%TYPE,
        i_origin         IN origin.id_origin%TYPE,
        i_dt_begin       IN episode.dt_begin_tstz%TYPE,
        i_dep_clin_serv  IN epis_info.id_dep_clin_serv%TYPE,
        i_external_cause IN visit.id_external_cause%TYPE,
        i_dt_arrival     IN epis_intake_time.dt_intake_time%TYPE DEFAULT NULL,
        i_prof_resp      IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        i_flg_unknown    IN epis_info.flg_unknown%TYPE DEFAULT pk_alert_constant.g_no,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_episode        OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN PLS_INTEGER;

    /********************************************************************************************
    * Inserts a new record on epis_ext_sys
    *
    * @param i_lang                language id
    * @param i_external_sys        external system id
    * @param i_ext_episode         external episode id
    * @param i_epis_type           Tipo de episódio
    * @param i_institution         ID da instituição onde é realizada a criação/actualização do episódio
    * @param i_episode             ID do episódio associado ao ID_EPIS_EXT_SYS
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      José Silva
    * @since                       30-09-2009
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_epis_ext_sys
    (
        i_lang         IN language.id_language%TYPE,
        i_external_sys IN epis_ext_sys.id_external_sys%TYPE,
        i_ext_episode  IN epis_ext_sys.value%TYPE,
        i_epis_type    IN epis_type.id_epis_type%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_epis_ext_sys OUT epis_ext_sys.id_epis_ext_sys%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a patient's registration.
    * The episode is changed to a 'scheduled' state (FLG_EHR = 'S').
    *
    * This function is the migration of PK_PFH_INTERFACE.INTF_CANCEL_EPISODE
    * for the cancellation of Ambulatory episodes (OUTP, PP, CARE).
    *
    * @param i_lang            language identifier
    * @param i_id_episode      episode identifier
    * @param i_prof            professional identification
    * @param i_cancel_reason   motive of cancellation
    * @param o_error           error message
    *
    * @return                  false, if errors occur, or true, otherwise
    *
    * @author                  Pedro Carneiro
    * @version                  2.5.0.7.6.1
    * @since                   2010/02/10
    */
    FUNCTION intf_cancel_episode
    (
        i_lang          IN language.id_language%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN episode.desc_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels an episode.
    * The episode status is set to 'cancelled', and it will have further use (FLG_STATUS = 'C').
    *
    * This function is the migration of PK_PFH_INTERFACE.INTF_CANCEL_SCHED_EPISODE
    * for the cancellation of Ambulatory episodes (OUTP, PP, CARE).
    *
    * @param i_lang            language identifier
    * @param i_id_episode      episode identifier
    * @param i_prof            professional identification
    * @param i_transaction_id  Scheduller 3 transsaction id
    * @param o_error           error message
    *
    * @return                  false, if errors occur, or true, otherwise
    *
    * @author                  Pedro Carneiro
    * @version                  2.5.0.7.6.1
    * @since                   2010/02/10
    */
    FUNCTION intf_cancel_sched_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_transaction_id IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Convert a schedule episode (flg_ehr = 'S') to a normal episode (flg_ehr = 'N')
    * and updates epis_ext_sys external episode
    *
    * i_lang            Language ID,
    * i_id_pat          Patient ID,
    * i_id_institution  Institution ID,
    * i_id_sched        Schedule ID,
    * i_id_professional Professional ID - PROFESSIONAL(ID, INST, SOFT),
    * i_id_episode      Episode ID,
    * i_epis_type       Episode Type ID,
    * i_epis_ext_value  External Episode ID
    *
    * @author                      Sérgio Santos
    * @since                       2008/11/05
    * @version                     1.0
    **********************************************************************************************/
    FUNCTION set_episode_sched_to_normal
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_epis_ext_value  IN epis_ext_sys.value%TYPE,
        i_transaction_id  IN VARCHAR2,
        o_episode         OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the episode intake time
    *
    * @param i_lang                language id
    * @param i_prof                Profissional
    * @param i_id_episode          Episode ID
    * @param o_dt_intake_time      Intake Time
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Sergio Dias
    * @since                       10-07-2013
    * @version                     2.6.3.6
    **********************************************************************************************/
    FUNCTION get_dt_intake_time
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_dt_intake_time OUT epis_intake_time.dt_intake_time%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_dt_intake_time(i_id_episode IN episode.id_episode%TYPE) RETURN epis_intake_time.dt_intake_time%TYPE;

    /**********************************************************************************************
    * DATABASE INTERNAL FUNCION. Register the data about the arrival of the patient.
    *
    * @param i_lang              the id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_epis           episode id
    * @param i_dt_transportation Data do transporte
    * @param i_id_transp_entity  Transporte entidade
    * @param i_flg_time          E - início do episódio, S - alta administrativa, T - transporte s/ episódio
    * @param i_notes             Notes
    * @param i_origin            Origem
    * @param i_external_cause    external cause
    * @param i_companion         acompanhante
    * @param i_internal_type     Called from (A) Arrived by (T) Triage
    * @param i_sysdate           Current date
    * @param o_error             Error message
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   José Brito (using SET_ARRIVE by Luís Gaspar)
    * @version                  2.6.0
    * @since                    2009/12/07
    **********************************************************************************************/
    FUNCTION update_episode_pfh
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis               IN episode.id_episode%TYPE,
        i_dt_transportation_str IN VARCHAR2,
        i_id_transp_entity      IN transportation.id_transp_entity%TYPE,
        i_flg_time              IN transportation.flg_time%TYPE,
        i_notes                 IN transportation.notes%TYPE,
        i_origin                IN visit.id_origin%TYPE,
        i_external_cause        IN visit.id_external_cause%TYPE,
        i_companion             IN epis_info.companion%TYPE,
        i_internal_type         IN VARCHAR2, -- (A) Arrived by (T) Triage
        i_sysdate               IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_resp          IN epis_multi_prof_resp.id_professional%TYPE,
        i_dt_intake_time        IN epis_intake_time.dt_intake_time%TYPE,
        i_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /** Used only to prevent decompile. Do not use */
    FUNCTION set_episode_sched_to_normal
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_sched        IN epis_info.id_schedule%TYPE,
        i_id_professional IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_type       IN episode.id_epis_type%TYPE,
        i_epis_ext_value  IN epis_ext_sys.value%TYPE,
        o_episode         OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patient_active_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        o_lst_episodes OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /* Stores log error messages. */
    g_error VARCHAR2(32000);
    /* Stores the package name and owner. */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_status_act           episode.flg_status%TYPE;
    g_status_ina           episode.flg_status%TYPE;
    g_inst_grp_flg_rel_adt institution_group.flg_relation%TYPE;

    g_flg_default VARCHAR2(1);
    g_found       BOOLEAN;

END pk_api_visit;
/
