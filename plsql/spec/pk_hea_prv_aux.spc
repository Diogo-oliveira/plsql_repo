/*-- Last Change Revision: $Rev: 1872174 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2018-10-12 11:57:15 +0100 (sex, 12 out 2018) $*/

CREATE OR REPLACE PACKAGE pk_hea_prv_aux IS

    /**
    * Returns the professional photo.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    *
    * @return                       The professional photo
    *
    * @author   Eduardo Lourenco 
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_photo
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the number of habits.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The number of habits
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_habits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /**
    * Returns the number of relevant notes.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The number of relevant notes
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_relev_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /**
    * Returns the number of previous episodes.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The number of previous episodes
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_prev_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    /**
    * Returns the blood type.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The blood type
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_blood_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns complaints and additional information.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_call_type            Function call type: A-application, R-reports
    *
    * @param o_title_diag           Diagnosis title (used in the report header)            
    * @param o_compl_diag           Complaint diagnoses
    * @param o_title_pain           Complaint title (used in the report header)
    * @param o_compl_pain           Complaint
    * @param o_info_adic            Additional information
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE set_comp_diag
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_call_type  IN VARCHAR2,
        o_title_diag OUT VARCHAR2,
        o_compl_diag OUT VARCHAR2,
        o_title_pain OUT VARCHAR2,
        o_compl_pain OUT VARCHAR2,
        o_info_adic  OUT VARCHAR2
    );

    /**
    * Returns the patient process.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_pat_identifier    Patient Identifier
    *
    * @return                       The patient process
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_process
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_pat_identifier IN pat_identifier.id_pat_identifier%TYPE,
        i_id_episode in episode.id_episode%type default null 
    ) RETURN VARCHAR;

    /**
    * Returns the room time.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_epis_row             Episode table row
    *
    * @return                       The room time
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_row IN episode%ROWTYPE
    ) RETURN VARCHAR;

    /**
    * Returns disposition, transfer or reopen if applied.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @return                       Disposition, transfer or reopen if applied
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_disp_transf_reopen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the patient health plan.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          schedule Id
    *
    * @return                       The patient health plan
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_health_plan
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the 'Servico Nacional de Saude' number.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           episode Id
    * @param i_id_schedule          schedule Id
    *
    * @return                       The 'Servico Nacional de Saude' number
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_sns
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the RECM and 'No allergies to drugs'.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    *
    * @return                       The RECM and 'No allergies to drugs'
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_recm_no_allergies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the category of a professional.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The category of a professional
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_category
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_instituttion IN institution.id_institution%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the name of the room.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The name of the room
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the service name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_dep_clin_serv     Dep_clin_serv Id
    *
    * @return                       The service name
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_service
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the clinical service name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_dep_clin_serv     Dep_clin_serv Id
    *
    * @return                       The clinical service name
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_clin_service
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the service in which the room is.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_room              Room Id
    *
    * @return                       The service in which the room is
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the service in which the bed is.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_bed               Bed Id
    *
    * @return                       The service in which the bed is
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_bed_service
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the room in which the bed is.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_bed               Bed Id
    *
    * @return                       The room in which the bed is
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_name
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the bed name.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_bed               Bed Id
    *
    * @return                       The bed name
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_bed_name
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_bed IN bed.id_bed%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the disposition date and label.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_row_ei               EPIS_INFO row_type
    * 
    * @param o_disp_date            Disposition date
    * @param o_disp_label           Disposition label
    *
    * @return                       The disposition date and label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE get_disposition_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_row_ei     IN epis_info%ROWTYPE,
        o_disp_date  OUT VARCHAR2,
        o_disp_label OUT VARCHAR2
    );

    /**
    * Returns the appointment type.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_row_ei               EPIS_INFO row_type
    * @param i_id_schedule          Schedule Id
    *
    * @return                       The appointment type
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_appointment_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_row_ei      IN epis_info%ROWTYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the date in the correct format.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_dt                   Date
    *
    * @return                       The date in the correct format
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_format_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_dt   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR;

    /**
    * Returns the waiting time.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_dt_target            Target date
    * @param i_dt_register          Register date
    * @param i_dt_first             First observation date
    *
    * @return                       The waiting time
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_waiting
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt_target   IN schedule_outp.dt_target_tstz%TYPE,
        i_dt_register IN episode.dt_begin_tstz%TYPE,
        i_dt_first    IN epis_info.dt_first_obs_tstz%TYPE
    ) RETURN VARCHAR;

    /**
    * Returns the surgery responsible professional and specialty.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    *
    * @param o_prof                 The surgery responsible professional
    * @param o_prof                 The surgery responsible professional specialty
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE get_surg_resp_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        o_prof           OUT VARCHAR2,
        o_prof_spec_inst OUT VARCHAR2
    );

    -- Function taken from PK_TRIAGE_AUDIT
    /**
    * Returns the episode complaint.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_episode              Episode Id
    *
    * @param o_title_epis_compl     Title of episode complaint
    * @param o_epis_compl           Episode complaint
    * @param o_error                Error message
    *
    * @return                       True if succeeded. False otherwise. 
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_epis_compl
    (
        i_lang             language.id_language%TYPE,
        i_prof             profissional,
        i_episode          episode.id_episode%TYPE,
        o_title_epis_compl OUT VARCHAR2,
        o_epis_compl       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the professional photo timestamp.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_professional      Professional Id
    *
    * @return                       The professional photo timestamp
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/05/06
    */
    FUNCTION get_photo_timestamp
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR;

    -- Log initialization.
    /* Stores log error messages. */
    g_error VARCHAR2(4000);

    /* Stores the package name. */
    g_package_name VARCHAR2(32);

    g_found BOOLEAN;
    g_exception EXCEPTION;

    g_id_patient patient.id_patient%TYPE;

    g_habits           NUMBER;
    g_allergies        NUMBER;
    g_prev_med_hist    NUMBER;
    g_prev_epis        NUMBER;
    g_blood_type       VARCHAR2(100);
    g_relev_notes      NUMBER;
    g_adv_dir_has      VARCHAR2(1);
    g_adv_dir_shortcut NUMBER;

    /*************************************************************************\
    *  Global package constants                                               *
    \*************************************************************************/

    g_pat_allergy_flg_cancelled CONSTANT pat_allergy.flg_status%TYPE := 'C';
    g_pat_allergy_flg_resolved  CONSTANT pat_allergy.flg_status%TYPE := 'R';

    g_past_history_flg_resolved CONSTANT pat_allergy.flg_status%TYPE := 'R';

    g_call_header_app    CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_call_header_rep    CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_flg_type_complaint CONSTANT epis_anamnesis.flg_type%TYPE := 'C';

END;
/
