/*-- Last Change Revision: $Rev: 2028902 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ref_api AS

    /**
    * Insert/Update table REF_ORG_DATA 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_ref_orig_data ref_orig_data%ROWTYPE
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */

    FUNCTION set_ref_orig_data
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_ref_orig_data IN ref_orig_data%ROWTYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the referral workflow identifier
    *
    * @param   i_lang     Language identifier
    * @param   i_prof     Professional id, institution and software
    * @param   i_ext_req  Referral identifier       
    * @param   o_ref_wf   Referral workflow identifier
    * @param   o_error    An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   11-01-2010
    *
    FUNCTION get_ref_workflow
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ext_req IN p1_external_request.id_external_request%TYPE,
        o_ref_wf  OUT p1_external_request.id_workflow%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert/Update table P1_DETAIL 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_p1_detail p1_detail to insert/update
    * @param   o_id_detail id_p1_detail to insert
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */

    FUNCTION set_p1_detail
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN profissional,
        i_p1_detail IN p1_detail%ROWTYPE,
        o_id_detail OUT p1_detail.id_detail%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert/Update table P1_TASK_DONE 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   o_id_p1_task_done p1_task_done to insert/update
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */

    FUNCTION set_p1_task_done
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_p1_task_done IN p1_task_done%ROWTYPE,
        o_id_task_done OUT p1_task_done.id_task_done%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert/Update table P1_EXR_DIAGNOSIS 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   o_id_p1_exr_diagnosis p1_exr_diagnosis to insert/update
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION set_p1_exr_diagnosis
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_p1_exr_diagnosis    IN p1_exr_diagnosis%ROWTYPE,
        o_id_p1_exr_diagnosis OUT p1_exr_diagnosis.id_exr_diagnosis%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Inserts/Updates table REF_MAP 
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional id, institution and software
    * @param   i_ref_map    Record data to insert or update
    * @param   o_id_ref_map Identifiers created/changed
    * @param   o_error      An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-10-2009
    */
    FUNCTION set_ref_map
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_ref_map    IN ref_map%ROWTYPE,
        o_id_ref_map OUT ref_map.id_ref_map%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Update column flg_migrated ( table p1_external_request)
    * Used when BDNP interface is available ALERT-191066
    *
    * @param  I_LANG                 Language associated to the professional executing the request
    * @param  I_PROF                 Professional id, institution and software    
    * @param  i_id_external_request  Referral identifier
    * @param  i_flg_migrated         Flag indicating if it was migrated
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   18-8-2011
    */
    FUNCTION set_referral_flg_migrated
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_flg_migrated        IN p1_external_request.flg_migrated%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    
    /**
    * Creates an active REF_MAP record 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_schedule    Schedule identifier
    * @param   i_id_episode     Episode identifier
    * @param   o_id_ref_map     REF_MAP identifier     
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-12-2009
    */
    FUNCTION create_ref_map
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN ref_map.id_external_request%TYPE,
        i_id_schedule IN ref_map.id_schedule%TYPE DEFAULT NULL,
        i_id_episode  IN ref_map.id_episode%TYPE,
        o_id_ref_map  OUT ref_map.id_ref_map%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels REF_MAP record 
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional id, institution and software
    * @param   i_ref_map    Record data 
    * @param   o_error      An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-11-2009
    */
    FUNCTION cancel_ref_map
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_ref_map_row IN ref_map%ROWTYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a record in table REF_MIG_INST_DEST
    *
    * @param   i_lang                         Language associated to the professional executing the request
    * @param   i_prof                         Professional id, institution and software
    * @param   i_id_ref                       Referral identifier
    * @param   i_id_inst_dest_new             New destination institution identifier
    * @param   i_flg_result                   Flag indicating if the referral was successfully migrated
    * @param   i_dt_create                    Migration date     
    * @param   i_error_desc                   Error description (in case the migration was not successful)
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-06-2012
    */
    FUNCTION create_ref_mig_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_ref           IN ref_mig_inst_dest.id_external_request%TYPE,
        i_id_inst_dest_new IN ref_mig_inst_dest.id_inst_dest_new%TYPE,
        i_flg_result       IN ref_mig_inst_dest.flg_result%TYPE,
        i_dt_create        IN ref_mig_inst_dest.dt_create%TYPE DEFAULT current_timestamp,
        i_error_desc       IN ref_mig_inst_dest.error_desc%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates FLG_PROCESSED in table REF_MIG_INST_DEST_DATA
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_inst_dest   Destination institution identifier
    * @param   i_flg_processed  Flag indicating if the referral was successfully processed or not
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-09-2012
    */
    FUNCTION set_ref_mig_inst_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN ref_mig_inst_dest_data.id_external_request%TYPE,
        i_id_inst_dest  IN ref_mig_inst_dest_data.id_inst_dest%TYPE,
        i_flg_processed IN ref_mig_inst_dest_data.flg_processed%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert/Update table p1_specaility 
    *
    * @param   i_lang                         language associated to the professional executing the request
    * @param   i_id_speciality                p1_specaility to insert/update
    * @param   i_id_content                   p1_specaility to insert/update
    * @param   i_id_parent                    p1_specaility to insert/update        
    * @param   i_id_parent                    p1_specaility to insert/update
    * @param   i_id_parent                    p1_specaility to insert/update
    * @param   i_id_parent                    p1_specaility to insert/update    
    * @param   o_p1_specaility p1_specaility to insert/update
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   24-01-2011
    */
    FUNCTION set_p1_speciality
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_id_speciality IN p1_speciality.id_speciality%TYPE,
        i_id_content    IN p1_speciality.id_content%TYPE,
        i_id_parent     IN p1_speciality.id_parent%TYPE,
        i_flg_available IN p1_speciality.flg_available%TYPE DEFAULT 'Y',
        i_gender        IN p1_speciality.gender%TYPE,
        i_age_min       IN p1_speciality.age_min%TYPE,
        i_age_max       IN p1_speciality.age_max%TYPE,
        i_trans_array   IN table_table_varchar,
        o_id_spec       OUT p1_speciality.id_speciality%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_prof_data      Professional data    
    * @param   i_id_ref         Referral identifier
    * @param   i_id_ref_comment Referral comment id
    * @param   i_text           Text comment
    * @param   i_flg_status     Comment status
    * @param   i_dt_comment     Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    **/

    FUNCTION set_ref_comments
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_text           IN CLOB,
        i_flg_status     IN ref_comments.flg_status%TYPE,
        i_dt_comment     IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set Referral comments read 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref_comment   
    * @param   i_flg_status
    * @param   i_flg_type
    * @param   i_read    
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   18-07-2013
    **/

    FUNCTION set_ref_comments_read
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_ref_comment      IN ref_comments.id_ref_comment%TYPE,
        i_flg_status          IN ref_comments.flg_status%TYPE,
        i_flg_type            IN ref_comments.flg_type%TYPE,
        i_read                IN OUT BOOLEAN,
        o_id_ref_comment_read OUT ref_comments_read.id_ref_comment_read%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Indicates for each MCDT, whether it is a chronic disease or not (FLG_ALD)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ref            Referral identifier    
    * @param   i_mcdt_ald       Chronic disease information for each MCDT (FLG_ALD) [id_mcdt|id_sample_type|flg_ald]
    * @param   o_p1_exr_temp    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-09-2012
    */
    FUNCTION set_p1_exr_flg_ald
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ref         IN p1_external_request.id_external_request%TYPE,
        i_mcdt_ald    IN table_table_varchar,
        o_p1_exr_temp OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ref_exam_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_ref_lab_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_ref_ot_ex_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_ref_proc_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

	
END pk_ref_api;
/
