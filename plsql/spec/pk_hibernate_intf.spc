/*-- Last Change Revision: $Rev: 1893513 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2019-02-18 15:10:58 +0000 (seg, 18 fev 2019) $*/

CREATE OR REPLACE PACKAGE pk_hibernate_intf IS

    /*
    * Returns a list of procedures, patient educations and nursing interventions, sorted
    * accordingly to Viewer presentation rules
    *
    * @param i_lang          Language ID
    * @param i_prof_id       Professional
    * @param i_prof_inst     Professional
    * @param i_prof_soft     Professional
    * @param i_id_patient    Patient's ID
    * @param i_package       Package identifier for area (exam, analysis, etc)
    * @param i_viewer_area   Viewer area (EHR, Workflow)
    *
    * @return                Cursor containing intervention list
    *
    * @author                Rui Baeta
    * @version               1.0
    * @since                 2008/11/27
    */

    FUNCTION get_ordered_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof_id     IN professional.id_professional%TYPE,
        i_prof_inst   IN institution.id_institution%TYPE,
        i_prof_soft   IN software.id_software%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_package     IN VARCHAR2,
        i_viewer_area IN VARCHAR2
    ) RETURN pk_types.cursor_type;

    /*
    * Returns detailed information of the selected item
    *
    * @param     i_lang        Language id
    * @param     i_prof        Professional id
    * @param     i_prof_inst   Institution id
    * @param     i_prof_soft   Software id
    * @param     i_package     Package identifier for area (exam, analysis, etc)
    * @param     i_item        Item id
    
    * @return    true or false on success or error
    *
    * @author    Nuno Neves
    * @version   2.5
    * @since     2012/01/12
    */

    FUNCTION get_ordered_list_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof_id   IN professional.id_professional%TYPE,
        i_prof_inst IN institution.id_institution%TYPE,
        i_prof_soft IN software.id_software%TYPE,
        i_package   IN VARCHAR2,
        i_item      IN NUMBER
    ) RETURN pk_types.cursor_type;
    /*
    * Return the translation of lab test alias if exists
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_flg_type           Flag that indicates the type of alias: 
                                      A - Lab Tests; G - Panel; P - Parameter; S - Sample
    * @param     i_code_translation   Code for translation
    
    * @return    string
    *
    * @author    Sérgio Santos
    * @version   2.6.3.1
    * @since     2013/01/01
    */

    FUNCTION get_lab_test_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_type         IN VARCHAR2 DEFAULT 'A',
        i_code_translation IN VARCHAR2
    ) RETURN VARCHAR2;
	
    FUNCTION has_patient_access
    (
        i_lang       IN language.id_language%TYPE,
        i_prof_id    IN professional.id_professional%TYPE,
        i_prof_inst  IN institution.id_institution%TYPE,
        i_prof_soft  IN software.id_software%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_access     OUT VARCHAR2
        --o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    g_undefined_error_id CONSTANT PLS_INTEGER := -20999;

    -- ALERT-164737
    g_ordered_list_ehr CONSTANT VARCHAR2(200) := 'EHR';
    g_ordered_list_wfl CONSTANT VARCHAR2(200) := 'WFL';

END pk_hibernate_intf;
/
