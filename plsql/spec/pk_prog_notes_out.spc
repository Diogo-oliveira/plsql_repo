/*-- Last Change Revision: $Rev: 1911734 $*/
/*-- Last Change by: $Author: nuno.coelho $*/
/*-- Date of last change: $Date: 2019-08-08 10:52:43 +0100 (qui, 08 ago 2019) $*/

CREATE OR REPLACE PACKAGE pk_prog_notes_out IS

    -- Author  : SOFIA.MENDES
    -- Created : 4/16/2013 11:17:12 AM
    -- Purpose : APIs to be used in external functionalities

    TYPE t_rec_progress_note_cda IS RECORD(
        id_epis_pn       epis_pn.id_epis_pn%TYPE,
        id_epis_pn_det   epis_pn_det.id_epis_pn_det%TYPE,
        flg_status       epis_pn.flg_status%TYPE,
        desc_status      VARCHAR2(1000 CHAR),
        pn_note          epis_pn_det.pn_note%TYPE,
        dt_reg_str       VARCHAR2(14 CHAR),
        dt_reg_tstz      epis_pn.dt_create%TYPE,
        dt_reg_formatted VARCHAR2(1000 CHAR));

    TYPE t_coll_progress_note_cda IS TABLE OF t_rec_progress_note_cda;

    g_has_error BOOLEAN;

    -- Public function and procedure declarations
    /**
    * Delete the notes associated to the given episodes.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_episode      Episode list
    * @param   o_error        Error information
    *
    * @return  Boolean
    *
    * @author  Sofia Mendes
    * @version 2.6.2
    * @since   16-Apr-2013
    */
    FUNCTION delete_episode_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the last note info for edis summary grids
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_id_epis_pn             Note identifier
    *
    * @param      o_flg_edited             Indicate if the SOAP block was edited
    * @param      o_pn_soap_block          Soap Block array with ids
    * @param      o_pn_signoff_note        Notes array
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              Sofia Mendes
    * @version                             2.6.3
    * @since                               23-Jul-2013
    */
    FUNCTION get_last_note_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_software IN software.id_software%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_pn_area  IN pn_area.id_pn_area%TYPE,
        o_note        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_pn_group_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN table_number,
        i_notes   IN epis_pn_det.pn_note%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_progress_note_cda
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_id_pn_note_type IN pn_note_type .id_pn_note_type%TYPE
    ) RETURN t_coll_progress_note_cda
        PIPELINED;

    /**
    * Returns the pn_note_type flag to viewer checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    * @param      i_pn_area                pn area internal name
    *
    * @param      o_flg_checklist          Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    * @param      o_error                  error information
    *
    * @return     false if errors occur, true otherwise
    *
    * @author     Anna Kurowska
    * @version    2.7.1
    * @since      02-Mar-2017
    */
    FUNCTION get_vwr_note_by_area
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_scope_type       IN VARCHAR2,
        i_pn_area          IN pn_area.internal_name%TYPE,
        i_ids_pn_note_type IN table_number,
        o_flg_checklist    OUT VARCHAR2,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN;
    /**
    * Returns flag to viewer checklist for note summary of given id_pn_note_type
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    * @param      i_id_pn_note_type        id pn note type,
    * @param      o_flg_checklist          Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    * @param      o_error                  error information
    *
    * @return     false if errors occur, true otherwise
    *
    * @author     Anna Kurowska
    * @version    2.7.1
    * @since      03-Mar-2017
    */
    FUNCTION get_vwr_note_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_scope_type      IN VARCHAR2,
        i_id_pn_note_type pn_note_type.id_pn_note_type%TYPE,
        o_flg_checklist   OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the pn_note_type flag to viewer checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    * @param      i_id_pn_note_type        PN_NOTE_TYPE ID
    *
    * @param      o_flg_checklist          Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    * @param      o_error                  error information
    *
    * @return     false if errors occur, true otherwise
    *
    * @author     Vanessa barsottelli
    * @version    2.6.5
    * @since      21-Set-2016
    */
    FUNCTION get_note_viewer_checklist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_scope_type      IN VARCHAR2,
        i_id_pn_note_type pn_note_type.id_pn_note_type%TYPE,
        o_flg_checklist   OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * History and Physical viewer checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       21-Set-2016
    */
    FUNCTION get_hp_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current visit viewer checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       24-Set-2016
    */
    FUNCTION get_cv_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current Discharge Summary checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       24-Set-2016
    */
    FUNCTION get_ds_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current Nursing assemssment notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_nsp_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current Nursing Initial Assessment checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       24-Set-2016
    */
    FUNCTION get_nia_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current Nursing Progress Note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Vanessa barsottelli
    * @version     2.6.5
    * @since       25-Set-2016
    */
    FUNCTION get_npn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    /**
    * Current physician progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_pn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current consultation report notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_crds_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current initial nutrition evaluation notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_dia_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current nutrition progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_dpn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current nutrition visit note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_nvn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /*
    * Current psychology visit note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       03/12/2018
    */
    FUNCTION get_vwr_psycho_visit_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current initial psychology evaluation notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       03/12/2018
    */
    FUNCTION get_vwr_psycho_ia
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current psychology progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       03/12/2018
    */
    FUNCTION get_vwr_psycho_prog_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
    /**
    * Current Pharmacist notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_phan_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current Initial respiratory assessment note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_ria_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Current Respiratory therapy progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Anna Kurowska
    * @version     2.7.1
    * @since       01/03/2017
    */
    FUNCTION get_rpn_vchecklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    * Get the id_tasks associated to a note and a given task type
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_id_epis_pn             Note ID
    * @param      i_id_tl_task             Task type ID
    *
    * @author      Sofia Mendes
    * @version     2.7.1
    * @since       07/09/2017
    */
    FUNCTION get_note_tasks_by_task_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_id_tl_task IN tl_task.id_tl_task%TYPE,
        o_tasks      OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    UC2 & UC3 & UC4: An ISS required diagnosis has been documented, please consider an ISS assessment.
    Please select one of the following actions or indicate a reason:
    
    UC5: ISS assessment score equal or greater than 16 requires a Discharge diagnosis of T07 (ICD-10).
    
    UC61: An ISS required diagnosis has been documented, please consider an ISS assessment. Please editthe note.
    UC62: An ISS assessment score equal or greater than 16 requires a Discharge diagnosis of T07 (ICD-10). Please edit the note.
    ******************************************************************************/
    FUNCTION check_iss_diag_validation
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        i_check_origin IN VARCHAR2 DEFAULT 'N', -- N: Submit in note; A: Submit in action
        o_return_flag  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    ******************************************************************************/
    FUNCTION get_iss_diag_val_params
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_return_flag     IN VARCHAR2,
        o_msg_box_desc    OUT VARCHAR2,
        o_msg_box_options OUT pk_types.cursor_type,
        o_include_reasons OUT VARCHAR2, -- Y/N
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Current initial CDC evaluation notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       03/12/2018
    */
    FUNCTION get_vwr_cdc_ia
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /*
    * Current CDC visit note checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.4
    * @since       09/07/2019
    */
    FUNCTION get_vwr_cdc_visit_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

	    /**
    * Current psychology progress notes checklist
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_patient                Patient ID
    * @param      i_episode                Episode ID
    * @param      i_scope_type             Scope: (P)atient ; (V)isit ; (E)pisode
    *
    * @return     Checklist status: (O)ngoing ; (C)ompleted ; (N)ot statred
    *
    * @author      Nuno Coelho
    * @version     2.7.1
    * @since       09/07/2019
    */
    FUNCTION get_vwr_cdc_prog_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;
	
    g_exception EXCEPTION;

END pk_prog_notes_out;
/
