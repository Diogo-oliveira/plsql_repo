/*-- Last Change Revision: $Rev: 2026983 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_dmgr_hist IS

    /********************************************************************************************
    * This function inserts a new row in the PAT_DMGR_HIST table
    *
    * @param i_patient_code   Patient ID number
    * @param i_lang   ID of the language used by the professional
    * @param i_prof   professional ID + institution ID + software version
    * @param o_error   error description
    *
    *
    * @return                TRUE on success; FALSE otherwise
    *
    *
    * @author                Rui Abreu
    * @since                 2007/03/22
       ********************************************************************************************/

    FUNCTION create_dmgr_hist
    (
        i_data  IN pat_dmgr_hist%ROWTYPE,
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
        
    ) RETURN BOOLEAN IS
    BEGIN
        INSERT INTO pat_dmgr_hist
        VALUES i_data;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
				
				    pk_alert_exceptions.process_error(i_lang, SQLCODE, SQLERRM, pk_message.get_message(i_lang, 'COMMON_M001'), 'ALERT', 'PK_DMGR_HIST', 'CREATE_DMGR_HIST', o_error); 
						
						pk_utils.undo_changes;
            RETURN false; 
        
    END create_dmgr_hist;

    /********************************************************************************************
    * This function finds the differences between two rows of the PAT_DMGR_HIST table
    *
    * @param i_patient_code   Patient ID number
    * @param i_row1   first row
    * @param i_row2   second row
    * @param io_new_info   buffer containing the new information
    * @param io_old_info   buffer containing all the outdated information
    * @param io_doc_info   buffer containing the name of the doctors who performed the modifications
    * @param io_date_info  buffer containing modifications dates and hours
    *
    *
    * @return                TRUE on success; FALSE otherwise
    *
    *
    * @author                Rui Abreu
    * @since                 2007/03/22
       ********************************************************************************************/

    FUNCTION find_differences
    (
        i_row1       IN pat_dmgr_hist%ROWTYPE,
        i_row2       IN pat_dmgr_hist%ROWTYPE,
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN profissional,
        io_new_info  IN OUT table_varchar,
        io_old_info  IN OUT table_varchar,
        io_doc_info  IN OUT table_varchar,
        io_date_time IN OUT table_varchar
        
    ) RETURN BOOLEAN IS
    
        l_count              NUMBER;
        l_buffer_actual_info VARCHAR2(20000);
        l_buffer_past_info   VARCHAR2(20000);
        l_tag                VARCHAR2(50);
        l_tag_desact_info    VARCHAR2(50);
        l_tag_sd1            VARCHAR2(50);
        l_tag_sd2            VARCHAR2(50);
        l_ref1               VARCHAR2(1000);
        l_ref2               VARCHAR2(1000);
    
        -----------------------------------------------------------------------------------------------------------------------        
        -----------------------------------------------------------------------------------------------------------------------        
    
    BEGIN
    
        -- tag that says : INFORMACAO DESACTUALIZADA 
        l_tag_desact_info := pk_message.get_message(i_lang, 'IDENT_PATIENT_T039');
    
        -- insertion index
        l_count := io_new_info.COUNT;
        -- dbms_output.put_line('Current index is' || ':' || l_count);
    
        -----------------------------COMPARING TOW ROWS, FIELD BY FIELD ------------------------------------------------------
    
        -- name
    
        -- are there any differences in this field ?
        IF (NOT (i_row1.name IS NULL AND i_row2.name IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T001');
        
            -- deleting data and not replacing it                                  
            IF i_row1.name IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.name || '</b></font>' || chr(10);
            
            END IF;
        
            -- inserting on an empty field                                     
            IF i_row2.name IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.name || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            -- altering an existent value
            IF (i_row1.name <> i_row2.name)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.name || '</b></font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || i_row2.name || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- gender
        IF (NOT (i_row1.gender IS NULL AND i_row2.gender IS NULL))
        THEN
        
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T003');
        
            l_tag_sd1 := pk_sysdomain.get_domain('PATIENT.GENDER', i_row1.gender, i_lang);
        
            l_tag_sd2 := pk_sysdomain.get_domain('PATIENT.GENDER', i_row2.gender, i_lang);
        
            IF i_row1.gender IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || l_tag_sd2 || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.gender IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_tag_sd1 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.gender <> i_row2.gender)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_tag_sd1 || '</b></font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || l_tag_sd2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- birth date
        IF (NOT (i_row1.dt_birth IS NULL AND i_row2.dt_birth IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T002');
        
            IF i_row1.dt_birth IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || pk_date_utils.dt_chr(i_lang, i_row2.dt_birth, i_prof) ||
                                      '</b></font>' || chr(10);
            END IF;
        
            IF i_row2.dt_birth IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' ||
                                        pk_date_utils.dt_chr(i_lang, i_row1.dt_birth, i_prof) || '</b></font>' ||
                                        chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.dt_birth <> i_row2.dt_birth)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' ||
                                        pk_date_utils.dt_chr(i_lang, i_row1.dt_birth, i_prof) || '</b></font>' ||
                                        chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || pk_date_utils.dt_chr(i_lang, i_row2.dt_birth, i_prof) ||
                                      '</b></font>' || chr(10);
            END IF;
        
        END IF;
    
        -- age
    
        IF (NOT (i_row1.age IS NULL AND i_row2.age IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T031');
        
            IF i_row1.age IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || i_row2.age || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.age IS NULL
            THEN
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.age || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.age <> i_row2.age)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.age || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.age || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- birth place------------------------------------------------------------------------------------------------------------------------------------
        IF (NOT (i_row1.birth_place IS NULL AND i_row2.birth_place IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T018');
        
            IF i_row1.birth_place IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.birth_place || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.birth_place IS NULL
            THEN
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.birth_place || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.birth_place <> i_row2.birth_place)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.birth_place || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.birth_place || '</b></font>' || chr(10);
            END IF;
        
        END IF;
    
        -- nationality
        IF (NOT (i_row1.id_country_nation IS NULL AND i_row2.id_country_nation IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T036');
        
            IF i_row1.id_country_nation IS NULL
            THEN
            
                SELECT t.code_country
                  INTO l_ref1
                  FROM country t
                 WHERE t.id_country = i_row2.id_country_nation;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.id_country_nation IS NULL
            THEN
            
                SELECT t.code_country
                  INTO l_ref1
                  FROM country t
                 WHERE t.id_country = i_row1.id_country_nation;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.id_country_nation <> i_row2.id_country_nation)
            THEN
            
                SELECT t.code_country
                  INTO l_ref1
                  FROM country t
                 WHERE t.id_country = i_row1.id_country_nation;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                SELECT t.code_country
                  INTO l_ref1
                  FROM country t
                 WHERE t.id_country = i_row2.id_country_nation;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- country address
        IF (NOT (i_row1.id_country_address IS NULL AND i_row2.id_country_address IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T010');
        
            IF i_row1.id_country_address IS NULL
            THEN
            
                SELECT t.code_country
                  INTO l_ref1
                  FROM country t
                 WHERE t.id_country = i_row2.id_country_address;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.id_country_address IS NULL
            THEN
            
                SELECT t.code_country
                  INTO l_ref1
                  FROM country t
                 WHERE t.id_country = i_row1.id_country_address;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.id_country_address <> i_row2.id_country_address)
            THEN
            
                SELECT t.code_country
                  INTO l_ref1
                  FROM country t
                 WHERE t.id_country = i_row1.id_country_address;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                SELECT t.code_country
                  INTO l_ref1
                  FROM country t
                 WHERE t.id_country = i_row2.id_country_address;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- social security number
        IF (NOT (i_row1.num_doc_external IS NULL AND i_row2.num_doc_external IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, i_prof, 'IDENT_PATIENT_T041');
        
            IF i_row1.num_doc_external IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.num_doc_external || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.num_doc_external IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_doc_external || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.num_doc_external <> i_row2.num_doc_external)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_doc_external || '</b></font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || i_row2.num_doc_external || '</b></font>' || chr(10);
            END IF;
        
        END IF;
    
        --health plan
        IF (NOT (i_row1.num_health_plan IS NULL AND i_row2.num_health_plan IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, i_prof, 'IDENT_PATIENT_T035');
        
            IF i_row1.num_health_plan IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.num_health_plan || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.num_health_plan IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_health_plan || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.num_health_plan <> i_row2.num_health_plan)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_health_plan || '</b></font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || i_row2.num_health_plan || '</b></font>' || chr(10);
            END IF;
        
        END IF;
    
        -- RECM
        IF (NOT (i_row1.id_recm IS NULL AND i_row2.id_recm IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T023');
        
            IF i_row1.id_recm IS NULL
            THEN
            
                SELECT t.code_recm
                  INTO l_ref1
                  FROM recm t
                 WHERE t.id_recm = i_row2.id_recm;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            END IF;
        
            IF i_row2.id_recm IS NULL
            THEN
            
                SELECT t.code_recm
                  INTO l_ref1
                  FROM recm t
                 WHERE t.id_recm = i_row1.id_recm;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.id_recm <> i_row2.id_recm)
            THEN
            
                SELECT t.code_recm
                  INTO l_ref1
                  FROM recm t
                 WHERE t.id_recm = i_row1.id_recm;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                SELECT t.code_recm
                  INTO l_ref1
                  FROM recm t
                 WHERE t.id_recm = i_row2.id_recm;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        --exemption -----------------------------------------------------------------------------------------------------------------------------
        IF (NOT (i_row1.id_isencao IS NULL AND i_row2.id_isencao IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T022');
        
            IF i_row1.id_isencao IS NULL
            THEN
            
                SELECT t.code_isencao
                  INTO l_ref1
                  FROM isencao t
                 WHERE t.id_isencao = i_row2.id_isencao;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.id_isencao IS NULL
            THEN
            
                SELECT t.code_isencao
                  INTO l_ref1
                  FROM isencao t
                 WHERE t.id_isencao = i_row1.id_isencao;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.id_isencao <> i_row2.id_isencao)
            THEN
            
                SELECT t.code_isencao
                  INTO l_ref1
                  FROM isencao t
                 WHERE t.id_isencao = i_row1.id_isencao;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                SELECT t.code_isencao
                  INTO l_ref1
                  FROM isencao t
                 WHERE t.id_isencao = i_row2.id_isencao;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- address
        IF (NOT (i_row1.address IS NULL AND i_row2.address IS NULL))
        THEN
        
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T006');
        
            IF i_row1.address IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.address || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.address IS NULL
            THEN
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.address || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.address <> i_row2.address)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.address || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.address || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        --LOCATION
        IF (NOT (i_row1.location IS NULL AND i_row2.location IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T008');
        
            IF i_row1.location IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.location || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.location IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.location || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.location <> i_row2.location)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.location || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.location || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- zip code
        IF (NOT (i_row1.zip_code IS NULL AND i_row2.zip_code IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T007');
        
            IF i_row1.zip_code IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.zip_code || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.zip_code IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.zip_code || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.zip_code <> i_row2.zip_code)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.zip_code || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.zip_code || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- district
        IF (NOT (i_row1.district IS NULL AND i_row2.district IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T009');
        
            IF i_row1.district IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.district || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.district IS NULL
            THEN
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.district || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.district <> i_row2.district)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.district || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.district || '</b></font>' || chr(10);
            END IF;
        
        END IF;
    
        -- main contact
        IF (NOT (i_row1.num_main_contact IS NULL AND i_row2.num_main_contact IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T032');
        
            IF i_row1.num_main_contact IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.num_main_contact || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.num_main_contact IS NULL
            THEN
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_main_contact || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.num_main_contact <> i_row2.num_main_contact)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_main_contact || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.num_main_contact || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- other contact
        IF (NOT (i_row1.num_contact IS NULL AND i_row2.num_contact IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T033');
        
            IF i_row1.num_contact IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.num_contact || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.num_contact IS NULL
            THEN
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_contact || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.num_contact <> i_row2.num_contact)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_contact || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.num_contact || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- marital status
        IF (NOT (i_row1.marital_status IS NULL AND i_row2.marital_status IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T011');
        
            -- retrieving the value, according to the language and flag
        
            l_tag_sd1 := pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', i_row1.marital_status, i_lang);
        
            -- retrieving the value, according to the language and flag
            l_tag_sd2 := pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.MARITAL_STATUS', i_row2.marital_status, i_lang);
        
            IF i_row1.marital_status IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_tag_sd2 || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.marital_status IS NULL
            THEN
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_tag_sd1 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.marital_status <> i_row2.marital_status)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_tag_sd1 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_tag_sd2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        --father name
        IF (NOT (i_row1.father_name IS NULL AND i_row2.father_name IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T014');
        
            IF i_row1.father_name IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.father_name || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.father_name IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.father_name || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.father_name <> i_row2.father_name)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.father_name || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.father_name || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        --mother name
        IF (NOT (i_row1.mother_name IS NULL AND i_row2.mother_name IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T015');
        
            IF i_row1.mother_name IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.mother_name || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.mother_name IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.mother_name || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.mother_name <> i_row2.mother_name)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.mother_name || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.mother_name || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- occupation (text))
        IF (NOT (i_row1.occupation_desc IS NULL AND i_row2.occupation_desc IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T020');
        
            IF i_row1.occupation_desc IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || i_row2.occupation_desc || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.occupation_desc IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.occupation_desc || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.occupation_desc <> i_row2.occupation_desc)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.occupation_desc || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.occupation_desc || '</b></font>' || chr(10);
            END IF;
        
        END IF;
    
        -- job status
        IF (NOT (i_row1.flg_job_status IS NULL AND i_row2.flg_job_status IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T013');
        
            l_tag_sd1 := pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', i_row1.flg_job_status, i_lang);
        
            l_tag_sd2 := pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_JOB_STATUS', i_row2.flg_job_status, i_lang);
        
            IF i_row1.flg_job_status IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || l_tag_sd2 || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.flg_job_status IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_tag_sd1 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.flg_job_status <> i_row2.flg_job_status)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_tag_sd1 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_tag_sd2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        -- scholarship
        IF (NOT (i_row1.id_scholarship IS NULL AND i_row2.id_scholarship IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T012');
        
            IF i_row1.id_scholarship IS NULL
            THEN
            
                SELECT t.code_scholarship
                  INTO l_ref1
                  FROM scholarship t
                 WHERE t.id_scholarship = i_row2.id_scholarship;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.id_scholarship IS NULL
            THEN
            
                SELECT t.code_scholarship
                  INTO l_ref1
                  FROM scholarship t
                 WHERE t.id_scholarship = i_row1.id_scholarship;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.id_scholarship <> i_row2.id_scholarship)
            THEN
            
                SELECT t.code_scholarship
                  INTO l_ref1
                  FROM scholarship t
                 WHERE t.id_scholarship = i_row1.id_scholarship;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                SELECT t.code_scholarship
                  INTO l_ref1
                  FROM scholarship t
                 WHERE t.id_scholarship = i_row2.id_scholarship;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        /*   
              -- nickname
              IF (NOT (i_row1.nick_name IS NULL AND i_row2.nick_name IS NULL))
              THEN
              
                  l_tag := pk_message.get_message(i_lang,
                                                        'IDENT_PATIENT_T029');
              
                  IF i_row1.nick_name IS NULL
                  THEN
                  
                      l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                              l_tag || ' : ' || '</font>' || chr(10);
                  
                      l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                            ' : ' || '<b>' || i_row2.nick_name || '</b></font>' || chr(10);
                  
                  END IF;
              
                  IF i_row2.nick_name IS NULL
                  THEN
                  
                      l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                              l_tag || ' : ' || '<b>' || i_row1.nick_name || '</b></font>' || chr(10);
                  
                      l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                            ' : ' || '</font>' || chr(10);
                  END IF;
              
                  IF (i_row1.nick_name <> i_row2.nick_name)
                  THEN
                  
                      l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                              l_tag || ' : ' || '<b>' || i_row1.nick_name || '</b></font>' || chr(10);
                  
                      l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                            ' : ' || '<b>' || i_row2.nick_name || '</b></font>' || chr(10);
                  
                  END IF;
              
              END IF;
        */
        -- occupation ID
        IF (NOT (i_row1.id_occupation IS NULL AND i_row2.id_occupation IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T020');
        
            IF i_row1.id_occupation IS NULL
            THEN
            
                SELECT t.code_occupation
                  INTO l_ref1
                  FROM occupation t
                 WHERE t.id_occupation = i_row2.id_occupation;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            END IF;
        
            IF i_row2.id_occupation IS NULL
            THEN
            
                SELECT t.code_occupation
                  INTO l_ref1
                  FROM occupation t
                 WHERE t.id_occupation = i_row1.id_occupation;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.id_occupation <> i_row2.id_occupation)
            THEN
            
                SELECT t.code_occupation
                  INTO l_ref1
                  FROM occupation t
                 WHERE t.id_occupation = i_row1.id_occupation;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
                SELECT t.code_occupation
                  INTO l_ref1
                  FROM occupation t
                 WHERE t.id_occupation = i_row2.id_occupation;
            
                l_ref2 := pk_translation.get_translation(i_lang, l_ref1);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || l_ref2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        IF (NOT (i_row1.desc_geo_state IS NULL AND i_row2.desc_geo_state IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T043');
        
            IF i_row1.desc_geo_state IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.desc_geo_state || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.desc_geo_state IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.desc_geo_state || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.desc_geo_state <> i_row2.desc_geo_state)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.desc_geo_state || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.desc_geo_state || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
    
        IF (NOT (i_row1.num_contrib IS NULL AND i_row2.num_contrib IS NULL))
        THEN
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T042');
        
            IF i_row1.num_contrib IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || i_row2.num_contrib || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.num_contrib IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_contrib || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.num_contrib <> i_row2.num_contrib)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || i_row1.num_contrib || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '<b>' || i_row2.num_contrib || '</b></font>' || chr(10);
            END IF;
        
        END IF;
    
        -- migrator
        IF (NOT (i_row1.flg_migrator IS NULL AND i_row2.flg_migrator IS NULL))
        THEN
        
            l_tag := pk_message.get_message(i_lang, 'IDENT_PATIENT_T044');
        
            l_tag_sd1 := pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_MIGRATOR', i_row1.flg_migrator, i_lang);
        
            l_tag_sd2 := pk_sysdomain.get_domain('PAT_SOC_ATTRIBUTES.FLG_MIGRATOR', i_row2.flg_migrator, i_lang);
        
            IF i_row1.flg_migrator IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '</font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || l_tag_sd2 || '</b></font>' || chr(10);
            
            END IF;
        
            IF i_row2.flg_migrator IS NULL
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_tag_sd1 || '</b></font>' || chr(10);
            
                l_buffer_past_info := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                      ' : ' || '</font>' || chr(10);
            
            END IF;
        
            IF (i_row1.flg_migrator <> i_row2.flg_migrator)
            THEN
            
                l_buffer_actual_info := l_buffer_actual_info || '<font face="Arial" color="#3c3c32" size="17">' ||
                                        l_tag || ' : ' || '<b>' || l_tag_sd1 || '</b></font>' || chr(10);
                l_buffer_past_info   := l_buffer_past_info || '<font face="Arial" color="#919178" size="17">' || l_tag ||
                                        ' : ' || '<b>' || l_tag_sd2 || '</b></font>' || chr(10);
            
            END IF;
        
        END IF;
        -------------------------------------------------------------------------------------------------------------------------------------------
        -------------------------------------------------------------------------------------------------------------------------------------------
    
        -- if the rows are equal, nothing is returned
    
        IF (l_buffer_actual_info IS NULL AND l_buffer_past_info IS NULL)
        THEN
            RETURN TRUE;
        END IF;
    
        -- if there are differences.....
    
        io_new_info.EXTEND;
        io_new_info(l_count + 1) := l_buffer_actual_info;
    
        io_old_info.EXTEND;
    
        --  the tag INFORMACAO DESACTUALIZADA should not appear in the outdated info buffer when the buffer is empty. Otherwise it should
        IF l_buffer_past_info IS NOT NULL
        THEN
            l_buffer_past_info := '<font face="Arial" color="#919178" size="17"><b>' || l_tag_desact_info ||
                                  '</b></font>' || chr(10) || l_buffer_past_info;
        END IF;
    
        io_old_info(l_count + 1) := l_buffer_past_info;
    
        -- doctor name
        io_doc_info.EXTEND;
    
        IF i_row1.id_professional IS NOT NULL
        THEN
				
            io_doc_info(l_count + 1) := '<font face="Arial" color="#3c3c32" size="15"><i>' || pk_prof_utils.get_name_signature ( i_lang, i_prof, i_row1.id_professional) || ' ' || '/' || ' ' ||
                                        '</i></font>';
        END IF;
				
				
				
    
        -- modification date and time
        io_date_time.EXTEND;
        io_date_time(l_count + 1) := '<font face="Arial" color="#3c3c32" size="15"><i>' ||
                                     pk_date_utils.date_time_chr_tsz(i_lang, i_row1.dt_change_tstz, i_prof) ||
                                     '</i></font>' || chr(10);
    
        RETURN TRUE;
    
    END find_differences;

    /********************************************************************************************
    * This function computes the history of all the changes ever done to a patients demographic data
    *  
    *
    * 
    * @param i_patient_code   Patient ID number
    * @param i_lang   ID of the language used by the professional
    * @param i_prof   professional ID + institution ID + software version
    * @param o_new_info   All the new information added
    * @param o_old_info   All the outdated information
    * @param o_doc_info   The name of the doctor who performed the modification
    * @param o_date_info   modification date and hour
    * @param o_error   error description
    *
    *
    * @return                TRUE on success; FALSE otherwise
    *
    *
    * @author                Rui Abreu
    * @since                 2007/03/22
       ********************************************************************************************/
    FUNCTION get_dmgr_hist
    (
        i_patient_code IN NUMBER,
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        o_new_info     OUT table_varchar,
        o_old_info     OUT table_varchar,
        o_doc_info     OUT table_varchar,
        o_date_info    OUT table_varchar,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_change_row pat_dmgr_hist%ROWTYPE;
        l_temp_row   pat_dmgr_hist%ROWTYPE;
        l_fake_row   pat_dmgr_hist%ROWTYPE;
        l_boolean    BOOLEAN;
    
        l_new_info  table_varchar := table_varchar();
        l_old_info  table_varchar := table_varchar();
        l_doc_name  table_varchar := table_varchar();
        l_date_time table_varchar := table_varchar();
    
        /* seleccionar as linhas correspondentes ao paciente */
        CURSOR c_1(id_pacient NUMBER) IS
            SELECT t.*
            --  FROM dmgr_test t
              FROM pat_dmgr_hist t
             WHERE t.id_patient = i_patient_code
             ORDER BY t.dt_change_tstz DESC;
    
    BEGIN
    
        l_temp_row.id_patient := NULL;
    
        /* seleccionar todas as linhas correspondentes ao ID do paciente passado como parâmetro, POR ORDEM DECRESCENTE da data de alteração */
        OPEN c_1(i_patient_code);
        LOOP
            FETCH c_1
                INTO l_change_row;
            EXIT WHEN c_1%NOTFOUND;
        
            IF l_temp_row.id_patient IS NOT NULL
            THEN
            
                /* comparaçao das linhas, duas a duas */
                l_boolean := find_differences(l_temp_row,
                                              l_change_row,
                                              i_lang,
                                              i_prof,
                                              l_new_info,
                                              l_old_info,
                                              l_doc_name,
                                              l_date_time);
            
            END IF;
        
            l_temp_row := l_change_row;
        
        END LOOP;
    
        -- comparaçao entre a última linha e uma linha propositadamente vazia, para ter as alteracoes iniciais
    
        IF (c_1%ROWCOUNT != 1)
        THEN
            l_boolean := find_differences(l_temp_row,
                                          l_fake_row,
                                          i_lang,
                                          i_prof,
                                          l_new_info,
                                          l_old_info,
                                          l_doc_name,
                                          l_date_time);
        END IF;
    
        /* entra aqui se a tabela só tem uma linha */
        IF (c_1%ROWCOUNT = 1)
        THEN
            --  dbms_output.put_line('Tabela so tem uma linha');
            l_boolean := find_differences(l_change_row,
                                          l_fake_row,
                                          i_lang,
                                          i_prof,
                                          l_new_info,
                                          l_old_info,
                                          l_doc_name,
                                          l_date_time);
        
            /* preenchimento dos parâmetros de retorno, provenientes da comparacao das linhas */
            o_new_info  := l_new_info;
            o_old_info  := l_old_info;
            o_doc_info  := l_doc_name;
            o_date_info := l_date_time;
        
            RETURN TRUE;
        END IF;
    
        CLOSE c_1;
    
        o_new_info  := l_new_info;
        o_old_info  := l_old_info;
        o_doc_info  := l_doc_name;
        o_date_info := l_date_time;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
						
				    pk_alert_exceptions.process_error(i_lang, SQLCODE, SQLERRM, pk_message.get_message(i_lang, 'COMMON_M001'), 'ALERT', 'PK_DMGR_HIST', 'GET_DMGR_HIST', o_error); 
						
						pk_utils.undo_changes;
            RETURN false; 
        
    END get_dmgr_hist;

END pk_dmgr_hist;
-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------
/
