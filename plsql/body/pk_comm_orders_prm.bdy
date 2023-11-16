/*-- Last Change Revision: $Rev: 1915164 $*/
/*-- Last Change by: $Author: humberto.cardoso $*/
/*-- Date of last change: $Date: 2019-09-05 10:07:36 +0100 (qui, 05 set 2019) $*/
CREATE OR REPLACE PACKAGE BODY pk_comm_orders_prm IS

    -- Private constant declarations
    g_yes CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
    g_no  CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_no;

    -- Log variables
    g_package_owner pk_types.t_low_char;
    g_package_name  pk_types.t_low_char;

    --==============================PRIVATE FUNCTIONS=================================
    --Support other internal functions / procedures

    --============================== PUBLIC FUNCTIONS =================================

    FUNCTION set_comm_order_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- Private variables
        l_ids_task_types    table_number;
        l_ids_concept_types table_number;
        l_result            BOOLEAN;
        l_result_tbl        NUMBER;
        l_error             t_error_out;
        l_result_start      NUMBER;
        l_result_end        NUMBER;
    
    BEGIN
        -- Collect the concept types and task types for comm orders
        pk_ea_logic_comm_orders.load_concept_types_task_types(o_ids_task_types    => l_ids_task_types,
                                                              o_ids_concept_types => l_ids_concept_types);
    
        -- The communication orders use terminology server config model
        -- First it is necessary copy the data from ts default tables
        -- These tables are already associated with other area "DIAGNOSIS" and is not necessary copy all the content
        -- This need to be changed when DEFAULT process support the same table for more than one area
        BEGIN
            -- Terminology: Call the TS function sending the task types and concept types
            l_result := alert_core_func.pk_diag_prm.set_ts_mtv_search(i_lang             => i_lang,
                                                                      i_institution      => i_institution,
                                                                      i_mkt              => i_mkt,
                                                                      i_vers             => i_vers,
                                                                      i_software         => i_software,
                                                                      i_id_concept_types => l_ids_concept_types,
                                                                      i_id_task_types    => l_ids_task_types,
                                                                      o_result_tbl       => l_result_tbl,
                                                                      o_error            => l_error);
        
            -- validaton
            IF l_result = FALSE
            THEN
                o_result_tbl := l_result_tbl;
                o_error      := l_error;
                RETURN l_result;
            END IF;
            dbms_output.put_line('msi_termin_version created: ' || to_char(o_result_tbl));
        
            -- Concept_version Call the TS function sending the task types and concept types
            l_result := alert_core_func.pk_diag_prm.set_ts_mcva_search(i_lang             => i_lang,
                                                                       i_institution      => i_institution,
                                                                       i_mkt              => i_mkt,
                                                                       i_vers             => i_vers,
                                                                       i_software         => i_software,
                                                                       i_id_concept_types => l_ids_concept_types,
                                                                       i_id_task_types    => l_ids_task_types,
                                                                       o_result_tbl       => l_result_tbl,
                                                                       o_error            => l_error);
        
            -- validaton
            IF l_result = FALSE
            THEN
                o_result_tbl := l_result_tbl;
                o_error      := l_error;
                RETURN l_result;
            END IF;
            dbms_output.put_line('msi_cncpt_vers_attrib created: ' || to_char(o_result_tbl));
        
            -- Call the TS function sending the task types and concept types
            l_result := alert_core_func.pk_diag_prm.set_ts_mct_search(i_lang             => i_lang,
                                                                      i_institution      => i_institution,
                                                                      i_mkt              => i_mkt,
                                                                      i_vers             => i_vers,
                                                                      i_software         => i_software,
                                                                      i_id_concept_types => l_ids_concept_types,
                                                                      i_id_task_types    => l_ids_task_types,
                                                                      o_result_tbl       => l_result_tbl,
                                                                      o_error            => l_error);
        
            -- validaton
            IF l_result = FALSE
            THEN
                o_result_tbl := l_result_tbl;
                o_error      := l_error;
                RETURN l_result;
            END IF;
        
            -- Call the TS function sending the task types and concept types
            l_result := alert_core_func.pk_diag_prm.set_ts_mcr_search(i_lang             => i_lang,
                                                                      i_institution      => i_institution,
                                                                      i_mkt              => i_mkt,
                                                                      i_vers             => i_vers,
                                                                      i_software         => i_software,
                                                                      i_id_concept_types => l_ids_concept_types,
                                                                      i_id_task_types    => l_ids_task_types,
                                                                      o_result_tbl       => l_result_tbl,
                                                                      o_error            => l_error);
        
            -- validaton
            IF l_result = FALSE
            THEN
                o_result_tbl := l_result_tbl;
                o_error      := l_error;
                RETURN l_result;
            END IF;
        
        END; -- End of terminology server copy
    
        -- Currently the REBUILD EA does not support the number of records created
        -- Gets the number of the records before EA
        SELECT COUNT(1)
          INTO l_result_start
          FROM comm_order_ea ea
         WHERE ea.id_institution_term_vers = i_institution
           AND ea.id_institution_conc_term = i_institution;
    
        -- Default process can send the id_software = 0
        FOR i IN 1 .. i_software.count
        LOOP
            -- If is not the ZERO software
            IF i_software(i) > 0
            THEN
                -- Call the EA
                pk_ea_logic_comm_orders.populate_ea(i_id_institution    => i_institution,
                                                    i_ids_softwares     => table_number(i_software(i)),
                                                    i_ids_task_types    => l_ids_task_types,
                                                    i_ids_concept_types => l_ids_concept_types);
            END IF;
        END LOOP;
    
        -- Currently the REBUILD EA does not support the number of records created
        -- Gets the number of the records after EA
        SELECT COUNT(1)
          INTO l_result_end
          FROM comm_order_ea ea
         WHERE ea.id_institution_term_vers = i_institution
           AND ea.id_institution_conc_term = i_institution;
    
        -- Return the results
        o_result_tbl := l_result_end - (l_result_start);
        o_error      := l_error;
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Rebuild comm_order_ea',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_COMM_ORDER_SEARCH',
                                              o_error);
            RETURN FALSE;
        
    END set_comm_order_search;

    FUNCTION set_co_questionnaire_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        -- Private types and variables
        TYPE table_comm_order_quest IS TABLE OF comm_order_questionnaire%ROWTYPE;
        l_comm_order_quest table_comm_order_quest;
    
    BEGIN
    
        -- Collects the data into the table types
        SELECT id_comm_order_questionnaire,
               id_concept_term,
               id_questionnaire,
               id_response,
               id_institution,
               flg_copy,
               flg_validation,
               flg_exterior,
               id_unit_measure,
               flg_time,
               flg_type,
               flg_mandatory,
               rank,
               flg_available,
               NULL,
               NULL,
               NULL,
               NULL,
               NULL,
               NULL BULK COLLECT
          INTO l_comm_order_quest
          FROM (
                 -- A question-response association can be availalble for a communication order if:
                 --- The communication order is available
                 --- The question-response is available
                 SELECT NULL                        AS id_comm_order_questionnaire,
                         co.id_concept_term, -- Uses the id_term available in de communication order
                         aqr.id_questionnaire, -- This ID is from alert.questionnaire_response
                         aqr.id_response, --This ID is from alert.questionnaire_response
                         co.id_institution_conc_term AS id_institution,
                         dq.flg_copy,
                         dq.flg_validation,
                         dq.flg_exterior,
                         dq.id_unit_measure,
                         dq.flg_time,
                         dq.flg_type,
                         dq.flg_mandatory,
                         dq.rank,
                         dq.flg_available
                   FROM alert_default.comm_order_questionnaire dq
                  INNER JOIN alert.comm_order_ea co
                     ON co.id_concept = dq.id_concept
                    AND co.id_concept_term = nvl(dq.id_concept_term, co.id_concept_term)
                 -- Joins with the default question -response to get the id_content
                  INNER JOIN alert_default.questionnaire_response dqr
                     ON dqr.id_questionnaire = dq.id_questionnaire
                    AND dqr.id_response = dq.id_response
                 -- Joins with the alert question response to get the correct ID's question and response
                  INNER JOIN alert.questionnaire_response aqr
                     ON aqr.id_content = dqr.id_content
                  WHERE
                 -- Default validation 
                  dq.id_market IN (SELECT column_value
                                     FROM TABLE(i_mkt))
               AND dq.version IN (SELECT column_value
                                   FROM TABLE(i_vers))
                 -- Comm order validation
               AND co.id_institution_term_vers = i_institution
               AND co.id_institution_conc_term = i_institution
               AND co.id_software_term_vers IN (SELECT column_value
                                                 FROM TABLE(i_software)
                                                WHERE column_value > 0)
               AND co.id_software_conc_term IN (SELECT column_value
                                                 FROM TABLE(i_software)
                                                WHERE column_value > 0)
               AND co.flg_active_term_vers = 'Y'
               AND dqr.flg_available = 'Y'
               AND aqr.flg_available = 'Y'
                 -- And the records does not exists already in the table
                 -- Uses as UK: id_concept_term, id_questionnaire, id_response, id_institution, flg_time
               AND NOT EXISTS (SELECT 1
                     FROM alert.comm_order_questionnaire aq
                    WHERE aq.id_concept_term = co.id_concept_term
                      AND aq.id_questionnaire = aqr.id_questionnaire
                      AND aq.id_response = aqr.id_response
                      AND aq.id_institution = co.id_institution_conc_term
                      AND aq.flg_time = dq.flg_time)) cnt;
    
        -- Insert the data into the alert table
        FORALL i IN 1 .. l_comm_order_quest.count
        
            INSERT INTO alert.comm_order_questionnaire
                (id_comm_order_questionnaire,
                 id_concept_term,
                 id_questionnaire,
                 id_response,
                 id_institution,
                 flg_copy,
                 flg_validation,
                 flg_exterior,
                 id_unit_measure,
                 flg_time,
                 flg_type,
                 flg_mandatory,
                 rank,
                 flg_available,
                 create_user,
                 create_time,
                 create_institution,
                 update_user,
                 update_time,
                 update_institution)
            VALUES
                (alert.seq_comm_order_questionnaire.nextval, -- id_comm_order_questionnaire,
                 l_comm_order_quest(i).id_concept_term,
                 l_comm_order_quest(i).id_questionnaire,
                 l_comm_order_quest(i).id_response,
                 l_comm_order_quest(i).id_institution,
                 l_comm_order_quest(i).flg_copy,
                 l_comm_order_quest(i).flg_validation,
                 l_comm_order_quest(i).flg_exterior,
                 l_comm_order_quest(i).id_unit_measure,
                 l_comm_order_quest(i).flg_time,
                 l_comm_order_quest(i).flg_type,
                 l_comm_order_quest(i).flg_mandatory,
                 l_comm_order_quest(i).rank,
                 l_comm_order_quest(i).flg_available,
                 USER, --create_user,
                 current_timestamp, --create_time,
                 NULL, -- create_institution,
                 NULL, -- update_user,
                 NULL, -- update_time,
                 NULL); -- update_institution);
    
        -- Return the results
        o_result_tbl := l_comm_order_quest.count;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'Insert data in comm_order_questionnaire',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_CO_QUESTIONNAIRE_SEARCH',
                                              o_error);
            RETURN FALSE;
        
    END set_co_questionnaire_search;

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
END pk_comm_orders_prm;
/
