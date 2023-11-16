/*-- Last Change Revision: $Rev: 1647578 $*/
/*-- Last Change by: $Author: mario.mineiro $*/
/*-- Date of last change: $Date: 2014-10-17 15:51:38 +0100 (sex, 17 out 2014) $*/

CREATE OR REPLACE PACKAGE pk_api_patient IS

    -- Author  : Rui Spratley
    -- Created : 23-05-2008
    -- Purpose : API for INTER_ALERT

    SUBTYPE obj_name IS VARCHAR2(30 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    TYPE rec_pat_ext_sys IS RECORD(
        id_patient            pat_ext_sys.id_patient%TYPE,
        id_ext_patient        pat_ext_sys.VALUE%TYPE,
        id_ext_system         pat_ext_sys.id_external_sys%TYPE,
        id_health_institution pat_ext_sys.id_institution%TYPE,
        desc_ext_system       VARCHAR2(200 CHAR));

    TYPE t_tbl_pat_ext IS TABLE OF rec_pat_ext_sys INDEX BY VARCHAR2(50 CHAR);

    TYPE rec_patient IS RECORD(
        id_patient             patient.id_patient%TYPE,
        complete_name          patient.name%TYPE,
        last_name              patient.last_name%TYPE,
        nick_name              patient.nick_name%TYPE,
        middle_name            patient.middle_name%TYPE,
        dt_birth               patient.dt_birth%TYPE,
        gender                 patient.gender%TYPE,
        marital_status         pat_soc_attributes.marital_status%TYPE,
        address                pat_soc_attributes.address%TYPE,
        city                   pat_soc_attributes.location%TYPE,
        state                  pat_soc_attributes.district%TYPE,
        postal_code            pat_soc_attributes.zip_code%TYPE,
        postal_seq             NUMBER,
        id_country             pat_soc_attributes.id_country_address%TYPE,
        id_country_nation      pat_soc_attributes.id_country_nation%TYPE,
        desc_country           country.code_country%TYPE,
        num_main_contact       pat_soc_attributes.num_main_contact%TYPE,
        num_contact            pat_soc_attributes.num_contact%TYPE,
        flg_job_status         pat_soc_attributes.flg_job_status%TYPE,
        father_name            pat_soc_attributes.father_name%TYPE,
        mother_name            pat_soc_attributes.mother_name%TYPE,
        id_isencao             pat_soc_attributes.id_isencao%TYPE,
        dt_isencao             pat_soc_attributes.dt_isencao%TYPE,
        id_scholarship         pat_soc_attributes.id_scholarship%TYPE,
        id_religion            pat_soc_attributes.id_religion%TYPE,
        num_contrib            pat_soc_attributes.num_contrib%TYPE,
        desc_geo_state         pat_soc_attributes.desc_geo_state%TYPE,
        birth_place            pat_soc_attributes.birth_place%TYPE,
        id_professional        professional.id_professional%TYPE,
        id_institution         institution.id_institution%TYPE,
        num_clin_record        clin_record.num_clin_record%TYPE,
        id_instit_enroled      clin_record.id_instit_enroled%TYPE,
        id_health_plan         pat_health_plan.id_health_plan%TYPE,
        num_health_plan        pat_health_plan.num_health_plan%TYPE,
        id_software            software.id_software%TYPE,
        id_recm                pat_cli_attributes.id_recm%TYPE,
        dt_val_recm            pat_cli_attributes.dt_val_recm%TYPE,
        mobil                  NUMBER,
        dt_mobil               patient_care_inst.dt_begin_tstz%TYPE,
        id_occupation          pat_job.id_pat_job%TYPE,
        dt_pat_job_tstz        pat_job.dt_pat_job_tstz%TYPE,
        occupation_desc        pat_job.occupation_desc%TYPE,
        id_prof_family         pat_family_prof.id_professional%TYPE,
        pat_ext                t_tbl_pat_ext,
        social_security_number doc_external.num_doc%TYPE,
        flg_state              clin_record.flg_status%TYPE);

    /*
    * return patients short name.
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_id_pat            patient identifier
    *
    * @return  patient short name, null if not available
    *
    * @author  rui spratley
    * @version 2.4.3
    * @since   2008/05/23
    *
    */
    FUNCTION intf_get_pat_short_name(i_id_pat IN patient.id_patient%TYPE) RETURN VARCHAR2;

    /*
    * cancel patients allergy.
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_id_pat_allergy    patients allergy identifier
    * @param   i_id_prof           profissional
    * @param   i_notes             notes
    * @param   o_error             error message
    *
    * @return                    true if everything was ok. false otherwise.
    *
    * @author  rui spratley
    * @version 2.4.3
    * @since   2008/05/23
    *
    */
    FUNCTION intf_cancel_pat_allergy
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_prof           IN profissional,
        i_notes          IN pat_allergy.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * create patients allergy records.
    *
    * @param   i_lang              language associated to the professional executing the request
    * @param   i_epis              patients allergy identifier
    * @param   i_prof              Profissional
    * @param   i_allergy           Allergy
    * @param   i_allergy_cancel    Allergy to cancel
    * @param   i_status            Status: A-Active; C-Canceled; P-Passive
    * @param   i_notes             notes
    * @param   i_dt_symptoms       Aprox. date of problem start. String with format YYYY-MM-DD that is converted after.
    * @param   i_type              I - reacção idiossincrática, A - allergy
    * @param   i_approved          U-Related by patient / M-Clinicaly comproved
    * @param   i_prof_cat_type     Professional category
    * @param   o_flg_show          Shows message (Y/N)
    * @param   o_msg_title         Title to show if o_flg_show=Y
    * @param   o_msg               Text to show if o_flg_show=Y
    * @param   o_button            button to show: N-No; R-Read; C-Confirmed. Can also show combinations of more than one button
    * @param   o_error             error message
    *
    * @return                    true if everything was ok. false otherwise.
    *
    * @author  rui spratley
    * @version 2.4.3
    * @since   2008/05/23
    *
    */
    FUNCTION intf_create_pat_allergy_array
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
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

    /********************************************************************************************
    * Create patients institution history.
    *
    * @param i_lang                language id
    * @param i_patient             patient id
    * @param i_institution         institution id
    * @param i_reason_type         reason type
    * @param i_reason              reason
    * @param i_dt_begin            begin date
    * @param i_institution_enroled institution enroled id
    * @param i_software            software id
    * @param o_error               Error message
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Paulo Fonseca
    * @since                       2009/05/28
    * @version                     2.5
    ********************************************************************************************/
    FUNCTION intf_update_patient_care_inst
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_patient             IN patient_care_inst.id_patient%TYPE,
        i_institution         IN patient_care_inst.id_institution%TYPE,
        i_reason_type         IN patient_care_inst.reason_type%TYPE,
        i_reason              IN patient_care_inst.reason%TYPE,
        i_dt_begin            IN patient_care_inst.dt_begin_tstz%TYPE,
        i_institution_enroled IN patient_care_inst.id_institution_enroled%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create patient family.
    *
    * i_lang                   language id
    * i_id_professional        professional id
    * i_id_institution         institution id
    * i_id_software            software id
    * i_num_clin_record        clin record id
    * i_id_instit_enroled      institution enroled id
    * i_id_prof_family         professional family id
    * i_complete_name          complete name
    * i_address                address
    * i_postal_code            postal code
    * i_city                   city
    * i_id_patient             patient id
    * i_episode                episode id
    * i_num_family_record      family record number
    *
    * @return                      true (sucess), false (error)
    *
    * @author                      Sérgio Santos (based on pk_pfh_interface.create_family)
    * @since                       2009/05/29
    * @version                     2.5
    ********************************************************************************************/
    FUNCTION intf_create_pat_family
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_id_professional   IN professional.id_professional%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_software       IN software.id_software%TYPE,
        i_num_clin_record   IN clin_record.num_clin_record%TYPE,
        i_id_instit_enroled IN clin_record.id_instit_enroled%TYPE,
        i_id_prof_family    IN pat_family_prof.id_professional%TYPE,
        i_complete_name     IN patient.name%TYPE,
        i_address           IN pat_soc_attributes.address%TYPE,
        i_postal_code       IN pat_soc_attributes.zip_code%TYPE,
        i_city              IN pat_soc_attributes.location%TYPE,
        i_id_patient        IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_num_family_record IN pat_family.num_family_record%TYPE,
        o_id_pat_family     OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function patient blood type
    *
    * @param      i_lang            Prefered language
    * @param      i_epis            Episode id
    * @param      i_id_pat          Patient id
    * @param      i_flg_group       Blood group
    * @param      i_flg_rh          Rhesus factor
    * @param      i_desc_other      Other information
    * @param      i_prof            Profissional, institution and software id's
    * @param      i_prof_cat_type   Professional category
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Fonseca
    * @version    2.5.0
    * @since      2010/01/19
    ************************************************************************************************************/
    FUNCTION intf_set_pat_blood
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_id_pat        IN patient.id_patient%TYPE,
        i_flg_group     IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh        IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other    IN pat_blood_group.desc_other_system%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function patient blood type
    *
    * @param      i_lang                  Prefered language
    * @param      i_epis                  Episode id
    * @param      i_id_pat                Patient id
    * @param      i_flg_group             Blood group
    * @param      i_flg_rh                Rhesus factor
    * @param      i_desc_other            Other information
    * @param      i_prof                  Profissional, institution and software id's
    * @param      i_prof_cat_type         Professional category
    * @param      i_dt_pat_blood_group    Date of blood group registry
    * @param      o_error                 Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Rui Duarte
    * @version    2.6.0.3.4
    * @since      2010-Nov-25
    ************************************************************************************************************/
    FUNCTION intf_set_pat_blood
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_epis               IN episode.id_episode%TYPE,
        i_id_pat             IN patient.id_patient%TYPE,
        i_flg_group          IN pat_blood_group.flg_blood_group%TYPE,
        i_flg_rh             IN pat_blood_group.flg_blood_rhesus%TYPE,
        i_desc_other         IN pat_blood_group.desc_other_system%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_pat_blood_group IN pat_blood_group.dt_pat_blood_group_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * Return the patient active health plan
    *
    * @param      i_lang            Prefered language
    * @param      i_epis            Episode id
    * @param      i_id_pat          Patient id
    * @param      i_prof            Profissional, institution and software id's
    *
    * @param      o_hplan           Health plan info
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Sérgio Santos
    * @version    2.5.0.7.8
    * @since      2010/05/05
    ************************************************************************************************************/
    FUNCTION intf_get_pat_hplan
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_epis        IN episode.id_episode%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_hplan_out   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Update patient with the new id patient
    *
    * @param   i_old_id_patient    
    * @param   i_new_id_patient    
    * @param   o_error             error message
    *
    * @return                    true if everything was ok. false otherwise.
    *
    * @author  Mário Mineiro
    * @version 2.6.3.10.1
    * @since   2008/05/23
    *
    */
    FUNCTION intf_update_patient
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_old_id_patient IN patient.id_patient%TYPE,
        i_new_id_patient IN patient.id_patient%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patient_profs
    (
        i_id_institution IN NUMBER,
        i_id_patient     IN sch_group.id_patient%TYPE,
        o_result         OUT t_search_profs,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- log mechanism
    g_log_object_owner obj_name;
    g_log_object_name  obj_name;
    g_exception EXCEPTION;
    g_error VARCHAR2(2000);
END pk_api_patient;
/
