/*-- Last Change Revision: $Rev: 2028620 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:56 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_doc_internal AS

    /****************************************************************************************
    PK CREATED BY   : LUIS GASPAR
    PK DATE CREATION: 08-2007
    PK GOAL         : THIS PACKAGE INCLUDES FUNCTIONS RELATED TO THE DOCUMENTS AREA, FOR DATABASE INTERNAL USE, WITH PARAMETERS NOT HANDLED BY JAVA.
    
    NOTES/ OBS      : ---
    ******************************************************************************************/

    /**
    * Get doc_external for identification screen
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_patient        the patient id
    * @param o_doc_external      doc_external value
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 01-Jun-2007
    * @author Luís Gaspar
    */

    FUNCTION get_doc_identific_internal
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_patient   IN doc_external.id_patient%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_external OUT doc_external%ROWTYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * A patient may have several documents, and only one may be updated at patient identification area.
    * Sets patient document updated at patient identification area. Does the insert update or delete.
    * No commit is performed.
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_patient        the patient id
    * @param i_num_doc           the documente id
    * @param o_id_doc            doc_external id table
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 01-Jun-2007
    * @author Luís Gaspar
    */
    FUNCTION set_doc_identific_internal
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_id_patient     IN doc_external.id_patient%TYPE,
        i_num_doc        IN doc_external.num_doc%TYPE,
        i_btn            IN sys_button_prop.id_sys_button_prop%TYPE,
        o_id_doc         OUT NUMBER,
        o_create_doc_msg OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets document id based in the doc_type for the context provided (patient, episode, external_request)
    * If the doc_type can be duplicated the result is allways null.
    *
    * @param i_lang         language id
    * @param i_prof         professional, software and institution ids
    * @param i_id_patient   the patient id
    * @param i_episode      episode id
    * @param i_ext_req      external request id
    * @param i_doc_type     doc type id
    * @param i_btn          is sys_button_prop
    * @param o_doc_external resulting document id
    * @param o_error        error message           
    *
    * @return true (sucess), false (error)
    * @created 24-Oct-2007
    * @author Joao Sa
    *
    * UPDATED - funçao movida do pk_doc para aqui
    * @created  Telmo Castro
    * @date     21-12-2007
    */

    FUNCTION get_doc_identific
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ext_req      IN p1_external_request.id_external_request%TYPE,
        i_doc_type     IN NUMBER,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_external OUT doc_external%ROWTYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

    g_doc_type_id                VARCHAR2(50);
    g_doc_destination_patient_id VARCHAR2(50);
    g_doc_original_patient_id    VARCHAR2(50);

    g_exception_msg EXCEPTION;
    g_exception     EXCEPTION;

END pk_doc_internal;
/
