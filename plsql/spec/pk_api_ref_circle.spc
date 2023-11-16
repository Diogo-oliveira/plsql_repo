/*-- Last Change Revision: $Rev: 748534 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2010-11-05 17:03:26 +0000 (sex, 05 nov 2010) $*/

CREATE OR REPLACE PACKAGE pk_api_ref_circle IS

    -- Author  : JOANA.BARROSO
    -- Created : 20-10-2009 17:27:11
    -- Purpose : Circle Project

    -- Public variable declarations
    g_error         VARCHAR2(4000);
    g_sysdate_tstz  TIMESTAMP WITH TIME ZONE;
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);
    g_exception EXCEPTION;
    g_exception_np EXCEPTION;

    g_retval BOOLEAN;
    g_found  BOOLEAN;

    g_null      CONSTANT VARCHAR2(1) := NULL;
    g_tl_report CONSTANT VARCHAR2(10) := 'TL_REPORT';

    -- Public function and procedure declarations

    /**
    * Associates an ORIS/INP episode to an INP/ORIS or OUTP/Exam Referral type
    * Used by ORIS/INP
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_ref                Referral identifier
    * @param   i_episode            Episode identifier
    * @param   o_ref_map            The association identifier created
    * @param   o_error              An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-11-2009
    */
    FUNCTION set_ref_map_episode
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ref     IN p1_external_request.id_external_request%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_ref_map OUT ref_map.id_ref_map%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Associates an OUTP/Exam episode to an Exam/OUTP or INP/ORIS Referral type
    * Used by OUTP/Exam
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_schedule           Schedule identifier
    * @param   i_episode            Episode identifier
    * @param   o_visit              Visit  identifier. Not used.
    * @param   o_ref_map            The association identifier created
    * @param   o_error              An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-11-2009
    */
    FUNCTION set_ref_map_from_episode
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_visit    OUT visit.id_visit%TYPE,
        o_ref_map  OUT ref_map.id_ref_map%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets information of episodes related to the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   o_linked_epis        Episodes information
    * @param   o_error              An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-10-2009
    */
    FUNCTION get_linked_episodes
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        o_linked_epis OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_ref_circle;
/

