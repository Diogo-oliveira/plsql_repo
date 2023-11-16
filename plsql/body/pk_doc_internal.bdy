/*-- Last Change Revision: $Rev: 2026997 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_doc_internal AS

    /**
    * Get default values to mandatory columns at doc_external to identification screen
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param o_id_doc_type       id doc_type
    * @param o_id_doc_ori_type   id doc_ori_type
    * @param o_id_doc_destination  id_doc_destination
    * @param o_id_doc_original    id_doc_original
    * @param o_error             an error message
    *
    * @return true (sucess), false (error)
    * @created 01-Jun-2007
    * @author Luís Gaspar
    */
    FUNCTION get_doc_identific_defaults
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        o_id_doc_type        OUT doc_external.id_doc_type%TYPE,
        o_id_doc_ori_type    OUT doc_external.id_doc_ori_type%TYPE,
        o_id_doc_destination OUT doc_external.id_doc_destination%TYPE,
        o_id_doc_original    OUT doc_external.id_doc_original%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('get_doc_identific_defaults 10');
        --    
        g_error       := 'GET SYS_CONFIG doc_type_id';
        o_id_doc_type := pk_sysconfig.get_config(g_doc_type_id, i_prof.institution, i_prof.software);
        pk_alertlog.log_debug('get_doc_identific_defaults,  o_id_doc_type=' || o_id_doc_type);
        IF (o_id_doc_type IS NULL)
        THEN
            RAISE g_exception_msg;
        END IF;
        --
        g_error := 'GET DOC_ORI_TYPE FOR DOC_TYPE = ' || o_id_doc_type;
        SELECT dtc.id_doc_ori_type_parent id_doc_ori_type
          INTO o_id_doc_ori_type
          FROM doc_types_config dtc
         WHERE dtc.id_doc_type = o_id_doc_type
           AND dtc.id_institution IN (i_prof.institution, 0)
           AND dtc.id_software IN (i_prof.software, 0)
           AND rownum < 2;
    
        pk_alertlog.log_debug('get_doc_identific_defaults,  o_id_doc_ori_type=' || o_id_doc_ori_type);
        --
        g_error              := 'GET SYS_CONFIG doc_destination_patient_id';
        o_id_doc_destination := pk_sysconfig.get_config(g_doc_destination_patient_id,
                                                        i_prof.institution,
                                                        i_prof.software);
        pk_alertlog.log_debug('get_doc_identific_defaults,  o_id_doc_destination=' || o_id_doc_destination);
        IF (o_id_doc_destination IS NULL)
        THEN
            RAISE g_exception_msg;
        END IF;
        --
        g_error           := 'GET SYS_CONFIG doc_original_patient_id';
        o_id_doc_original := pk_sysconfig.get_config(g_doc_original_patient_id, i_prof.institution, i_prof.software);
        pk_alertlog.log_debug('get_doc_identific_defaults,  o_id_doc_original=' || o_id_doc_original);
        --                                             
        IF (o_id_doc_original IS NULL)
        THEN
            RAISE g_exception_msg;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_msg THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
                -- mensagem a pedir validação de configuração           
                l_error_v VARCHAR2(100) := REPLACE(pk_message.get_message(i_lang, 'COMMON_M039'),
                                                   '@1',
                                                   'SYS_CONFIG (' || g_doc_type_id || ')') || chr(10) ||
                                           'PK_DOC.GET_DOC_IDENTIFIC_DEFAULTS';
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_DOC_INTERNAL',
                                   'GET_DOC_IDENTIFIC_DEFAULTS',
                                   l_error_v,
                                   'D');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                --                pk_utils.undo_changes; 
            
                -- return failure of function_dummy                 
                RETURN FALSE;
            
            END;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_DOC_INTERNAL',
                                   'GET_DOC_IDENTIFIC_DEFAULTS');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                --                pk_utils.undo_changes; 
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        
    END;

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
    *
    * UPDATED - passou a invocar a versao local do get_doc_identific
    * @author Telmo Castro
    * @date   21-12-2007
    */
    FUNCTION get_doc_identific_internal
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_patient   IN doc_external.id_patient%TYPE,
        i_btn          IN sys_button_prop.id_sys_button_prop%TYPE,
        o_doc_external OUT doc_external%ROWTYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_doc_type        doc_external.id_doc_type%TYPE;
        l_id_doc_ori_type    doc_external.id_doc_ori_type%TYPE;
        l_id_doc_destination doc_external.id_doc_destination%TYPE;
        l_id_doc_original    doc_external.id_doc_original%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
        -- get doc_ori_type associated with id screen
        IF NOT get_doc_identific_defaults(i_lang,
                                          i_prof,
                                          l_id_doc_type,
                                          l_id_doc_ori_type,
                                          l_id_doc_destination,
                                          l_id_doc_original,
                                          o_error)
        THEN
            RAISE g_exception;
        END IF;
        -- document in db?
        IF NOT
            get_doc_identific(i_lang, i_prof, i_id_patient, NULL, NULL, l_id_doc_type, i_btn, o_doc_external, o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            --            ROLLBACK;
            RETURN FALSE;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_DOC_INTERNAL',
                                   'GET_DOC_IDENTIFIC_INTERNAL');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                --                pk_utils.undo_changes; 
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    /**
    * A patient may have several documents, and only one may be updated at patient identification area.
    * Sets patient document updated at patient identification area. Does the insert update or delete.
    * No commit is performed
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
    *
    * UPDATED - passou a invocar a versao local do get_doc_identific
    * @author Telmo Castro
    * @date   21-12-2007
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
    ) RETURN BOOLEAN IS
        l_id_doc_type        doc_external.id_doc_type%TYPE;
        l_id_doc_ori_type    doc_external.id_doc_ori_type%TYPE;
        l_id_doc_destination doc_external.id_doc_destination%TYPE;
        l_id_doc_original    doc_external.id_doc_original%TYPE;
    
        l_exception EXCEPTION;
        l_doc_external_row doc_external%ROWTYPE;
    
    BEGIN
        pk_alertlog.log_debug('Set_doc_internal 10, ' || i_num_doc);
    
        -- get doc_ori_type associated with id screen
        IF NOT get_doc_identific_defaults(i_lang,
                                          i_prof,
                                          l_id_doc_type,
                                          l_id_doc_ori_type,
                                          l_id_doc_destination,
                                          l_id_doc_original,
                                          o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (i_num_doc IS NOT NULL)
        THEN
            -- create doc_external
            pk_alertlog.log_debug('Set_doc_internal creating ');
            g_error := 'CREATE DOC_EXTERNAL VALUES';
            IF NOT pk_doc.create_doc_internal(i_lang,
                                              i_prof,
                                              i_id_patient,
                                              NULL,
                                              NULL,
                                              l_id_doc_type,
                                              NULL,
                                              i_num_doc,
                                              NULL,
                                              NULL,
                                              l_id_doc_destination,
                                              NULL,
                                              l_id_doc_ori_type,
                                              NULL,
                                              NULL,
                                              NULL,
                                              l_id_doc_original,
                                              NULL,
                                              i_btn,
                                              --
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              NULL,
                                              table_varchar(),
                                              table_varchar(),
                                              table_varchar(),
                                              table_varchar(),
                                              table_varchar(),
                                              --
                                              l_doc_external_row.id_doc_external,
                                              o_create_doc_msg,
                                              o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'CALL get_doc_identific';
            IF NOT get_doc_identific(i_lang,
                                     i_prof,
                                     i_id_patient,
                                     NULL,
                                     NULL,
                                     l_id_doc_type,
                                     i_btn,
                                     l_doc_external_row,
                                     o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF l_doc_external_row.id_doc_external IS NOT NULL
            THEN
                -- cancel document
                pk_alertlog.log_debug('Set_doc_internal canceling ');
                IF (l_doc_external_row.id_doc_external IS NOT NULL)
                THEN
                    g_error := 'CANCEL DOC_EXTERNAL';
                    IF NOT pk_doc.cancel_doc(i_lang, i_prof, l_doc_external_row.id_doc_external, o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_DOC_INTERNAL',
                                   'SET_DOC_IDENTIFIC_INTERNAL');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END set_doc_identific_internal;

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
    ) RETURN BOOLEAN IS
        l_ret   BOOLEAN;
        l_my_pt profile_template.id_profile_template%TYPE;
    
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
        l_ext_req p1_external_request.id_external_request%TYPE;
    
        CURSOR c_doc
        (
            x_patient patient.id_patient%TYPE,
            x_episode episode.id_episode%TYPE,
            x_ext_req p1_external_request.id_external_request%TYPE
        ) IS
            SELECT *
              FROM (SELECT de.*
                      FROM doc_external de, doc_type dt
                     WHERE de.id_patient = x_patient
                       AND de.id_doc_type = i_doc_type
                       AND dt.id_doc_type = de.id_doc_type
                       AND dt.flg_duplicate = pk_doc.g_doc_config_n
                       AND de.flg_status = pk_doc.g_doc_active
                    UNION
                    SELECT de.*
                      FROM doc_external de, doc_type dt
                     WHERE de.id_episode = x_episode
                       AND de.id_doc_type = i_doc_type
                       AND dt.id_doc_type = de.id_doc_type
                       AND dt.flg_duplicate = pk_doc.g_doc_config_n
                       AND de.flg_status = pk_doc.g_doc_active
                    UNION
                    SELECT de.*
                      FROM doc_external de, doc_type dt
                     WHERE de.id_external_request = x_ext_req
                       AND de.id_doc_type = i_doc_type
                       AND dt.id_doc_type = de.id_doc_type
                       AND dt.flg_duplicate = pk_doc.g_doc_config_n
                       AND de.flg_status = pk_doc.g_doc_active)
             ORDER BY id_patient, id_episode, id_external_request;
    
        l_error t_error_out;
    BEGIN
        BEGIN
            g_error := 'GET PROFILE';
            l_ret   := pk_doc.get_profile_template(i_lang, i_prof, l_my_pt, l_error);
        
            -- Validate context (Pacient, Episode and External Request)   
            SELECT decode(pk_doc.get_config('DOC_PATIENT', i_prof, l_my_pt, i_btn),
                          pk_doc.g_doc_config_y,
                          i_patient,
                          NULL),
                   decode(pk_doc.get_config('DOC_EPISODE', i_prof, l_my_pt, i_btn),
                          pk_doc.g_doc_config_y,
                          i_episode,
                          NULL),
                   decode(pk_doc.get_config('DOC_REFERRAL', i_prof, l_my_pt, i_btn),
                          pk_doc.g_doc_config_y,
                          i_ext_req,
                          NULL)
              INTO l_patient, l_episode, l_ext_req
              FROM dual;
        
            IF l_patient IS NULL
               AND l_episode IS NULL
               AND l_ext_req IS NULL
            THEN
            
                RAISE g_exception_msg;
            ELSE
                pk_alertlog.log_debug('l_patient: ' || l_patient || ', l_episode: ' || l_episode || ', l_ext_req: ' ||
                                      l_ext_req || ' i_doc_type: ' || i_doc_type);
            
            END IF;
        
            g_error := 'Open c_doc';
            OPEN c_doc(l_patient, l_episode, l_ext_req);
            FETCH c_doc
                INTO o_doc_external;
            CLOSE c_doc;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_msg THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
                l_error_v VARCHAR2(100) := 'No parameters DOC_PATIENT, DOC_EPISODE or DOC_REFERRAL defined in DOC_CONFIG for SOFTWARE: ' ||
                                           i_prof.software || ', INSTITUTION: ' || i_prof.institution ||
                                           ', PROFILE_TEMPLATE: ' || l_my_pt || ' and SYS_BUTTON_PROP: ' || i_btn;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   'ALERT',
                                   'PK_DOC_INTERNAL',
                                   'GET_DOC_IDENTIFIC',
                                   l_error_v,
                                   'U');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_DOC_INTERNAL', 'GET_DOC_IDENTIFIC');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
        
    END get_doc_identific;

BEGIN

    pk_alertlog.log_init(pk_alertlog.who_am_i); -- Inicialização do log

    g_doc_type_id                := 'DOC_TYPE_ID';
    g_doc_destination_patient_id := 'DOC_DESTINATION_PATIENT_ID';
    g_doc_original_patient_id    := 'DOC_ORIGINAL_PATIENT_ID';

END pk_doc_internal;
/
