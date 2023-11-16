/*-- Last Change Revision: $Rev: 2050037 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-11-11 08:41:01 +0000 (sex, 11 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_patient IS

    TYPE rec_necess IS RECORD(
        necess       pk_translation.t_desc_translation,
        id_necessity pat_necessity.id_necessity%TYPE,
        rank         necessity.rank%TYPE,
        flg_status   pat_necessity.flg_status%TYPE,
        flg_comb     necessity.flg_comb%TYPE);

    TYPE cursor_necess IS REF CURSOR RETURN rec_necess;

    TYPE table_necess IS TABLE OF rec_necess;

    TYPE t_rec_pat_blood_cda IS RECORD(
        id_pat_blood      pat_blood_group.id_pat_blood_group%TYPE,
        flg_status        pat_blood_group.flg_status%TYPE,
        desc_status       VARCHAR2(1000 CHAR),
        flg_blood_group   pat_blood_group.flg_blood_group%TYPE,
        desc_blood_group  VARCHAR2(1000 CHAR),
        flg_blood_rhesus  pat_blood_group.flg_blood_rhesus%TYPE,
        desc_blood_rhesus VARCHAR2(1000 CHAR),
        dt_reg_str        VARCHAR2(14 CHAR),
        dt_reg_tstz       pat_blood_group.dt_pat_blood_group_tstz%TYPE,
        dt_reg_formatted  VARCHAR2(1000 CHAR));

    TYPE t_coll_pat_blood_cda IS TABLE OF t_rec_pat_blood_cda;

    k_format_age_ynr CONSTANT VARCHAR2(0100 CHAR) := 'YEARS_NOT_ROUNDED';

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_necess);

    /*
    * Return designated provider
    *
    * @param   i_lang                  language associated to the professional executing the request
    * @param   i_prof                  Professional info
    * @param   i_patient               patient identifier  
    * @param   i_episode               episode identifier    
    *
    * @RETURN  designated provider
    * @author  paulo teixeira
    * @version 2.5.1
    * @since   2010-10-19
    *
    */
    FUNCTION get_designated_provider
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*
    * Return negative "julian" age for purpose of sorting in main grids. Formula only.
    *
    * @param   I_LANG              language associated to the professional executing the request
    * @param   i_dt_birth          date of birth of individual
    * @param   i_age               age of individual
    *
    * @RETURN  negative julian date if available, null if not available
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   15-FEB-2008
    *
    */
    FUNCTION get_julian_age
    (
        i_lang        language.id_language%TYPE,
        i_dt_birth    patient.dt_birth%TYPE,
        i_age         patient.age%TYPE,
        i_dt_deceased patient.dt_deceased%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    /*
    * Return negative "julian" age for purpose of sorting in main grids with patient id
    *
    * @param   I_LANG              language associated to the professional executing the request
    * @param   i_id_patient        id of patient
    *
    * @RETURN  negative julian date if available, null if not available
    * @author  Carlos Ferreira
    * @version 1.0
    * @since   15-FEB-2008
    *
    */
    FUNCTION get_julian_age
    (
        i_lang       language.id_language%TYPE,
        i_id_patient patient.id_patient%TYPE
    ) RETURN NUMBER;

    /**
    * Return translated initial for the gender domain. Internally this functions does caching.
    *
    * @param i_lang language id
    * @param i_gender value of the patient.gender column
    */
    FUNCTION get_gender
    (
        i_lang   language.id_language%TYPE,
        i_gender patient.gender%TYPE
    ) RETURN sys_domain.desc_val%TYPE;

    /*
    * Returns the patient's gender
    *
    * @param   i_id_patient        id of patient
    *
    * @return  String with the patients gender
    * @author  Joao Martins
    * @version 2.6.0.1
    * @since   26-Feb-2010
    */
    FUNCTION get_pat_gender(i_id_patient IN patient.id_patient%TYPE) RETURN patient.gender%TYPE;

    FUNCTION get_pat_birth_date
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        o_name          OUT patient.name%TYPE,
        o_nick_name     OUT patient.nick_name%TYPE,
        o_gender        OUT patient.gender%TYPE,
        o_dt_birth      OUT VARCHAR2,
        o_age           OUT VARCHAR2,
        o_dt_deceased   OUT VARCHAR2,
        o_dt_birth_send OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_info
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_name        IN patient.name%TYPE,
        i_nick_name   IN patient.nick_name%TYPE,
        i_gender      IN patient.gender%TYPE,
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_dt_deceased IN patient.dt_deceased%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_info
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_name        OUT patient.name%TYPE,
        o_nick_name   OUT patient.nick_name%TYPE,
        o_gender      OUT patient.gender%TYPE,
        o_dt_birth    OUT VARCHAR2,
        o_age         OUT VARCHAR2,
        o_dt_deceased OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_desc_pat_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat        IN patient.id_patient%TYPE,
        o_name          OUT patient.name%TYPE,
        o_nick_name     OUT patient.nick_name%TYPE,
        o_gender        OUT patient.gender%TYPE,
        o_desc_gender   OUT VARCHAR2,
        o_dt_birth      OUT VARCHAR2,
        o_dt_birth_send OUT VARCHAR2,
        o_age           OUT VARCHAR2,
        o_dt_deceased   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_age
    (
        i_lang       IN language.id_language%TYPE,
        i_dt_start   IN DATE,
        i_dt_end     IN DATE,
        i_age_format IN VARCHAR2 DEFAULT 'YEARS'
    ) RETURN NUMBER;

    /**
    * Returns the patient age with a given format (YEARS, MONTHS OR DAYS)
    *
    * @param   i_lang         Professional preferred language
    * @param   i_dt_birth     Date of birth
    * @param   i_dt_deceased  Date of death
    * @param   i_age          Patient age
    * @param   i_age_format   Age format (years, months or days)
    *
    * @param   o_error        Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  JOSE.SILVA
    * @version 2.6.0.4
    * @since   07-09-2010
    */
    FUNCTION get_pat_age
    (
        i_lang        IN language.id_language%TYPE,
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_dt_deceased IN patient.dt_deceased%TYPE DEFAULT NULL,
        i_age         IN patient.age%TYPE,
        i_age_format  IN VARCHAR2 DEFAULT 'YEARS',
        i_patient     IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION get_pat_age
    (
        i_lang     IN language.id_language%TYPE,
        i_dt_birth IN patient.dt_birth%TYPE,
        i_age      IN patient.age%TYPE,
        i_inst     IN institution.id_institution%TYPE,
        i_soft     IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_age
    (
        i_lang        IN language.id_language%TYPE,
        i_dt_birth    IN patient.dt_birth%TYPE,
        i_dt_deceased IN patient.dt_deceased%TYPE,
        i_age         IN patient.age%TYPE,
        i_inst        IN institution.id_institution%TYPE,
        i_soft        IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_age_long
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_age_years
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE
    ) RETURN NUMBER;

    FUNCTION get_pat_age
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_pat_age
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_age_with_format
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_units      OUT VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_pat_short_name(i_id_pat IN patient.id_patient%TYPE) RETURN VARCHAR2;

    FUNCTION set_pat_problem
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_pat           IN patient.id_patient%TYPE,
        i_pat_problem   IN pat_problem.id_pat_problem%TYPE,
        i_prof          IN profissional,
        i_diag          IN pat_problem.id_diagnosis%TYPE,
        i_desc          IN pat_problem.desc_pat_problem%TYPE,
        i_notes         IN pat_problem.notes%TYPE,
        i_age           IN pat_problem.flg_age%TYPE,
        i_dt_symptoms   IN VARCHAR2,
        i_flg_approved  IN pat_problem.flg_aproved%TYPE,
        i_pct           IN pat_problem.pct_incapacity%TYPE,
        i_surgery       IN pat_problem.flg_surgery%TYPE,
        i_notes_support IN pat_problem.notes_support%TYPE,
        i_dt_confirm    IN VARCHAR2,
        i_rank          IN pat_problem.rank%TYPE,
        i_status        IN pat_problem.flg_status%TYPE,
        i_epis_diag     IN pat_problem.id_epis_diagnosis%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_notes_cancel  IN pat_problem.cancel_notes%TYPE DEFAULT NULL,
        i_cancel_reason IN pat_problem.id_cancel_reason%TYPE DEFAULT NULL,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_problem_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg            IN table_varchar,
        i_notes          IN table_varchar,
        i_type           IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_pat_problem_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_problem.id_patient%TYPE,
        i_prof           IN profissional,
        i_desc_problem   IN table_varchar,
        i_flg            IN table_varchar,
        i_notes          IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_age            IN table_varchar,
        i_flg_approved   IN table_varchar,
        i_epis_anamnesis IN table_number,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_relev_disease_array
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_pat           IN pat_problem.id_patient%TYPE,
        i_prof          IN profissional,
        i_id_diagnosis  IN table_number,
        i_flg           IN table_varchar,
        i_notes         IN table_varchar,
        i_dt_symptoms   IN table_varchar,
        i_age           IN table_varchar,
        i_flg_approved  IN table_varchar,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_diag     IN pat_problem.desc_pat_problem%TYPE,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_pat_problem
    (
        i_lang      IN language.id_language%TYPE,
        i_diag      IN pat_problem.id_diagnosis%TYPE,
        i_id_pat    IN pat_problem.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem
    (
        i_lang        IN language.id_language%TYPE,
        i_pat         IN pat_problem.id_patient%TYPE,
        i_status      IN pat_problem.flg_status%TYPE,
        i_type        IN VARCHAR2,
        i_prof        IN profissional,
        o_pat_problem OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_problem_det
    (
        i_lang     IN language.id_language%TYPE,
        i_pat_prob IN pat_problem.id_pat_problem%TYPE,
        i_type     IN VARCHAR2,
        i_prof     IN profissional,
        o_problem  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_relev_disease_list
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN pat_problem.id_patient%TYPE,
        i_status  IN pat_problem.flg_status%TYPE,
        i_prof    IN profissional,
        o_disease OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_relev_disease_det
    (
        i_lang    IN language.id_language%TYPE,
        i_disease IN pat_problem.id_pat_problem%TYPE,
        i_prof    IN profissional,
        o_disease OUT pk_types.cursor_type,
        o_notes   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_id_pat         IN pat_allergy.id_patient%TYPE,
        i_prof           IN profissional,
        i_allergy        IN pat_allergy.id_allergy%TYPE,
        i_drug_pharma    IN pat_allergy.id_drug_pharma%TYPE,
        i_notes          IN pat_allergy.notes%TYPE,
        i_dt_first_time  IN VARCHAR2,
        i_flg_type       IN pat_allergy.flg_type%TYPE,
        i_flg_approved   IN pat_allergy.flg_aproved%TYPE,
        i_flg_status     IN pat_allergy.flg_status%TYPE,
        i_dt_symptoms    IN VARCHAR2,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_pat_allergy_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_allergy.id_patient%TYPE,
        i_prof           IN profissional,
        i_allergy        IN table_number,
        i_allergy_cancel IN table_number,
        i_status         IN table_varchar,
        i_notes          IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_type           IN table_varchar,
        i_approved       IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION call_create_pat_allergy_array
    (
        i_lang           IN language.id_language%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        i_pat            IN pat_allergy.id_patient%TYPE,
        i_prof           IN profissional,
        i_allergy        IN table_number,
        i_allergy_cancel IN table_number,
        i_status         IN table_varchar,
        i_notes          IN table_varchar,
        i_dt_symptoms    IN table_varchar,
        i_type           IN table_varchar,
        i_approved       IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_selected_allergies
    (
        i_lang        IN language.id_language%TYPE,
        i_patient     IN pat_allergy.id_patient%TYPE,
        i_allergy     IN pat_allergy.id_allergy%TYPE,
        i_prof        IN profissional,
        o_flg_without OUT allergy.flg_without%TYPE,
        o_allergy     OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg         OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_aux_pat_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_allergy IN pat_allergy.id_allergy%TYPE,
        i_prof    IN profissional,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_allergy_list
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN pat_allergy.id_patient%TYPE,
        i_status  IN pat_allergy.flg_status%TYPE,
        i_prof    IN profissional,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_allergy_det
    (
        i_lang    IN language.id_language%TYPE,
        i_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_prof    IN profissional,
        o_allergy OUT pk_types.cursor_type,
        o_notes   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION call_cancel_pat_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_prof           IN profissional,
        i_notes          IN pat_allergy.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_prof           IN profissional,
        i_notes          IN pat_allergy.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_allergy_array
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN table_number,
        i_prof           IN profissional,
        i_notes          IN pat_allergy.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_pat_allergy
    (
        i_lang      IN language.id_language%TYPE,
        i_allergy   IN allergy.id_allergy%TYPE,
        i_id_pat    IN patient.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_soc_att
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_name             IN patient.name%TYPE,
        i_nick_name        IN patient.nick_name%TYPE,
        i_gender           IN patient.gender%TYPE,
        i_dt_birth         IN patient.dt_birth%TYPE,
        i_isencao          IN pat_soc_attributes.id_isencao%TYPE,
        i_dt_deceased      IN patient.dt_deceased%TYPE,
        i_marital_status   IN pat_soc_attributes.marital_status%TYPE,
        i_address          IN pat_soc_attributes.address%TYPE,
        i_location         IN pat_soc_attributes.location%TYPE,
        i_district         IN pat_soc_attributes.district%TYPE,
        i_zip_code         IN pat_soc_attributes.zip_code%TYPE,
        i_country_nat      IN pat_soc_attributes.id_country_nation%TYPE,
        i_country_res      IN pat_soc_attributes.id_country_address%TYPE,
        i_scholarship      IN pat_soc_attributes.id_scholarship%TYPE,
        i_religion         IN pat_soc_attributes.id_religion%TYPE,
        i_num_main_contact IN pat_soc_attributes.num_main_contact%TYPE,
        i_num_contact      IN pat_soc_attributes.num_contact%TYPE,
        i_flg_job_status   IN pat_soc_attributes.flg_job_status%TYPE,
        i_father_name      IN pat_soc_attributes.father_name%TYPE,
        i_mother_name      IN pat_soc_attributes.mother_name%TYPE,
        i_job              IN pat_job.id_occupation%TYPE,
        i_recm             IN recm.id_recm%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_epis             IN episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_soc_att
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_pat    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * 
    * Register the patient's necessities.
    *   
    * @param i_lang               Language ID 
    * @param i_prof               Professional info 
    * @param i_id_patient         Patient ID 
    * @param i_id_episode         Episode ID
    * @param i_tbl_id_necessity   Array with necessities ID 
    * @param i_tbl_flg_status     Array with the necessities status 
    * @param i_sysdate            Register date
    * @param i_id_epis_triage     Triage event ID
    * @param i_id_institution     Institution where the necessity is registered ID
    * @param o_error              Error message 
    *
    * @return                TRUE / FALSE
    *                        
    * @author                Sergio Dias
    * @version               2.6.3.8.1
    * @since                 16-9-2013
    **************************************************************************/
    FUNCTION set_pat_necess
    (
        i_lang             IN language.id_language%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_tbl_id_necessity IN table_number,
        i_tbl_flg_status   IN table_varchar,
        i_prof             IN profissional,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * 
    * Register the patient's necessities.
    *   
    * @param i_lang               Language ID 
    * @param i_prof               Professional info 
    * @param i_id_patient         Patient ID 
    * @param i_id_episode         Episode ID
    * @param i_tbl_id_necessity   Array with necessities ID 
    * @param i_tbl_flg_status     Array with the necessities status 
    * @param i_sysdate            Register date
    * @param i_id_epis_triage     Triage event ID
    * @param i_id_institution     Institution where the necessity is registered ID
    * @param o_error              Error message 
    *
    * @return                TRUE / FALSE
    *                        
    * @author                Sergio Dias
    * @version               2.6.3.8.1
    * @since                 16-9-2013
    **************************************************************************/
    FUNCTION set_pat_necess
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_tbl_id_necessity IN table_number,
        i_tbl_flg_status   IN table_varchar,
        i_prof_cat_type    IN category.flg_type%TYPE DEFAULT NULL,
        i_sysdate          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_epis_triage   IN epis_triage.id_epis_triage%TYPE DEFAULT NULL,
        i_id_institution   IN institution.id_institution%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_necess
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_status IN pat_necessity.flg_status%TYPE,
        o_necess OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_pat_necess
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_necess     OUT cursor_necess,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_hplan
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_id_hplan      IN table_number, --HEALTH_PLAN.ID_HEALTH_PLAN%TYPE,
        i_num_hplan     IN table_varchar, --PAT_HEALTH_PLAN.NUM_HEALTH_PLAN%TYPE,
        i_dt_hplan      IN table_varchar, --PAT_HEALTH_PLAN.DT_HEALTH_PLAN%TYPE,
        i_default       IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_default_epis  IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_barcode       IN table_varchar, --PAT_HEALTH_PLAN.BARCODE%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_hplan    IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_hplan_interface
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_id_hplan      IN table_number, --HEALTH_PLAN.ID_HEALTH_PLAN%TYPE,
        i_num_hplan     IN table_varchar, --PAT_HEALTH_PLAN.NUM_HEALTH_PLAN%TYPE,
        i_dt_hplan      IN table_date, --PAT_HEALTH_PLAN.DT_HEALTH_PLAN%TYPE,
        i_default       IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_default_epis  IN table_varchar, --PAT_HEALTH_PLAN.FLG_DEFAULT%TYPE,
        i_barcode       IN table_varchar, --PAT_HEALTH_PLAN.BARCODE%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_hplan_internal
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_id_hplan      IN table_number,
        i_num_hplan     IN table_varchar,
        i_dt_hplan      IN table_date,
        i_default       IN table_varchar,
        i_default_epis  IN table_varchar,
        i_barcode       IN table_varchar,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_desc_hplan    IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_hplan
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_epis       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_hplan         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_hplan
    (
        i_lang          IN language.id_language%TYPE,
        i_pat_hplan     IN pat_health_plan.id_pat_health_plan%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg           OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_doc
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_id_doc        IN table_number, --DOC_TYPE.ID_DOC_TYPE%TYPE,
        i_number        IN table_varchar, --PAT_DOC.VALUE%TYPE,
        i_dt_emi        IN table_varchar, --PAT_DOC.DT_EMITED%TYPE,
        i_dt_exp        IN table_varchar, --PAT_DOC.DT_EXPIRE%TYPE,
        i_prof          IN profissional,
        i_status        IN table_varchar, --PAT_DOC.FLG_STATUS%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_doc
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_doc    OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_job_internal
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_occup             IN pat_job.id_occupation%TYPE,
        i_prof              IN profissional,
        i_location          IN pat_job.location%TYPE,
        i_year_begin        IN pat_job.year_begin%TYPE,
        i_year_end          IN pat_job.year_end%TYPE,
        i_activity_type     IN pat_job.activity_type%TYPE,
        i_prof_disease_risk IN pat_job.prof_disease_risk%TYPE,
        i_notes             IN pat_job.notes%TYPE,
        i_num_workers       IN pat_job.num_workers%TYPE,
        i_company           IN pat_job.company%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_occupation_desc   IN pat_job.occupation_desc%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_job
    (
        i_lang              IN language.id_language%TYPE,
        i_id_pat            IN patient.id_patient%TYPE,
        i_occup             IN pat_job.id_occupation%TYPE,
        i_prof              IN profissional,
        i_location          IN pat_job.location%TYPE,
        i_year_begin        IN pat_job.year_begin%TYPE,
        i_year_end          IN pat_job.year_end%TYPE,
        i_activity_type     IN pat_job.activity_type%TYPE,
        i_prof_disease_risk IN pat_job.prof_disease_risk%TYPE,
        i_notes             IN pat_job.notes%TYPE,
        i_num_workers       IN pat_job.num_workers%TYPE,
        i_company           IN pat_job.company%TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_epis              IN episode.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_last_pat_job
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        o_occup  OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_job
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_status IN pat_job.flg_status%TYPE,
        i_prof   IN profissional,
        o_occup  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_clin_rec
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pat        IN clin_record.id_patient%TYPE,
        i_instit     IN clin_record.id_institution%TYPE,
        i_num        IN clin_record.num_clin_record%TYPE,
        i_pat_family IN clin_record.id_pat_family%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clin_rec
    (
        i_lang       IN language.id_language%TYPE,
        i_pat        IN clin_record.id_patient%TYPE,
        i_instit     IN clin_record.id_institution%TYPE,
        i_pat_family IN clin_record.id_pat_family%TYPE,
        o_num        OUT clin_record.num_clin_record%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_cli_att_internal
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_flg_pregnancy   IN pat_cli_attributes.flg_pregnancy%TYPE,
        i_flg_breast_feed IN pat_cli_attributes.flg_breast_feed%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_id_recm         IN pat_cli_attributes.id_recm%TYPE,
        i_dt_val_recm     IN pat_cli_attributes.dt_val_recm%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_cli_att
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_flg_pregnancy   IN pat_cli_attributes.flg_pregnancy%TYPE,
        i_flg_breast_feed IN pat_cli_attributes.flg_breast_feed%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_id_recm         IN pat_cli_attributes.id_recm%TYPE,
        i_dt_val_recm     IN pat_cli_attributes.dt_val_recm%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_cli_att
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        o_id_pat_cli_attr OUT pat_cli_attributes.id_pat_cli_attributes%TYPE,
        o_flg_pregnancy   OUT pat_cli_attributes.flg_pregnancy%TYPE,
        o_flg_breast_feed OUT pat_cli_attributes.flg_breast_feed%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_blood
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_flg_group     IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh        IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other    IN pat_blood_group.desc_other_system%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_blood_int
    (
        i_lang            IN language.id_language%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        i_id_pat          IN patient.id_patient%TYPE,
        i_flg_group       IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh          IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other      IN pat_blood_group.desc_other_system%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_analysis_result IN analysis_result.id_analysis_result%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_blood_int
    (
        i_lang               IN language.id_language%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_flg_group          IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh             IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other         IN pat_blood_group.desc_other_system%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_pat_blood_group IN pat_blood_group.dt_pat_blood_group_tstz%TYPE,
        i_analysis_result    IN analysis_result.id_analysis_result%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION with_notes
    (
        i_lang  IN language.id_language%TYPE,
        id_ares IN analysis_result.id_analysis_result%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_blood
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_blood  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_blood_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        id_pat_blood_group IN pat_blood_group.id_pat_blood_group%TYPE,
        i_all              IN BOOLEAN DEFAULT FALSE,
        o_blood_detail     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_blood_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat           IN patient.id_patient%TYPE,
        i_prof             IN profissional,
        id_pat_blood_group IN pat_blood_group.id_pat_blood_group%TYPE,
        o_blood_detail     OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_vaccine
    (
        i_lang            IN language.id_language%TYPE,
        i_id_pat          IN pat_vaccine.id_patient%TYPE,
        i_prof            IN profissional,
        i_vaccine         IN pat_vaccine.id_vaccine%TYPE,
        i_instit          IN pat_vaccine.id_institution%TYPE,
        i_dt_take         IN VARCHAR2,
        i_flg_take_type   IN pat_vaccine.flg_take_type%TYPE,
        i_lab             IN pat_vaccine.lab%TYPE,
        i_lote            IN pat_vaccine.lote%TYPE,
        i_notes           IN pat_vaccine.notes%TYPE,
        i_tuberculin_type IN pat_vaccine.tuberculin_type%TYPE,
        i_prof_cat_type   IN category.flg_type%TYPE,
        i_epis            IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_vaccine
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN pat_vaccine.id_patient%TYPE,
        i_vaccine IN pat_vaccine.id_vaccine%TYPE,
        i_prof    IN profissional,
        o_vaccine OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_id_pat     IN pat_notes.id_patient%TYPE,
        i_flg_status IN pat_notes.flg_status%TYPE,
        i_prof       IN profissional,
        o_notes      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_notes
    (
        i_lang   IN language.id_language%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        i_id_pat IN pat_notes.id_patient%TYPE,
        i_prof   IN profissional,
        i_notes  IN pat_notes.notes%TYPE,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat_notes IN pat_notes.id_pat_notes%TYPE,
        i_prof         IN profissional,
        i_notes        IN pat_notes.notes%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION ins_pat_problem_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_pat_problem_hist pat_problem_hist%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION ins_pat_problem_hist_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_pat_problem_hist pat_problem_hist%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION ins_pat_allergy_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_pat_allergy_hist pat_allergy_hist%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_pat_habit
    (
        i_lang   IN language.id_language%TYPE,
        i_habit  IN habit.id_habit%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        o_msg    OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_habit
    (
        i_lang                      IN language.id_language%TYPE,
        i_epis                      IN episode.id_episode%TYPE,
        i_id_patient                IN pat_habit.id_patient%TYPE,
        i_id_habit                  IN pat_habit.id_habit%TYPE,
        i_flg_status                IN pat_habit.flg_status%TYPE,
        i_prof                      IN profissional,
        i_notes                     IN pat_habit.notes%TYPE,
        i_prof_cat_type             IN category.flg_type%TYPE,
        i_dt_begin_hab              IN VARCHAR2,
        i_dt_end_hab                IN VARCHAR2,
        i_id_habit_characterization IN habit_characterization.id_habit_characterization%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get detail last record
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param i_episode                   Episode ID
    * @param i_patient                   Patient ID
    * @param i_pat_habit                 Patient habit ID
    * @param o_habit_detail              habit cursor
    * @param o_error                     Error type
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version 2.5.0.7.7
    * @since   19-Feb-2010
    * @reason  ALERT-68901
    **********************************************************************************************/
    FUNCTION get_pat_habit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN pat_habit.id_episode%TYPE,
        i_patient      IN pat_habit.id_patient%TYPE,
        i_pat_habit    IN pat_habit.id_pat_habit%TYPE,
        o_habit_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set patient's habit
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param i_episode                   Episode ID
    * @param i_patient                   Patient ID
    * @param i_pat_habit                 Patient habit ID
    * @param i_dt_begin                  Patient habit date begin
    * @param i_flg_status                Habit flag status
    * @param i_notes                     Notes
    * @param o_error                     Error type
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version 2.5.0.7.7
    * @since   19-Feb-2010
    * @reason  ALERT-68901
    **********************************************************************************************/
    FUNCTION set_pat_habit
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN pat_habit.id_episode%TYPE,
        i_patient                   IN pat_habit.id_patient%TYPE,
        i_pat_habit                 IN pat_habit.id_pat_habit%TYPE,
        i_dt_begin                  IN VARCHAR2,
        i_flg_status                IN pat_habit.flg_status%TYPE,
        i_notes                     IN pat_habit.notes%TYPE,
        i_id_habit_characterization IN habit_characterization.id_habit_characterization%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * get patient habits
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_id_pat_habit      Patient habit id
    * @param IN   i_prof              Professional Type
    * @param IN   i_all               Boolean
    * @param OUT  o_habit_detail      Habits array 
    * @param OUT  o_error             Error structure
    *
    * @value      i_all               {*} True  (Include all: Create, History, Review)
    *                                 {*} False (Include only Create)  
    *
    * @return BOOLEAN
    *
    * @version  2.5.0.7.5
    * @since    2009-Dec-09
    * @author   Filipe Machado
    * @reason   ALERT-61063
    ********************************************************************************************/

    FUNCTION get_pat_habit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_prof         IN profissional,
        i_all          IN BOOLEAN DEFAULT FALSE,
        o_habit_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * get patient habits
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_id_pat_habit      Patient habit id
    * @param IN   i_prof              Professional Type
    * @param OUT  o_habit_detail      Habits array 
    * @param OUT  o_error             Error structure
    *
    * @return BOOLEAN
    *
    * @version  2.5.0.7.5
    * @since    2009-Dec-09
    * @author   Filipe Machado
    * @reason   ALERT-61063
    ********************************************************************************************/

    FUNCTION get_pat_habit
    (
        i_lang         IN language.id_language%TYPE,
        i_id_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_prof         IN profissional,
        o_habit_detail OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get habit status
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Profissional array
    * @param o_habit_status              Habit status
    * @param o_error                     Error type
    *                        
    * @return                            True or False on success or error
    *
    * @author  Filipe Machado
    * @version 2.5.0.7.7
    * @since   22-Feb-2010
    * @reason  ALERT-68901
    **********************************************************************************************/

    FUNCTION get_habit_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_habit_status OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************************** 
    * get habit date begin last update or insert
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_pat_habit         Habit ID
    * @param IN   i_id_pat            Patient id
    * @param IN   i_prof              Professional Type
    *
    * @return BOOLEAN
    *
    * @version  2.5.0.7.7
    * @since    2009-Feb-22
    * @author   Filipe Machado
    * @reason   ALERT-61063
    ********************************************************************************************/

    FUNCTION get_dt_begin_last_update
    (
        i_lang      IN language.id_language%TYPE,
        i_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_id_pat    IN pat_habit.id_patient%TYPE,
        i_prof      IN profissional
    ) RETURN VARCHAR2;

    /******************************************************************************************** 
    * get habit date begin last update or insert (YYYY-MM-DAY format)
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_pat_habit         Habit ID
    * @param IN   i_id_pat            Patient id
    * @param IN   i_prof              Professional Type
    *
    * @return BOOLEAN
    *
    * @version  2.5.0.7.7
    * @since    2009-Feb-22
    * @author   Filipe Machado
    * @reason   ALERT-61063
    ********************************************************************************************/

    FUNCTION get_dt_begin_to_flash
    (
        i_lang      IN language.id_language%TYPE,
        i_pat_habit IN pat_habit.id_pat_habit%TYPE,
        i_id_pat    IN pat_habit.id_patient%TYPE,
        i_prof      IN profissional
    ) RETURN VARCHAR2;

    FUNCTION get_all_habit
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN pat_habit.id_patient%TYPE,
        i_prof   IN profissional,
        o_habit  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_habit
    (
        i_lang          IN language.id_language%TYPE,
        i_id_pat_habit  IN pat_habit.id_pat_habit%TYPE,
        i_prof          IN profissional,
        i_notes         IN pat_habit.note_cancel%TYPE,
        i_cancel_reason IN pat_habit.id_cancel_reason%TYPE DEFAULT NULL,
        i_dt_hab_end    IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pat_fam_soc_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_id_patient    IN pat_fam_soc_hist.id_patient%TYPE,
        i_flg_type      IN pat_fam_soc_hist.flg_type%TYPE,
        i_notes         IN pat_fam_soc_hist.notes%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_pat_fam_soc_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_id_pat_fam_soc_hist IN pat_fam_soc_hist.id_pat_fam_soc_hist%TYPE,
        i_prof                IN profissional,
        i_notes               IN pat_fam_soc_hist.notes_cancel%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_fam_soc_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN pat_fam_soc_hist.id_patient%TYPE,
        i_type    IN pat_fam_soc_hist.flg_type%TYPE,
        i_prof    IN profissional,
        o_pat_fam OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   definir o código INE em função do código postal 
       PARAMETROS:  Entrada:   I_LANG - língua registada como preferencial do profissional
            I_PROF - profissional que regista,
           I_ZIP_CODE - código postal,
                               O_INE_LOCATION - código de localização do INE 
           O_ERROR - erro 
       
      CRIAÇÃO: LG 2006/09/01 
      NOTAS: 
    *********************************************************************************/
    FUNCTION find_ine_location_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_zip_code     IN VARCHAR2,
        o_ine_location OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a patient. 
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_PROF  professional, institution and software ids 
    * @param   I_KEYS array with keys about which info is available to create the patient  
    * @param   I_VALUES array with which info is available to create the patient
    * @param   I_PROF_CAT_TYPE the professional category
    * @param   I_EPIS Episode id   
    * @param   O_ID_PATIENT The new patient id    
    * @param   O_FLG_SHOW  =Y to show a message, otherwise = N 
    * @param   O_MSG_TITLE  the message title, when O_FLG_SHOW = Y 
    * @param   O_MSG_TEXT  the message text , when O_FLG_SHOW = Y
    * @param   O_BUTTON the buttons to show with the message N - No, L - read, C - confirmed. any combination is allowed   
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   19-10-2006
    *
    * @author  Pedro Santos
    * @version 2.4.3-Denormalized
    * @since   2008/10/30 
    * reason added i_epis 
    */
    FUNCTION create_patient
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_context        IN screen_template.context%TYPE,
        i_keys           IN table_varchar,
        i_values         IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_btn            IN sys_button_prop.id_sys_button_prop%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        o_id_patient     OUT patient.id_patient%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set patient attributes: personal, clinical, social, etc. 
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_PROF  professional, institution and software ids 
    * @param   I_EPIS Episode id 
    * @param   I_ID_PATIENT the patient id 
    * @param   I_KEYS array with keys about which info is available to the patient  
    * @param   I_VALUES array with which info is available to the patient
    * @param   I_PROF_CAT_TYPE the professional category   
    * @param   O_FLG_SHOW  =Y to show a message, otherwise = N 
    * @param   O_MSG_TITLE  the message title, when O_FLG_SHOW = Y 
    * @param   O_MSG_TEXT  the message text , when O_FLG_SHOW = Y
    * @param   O_BUTTON the buttons to show with the message N - No, L - read, C - confirmed. any combination is allowed   
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar 
    * @version 1.0 
    * @since   26-10-2006 
    *
    * @author    Pedro Santos
    * @version   2.4.3-Denormalized
    * @since     2008/09/30
    */
    FUNCTION set_patient_attributes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_context        IN screen_template.context%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_keys           IN table_varchar,
        i_values         IN table_varchar,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_btn            IN sys_button_prop.id_sys_button_prop%TYPE,
        i_epis           IN episode.id_episode%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get patient attributes: personal, clinical, social, etc. 
    * O_KEYS and O_VALUES are related by array index.
    *
    * @param   I_LANG language associated to the professional executing the request 
    * @param   I_PROF  professional, institution and software ids 
    * @param I_CONTEXT context identifing the screen template,
    * @param  I_PATIENT the patient 
    * @param   I_PROF_CAT_TYPE the professional category   
    * @param   O_KEYS array with keys about which info is available the patient. A key has the <TABLE>.<COLUMN> format to identifie the value.  
    * @param   O_VALUES array with which info is available to the patient 
    * @param   O_ERROR an error message, set when return=false 
    *
    * @RETURN  TRUE if sucess, FALSE otherwise 
    * @author  Luís Gaspar E
    * @version 1.0 
    * @since   26-10-2006 
    */

    FUNCTION get_patient_attributes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_context       IN screen_template.context%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_btn           IN sys_button_prop.id_sys_button_prop%TYPE,
        o_keys          OUT table_varchar,
        o_values        OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Criar ou actualizar a história do paciente : Médica, Cirúrgica, Familiar e Social 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             patient id
    * @param i_dt_pat_history         
    * @param i_id_diagnosis           diagnosis id
    * @param i_flg_status             Estado.Se o acrónimo da história = HMC, então os estados serão estes:D - despiste(ampulheta)
                                                                                                           F - confirmar
                                                                                                           R - declinar(-)
                                                                                                           B - Diagnóstico base
                                      Se o acrónimo da história = HFS, então os estados serão estes:A - Activo             
    * @param i_desc_diag              description diagnosis 
    * @param i_notes                  notes
    * @param i_flg_type_hist          Qual o tipo de história: M - Médica; C - Cirurgica; F - Familiar; S - Social
    * @param i_prof_cat_type          professional category
    * @param i_dt_begin_hist          Data aproximada de início da história do paciente. 
    * @param i_dt_end_hist            Data fim aproximada da história do paciente.
    * @param i_epis                   Episode id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    *
    * @author                         Pedro Santos
    * @version                        2.4.3-Denormalized
    * @since                          2008/10/30   
    **********************************************************************************************/
    FUNCTION create_pat_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_dt_pat_history IN pat_history.dt_pat_history_tstz%TYPE,
        i_id_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_flg_status     IN pat_history.flg_status%TYPE,
        i_desc_diag      IN pat_history.desc_diagnosis%TYPE,
        i_notes          IN pat_history.notes%TYPE,
        i_flg_type_hist  IN pat_history.flg_type_hist%TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_dt_begin_hist  IN VARCHAR2,
        i_dt_end_hist    IN VARCHAR2,
        i_epis           IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Cancelar as notas da história do paciente : Médica, Cirúrgica, Familiar e Social  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_pat_history         
    * @param i_notes                  notes
    * @param i_flg_type_hist          Qual o tipo de história: M - Médica; C - Cirurgica; F - Familiar; S - Social
    * @param i_prof_cat_type          professional category
    * @param i_dt_end_hist            Data fim aproximada da história do paciente.
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    **********************************************************************************************/
    FUNCTION cancel_pat_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_history IN pat_history.id_pat_history%TYPE,
        i_notes          IN pat_history.notes%TYPE,
        i_flg_type_hist  IN pat_history.flg_type_hist%TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_dt_end_hist    IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Listar as notas da história do paciente : Médica, Cirúrgica, Familiar e Social  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             patient id         
    * @param i_flg_type_hist          Qual o tipo de história: M - Médica; C - Cirurgica; F - Familiar; S - Social
    * @param o_past_hist              Listar as notas da história do paciente : Médica, Cirúrgica, Familiar e Social
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    **********************************************************************************************/
    FUNCTION get_pat_history
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_flg_type_hist IN VARCHAR2,
        o_pat_hist      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Actualizar o histório da histórica Médica/Cirúrgica/Familiar/Social do paciente sempre que é alterado o seu estado  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             patient id         
    * @param i_id_pat_hist            ID da história do paciente
    * @param i_prof_cat_type          professional category
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    **********************************************************************************************/
    FUNCTION set_pat_history_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_pat_hist   IN pat_history.id_pat_history%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Alterar o estado de uma história médica/cirúrgica/familiar/social de um paciente  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             patient id         
    * @param i_id_pat_hist            ID da história do paciente
    * @param i_flg_status             status    
    * @param i_prof_cat_type          professional category
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/15 
    **********************************************************************************************/
    FUNCTION set_pat_hist_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_pat_hist   IN pat_history.id_pat_history%TYPE,
        i_flg_status    IN pat_history.flg_status%TYPE,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente e/ou do acompanhante   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_printer                porta da impressora
    * @param o_barcode_pat            String para impressão (paciente)    
    * @param o_barcode_nec            String para impressão (acompanhante)
    * @param o_barcode_pat_n          String para impressão (paciente patient.name)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/19 
    *
    * UPDATED: ALERT-122457 - Type: BUG and CONFIG Area: Wristbands ALERT EDIS 2.5.0.7.8 Expec (truncated)
    * @author  Alexandre Santos
    * @date    16-09-2010
    * @version 2.8.0.7.8
    **********************************************************************************************/
    FUNCTION get_barcode_print
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_config            IN sys_config.id_sys_config%TYPE,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_barcode_nec       OUT VARCHAR2,
        o_barcode_pat_n     OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente e/ou do acompanhante.
    * Usada em queries SQL.   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_error                  Error message
    *
    * @return                         String para impressão (paciente)  
    *                        
    * @author                         Rui Baeta
    * @since                          2008/02/29 
    **********************************************************************************************/
    FUNCTION get_barcode_print
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente e/ou do acompanhante   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_printer                porta da impressora
    * @param o_barcode_pat            String para impressão (paciente)    
    * @param o_barcode_nec            String para impressão (acompanhante)
    * @param o_barcode_pat_n          String para impressão (paciente patient.name)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rui Spratley
    * @version                        2.4.2.15
    * @since                          2008/09/11
    **********************************************************************************************/
    FUNCTION get_barcode_print_new
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_barcode_nec       OUT VARCHAR2,
        o_barcode_pat_n     OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get major incident data for the patient's wristband/frontsheet.    
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_printer                porta da impressora
    * @param o_barcode_pat            String para impressão (paciente)    
    * @param o_barcode_nec            String para impressão (acompanhante)
    * @param o_barcode_pat_n          String para impressão (paciente patient.name)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Gisela Couto
    * @version                        2.6.4.2
    * @since                          2014/09/08
    **********************************************************************************************/
    FUNCTION get_barcode_print_major_inc
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /**********************************************************************************************
    * Obter associado ao episódio / paciente   
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_episode                episode id
    * @param o_barcode                Barcode associado ao episódio / paciente 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/01/20 
    *
    * UPDATED: ALERT-125592 - Support in Alert for external barcodes
    * @author  Alexandre Santos
    * @date    21-09-2010
    * @version 2.5.0.7.8
    **********************************************************************************************/
    FUNCTION get_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_barcode OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /**********************************************************************************************
    * Devolve o id_patient do sonho que corresponde ao id_patient ALert 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id         
    * @param o_pat_ext_sys            Devolve o id_patient do sonho
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2007/03/19
    **********************************************************************************************/
    FUNCTION get_pat_ext_sys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_pat_ext_sys OUT pat_ext_sys.value%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the external patient ID 
    *
    * @param i_lang                   The id language
    * @param i_prof                   Professional, software and institution id
    * @param i_ext_sys                External system ID
    * @param i_patient                Patient ID         
    * @param i_institution            Institution ID
    *
    * @return                         External patient ID
    *
    * @author  José Silva
    * @date    17-11-2011
    * @version 2.5.1.9
    **********************************************************************************************/
    FUNCTION get_pat_ext_sys
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ext_sys     IN external_sys.id_external_sys%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN pat_ext_sys.value%TYPE;

    /**
    * Validate item applicable gender.
    * Anwers the question? Is this item applicable to this patient gender?
    *
    * @param i_pat_gender        The patient gender
    * @param i_item_gender       The item gender
    *
    * @return 1 when applicable, 0 otherwise
    * @created 26-05-2007
    * @author Luís Gaspar & Luís Oliveira
    */
    FUNCTION validate_pat_gender
    (
        i_pat_gender  IN patient.gender%TYPE,
        i_item_gender IN patient.gender%TYPE
    ) RETURN NUMBER result_cache;

    /**
    * Returns the url used to access an external system from 
    *
    * @param i_lang        the language id
    * @param i_prof        professional, software and institution id
    * @param i_patient     the patient id
    * @param i_episode     the episode id
    * @param o_url         The external system url
    * @param o_error       An error message
    *
    * @return boolean true if success, false otherwise
    * @created 06-Jun-2007
    * @author Luís Gaspar
    */
    FUNCTION get_ext_sys_url
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_url     OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Nome do paciente
    *
    * @param i_lang                language id
    * @param i_patient             patient id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/19
    **********************************************************************************************/
    FUNCTION get_patient_name
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_patient_name
    (
        i_lang         IN language.id_language%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        o_patient_name OUT patient.name%TYPE
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Nome abreviado do paciente
    *
    * @param i_lang                language id
    * @param i_patient             patient id
    *
    * @return                      description
    *    
    * @author                      Emilia Taborda
    * @version                     1.0
    * @since                       2007/10/19
    **********************************************************************************************/
    FUNCTION get_patient_nick_name
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente bem como todas as alergias activas do paciente   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    * @param o_printer                porta da impressora
    * @param o_barcode_pat            String para impressão (paciente)    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @author                         Rui Baeta
    * @version                        1.0 
    * @since                          2007/10/29
    **********************************************************************************************/
    FUNCTION get_barcode_allergy_print
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode_pat       OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Obter os resultados dos parametros do paciente bem como todas as alergias activas do paciente.
    * Usada em queries SQL.   
    *
    * @param i_lang                   the id language
    * @param i_episode                episode id
    * @param i_patient                patient id         
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         String para impressão (paciente)    
    *                        
    * @author                         Rui Baeta
    * @version                        1.0 
    * @since                          2007/12/19
    **********************************************************************************************/
    FUNCTION get_barcode_allergy_print
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        i_prof    IN profissional
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Method that tests if the professional can create patients based on his profile template
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids   
    * @param o_permission             Flag 'Y' if the profissional can create patients, 'N' if he can't
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error                     
    *
    * @author                         Sérgio Santos
    * @version                        1.0 
    * @since                          2008/02/08
    **********************************************************************************************/
    FUNCTION get_pat_creation_permission
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_permission OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This functions sets a habit as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional Type
     * @param IN   i_id_blood_type     Blood Type ID
     * @param IN   i_review_notes      Notes
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-23
     * @author   Thiago Brito
    */
    FUNCTION set_habit_review
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_id_habit     IN pat_habit.id_pat_habit%TYPE,
        i_review_notes IN review_detail.review_notes%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This functions sets a blood type as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional Type
     * @param IN   i_id_blood_type     Blood Type ID
     * @param IN   i_review_notes      Notes
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-23
     * @author   Thiago Brito
    */
    FUNCTION set_blood_type_review
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_blood_type IN pat_allergy.id_pat_allergy%TYPE,
        i_review_notes  IN review_detail.review_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * Gets the patient location based on the institution group.
     *
     * @param IN   i_institution       Professional institution id
     * @param IN   i_flg_relation      type of relation between institutions
     * @param IN   i_patient           Patient id
     *
     * @return     Patient location. First verifies if the location exists in the professional institution
     *                               then verifies if the location exists in the institution 0
     *                               then verifies if exists in one of the institutions group
     *
     * @version  2.5.0.7
     * @since    11-12-2009
     * @author   Alexandre Santos
    */
    FUNCTION get_pat_location
    (
        i_institution  IN institution_group.id_institution%TYPE,
        i_flg_relation IN institution_group.flg_relation%TYPE,
        i_patient      IN patient.id_patient%TYPE
    ) RETURN pat_soc_attributes.location%TYPE;

    /**
    * Check if the professional is responsible for the episode.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    *
    * @return               patient's name
    */
    FUNCTION get_prof_resp
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER;

    /**
    * Get patient name (VIP compliant).
    *
    * @param i_lang          language identifier
    * @param i_prof          logged professional structure
    * @param i_patient       patient identifier
    * @param i_episode       episode identifier
    * @param i_schedule      schedule identifier
    * @param i_id_sys_config sys_config identifier (DEFAULT 'PATIENT_NAME_PATTERN')
    *
    * @return               patient's name
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.0
    * @since                2010/01/08
    */
    FUNCTION get_pat_name
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_schedule      IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN'
    ) RETURN patient.name%TYPE;

    /**
    * Get patient name to use in sorting (order by clause only) 
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    *
    * @return               patient's name
    *
    * @author               Bruno Martins
    * @version              2.6.0.0
    * @since                2010/01/22
    */
    FUNCTION get_pat_name_to_sort
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_schedule IN schedule.id_schedule%TYPE DEFAULT NULL
    ) RETURN patient.name%TYPE;

    /******************************************************************************
     OBJECTIVO:   Retornar informação para do falecimento do doente 
     PARAMETROS:  
               Entrada: 
               I_LANG - Língua registada como preferência do profissional 
               I_ID_PAT - ID do doente 
               i_PROF - ID do profissional
               Saída:   
               O_STATUS - A - activo, O - falecido, I - inactivo 
               O_DT_DECEASED - PATIENT.DT_DECEASED 
               O_ERROR - erro 
    *
    * CRIAÇÃO: ALERT-14510
    * @author  Isabela Fontoura
    * @date    07-01-2010
    * @version 1.0
    *********************************************************************************/
    FUNCTION get_decease_info_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_status      OUT patient.flg_status%TYPE,
        o_dt_deceased OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient's age & gender based on episode ID
    *
    * @param i_lang                      Language ID
    * @param i_episode                   Episode ID
    * @param o_gender                    Patient's gender or NULL if patient doesn't exist
    * @param o_age                       Patient's age or NULL if patient doesn't exist
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7
    * @since   27-Oct-09
    **********************************************************************************************/
    FUNCTION get_pat_info_by_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_gender  OUT patient.gender%TYPE,
        o_age     OUT patient.age%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get patient's age & gender based on patient ID
    *
    * @param i_lang                      Language ID
    * @param i_patient                   Patient ID
    * @param o_gender                    Patient's gender or NULL if patient doesn't exist
    * @param o_age                       Patient's age or NULL if patient doesn't exist
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7
    * @since   27-Oct-09
    **********************************************************************************************/
    FUNCTION get_pat_info_by_patient
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_gender  OUT patient.gender%TYPE,
        o_age     OUT patient.age%TYPE
    ) RETURN BOOLEAN;

    /**
    * Get Show patient info
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    *
    * @return               Y/N
    *
    * @author               Elisabete Bugalho
    * @version              2.6.0.0
    * @since                25-02-2010
    */
    FUNCTION get_show_patient_info
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_schedule  IN schedule.id_schedule%TYPE DEFAULT NULL,
        o_show_info OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /* universal patient search function. the market parameter determines the data source, that is, which views objects are
    * used. search_values holds both the search criteria and respective search value. 
    * values for search criteria can be seen below. They are the constants wih prefix g_search_pat.
    * The search values must be stored like this: i_search_values(g_search_pat_nhn) := 'DF9233381'
    * output is sent to global temporary table PAT_TMPTAB_SEARCH. In this initial version this table only holds the id_patient.
    * Other columns can be added according to specific needs. GTT used due to potentially huge number of result rows obtained.
    * 
    *  
    * @param i_lang             Language ID
    * @param i_prof             Professional Type
    * @param i_id_market        market id. used to contextualize search itself
    * @param i_search_values    associative array containing both search criteria and its search values
    * @param o_all_patients      indicates if an actual search was performed. Y= no search done. so no patient restrictions in the top search
    * @param o_error            Error data
    *
    * @return                   true or false on success or error
    *
    * @version  2.6
    * @data     08-02-2010
    * @author  Telmo
    */
    FUNCTION search_patients
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_market     IN market.id_market%TYPE,
        i_search_values IN pk_utils.hashtable_pls_integer,
        o_all_patients  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVE:   Return habit characterization values
       PARAMETERS:  IN:   I_LANG - Language ID
                          I_PROF - Professional data   
                    OUT:  O_HABIT_CHARACTERIZATION - Habit characterization values
                          O_ERROR - error
     
      CREATED: Sergio Dias 16-2-2011
    * @version 2.6.1.
    *********************************************************************************/
    FUNCTION get_habit_characterization
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_habit               IN habit.id_habit%TYPE,
        o_habit_characterization OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVE:   Return habit info: characterization and start date
       PARAMETERS:  IN:   I_LANG - Language ID
                          I_PROF - Professional data   
                    OUT:  O_HABIT_CHARACTERIZATION - Habit characterization values
                          O_ERROR - error
     
      CREATED: Sofia Mendes 2-2-2011
    * @version 2.6.2.
    *********************************************************************************/
    FUNCTION get_pat_habit_info
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_habit           IN pat_habit.id_pat_habit%TYPE,
        o_habit_characterization OUT pk_translation.t_desc_translation,
        o_start_date             OUT pk_translation.t_desc_translation,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a patient's national health service number.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               national health service number
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2012/02/08
    */
    FUNCTION get_nhs_number
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN pat_health_plan.num_health_plan%TYPE;

    /********************************************************************************************
    * Get habits associated to a list of given episodes
    *
    * @param i_lang              language id
    * @param i_pat               patient id
    * @param i_epis               episode id
    * @param i_prof              professional, software and institution ids
    * @param o_habit             array with info habits
    *
    * @param o_error             Error message
    *
    * @return                    true or false on success or error
    *
    * @author                    Sofia Mendes (code separated from pk_episode.get_summary_s)
    * @since                     21/03/2013
    ********************************************************************************************/
    FUNCTION get_habits
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN table_number,
        o_habit OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get list of episode (scope: patient/visit/episode)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_patient        patient id
    * @param i_id_episode        episode id
    * @param i_flg_visit_or_epis scope (E-Episode, V-visit, P-Patient)
    *
    * @return                    episode list 
    *
    * @author                    Jorge Silva
    * @since                     25/09/2013
    ********************************************************************************************/
    FUNCTION get_episode_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN pat_history_diagnosis.id_patient%TYPE,
        i_id_episode        IN pat_problem.id_episode%TYPE,
        i_flg_visit_or_epis IN VARCHAR2
    ) RETURN table_number;

    /********************************************************************************************
    * Get list of episode (scope: patient/visit/episode)
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_patient        patient id
    * @param i_id_episode        episode id
    * @param i_id_visit          visit id
    * @param i_flg_visit_or_epis scope (E-Episode, V-visit, P-Patient)
    *
    * @return                    episode list 
    *
    * @author                    Joel Lopes
    * @since                     08/01/2014
    ********************************************************************************************/
    FUNCTION get_episode_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN pat_history_diagnosis.id_patient%TYPE,
        i_id_episode        IN pat_problem.id_episode%TYPE,
        i_id_visit          IN visit.id_visit%TYPE,
        i_flg_visit_or_epis IN VARCHAR2
    ) RETURN table_number;

    /**
     * This function returns a true if the patient has any episode
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     *
     * @return   BOOLEAN
     *
     * @version  1.0
     * @since    2.5.2.7
     * @created  Jorge Silva
    */
    FUNCTION get_pat_has_any_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN;

    /**
     * This function returns a true if the patient has any episode not canceled
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     *
     * @return   BOOLEAN
     *
     * @version  1.0
     * @since    2.5.2.7
     * @created  Jorge Silva
    */
    FUNCTION get_pat_has_any_episode_active
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN;

    /**
     * This function returns a Y/N if patient is inactive
     *
     * @param    IN  i_lang            Language ID
     * @param    IN  i_prof            Professional structure
     * @param    IN  i_patient         Patient ID
     *
     * @return   Varchar
     *
     * @version  1.0
     * @since    2.6.4.3
     * @created  Jorge Silva
    */
    FUNCTION get_pat_has_inactive
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION has_arabic_name(i_patient IN patient.id_patient%TYPE) RETURN VARCHAR2;
    FUNCTION get_arabic_name(i_patient IN patient.id_patient%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
     * Gets patient/episode barcode
     *
     * @param i_lang          language id
     * @param i_prof          professional, software and institution ids
     * @param i_episode       episode id
    *********************************************************************************************/
    FUNCTION get_episode_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
     * Gets patient blood type for CDA
     *
     * @param i_lang          language id
     * @param i_prof          professional, software and institution ids
     * @param i_id_patient    patient ID
    *********************************************************************************************/
    FUNCTION tf_pat_blood_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_pat_blood_cda
        PIPELINED;

    /********************************************************************************************
    * Function that returns the patient job ID
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                Patient ID
    *
    * @return                         ID_OCUPATION
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          19/01/2017
    **********************************************************************************************/

    FUNCTION get_pat_job(i_id_pat IN patient.id_patient%TYPE) RETURN pat_job.id_occupation%TYPE;

    /********************************************************************************************
    * Function that returns Age type of a patient
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                Patient ID
    *
    * @return                         Type of age (Mi- Minutes/ H - Hour/D - Day/M - Months /Y - Years)
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          30/01/2017
    **********************************************************************************************/

    FUNCTION get_pat_age_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_date    IN episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function that returns the age in 
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                Patient ID
    * @param i_type                   Type of age (H - Hour/D - Day/M - Months /Y - Years)
    * 
    * @return                         age based on type
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          30/01/2017
    **********************************************************************************************/

    FUNCTION get_pat_age_num
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_type    IN VARCHAR2,
        i_view    IN VARCHAR2 DEFAULT 'N',
        i_date    IN episode.dt_end_tstz%TYPE DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION get_partial_pat_age
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_ne      IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;

    FUNCTION get_patient_ssn
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_bed_dept
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN drug_req.id_episode%TYPE
    ) RETURN department.id_department%TYPE;

    /**
    * FUNCTION get_alert_process_number 
    *
    * @param i_lang                        Language identification 
    * @param i_prof                        Professional data 
    * @param i_episode                     Episode id
    *
    * @return                              Return alert_process_number column value
    *
    * @raises                              PL/SQL generic error "OTHERS"
    *
    * @author                              Amanda Lee
    * @version                             V2.7.3.6
    * @since                               2018-07-03
    */
    FUNCTION get_alert_process_number
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN pat_identifier.alert_process_number%TYPE;

    FUNCTION ckeck_has_process_number
    (
        i_patient     IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR;

    FUNCTION get_patient_restricted_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_dt_birth
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN DATE;

    FUNCTION get_pat_preferred_language
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_marital_state
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_religion
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_address
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_process_number
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN pat_identifier.alert_process_number%TYPE;

    FUNCTION get_patient_phone
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_patient_docid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN pat_soc_attributes.document_identifier_number%TYPE;
    FUNCTION get_pat_health_plan
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
        
    ) RETURN VARCHAR2;
    FUNCTION get_pat_hplan_entity
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
        
    ) RETURN VARCHAR2;

    /**
    * Get the patient name for professionals who do not need to have responsibility (example: pharmacist)
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               patient's name
    */
    FUNCTION get_pat_name_without_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_schedule      IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_sys_config IN sys_config.id_sys_config%TYPE DEFAULT 'PATIENT_NAME_PATTERN'
    ) RETURN patient.name%TYPE;

    FUNCTION get_patient_minimal_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_scholarship
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    FUNCTION get_pat_country_birth
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pat_occupation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    
    FUNCTION get_pat_race
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    
        FUNCTION get_pat_job_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
        FUNCTION get_pat_job_company
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;    
    /**######################################################
      GLOBAIS
    ######################################################**/
    g_error        VARCHAR2(4000);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;
    g_sysdate_char VARCHAR2(50);

    --
    g_patient_active           CONSTANT patient.flg_status%TYPE := 'A';
    g_pat_necess_active_config CONSTANT pat_necessity.flg_status%TYPE := 'A';
    g_pat_necess_active        CONSTANT pat_necessity.flg_status%TYPE := 'R';
    g_pat_hplan_active         CONSTANT pat_health_plan.flg_status%TYPE := 'A';
    g_pat_hplan_flg_default_no CONSTANT pat_health_plan.flg_default%TYPE := 'N';
    g_pat_job_active           CONSTANT pat_job.flg_status%TYPE := 'A';
    g_pat_doc_active           CONSTANT pat_doc.flg_status%TYPE := 'A';
    g_clin_rec_active          CONSTANT clin_record.flg_status%TYPE := 'A';

    g_epis_diag_passive CONSTANT epis_diagnosis.flg_type%TYPE := 'P';

    g_pat_allergy_active    CONSTANT pat_allergy.flg_status%TYPE := 'A';
    g_pat_allergy_passive   CONSTANT pat_allergy.flg_status%TYPE := 'P';
    g_pat_allergy_cancel    CONSTANT pat_allergy.flg_status%TYPE := 'C';
    g_pat_allergy_available CONSTANT allergy.flg_available%TYPE := 'Y';

    g_pat_allergy_all CONSTANT pat_allergy.flg_type%TYPE := 'A';
    --g_pat_allergy_reac CONSTANT pat_allergy.flg_type%TYPE := 'I';

    --g_pat_allergy_doc CONSTANT pat_allergy.flg_aproved%TYPE := 'M';
    g_pat_allergy_pat CONSTANT pat_allergy.flg_aproved%TYPE := 'U';

    g_flg_pesq CONSTANT VARCHAR2(1) := 'P';

    g_pat_probl_active  CONSTANT pat_problem.flg_status%TYPE := 'A';
    g_pat_probl_passive CONSTANT pat_problem.flg_status%TYPE := 'P';
    g_pat_probl_cancel  CONSTANT pat_problem.flg_status%TYPE := 'C';

    g_pat_note_flg_active CONSTANT pat_notes.flg_status%TYPE := 'A';
    g_pat_note_flg_cancel CONSTANT pat_notes.flg_status%TYPE := 'C';

    g_necess_avail      CONSTANT necessity.flg_available%TYPE := 'Y';
    g_pat_hplan_default CONSTANT pat_health_plan.flg_default%TYPE := 'Y';
    g_doc_avail         CONSTANT doc_type.flg_available%TYPE := 'Y';
    g_hplan_avail       CONSTANT health_plan.flg_available%TYPE := 'Y';

    g_pat_necess_inactive CONSTANT VARCHAR2(1) := 'I';

    g_pat_habit_canc        CONSTANT pat_habit.flg_status%TYPE := 'C';
    g_pat_habit_active      CONSTANT pat_habit.flg_status%TYPE := 'A';
    g_pat_fam_soc_hist_canc CONSTANT pat_fam_soc_hist.flg_status%TYPE := 'C';
    g_pat_fam_soc_hist_act  CONSTANT pat_fam_soc_hist.flg_status%TYPE := 'A';

    g_pat_blood_active   CONSTANT pat_blood_group.flg_status%TYPE := 'A';
    g_pat_blood_inactive CONSTANT pat_blood_group.flg_status%TYPE := 'I';
    g_pat_blood_cancel   CONSTANT pat_blood_group.flg_status%TYPE := 'C';

    g_pat_prob_allrg CONSTANT VARCHAR2(1) := 'A';
    g_pat_prob_prob  CONSTANT VARCHAR2(1) := 'P';

    -- to execute dynamic pl/sql blocks with table metadata. Used to 
    g_patient_row            patient%ROWTYPE;
    g_pat_soc_attributes_row pat_soc_attributes%ROWTYPE;
    g_pat_job_row            pat_job%ROWTYPE;
    g_pat_cli_attributes_row pat_cli_attributes%ROWTYPE;
    g_clin_record_row        clin_record%ROWTYPE;
    g_pat_health_plan_row    pat_health_plan%ROWTYPE;
    g_doc_external_row       doc_external%ROWTYPE;

    g_date_convert_pattern CONSTANT VARCHAR2(50) := 'YYYYMMDD';
    --
    g_diag_type_p CONSTANT pat_history.flg_type%TYPE := 'P';
    --g_diag_type_d CONSTANT pat_history.flg_type%TYPE := 'D';
    g_diag_type_b CONSTANT pat_history.flg_type%TYPE := 'B';
    --
    g_ph_flg_status_ca CONSTANT pat_history.flg_status%TYPE := 'C'; -- cancelar
    g_ph_flg_status_d  CONSTANT pat_history.flg_status%TYPE := 'D'; --despiste(ampulheta)
    g_ph_flg_status_co CONSTANT pat_history.flg_status%TYPE := 'F'; --confirmar
    g_ph_flg_status_r  CONSTANT pat_history.flg_status%TYPE := 'R'; --declinar(-)
    g_ph_flg_status_b  CONSTANT pat_history.flg_status%TYPE := 'B'; --Diagnóstico base
    g_ph_flg_status_a  CONSTANT pat_history.flg_status%TYPE := 'A'; --Activo
    --
    g_ph_type_hist_m CONSTANT pat_history.flg_type_hist%TYPE := 'M';
    g_ph_type_hist_c CONSTANT pat_history.flg_type_hist%TYPE := 'C';
    g_ph_type_hist_f CONSTANT pat_history.flg_type_hist%TYPE := 'F';
    --g_ph_type_hist_s CONSTANT pat_history.flg_type_hist%TYPE := 'S';
    --
    g_pat_hist_status CONSTANT sys_domain.code_domain%TYPE := 'PAT_HISTORY.FLG_STATUS';
    --
    g_mov_n       CONSTANT necessity.flg_mov%TYPE := 'N';
    g_pat_nec_act CONSTANT pat_necessity.flg_status%TYPE := 'A';
    --
    g_necessity_y CONSTANT sys_config.value%TYPE := 'Y';
    g_necessity_a CONSTANT sys_config.value%TYPE := 'A';
    g_companion sys_config.value%TYPE;

    g_pat_history_diagnosis_n CONSTANT VARCHAR2(1) := 'N';

    g_allergy_avail  CONSTANT allergy.flg_available%TYPE := 'Y';
    g_allergy_active CONSTANT allergy.flg_active%TYPE := 'A';

    g_all_software    CONSTANT software.id_software%TYPE := 0;
    g_all_institution CONSTANT institution.id_institution%TYPE := 0;

    --Migration
    g_patient_alert CONSTANT VARCHAR(1) := 'A';
    --g_patient_migration CONSTANT VARCHAR(1) := 'M';
    --g_patient_test      CONSTANT VARCHAR(1) := 'T';
    --

    g_flg_status_a CONSTANT VARCHAR2(1) := 'A';
    g_flg_status_c CONSTANT VARCHAR2(1) := 'C';
    g_flg_status_r CONSTANT VARCHAR2(1) := 'R';
    g_flg_status_i CONSTANT VARCHAR2(1) := 'I';
    g_flg_status_o CONSTANT VARCHAR2(1) := 'O';
    g_flg_status_p CONSTANT VARCHAR2(1) := 'P';

    g_habit_review_area      review_detail.flg_context%TYPE := '';
    g_blood_type_review_area review_detail.flg_context%TYPE := '';

    g_package_name  VARCHAR2(200);
    g_package_owner VARCHAR2(200);

    -- search criteria
    g_search_pat_bsn           CONSTANT NUMBER(2) := 1;
    g_search_pat_ssn           CONSTANT NUMBER(2) := 2;
    g_search_pat_nhn           CONSTANT NUMBER(2) := 3;
    g_search_pat_recnum        CONSTANT NUMBER(2) := 4;
    g_search_pat_birthdate     CONSTANT NUMBER(2) := 5;
    g_search_pat_gender        CONSTANT NUMBER(2) := 6;
    g_search_pat_surnameprefix CONSTANT NUMBER(2) := 7;
    g_search_pat_surnamemaiden CONSTANT NUMBER(2) := 8;
    g_search_pat_names         CONSTANT NUMBER(2) := 9;
    g_search_pat_initials      CONSTANT NUMBER(2) := 10;
    g_search_pat_pat_id        CONSTANT NUMBER(2) := 11;

    g_pat_gender_male   CONSTANT patient.gender%TYPE := 'M';
    g_pat_gender_female CONSTANT patient.gender%TYPE := 'F';

    g_scope_patient CONSTANT VARCHAR2(1) := 'P';
    g_scope_visit   CONSTANT VARCHAR2(1) := 'V';
    g_scope_episode CONSTANT VARCHAR2(1) := 'E';

    g_conf_barcode_pat_major_inc CONSTANT sys_config.id_sys_config%TYPE := 'BARCODE_PATIENT_MAJOR_INC';
    g_conf_barcode_patient       CONSTANT sys_config.id_sys_config%TYPE := 'BARCODE_PATIENT';

    g_has_error BOOLEAN;

    g_flg_type_birth_si CONSTANT patient.flg_type_dt_birth%TYPE := 'SI';
    g_flg_type_birth_ne CONSTANT patient.flg_type_dt_birth%TYPE := 'NE';
    g_flg_type_birth_f  CONSTANT patient.flg_type_dt_birth%TYPE := 'F';

    g_flg_level_dt_birth_y CONSTANT patient.flg_level_dt_birth%TYPE := 'Y';
    g_flg_level_dt_birth_m CONSTANT patient.flg_level_dt_birth%TYPE := 'M';
    g_flg_level_dt_birth_d CONSTANT patient.flg_level_dt_birth%TYPE := 'D';
    g_flg_level_dt_birth_h CONSTANT patient.flg_level_dt_birth%TYPE := 'H';

    g_flg_ssn_status_d CONSTANT person.flg_ssn_status%TYPE := 'D'; --VALUE
    g_flg_ssn_status_e CONSTANT person.flg_ssn_status%TYPE := 'E'; -- Unavailable - Foreign patient
    g_flg_ssn_status_u CONSTANT person.flg_ssn_status%TYPE := 'U'; --Unavailable - Unknown
    g_flg_ssn_status_n CONSTANT person.flg_ssn_status%TYPE := 'N'; -- NOT AVAILABLE

    FUNCTION get_pat_age_to_sort(i_patient IN NUMBER) RETURN NUMBER;

END pk_patient;
/
