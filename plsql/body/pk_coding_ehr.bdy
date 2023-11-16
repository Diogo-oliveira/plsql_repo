/*-- Last Change Revision: $Rev: 2020537 $*/
/*-- Last Change by: $Author: humberto.cardoso $*/
/*-- Date of last change: $Date: 2022-08-01 16:07:44 +0100 (seg, 01 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_coding_ehr IS

    -- =========================== Private constant declarations =====================
    k_yes CONSTANT VARCHAR2(1) := 'Y';
    k_no  CONSTANT VARCHAR2(1) := 'N';

    -- =========================== Private variables =====================
    g_package_owner VARCHAR2(30 CHAR); -- Log and debug
    g_package_name  VARCHAR2(30 CHAR); -- Log and debug

    tbl_ids_ehr              table_number; -- Stores the list of PK that identifies the records in each area.
    tbl_ehr_descriptions     table_varchar; -- Stores the list of descriptions for the records.
    tbl_codes_translations   table_varchar; -- Stores the list of translation codes for the ehr description. To use when the content can be collected using pk_translation
    tbl_ids_cnt              table_number; -- Store the list of ID's that internally identifies the content related with this EHR record.
    tbl_ehr_count            table_number; --Store the list of the number of ocurrences of the EHR
    tbl_flgs_status          table_varchar; -- Store the list of the status of the item in the current area.
    tbl_ids_content          table_varchar; -- Store the list of the ID_CONTENTs to use in mappings.
    tbl_ids_terminologies    table_number; -- Store the list of the ID's of the terminologies.
    tbl_standard_codes       table_varchar; -- Store the list of the codes used to represent the records.
    tbl_stadatd_descriptions table_varchar; -- Store the list of the descriptions of the terminologies.
    tbl_dt_last_update       table_date; -- Store the list of dates of the last update of the records in this area.
    tbl_ranks                table_number; -- Store the list of the ranks.

    -- =========================== Private functions =====================
    /**
    * Gets the row type t_coding_ehr_item with the default values.
    * Used to avoid code duplication.
    *
    * @return                               The t_coding_ehr_item with the default values.
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION get_default_row RETURN t_coding_ehr_item IS
        l_row t_coding_ehr_item;
    BEGIN
        RETURN l_row;
    END get_default_row;

    /**
    * Get the value of the table in the specified index.
    * If the table is null, return the default value.
    * Used to avoid code duplication.
    *
    * @param i_table                        The table used to get the data.
    * @param i_index                        The index of the row to collect the value.
    * @param i_default                      The value to return if the table is null
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/12
    */
    FUNCTION get_value
    (
        i_table   IN table_number,
        i_index   IN NUMBER,
        i_default IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN i_default;
        ELSE
            RETURN i_table(i_index);
        END IF;
    END get_value;

    /**
    * Get the value of the table in the specified index.
    * If the table is null, return the default value.
    * Used to avoid code duplication.
    *
    * @param i_table                        The table used to get the data.
    * @param i_index                        The index of the row to collect the value.
    * @param i_default                      The value to return if the table is null
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/12
    */
    FUNCTION get_value
    (
        i_table   IN table_varchar,
        i_index   IN NUMBER,
        i_default IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN i_default;
        ELSE
            RETURN i_table(i_index);
        END IF;
    END get_value;

    /**
    * Get the value of the table in the specified index.
    * If the table is null, return the default value.
    * Used to avoid code duplication.
    *
    * @param i_table                        The table used to get the data.
    * @param i_index                        The index of the row to collect the value.
    * @param i_default                      The value to return if the table is null
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/12
    */
    FUNCTION get_value
    (
        i_table   IN table_date,
        i_index   IN NUMBER,
        i_default IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        IF i_table IS NULL
        THEN
            RETURN i_default;
        ELSE
            RETURN i_table(i_index);
        END IF;
    END get_value;

    /**
    * Loads the values collected to the global tables into the coding table.
    * Clear all the tables when completed.
    * Used to avoid code duplication.
    *
    * @param io_table                       The table to fill.
    * @param i_lang                         The language identifier to use when working with translations.
    * @param i_ehr_source                   The source where the ID_EHR is stored. Format should be: TABLE_NAME.COLUMN_NAME
    * @param i_cnt_source                   The source where the ID_CNT is stored. Format should be: TABLE_NAME.COLUMN_NAME
    * @param i_code_domain                  The sys_domain.code_domain value that can be used to evaluate the status. 
    * @param i_termin_source                The source of terminolgies in this area: TERMINOLOGY / CODIFICATION.
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/12
    */
    PROCEDURE load_and_clear
    (
        io_table        IN OUT NOCOPY table_coding_ehr_item,
        i_lang          IN language.id_language%TYPE,
        i_ehr_source    IN VARCHAR2,
        i_cnt_source    IN VARCHAR2,
        i_code_domain   IN VARCHAR2,
        i_termin_source IN VARCHAR2 DEFAULT NULL
    ) IS
        -- Private variables  
        l_old_rows NUMBER; -- Stores the number of existing rows
        l_row      pk_coding_ehr.t_coding_ehr_item; -- Stores each record
    
    BEGIN
        -- Gets the number of existing rows and rows to copy
        l_old_rows := io_table.count();
    
        -- For each record stored in the global variables
        FOR i IN 1 .. tbl_ids_ehr.count()
        LOOP
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Copy all the necessary values
            l_row.id_ehr               := tbl_ids_ehr(i);
            l_row.ehr_source           := i_ehr_source;
            l_row.id_cnt               := tbl_ids_cnt(i);
            l_row.cnt_source           := i_cnt_source;
            l_row.ehr_count            := get_value(tbl_ehr_count, i);
            l_row.flg_status           := tbl_flgs_status(i);
            l_row.code_domain          := i_code_domain;
            l_row.id_content           := get_value(i_table => tbl_ids_content, i_index => i);
            l_row.termin_source        := i_termin_source;
            l_row.id_terminology       := get_value(i_table => tbl_ids_terminologies, i_index => i);
            l_row.standard_code        := get_value(i_table => tbl_standard_codes, i_index => i);
            l_row.standard_description := get_value(i_table => tbl_stadatd_descriptions, i_index => i);
            l_row.dt_last_update       := get_value(i_table => tbl_dt_last_update, i_index => i);
            l_row.rank                 := get_value(i_table => tbl_ranks, i_index => i);
        
            -- Gets the descriptions
            IF tbl_ehr_descriptions IS NOT NULL
            THEN
                l_row.ehr_description := tbl_ehr_descriptions(i);
            
            ELSIF tbl_codes_translations IS NOT NULL
            THEN
                l_row.ehr_description := pk_translation.get_translation(i_lang      => i_lang,
                                                                        i_code_mess => tbl_codes_translations(i));
            END IF;
        
            -- Add the row to the collection
            io_table.extend();
            io_table(l_old_rows + i) := l_row;
        END LOOP;
    
        -- Clear all the global tables
        tbl_ids_ehr              := NULL;
        tbl_ehr_descriptions     := NULL;
        tbl_codes_translations   := NULL;
        tbl_ids_cnt              := NULL;
        tbl_ehr_count            := NULL;
        tbl_flgs_status          := NULL;
        tbl_ids_content          := NULL;
        tbl_ids_terminologies    := NULL;
        tbl_standard_codes       := NULL;
        tbl_stadatd_descriptions := NULL;
        tbl_dt_last_update       := NULL;
        tbl_ranks                := NULL;
    
    END load_and_clear;

    /**
    * Get the diagnosis according to the input parameters.
    * PRIVATE: avoid code duplication.
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_diagnoses
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_type       IN epis_diagnosis.flg_type%TYPE,
        i_flg_final_type IN epis_diagnosis.flg_final_type%TYPE
    ) RETURN table_coding_ehr_item IS
    
        -- Private variables
        l_row          t_coding_ehr_item; -- Stores each record
        l_table        table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
        l_id_term_type NUMBER := pk_ts_logic.k_id_term_type_preferred; -- Stores the id of the preferred term
    
    BEGIN
        -- Gets the records from epis_diagnosis
        FOR r IN (SELECT e.id_epis_diagnosis,
                         e.id_diagnosis,
                         e.flg_status,
                         c.id_terminology,
                         c.code,
                         e.id_alert_diagnosis,
                         (SELECT id_concept_term
                            FROM ( -- Prefered terms can be not available for outdated codes
                                  SELECT ct.id_concept_term,
                                          row_number() over(ORDER BY ct.flg_available DESC, ct.id_concept_term) AS rn
                                    FROM concept_term ct
                                   WHERE ct.id_concept_vers_start = cv.id_concept_version
                                     AND ct.id_cncpt_vrs_inst_owner = cv.id_inst_owner
                                     AND ct.id_concept_term_type = l_id_term_type)
                           WHERE rn = 1) AS id_preferred_term,
                         coalesce(e.dt_epis_diagnosis_tstz, e.dt_cancel_tstz, e.dt_rulled_out_tstz, e.dt_confirmed_tstz) AS dt_last_update,
                         row_number() over(ORDER BY e.id_epis_diagnosis) AS rn
                    FROM epis_diagnosis e
                   INNER JOIN concept_version cv
                      ON cv.id_concept_version = e.id_diagnosis
                     AND cv.id_inst_owner = e.id_diag_inst_owner
                   INNER JOIN concept c
                      ON c.id_concept = cv.id_concept
                     AND c.id_inst_owner = cv.id_concept_inst_owner
                   WHERE e.id_episode = i_episode
                     AND e.flg_type = i_flg_type
                     AND e.flg_final_type = i_flg_final_type
                   ORDER BY e.id_epis_diagnosis)
        LOOP
        
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Set the values for this area
            l_row.id_ehr         := r.id_epis_diagnosis;
            l_row.ehr_source     := 'EPIS_DIAGNOSIS.ID_EPIS_DIAGNOSIS';
            l_row.flg_status     := r.flg_status;
            l_row.code_domain    := 'EPIS_DIAGNOSIS.FLG_STATUS';
            l_row.id_content     := NULL;
            l_row.termin_source  := 'TERMINOLOGY';
            l_row.id_terminology := r.id_terminology;
            l_row.standard_code  := r.code;
            l_row.rank           := r.rn;
            l_row.dt_last_update := r.dt_last_update;
        
            -- Gets the discriptions
            -- The standard description is the preferred term
            l_row.standard_description := pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                  i_id_concept_term => r.id_preferred_term,
                                                                                  i_id_task_type    => 63);
        
            -- If there is no id_alert_diagnosis the preferred term is considered
            -- TODO: This area needs to be updated: IS POSSIBLE to have a preferred term updated and the EHR record can change
            IF r.id_alert_diagnosis IS NULL
            THEN
                l_row.id_cnt          := r.id_diagnosis;
                l_row.cnt_source      := 'CONCEPT_VERSION.ID_CONCEPT_VERSION';
                l_row.ehr_description := l_row.standard_description;
            
            ELSE
                l_row.id_cnt     := r.id_alert_diagnosis;
                l_row.cnt_source := 'CONCEPT_TERM.ID_CONCEPT_TERM';
                -- Collect the description for the preferred term
                l_row.ehr_description := pk_ts_core_ro.get_term_desc_translation(i_id_language     => i_lang,
                                                                                 i_id_concept_term => r.id_alert_diagnosis,
                                                                                 i_id_task_type    => 63);
            END IF;
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_diagnoses;

    /**
    * Get the exams according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    * @param i_exam_flg_type                Filter the Exam type: I - Imaging; E - Other exams 
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_exams
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_exam_flg_type exam.flg_type%TYPE
    ) RETURN table_coding_ehr_item IS
    
        -- Private variables
        l_row   pk_coding_ehr.t_coding_ehr_item; -- Stores each record
        l_table table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
    
    BEGIN
        -- EMR-52837: Get the exams from the EA: improves performance
        FOR r IN (SELECT ea.id_exam_req_det,
                         e.id_exam,
                         e.id_content,
                         e.code_exam,
                         ea.flg_status_req AS flg_status,
                         ec.id_codification,
                         ec.standard_code,
                         ec.standard_desc,
                         coalesce(ea.dt_dg_last_update, ea.dt_begin, ea.dt_req) AS dt_last_update,
                         row_number() over(ORDER BY coalesce(ea.dt_dg_last_update, ea.dt_begin, ea.dt_req)) AS rn
                    FROM exams_ea ea
                   INNER JOIN exam e
                      ON e.id_exam = ea.id_exam
                    LEFT OUTER JOIN exam_codification ec
                      ON ec.id_exam_codification = ea.id_exam_codification
                   WHERE ea.id_episode = i_episode -- Filter the current episode
                     AND ea.flg_time = 'E' -- E: This episone
                     AND ea.flg_type = i_exam_flg_type -- Filter the Exam type: I - Imaging; E - Other exams 
                  )
        
        LOOP
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Set the values for this area
            -- The translation uses a function of the EHR area
            l_row.id_ehr               := r.id_exam_req_det;
            l_row.ehr_description      := pk_exam_utils.get_alias_translation(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_code_exam => r.code_exam);
            l_row.ehr_source           := 'EXAM_REQ_DET.ID_EXAM_REQ_DET';
            l_row.id_cnt               := r.id_exam;
            l_row.cnt_source           := 'EXAM.ID_EXAM';
            l_row.flg_status           := r.flg_status;
            l_row.code_domain          := 'EXAM_REQ_DET.FLG_STATUS';
            l_row.id_content           := r.id_content;
            l_row.termin_source        := 'CODIFICATION';
            l_row.id_terminology       := r.id_codification;
            l_row.standard_code        := r.standard_code;
            l_row.standard_description := r.standard_desc;
            l_row.dt_last_update       := r.dt_last_update;
            l_row.rank                 := r.rn;
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_exams;

    /**
    * Get the supplies according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    * @param i_flg_reusable                 Filter using the flg_reusable: Y - Yes; N - No
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_supplies
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_reusable IN supply_workflow.flg_reusable%TYPE
    ) RETURN table_coding_ehr_item IS
        l_row   pk_coding_ehr.t_coding_ehr_item; -- Stores each record
        l_table table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
    BEGIN
        -- Get supplies
        FOR r IN (
                  -- To remove after EMR-53142
                      WITH temp_supply_workflow AS
                       (SELECT ww.id_episode,
                               ww.id_supply_workflow,
                               ww.id_supply,
                               ww.quantity,
                               ww.flg_status,
                               ww.flg_outdated,
                               coalesce((SELECT si.flg_reusable
                                          FROM supply_soft_inst si
                                         WHERE si.id_supply = ww.id_supply
                                           AND si.id_institution = i_prof.institution
                                           AND si.id_software = i_prof.software),
                                        ww.flg_reusable) AS flg_reusable,
                               ww.dt_supply_workflow
                          FROM supply_workflow ww
                         WHERE ww.id_episode = i_episode)
                      SELECT w.id_supply_workflow,
                             s.id_supply,
                             s.id_content,
                             s.code_supply,
                             w.quantity AS ehr_count,
                             w.flg_status,
                             w.dt_supply_workflow AS dt_last_update,
                             row_number() over(ORDER BY w.dt_supply_workflow) AS rn
                        FROM temp_supply_workflow w
                       INNER JOIN supply s
                          ON s.id_supply = w.id_supply
                       WHERE w.id_episode = i_episode -- Filter the current episode
                         AND w.flg_outdated = 'A' -- Record is not outdated
                         AND w.flg_status != 'X' -- Status assumed when the supply is used after request; Another record is created
                         AND w.flg_reusable = coalesce(i_flg_reusable, w.flg_reusable) -- Filter flg_reusable
                  )
        LOOP
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Set the values for this area
            l_row.id_ehr               := r.id_supply_workflow;
            l_row.ehr_description      := pk_translation.get_translation(i_lang => i_lang, i_code_mess => r.code_supply);
            l_row.ehr_source           := 'SUPPLY_WORKFLOW.ID_SUPPLY_WORKFLOW';
            l_row.id_cnt               := r.id_supply;
            l_row.cnt_source           := 'SUPPLY.ID_SUPPLY';
            l_row.ehr_count            := r.ehr_count;
            l_row.flg_status           := r.flg_status;
            l_row.code_domain          := 'SUPPLY_WORKFLOW.FLG_STATUS';
            l_row.id_content           := r.id_content;
            l_row.termin_source        := 'NONE';
            l_row.id_terminology       := NULL;
            l_row.standard_code        := NULL;
            l_row.standard_description := NULL;
            l_row.dt_last_update       := r.dt_last_update;
            l_row.rank                 := r.rn;
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_supplies;

    -- =========================== Public functions =====================

    /**
    * Get the primary discharge diagnosis according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_main_discharge_diagnoses
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
    BEGIN
        -- Return the value of the main function sending the correct arguments
        -- Main discharge diagnoses
        RETURN tf_get_diagnoses(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => i_episode,
                                i_flg_type       => 'D', -- (D)-> Final/discharge diagnois; (P)->Differential; (B)->Primary (Oris)
                                i_flg_final_type => 'P' -- Primary diagnosis
                                );
    
    END tf_get_main_discharge_diagnoses;

    /**
    * Get the secondary discharge diagnoses according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_secondary_discharge_diagnoses
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
    BEGIN
        -- Return the value of the main function sending the correct arguments
        -- Main discharge diagnoses
        RETURN tf_get_diagnoses(i_lang           => i_lang,
                                i_prof           => i_prof,
                                i_episode        => i_episode,
                                i_flg_type       => 'D', -- (D)-> Final/discharge diagnois; (P)->Differential; (B)->Primary (Oris)
                                i_flg_final_type => 'S' -- Secondary diagnosis  
                                );
    
    END tf_get_secondary_discharge_diagnoses;

    /**
    * Get the imaging exams according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_imaging_exams
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
    BEGIN
        -- Return the value of the main function sending the correct arguments
        -- Imaging exams
        RETURN tf_get_exams(i_lang          => i_lang,
                            i_prof          => i_prof,
                            i_episode       => i_episode,
                            i_exam_flg_type => 'I' -- Filter the Exam type: I - Imaging; 
                            );
    
    END tf_get_imaging_exams;

    /**
    * Get the other exams according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_other_exams
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
    BEGIN
        -- Return the value of the main function sending the correct arguments
        -- Imaging exams
        RETURN tf_get_exams(i_lang          => i_lang,
                            i_prof          => i_prof,
                            i_episode       => i_episode,
                            i_exam_flg_type => 'E' -- Filter the Exam type: E - Other exams
                            );
    
    END tf_get_other_exams;

    /**
    * Get the procedures/interventions according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_procedures
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
        -- Declares the cursor to collect the data
        CURSOR cursor_data IS
            SELECT ea.id_interv_presc_det,
                   i.id_intervention,
                   i.code_intervention,
                   i.id_content,
                   ea.flg_status_det,
                   ic.id_codification,
                   ic.standard_code,
                   ic.standard_desc,
                   coalesce(ea.update_time, ea.dt_interv_prescription, ea.dt_plan, ea.dt_begin_det) AS dt_last_update,
                   row_number() over(ORDER BY ea.id_interv_presc_det) AS rn
              FROM alert.procedures_ea ea
             INNER JOIN intervention i
                ON i.id_intervention = ea.id_intervention
              LEFT OUTER JOIN interv_codification ic
                ON ic.id_interv_codification = ea.id_interv_codification
             WHERE ea.id_episode = i_episode -- Filter the current episode
               AND ea.flg_time IN ('E', 'A', 'H'); -- Execution type: (E)pisode, (A)ll, ,(H) Executed in various episodes
    
        -- Declares the cursor types
        TYPE table_cursor IS TABLE OF cursor_data%ROWTYPE;
    
        -- Private variables
        l_row   pk_coding_ehr.t_coding_ehr_item; -- Stores each record
        l_table table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
        c_row   cursor_data%ROWTYPE; -- Stores single cursor row
        c_table table_cursor; -- Stores all the cursor rows
    
    BEGIN
        -- Collect all the data
        OPEN cursor_data;
        FETCH cursor_data BULK COLLECT
            INTO c_table;
        CLOSE cursor_data;
    
        -- Process the collected data
        FOR i IN 1 .. c_table.count
        LOOP
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Store the current row
            c_row := c_table(i);
        
            -- Set the values for this area
            -- The translation uses a function of the EHR area
            l_row.id_ehr               := c_row.id_interv_presc_det;
            l_row.ehr_description      := pk_procedures_utils.get_alias_translation(i_lang        => i_lang,
                                                                                    i_prof        => i_prof,
                                                                                    i_code_interv => c_row.code_intervention);
            l_row.ehr_source           := 'PROCEDURES_EA.ID_ID_INTERV_PRESC_DET';
            l_row.id_cnt               := c_row.id_intervention;
            l_row.cnt_source           := 'INTERVENTION.ID_INTERVENTION';
            l_row.flg_status           := c_row.flg_status_det;
            l_row.code_domain          := 'INTERV_PRESC_DET.FLG_STATUS';
            l_row.id_content           := c_row.id_content;
            l_row.termin_source        := 'CODIFICATION';
            l_row.id_terminology       := c_row.id_codification;
            l_row.standard_code        := c_row.standard_code;
            l_row.standard_description := c_row.standard_desc;
            l_row.dt_last_update       := c_row.dt_last_update;
            l_row.rank                 := c_row.rn;
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_procedures;

    /**
    * Get the lab tests according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_lab_tests
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
        -- Private variables
        l_row   pk_coding_ehr.t_coding_ehr_item; -- Stores each record
        l_table table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
    
    BEGIN
        -- EMR-52837: Use lab_tests_ea and not analysis_req_det:
        --    analysis_req_det have records with analysis_req_det.flg_status = 'DF' that are not visible in the application
        --    better performance
        FOR r IN (SELECT ea.id_analysis_req_det,
                         a.id_analysis,
                         a.id_content,
                         a.code_analysis,
                         (SELECT st.code_sample_type
                            FROM sample_type st
                           WHERE st.id_sample_type = ea.id_sample_type) AS code_sample_type,
                         ea.flg_status_req AS flg_status,
                         ac.id_codification,
                         ac.standard_code,
                         ac.standard_desc,
                         ea.dt_dg_last_update AS dt_last_update,
                         row_number() over(ORDER BY ea.dt_dg_last_update) AS rn
                    FROM lab_tests_ea ea
                   INNER JOIN analysis a
                      ON a.id_analysis = ea.id_analysis
                    LEFT OUTER JOIN analysis_codification ac
                      ON ac.id_analysis_codification = ea.id_analysis_codification
                   WHERE ea.id_episode = i_episode -- Filter the current episode
                     AND ea.flg_time_harvest = 'E' -- E: This episode 
                  )
        
        LOOP
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Set the values for this area
            -- The translation uses a function of the EHR area
            l_row.id_ehr          := r.id_analysis_req_det;
            l_row.ehr_description := pk_lab_tests_utils.get_alias_translation(i_lang                      => i_lang,
                                                                              i_prof                      => i_prof,
                                                                              i_flg_type                  => 'A', --Flag that indicates the type of alias:  A - Lab Tests
                                                                              i_analysis_code_translation => r.code_analysis,
                                                                              i_sample_code_translation   => r.code_sample_type,
                                                                              i_dep_clin_serv             => NULL);
        
            l_row.ehr_source           := 'ANALYSIS_REQ_DET.ID_ANALYSIS_REQ_DET';
            l_row.id_cnt               := r.id_analysis;
            l_row.cnt_source           := 'ANALYSIS.ID_ANALYSIS';
            l_row.flg_status           := r.flg_status;
            l_row.code_domain          := 'ANALYSIS_REQ_DET.FLG_STATUS';
            l_row.id_content           := r.id_content;
            l_row.termin_source        := 'CODIFICATION';
            l_row.id_terminology       := r.id_codification;
            l_row.standard_code        := r.standard_code;
            l_row.standard_description := r.standard_desc;
            l_row.dt_last_update       := r.dt_last_update;
            l_row.rank                 := r.rn;
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_lab_tests;

    /**
    * Get the vital signs records according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_vital_signs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
        -- Private variables
        l_table      table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
        l_table_pdms table_number; -- Store the PDMS ID's
    
    BEGIN
        -- Collect the pdms equipment
        l_table_pdms := alert_pdms_tr.pk_coding_pdms.tf_get_vs_equipment_ids();
    
        -- Collect the records into the variables
        SELECT vr.id_vital_sign_read,
               vs.code_vital_sign,
               vr.flg_state,
               vs.id_vital_sign,
               vs.id_content,
               decode(vr.flg_state, 'C', vr.dt_cancel_tstz, vr.dt_vital_sign_read_tstz) AS dt_last_update
          BULK COLLECT
          INTO tbl_ids_ehr, tbl_codes_translations, tbl_flgs_status, tbl_ids_cnt, tbl_ids_content, tbl_dt_last_update
          FROM vital_sign_read vr
         INNER JOIN vital_sign vs
            ON vs.id_vital_sign = vr.id_vital_sign
         WHERE vr.id_episode = i_episode
           AND vr.id_vital_sign NOT IN (SELECT column_value
                                          FROM TABLE(l_table_pdms)) -- Exclude pdms equipment
         ORDER BY 1;
    
        -- Load the data into the table, sending the values for this area
        load_and_clear(io_table      => l_table,
                       i_lang        => i_lang,
                       i_ehr_source  => 'VITAL_SIGN_READ.ID_VITAL_SIGN_READ',
                       i_cnt_source  => 'VITAL_SIGN.ID_VITAL_SIGN',
                       i_code_domain => 'VITAL_SIGN_READ.FLG_STATE');
    
        -- Some vital signs like blood pressure are gruped
        -- For these records the 'ID' is converted using the date
        SELECT to_number(to_char(vr.dt_vital_sign_read_tstz, 'yyyymmddhh24miss')) AS id_ehr,
               vsp.code_vital_sign,
               vr.flg_state,
               vsp.id_vital_sign,
               vsp.id_content,
               decode(vr.flg_state, 'C', vr.dt_cancel_tstz, vr.dt_vital_sign_read_tstz) AS dt_last_update
          BULK COLLECT
          INTO tbl_ids_ehr, tbl_codes_translations, tbl_flgs_status, tbl_ids_cnt, tbl_ids_content, tbl_dt_last_update
          FROM vital_sign_read vr
         INNER JOIN alert.vital_sign_relation r
            ON r.id_vital_sign_detail = vr.id_vital_sign
           AND r.relation_domain IN ('C', 'S') -- Relation domain: C -concatenation (e.g. blood pressurel), S - sum (e.g. Glasgow)
         INNER JOIN vital_sign vsp
            ON vsp.id_vital_sign = r.id_vital_sign_parent
         WHERE vr.id_episode = i_episode
           AND vr.id_vital_sign NOT IN (SELECT column_value
                                          FROM TABLE(l_table_pdms)) -- Exclude pdms equipment
         GROUP BY to_number(to_char(vr.dt_vital_sign_read_tstz, 'yyyymmddhh24miss')),
                  vr.flg_state,
                  vsp.id_vital_sign,
                  vsp.code_vital_sign,
                  vsp.intern_name_vital_sign,
                  vsp.id_content,
                  decode(vr.flg_state, 'C', vr.dt_cancel_tstz, vr.dt_vital_sign_read_tstz)
         ORDER BY 1;
    
        -- Load the data into the table
        -- Set the values for this area
        load_and_clear(io_table      => l_table,
                       i_lang        => i_lang,
                       i_ehr_source  => 'VITAL_SIGN_READ.DT_VITAL_SIGN_READ_TSTZ',
                       i_cnt_source  => 'VITAL_SIGN.ID_VITAL_SIGN',
                       i_code_domain => 'VITAL_SIGN_READ.FLG_STATE');
    
        -- Return the table
        RETURN l_table;
    END tf_get_vital_signs;

    /**
    * Get the consult requests/opinions according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_consult_requests
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
        -- Private variables
        l_table table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
    
    BEGIN
        -- Gets the records from opinion
        -- Records can be related with clinical service or speciality
        -- The collection of data is easy with two queries
    
        -- Collect by clinical service
        SELECT p.id_opinion,
               p.flg_state,
               coalesce(p.dt_approved, p.dt_cancel_tstz, p.dt_problem_tstz, p.dt_last_update) AS dt_last_update,
               cs.id_clinical_service AS cnt_id,
               cs.code_clinical_service AS code_translation,
               cs.id_content
          BULK COLLECT
          INTO tbl_ids_ehr, tbl_flgs_status, tbl_dt_last_update, tbl_ids_cnt, tbl_codes_translations, tbl_ids_content
          FROM opinion p
         INNER JOIN clinical_service cs
            ON cs.id_clinical_service = p.id_clinical_service
         WHERE p.id_episode = i_episode -- Filter the current episode
           AND p.id_opinion_type IS NULL;
    
        -- Load the data into the table, sending the values for this area
        load_and_clear(io_table      => l_table,
                       i_lang        => i_lang,
                       i_ehr_source  => 'OPINION.ID_OPINION',
                       i_cnt_source  => 'CLINICAL_SERVICE.ID_CLINICAL_SERVICE',
                       i_code_domain => 'OPINION.FLG_STATE');
    
        -- Collect by SPECIALITY
        SELECT p.id_opinion,
               p.flg_state,
               coalesce(p.dt_approved, p.dt_cancel_tstz, p.dt_problem_tstz, p.dt_last_update) AS dt_last_update,
               s.id_speciality,
               s.code_speciality,
               s.id_content
          BULK COLLECT
          INTO tbl_ids_ehr, tbl_flgs_status, tbl_dt_last_update, tbl_ids_cnt, tbl_codes_translations, tbl_ids_content
          FROM opinion p
         INNER JOIN speciality s
            ON s.id_speciality = p.id_speciality
         WHERE p.id_episode = i_episode -- Filter the current episode
           AND p.id_opinion_type IS NULL;
    
        -- Load the data into the table, sending the values for this area
        load_and_clear(io_table      => l_table,
                       i_lang        => i_lang,
                       i_ehr_source  => 'OPINION.ID_OPINION',
                       i_cnt_source  => 'SPECIALITY.ID_SPECIALITY',
                       i_code_domain => 'OPINION.FLG_STATE');
    
        -- Return the table
        RETURN l_table;
    END tf_get_consult_requests;

    /**
    * Get the progress notes according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.2.0
    * @since                                2020/10/07
    */
    FUNCTION tf_get_progress_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
        -- Private variables
        l_row              t_coding_ehr_item; -- Stores each record
        l_table            table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
        l_id_software      NUMBER := i_prof.software;
        l_id_market        NUMBER := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_id_category      NUMBER := pk_prof_utils.get_id_category(i_lang, i_prof);
        l_id_prof_template NUMBER := pk_prof_utils.get_prof_profile_template(i_prof);
    
    BEGIN
        -- Gets the records from epis_pn
        FOR r IN (
                  -- Collect the necessary flg to detect "automatic" notes
                      WITH mkt_config AS
                       (SELECT p.id_pn_area,
                               p.flg_synchronized,
                               row_number() over(PARTITION BY p.id_pn_area ORDER BY p.id_software DESC, p.id_market DESC, p.id_category DESC, p.id_profile_template DESC) AS rn
                          FROM pn_note_type_mkt p
                         WHERE p.id_software IN (-1, l_id_software)
                           AND p.id_market IN (0, l_id_market)
                           AND p.id_category IN (-1, l_id_category)
                           AND p.id_profile_template IN (0, l_id_prof_template))
                      -- Collect the data
                      SELECT epn.id_epis_pn,
                             epn.flg_status,
                             a.code_pn_area,
                             epn.id_pn_area,
                             a.internal_name AS pn_area_internal_name,
                             coalesce(epn.dt_signoff, epn.dt_last_update, epn.dt_pn_date, epn.dt_create) note_date,
                             row_number() over(ORDER BY coalesce(epn.dt_signoff, epn.dt_last_update, epn.dt_pn_date, epn.dt_create)) AS rn
                        FROM epis_pn epn
                       INNER JOIN episode epis
                          ON epn.id_episode = epis.id_episode
                       INNER JOIN pn_area a
                          ON a.id_pn_area = epn.id_pn_area
                        LEFT OUTER JOIN mkt_config m
                          ON m.id_pn_area = epn.id_pn_area
                         AND m.rn = 1
                       WHERE epis.id_episode = i_episode
                         AND coalesce(m.flg_synchronized, 'N') = 'N' -- Exclude "automatic" notes
                  )
        LOOP
        
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Set the values for this area
            l_row.id_ehr               := r.id_epis_pn;
            l_row.ehr_description      := pk_message.get_message(i_lang => i_lang, i_code_mess => r.code_pn_area);
            l_row.ehr_source           := 'EPIS_PN.ID_EPIS_PN';
            l_row.id_cnt               := r.id_pn_area;
            l_row.cnt_source           := 'PN_AREA.ID_PN_AREA';
            l_row.flg_status           := r.flg_status;
            l_row.code_domain          := 'EPIS_PN.FLG_STATUS';
            l_row.id_content           := r.pn_area_internal_name;
            l_row.termin_source        := 'NONE';
            l_row.id_terminology       := NULL;
            l_row.standard_code        := NULL;
            l_row.standard_description := NULL;
            l_row.dt_last_update       := r.note_date;
            l_row.rank                 := r.rn;
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_progress_notes;

    /**
    * Get the disposable supplies according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_disposable_supplies
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
    BEGIN
        -- Return the value of the main function sending the correct arguments
        RETURN tf_get_supplies(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_episode      => i_episode,
                               i_flg_reusable => k_no -- Filter the Flg_Reusable
                               );
    
    END tf_get_disposable_supplies;

    /**
    * Get the durable / reusable supplies according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The list of EHR items.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_durable_supplies
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
    
        -- Private variables
        l_table      table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
        l_table_pdms table_number; -- Store the PDMS ID's
    BEGIN
    
        -- Get the results of the main function sending the correct arguments
        l_table := tf_get_supplies(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_episode      => i_episode,
                                   i_flg_reusable => k_yes -- Filter the Flg_Reusable
                                   );
    
        -- Collect the pdms equipment
        l_table_pdms := alert_pdms_tr.pk_coding_pdms.tf_get_vs_equipment_ids();
    
        -- Collect the records into the variables
        SELECT vr.id_vital_sign_read,
               vs.code_vital_sign,
               vr.flg_state,
               vs.id_vital_sign,
               vs.id_content,
               decode(vr.flg_state, 'C', vr.dt_cancel_tstz, vr.dt_vital_sign_read_tstz) AS dt_last_update
          BULK COLLECT
          INTO tbl_ids_ehr, tbl_codes_translations, tbl_flgs_status, tbl_ids_cnt, tbl_ids_content, tbl_dt_last_update
          FROM vital_sign_read vr
         INNER JOIN vital_sign vs
            ON vs.id_vital_sign = vr.id_vital_sign
         WHERE vr.id_episode = i_episode
           AND vr.id_vital_sign IN (SELECT column_value
                                      FROM TABLE(l_table_pdms)) -- Only pdms equipment
         ORDER BY 1;
    
        -- Load the data into the table, sending the values for this area
        load_and_clear(io_table      => l_table,
                       i_lang        => i_lang,
                       i_ehr_source  => 'VITAL_SIGN_READ.ID_VITAL_SIGN_READ',
                       i_cnt_source  => 'VITAL_SIGN.ID_VITAL_SIGN',
                       i_code_domain => 'VITAL_SIGN_READ.FLG_STATE');
    
        -- Return results
        RETURN l_table;
    
    END tf_get_durable_supplies;

    /**
    * Get the length of stay according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The EHR item with ehr_start_date and ehr_end_date for the episode.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_length_of_stay
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
        l_row   pk_coding_ehr.t_coding_ehr_item; -- Stores each record
        l_table table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows
    BEGIN
        -- Get correct dates for the episode
        FOR r IN (SELECT e.id_episode,
                         e.flg_status,
                         coalesce(e.dt_cancel_tstz, e.dt_end_tstz, e.dt_creation) AS dt_last_update,
                         e.dt_begin_tstz AS dt_begin,
                         (SELECT MAX(coalesce(d.dt_med_tstz, d.dt_admin_tstz))
                            FROM alert.discharge d
                           WHERE d.id_episode = e.id_episode
                             AND d.flg_status = 'A' -- Record is not outdated
                          ) AS dt_discharge,
                         (SELECT MIN(d.dt_death)
                            FROM alert.death_registry d
                           WHERE d.id_episode = e.id_episode
                             AND d.flg_status = 'A' -- Record is not outdated
                          ) AS dt_death
                    FROM episode e
                   WHERE e.id_episode = i_episode -- Filter the current episode
                  )
        LOOP
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Set the values
            l_row.id_ehr               := r.id_episode;
            l_row.ehr_source           := 'EPISODE.ID_EPISODE';
            l_row.ehr_start_date       := r.dt_begin;
            l_row.ehr_end_date         := coalesce(r.dt_discharge, r.dt_death);
            l_row.dt_last_update       := r.dt_last_update;
            l_row.termin_source        := 'NONE';
            l_row.id_terminology       := NULL;
            l_row.standard_code        := NULL;
            l_row.standard_description := NULL;
        
            -- Custom domain
            l_row.code_domain := 'CURRENT' || k_key_separator || 'DISCHARGE' || k_key_separator || 'DEATH';
            IF r.dt_discharge IS NOT NULL
            THEN
                l_row.flg_status := 'DISCHARGE';
            ELSIF r.dt_death IS NOT NULL
            THEN
                l_row.flg_status := 'DEATH';
            ELSE
                l_row.flg_status := 'CURRENT';
            END IF;
        
            -- Only one row can be returned and is used by code
            l_row.id_content      := k_length_of_stay;
            l_row.ehr_description := NULL;
            l_row.ehr_count       := 1;
            l_row.rank            := 0;
            l_row.id_cnt          := NULL;
            l_row.cnt_source      := NULL;
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_length_of_stay;

    /**
    * Get the length of stay by service according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The EHR item with ehr_start_date and ehr_end_date for each service.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/08/01
    */
    FUNCTION tf_get_los_by_service
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
        l_row                 pk_coding_ehr.t_coding_ehr_item; -- Stores each record
        l_table               table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows   
        l_id_department       NUMBER; -- Stores the department ID
        l_id_clinical_service NUMBER; -- Stores the clinical service ID
    
    BEGIN
        -- Get the data
        -- The information in the patient header is according to the data episode table
        -- This information is copied to the fields %_orig when the transfers ocurrs
        FOR r IN (WITH service_transfers AS
                       (SELECT x.*
                         FROM (SELECT row_number() over(ORDER BY t.id_epis_prof_resp) AS rn,
                                      decode(t.flg_transfer,
                                             'N',
                                             coalesce(t.dt_comp_tstz, t.dt_request_tstz),
                                             coalesce(t.dt_end_transfer_tstz, t.dt_execute_tstz, t.dt_comp_tstz)) AS ehr_start_date,
                                      t.id_epis_prof_resp,
                                      t.id_episode,
                                      t.flg_type,
                                      t.flg_status,
                                      t.flg_transfer,
                                      t.flg_transf_type,
                                      t.trf_reason,
                                      t.id_department_orig,
                                      t.id_department_dest,
                                      e.id_department AS id_department_episode,
                                      t.id_clinical_service_orig,
                                      t.id_clinical_service_dest,
                                      e.id_clinical_service AS id_clinical_service_episode,
                                      coalesce(t.update_time, t.create_time) AS dt_last_update
                                 FROM epis_prof_resp t
                                INNER JOIN episode e
                                   ON e.id_episode = t.id_episode
                                WHERE t.id_episode = i_episode -- Filter by episode
                               ) x
                        WHERE (x.flg_transfer = 'N' AND rn = 1 -- First record
                              OR x.flg_transf_type = 'S' /*Filter by S - Service transfer*/
                              ) -- End OR
                       ) -- End with
                      SELECT coalesce(n.id_department_orig, c.id_department_dest) AS id_department, -- According to tests, this is the correct order
                             coalesce(n.id_clinical_service_orig, c.id_clinical_service_dest) AS id_clinical_service, -- According to tests, this is the correct order
                             n.ehr_start_date AS ehr_end_date, -- The end date of the current record is the end date of the current one (completed)
                             n.id_epis_prof_resp AS next_id_epis_prof_resp,
                             c.*
                        FROM service_transfers c -- Current service
                        LEFT OUTER JOIN service_transfers n -- next service
                          ON n.rn = (c.rn + 1) -- When there is a next line
                         AND n.flg_status IN ('T', 'F', 'X') -- Completed / Final / Performed
                  )
        LOOP
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Set the values for this area
            l_row.id_ehr               := r.id_epis_prof_resp;
            l_row.ehr_source           := 'EPIS_PROF_RESP.ID_EPIS_PROF_RESP';
            l_row.ehr_count            := 1;
            l_row.ehr_start_date       := r.ehr_start_date;
            l_row.ehr_end_date         := r.ehr_end_date;
            l_row.flg_status           := r.flg_status;
            l_row.code_domain          := 'EPIS_PROF_RESP.FLG_STATUS';
            l_row.termin_source        := 'NONE';
            l_row.id_terminology       := NULL;
            l_row.standard_code        := NULL;
            l_row.standard_description := NULL;
            l_row.dt_last_update       := NULL;
            l_row.rank                 := r.rn;
        
            -- When there is no service transfers the information needs to be collected from the episode
            -- TODO: This needs to be updated with the souport of EVENTS from EHR in CODING
            IF (r.rn = 1 AND r.id_department IS NULL AND r.id_clinical_service IS NULL)
            THEN
                SELECT e.id_department AS id_department_episode, e.id_clinical_service AS id_clinical_service_episode
                  INTO l_id_department, l_id_clinical_service
                  FROM episode e
                 WHERE e.id_episode = i_episode; -- Filter by episode
            ELSE
                -- Use the information collected from the row
                l_id_department       := r.id_department;
                l_id_clinical_service := r.id_clinical_service;
            END IF;
        
            -- Content can be grouped using the two ID's
            l_row.id_cnt     := NULL;
            l_row.id_content := NULL;
            l_row.cnt_source := 'DEPARTMENT' || k_key_separator || 'CLINICAL_SERVICE';
            l_row.cnt_key    := l_id_department || k_key_separator || l_id_clinical_service;
        
            -- Sets the descriptions
            -- Calling an pl/sql funcion in SQL is not the best performance, but simplifies the code
            SELECT listagg(description, ' - ') within GROUP(ORDER BY rn)
              INTO l_row.ehr_description
              FROM (SELECT 1 AS rn, pk_translation.get_translation(i_lang, d.code_department) AS description
                      FROM department d
                     WHERE d.id_department = l_id_department
                    UNION ALL
                    SELECT 2 AS rn, pk_translation.get_translation(i_lang, cs.code_clinical_service) AS description
                      FROM clinical_service cs
                     WHERE cs.id_clinical_service = l_id_clinical_service);
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_los_by_service;

    /**
    * Get the length of stay by bed (rrom type - bed type) according to the input parameters.
    *
    * @param i_lang                         The language identifier.
    * @param i_prof                         The professional information used to filter the data.
    * @param i_episode                      The episode identifier used to filter the data.
    *
    * @return                               The EHR item with ehr_start_date and ehr_end_date for each room type - bed type.
    *
    * @raises                               
    *
    * @author                               Humberto Cardoso
    * @version                              2.8.4.0
    * @since                                2022/05/11
    */
    FUNCTION tf_get_los_by_bed
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN table_coding_ehr_item IS
        l_row   pk_coding_ehr.t_coding_ehr_item; -- Stores each record
        l_table table_coding_ehr_item := table_coding_ehr_item(); -- Stores all the rows   
    BEGIN
        -- Get the data
        FOR r IN (SELECT row_number() over(ORDER BY a.id_bmng_allocation_bed) AS rn,
                         a.id_bmng_allocation_bed,
                         (SELECT coalesce(pk_translation.get_translation(i_lang, rt.code_room_type), rt.desc_room_type)
                            FROM room_type rt
                           WHERE rt.id_room_type = rr.id_room_type) AS room_type,
                         (SELECT coalesce(pk_translation.get_translation(i_lang, bt.code_bed_type), bt.desc_bed_type)
                            FROM bed_type bt
                           WHERE bt.id_bed_type = b.id_bed_type) AS bed_type,
                         coalesce(pk_translation.get_translation(i_lang, b.code_bed), b.desc_bed) AS bed,
                         rr.id_room_type,
                         b.id_bed_type,
                         a.flg_outdated,
                         a.dt_creation AS ehr_start_date,
                         a.dt_release AS ehr_end_date,
                         coalesce(a.update_time, a.create_time) AS dt_last_update
                    FROM bmng_allocation_bed a
                   INNER JOIN bed b
                      ON b.id_bed = a.id_bed
                   INNER JOIN room rr
                      ON rr.id_room = a.id_room
                   WHERE a.id_episode = i_episode -- Filter by episode
                   ORDER BY a.id_bmng_allocation_bed)
        LOOP
            -- Set the default values in the record
            l_row := get_default_row;
        
            -- Set the values for this area
            l_row.id_ehr               := r.id_bmng_allocation_bed;
            l_row.ehr_source           := 'BMNG_ALLOCATION_BED.ID_BMNG_ALLOCATION_BED';
            l_row.ehr_count            := 1;
            l_row.ehr_start_date       := r.ehr_start_date;
            l_row.ehr_end_date         := r.ehr_end_date;
            l_row.termin_source        := 'NONE';
            l_row.id_terminology       := NULL;
            l_row.standard_code        := NULL;
            l_row.standard_description := NULL;
            l_row.dt_last_update       := NULL;
            l_row.rank                 := r.rn;
        
            -- Custom domain
            l_row.code_domain := 'CURRENT' || k_key_separator || 'OUTDATED';
            IF r.flg_outdated = 'Y'
            THEN
                l_row.flg_status := 'OUTDATED';
            ELSE
                l_row.flg_status := 'CURRENT';
            END IF;
        
            -- Content can be grouped using the two ID's
            l_row.id_cnt     := NULL;
            l_row.id_content := NULL;
            l_row.cnt_source := 'ROOM_TYPE' || k_key_separator || 'BED_TYPE';
            l_row.cnt_key    := r.id_room_type || k_key_separator || r.id_bed_type;
        
            -- Sets the descriptions
            IF (r.room_type IS NULL)
               AND (r.bed_type IS NULL)
            THEN
                l_row.ehr_description := r.bed;
            ELSIF r.room_type IS NULL
            THEN
                l_row.ehr_description := r.bed_type;
            ELSIF r.bed_type IS NULL
            THEN
                l_row.ehr_description := r.room_type;
            ELSE
                l_row.ehr_description := r.room_type || ' - ' || r.bed_type;
            END IF;
        
            -- Add the row to the collection
            l_table.extend();
            l_table(l_table.count) := l_row;
        END LOOP;
    
        -- Return the table
        RETURN l_table;
    END tf_get_los_by_bed;

BEGIN
    -- Initialization and log
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    alertlog.pk_alertlog.log_init(object_name => g_package_name);
END pk_coding_ehr;
/
