/*-- Last Change Revision: $Rev: 2028492 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_referral IS

    -- Author  : JOANA.BARROSO
    -- Created : 11-10-2010 16:22:56
    -- Purpose : 

    -- Public type declarations

    TYPE ref_detail_cur IS TABLE OF pk_ref_ext_sys.ref_detail_rec;
    TYPE ref_cur IS TABLE OF pk_ref_ext_sys.ref_rec;

    /*
    * Get Referral short detail (Patient Portal)
    *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_pat                 Paciente id
    * @param i_id_external_request Referral id
    * @param o_detail              Referral detail
    * @param o_id_content          Content Id    
    
    * @param o_error               Error
    *
    * @return  true if sucess, false otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-10-2010
    */
    FUNCTION get_referral
    (
        i_lang                IN language.id_language%TYPE,
        i_id_group            IN institution_group.id_group%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get Referral short detail (Patient Portal)
    *
    * @param i_lang                Language id
    * @param i_prof                Professional, Institution and Software ids
    * @param i_pat                 Paciente id
    * @param i_num_req             Referral num_req 
    * @param o_detail              Referral detail
    * @param o_id_content          Content Id    
    * @param o_error               Error
    *
    * @return  true if sucess, false otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   06-10-2010
    */

    FUNCTION get_referral
    (
        i_lang     IN language.id_language%TYPE,
        i_id_group IN institution_group.id_group%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_num_req  IN p1_external_request.num_req%TYPE,
        o_detail   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_referral_list
    (
        i_lang     IN language.id_language%TYPE,
        i_id_group IN institution_group.id_group%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        o_ref_list OUT pk_ref_ext_sys.ref_cur,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_referrals_to_schedule
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_inst_dest_list IN table_number,
        i_ref_type       IN table_varchar,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_dt_schedule    IN schedule.dt_schedule_tstz%TYPE,
        o_ref_list       OUT pk_ref_ext_sys.ref_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Import Requests registed in SONHO
    *
    * @param   I_LANG                 Language associated to the professional executing the request
    * @param   I_PROF                 Professional id, institution and software    
    * @param   I_PAT                  Patient id (NOT NULL)
    * @param   I_INST_ORIG            Origin Ext Code institution    
    * @param   I_ID_DEP_CLIN_SERV     Id department/clinical_service (NOT NULL)
    * @param   I_FLG_TYPE             Referral type: {*} (C)onsultation {*} (A)nalisys {*} (I)mage {*} (E)xam {*} (P) Intervention {*} (F)Mfr  (NOT NULL)
    * @param   I_FLG_PRIORITY         Referral priority flag: {*} Y - urgent {*} N - otherwise
    * @param   I_FLG_HOME             Referral home flag: {*} Y - home {*} N - otherwise
    * @param   I_FLG_STATUS           Referral status: {*} (I)ssued {*} (T)riage {*} (A)ccepted {*} (S)cheduled (NOT NULL)
    * @param   I_DECISION_URG_LEVEL   Referral triage level (NOT NULL if I_FLG_STATUS in ('A','S')
    * @param   I_APPOITMENT_DATE      Appoitment's date/hour (NOT NULL if flg_status = 'S')
    * @param   I_NUM_ORDER_SCH        Scheduled consultation professional num order   
    * @param   I_PROF_NAME_SCH        Scheduled consultation professional name
    * @param   I_EXT_REFERENCE        External reference    
    * @param   I_JUSTIFICATION        Referral justification (NOT NULL)
    * @param   I_DT_ISSUED            Referral issued date (NOT NULL)
    * @param   i_dt_triage            Referral triaged date (NOT NULL if I_FLG_STATUS in ('T','A','S')
    * @param   i_dt_accepted          Referral accepted date (NOT NULL if I_FLG_STATUS in ('A','S')   
    * @param   i_dt_scheduled         Referral scheduled date (NOT NULL if I_FLG_STATUS in ('S')
    * @param   I_SEQ_NUM              Match sequential number
    * @param   I_CLIN_REC             Clinical record number
    * @param   I_INST_NAME            Origin institution name   (Referral Detail)
    * @param   I_PROF_NAME            Origin professional name (Referral Detail)
    *
    * @param   O_ID_EXTERNAL_REQUEST  Referral id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   11-11-2010
    */

    FUNCTION import_referral
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat                 IN patient.id_patient%TYPE,
        i_inst_orig           IN institution.ext_code%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE, -- not null
        i_flg_type            IN p1_external_request.flg_type%TYPE,
        i_flg_priority        IN p1_external_request.flg_priority%TYPE,
        i_flg_home            IN p1_external_request.flg_home%TYPE,
        i_flg_status          IN p1_external_request.flg_status%TYPE, -- not null
        i_decision_urg_level  IN p1_external_request.decision_urg_level%TYPE,
        i_appoitment_date     IN TIMESTAMP WITH TIME ZONE,
        i_num_order_sch       IN professional.num_order%TYPE,
        i_prof_name_sch       IN professional.name%TYPE,
        i_ext_reference       IN p1_external_request.ext_reference%TYPE,
        i_justification       IN table_varchar,
        i_dt_issued           IN TIMESTAMP WITH TIME ZONE,
        i_dt_triage           IN TIMESTAMP WITH TIME ZONE,
        i_dt_accepted         IN TIMESTAMP WITH TIME ZONE,
        i_dt_scheduled        IN TIMESTAMP WITH TIME ZONE,
        i_seq_num             IN p1_match.sequential_number%TYPE,
        i_clin_rec            IN clin_record.num_clin_record%TYPE,
        i_inst_name           IN pk_translation.t_desc_translation,
        i_prof_name           IN professional.name%TYPE,
        o_id_external_request OUT p1_external_request.id_external_request%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Migrate a referral to a different dest institution
    * This function has COMMITs/ROLLBACKs
    *
    * @param   i_default_dcs       Indicates if dep_clin_serv is mapped or calculated by default
    * @param   i_notes             Notes associated to the migration
    * @param   o_error             An error message, set when return=false
    *
    * @value   i_default_dcs       {*} Y- calculated by default for the referral speciality {*} N- calculated from table MAP
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   14-06-2012
    */
    FUNCTION mig_ref_dest_institution
    (
        i_default_dcs IN VARCHAR2 DEFAULT pk_ref_constant.g_yes,
        i_notes       IN VARCHAR2 DEFAULT NULL,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_referral;
/
