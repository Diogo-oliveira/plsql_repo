/*-- Last Change Revision: $Rev: 1446789 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2013-02-28 10:06:02 +0000 (qui, 28 fev 2013) $*/
CREATE OR REPLACE PACKAGE pk_api_ref_event AS

    /**
    * Notify inter-alert of referral update    
    * 
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_id_ref             Referral identifier
    * @param i_id_inst            Institution where the referral was changed
    *
    * @author  Ana Monteiro
    * @version 2.6
    * @since   2010-10-21   
    */
    PROCEDURE set_ref_update
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_ref     IN p1_external_request.id_external_request%TYPE,
        i_flg_status IN p1_external_request.flg_status%TYPE,
        i_id_inst    IN p1_external_request.id_inst_dest%TYPE
    );

    /**
    * Check if referral has changed:    
    *  - Referral is issued to dest institution
    *  - Referral is canceled
    *  - Referral is blocked
    *  - Referral is unblocked
    *  - Referral is scheduled
    *  - Referral is declined by physician (including clinical director)
    *  - Referral is refused by physician
    *  - Referral is executed
    *  - Patient referral is missed
    *  - Referral is triaged
    *  - Clinical service change
    *  - Referral is sent to triage
    *  - Referral is declined bureaucratic
    *  - Referral schedule is canceled
    *  - Referral is approved/not approved by clinical director
    * 
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_track_old_row      Referral tracking old rowtype (before update)
    * @param i_track_new_row      Referral tracking new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.5
    * @since   2010-05-15   
    */
    PROCEDURE set_tracking
    (
        i_event         IN NUMBER,
        i_track_old_row IN p1_tracking%ROWTYPE,
        i_track_new_row IN p1_tracking%ROWTYPE
    );

    /**
    * Check if referral has changed:
    *  - Documents associated to the referral request
    * 
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_docext_old_row     Doc external old rowtype (before update)
    * @param i_docext_new_row     Doc external new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.5.0.7
    * @since   2010-02-04   
    */
    PROCEDURE set_doc_external
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_event          IN NUMBER,
        i_docext_old_row IN doc_external%ROWTYPE,
        i_docext_new_row IN doc_external%ROWTYPE
    );

    /**
    * Check if referral has changed:
    *  - Image document associated to the referral request
    * 
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_docimg_old_row     Doc image old rowtype (before update)
    * @param i_docimg_new_row     Doc image new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.5.0.7
    * @since   2010-02-04   
    */
    PROCEDURE set_doc_image
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_event          IN NUMBER,
        i_docimg_old_row IN doc_image%ROWTYPE,
        i_docimg_new_row IN doc_image%ROWTYPE
    );

    /**
    * Check if referral has changed:
    *  - Document comments associated to the referral request
    * 
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_doccom_old_row     Doc comments old rowtype (before update)
    * @param i_doccom_new_row     Doc comments new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.5.0.7
    * @since   2010-02-04   
    */
    PROCEDURE set_doc_comments
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_event          IN NUMBER,
        i_doccom_old_row IN doc_comments%ROWTYPE,
        i_doccom_new_row IN doc_comments%ROWTYPE
    );

    /**
    * Check if patient has changed: 
    *  - Patient name, gender, dt_birth, address, location, zip_code and country
    * 
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier, insitution and software
    * @param i_id_patient         Patient identifier that has changed
    * @param i_pat_old_row        Patient old rowtype (before update)
    * @param   o_error error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 2.5
    * @since   2010-05-11   
    * 
    */
    FUNCTION set_patient
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check changes on REF_DEST_INSTITUTION_SPEC
    * 
    * @param i_event              Event identifier: {*} 1-Insert event {*} 2-Update event {*} 3-Delete event
    * @param i_track_old_row      Referral old rowtype (before update)
    * @param i_track_new_row      Referral new rowtype (after update)
    *
    * @author  Ana Monteiro
    * @version 2.6
    * @since   2013-02-19   
    */
    PROCEDURE set_ref_dest_institution_spec
    (
        i_event   IN NUMBER,
        i_old_row IN ref_dest_institution_spec%ROWTYPE,
        i_new_row IN ref_dest_institution_spec%ROWTYPE
    );

END pk_api_ref_event;
/
