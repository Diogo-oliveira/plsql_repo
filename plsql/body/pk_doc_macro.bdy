/*-- Last Change Revision: $Rev: 2026999 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_doc_macro IS

    -----------> STATIC VARIABLES <-----------
    g_error VARCHAR2(1000 CHAR);
    -- Package info
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_sysdate       TIMESTAMP WITH LOCAL TIME ZONE;

    g_exception EXCEPTION;
    ---------> END STATIC VARIABLES <---------

    /*************************************************************************
    * Converts a cursor into a table_number                                  *
    *                                                                        *
    * @param p_cursor           Preferred language ID for this professional  *
    *                                                                        *
    * @return                   table_number                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  2.6.2.1     0                                 *
    * @since                    23/03/2012                                   *
    *************************************************************************/
    FUNCTION cursor2tbl_number(p_cursor IN SYS_REFCURSOR) RETURN table_number IS
        l_return table_number;
    BEGIN
        FETCH p_cursor BULK COLLECT
            INTO l_return;
    
        CLOSE p_cursor;
    
        RETURN l_return;
    END;

    /*************************************************************************
    * Converts a cursor into a table_varchar                                 *
    *                                                                        *
    * @param p_cursor           Preferred language ID for this professional  *
    *                                                                        *
    * @return                   table_number                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  2.6.2.1                                      *
    * @since                    23/03/2012                                   *
    *************************************************************************/
    FUNCTION cursor2tbl_varchar(p_cursor IN SYS_REFCURSOR) RETURN table_varchar IS
        l_return table_varchar;
    BEGIN
        FETCH p_cursor BULK COLLECT
            INTO l_return;
    
        CLOSE p_cursor;
    
        RETURN l_return;
    END;

    /*************************************************************************
    * Extracts the value through the type of element. Example: for element   *
    * of type numeric with unit of measure (UOM) it can strip the UOM ID,    *
    * retuning the numeric value only                                        *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_element_type     Element type (Comp. element date, etc.)      *
    * @param i_element_value    Element value                                *
    *                                                                        *
    * @return                   Value from element value                     *
    *                                                                        *
    * @author                   Ariel Geraldo Machado                        *
    * @version                  2.5                                          *
    * @since                    25/Jun/2009                                  *
    *************************************************************************/
    FUNCTION get_value
    (
        i_lang          IN language.id_language%TYPE,
        i_element_type  IN doc_element.flg_type%TYPE,
        i_element_value IN doc_macro_version_det.value%TYPE
    ) RETURN VARCHAR2 IS
        l_value         doc_macro_version_det.value%TYPE;
        l_element_value table_varchar2;
    BEGIN
        CASE i_element_type
            WHEN g_elem_flg_type_comp_numeric THEN
                --compound element for number
            
                -- Checks if number has an unit of measure (UOM). 
                -- Format <num_value>|<UOM>
                l_element_value := pk_utils.str_split(i_element_value, '|');
                l_value         := l_element_value(1);
            
            WHEN g_elem_flg_type_comp_ref_value THEN
                --compound element for number with reference values
            
                -- Checks if number has an unit of measure (UOM) and/or reference values
                -- Format <num_value>|<id_unit_measure>|<flg_ref_op_min>|<ref_val_min>|<flg_ref_op_min>|<ref_val_max>
                l_element_value := pk_utils.str_split(i_element_value, '|');
                l_value         := l_element_value(1);
            ELSE
                l_value := i_element_value;
        END CASE;
    
        RETURN l_value;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_out t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_VALUE',
                                                  l_error_out);
                RETURN NULL;
            END;
    END get_value;

    /*************************************************************************
    * Extracts the properties for value through the type of element,         *
    * example: for elements of type date it returns time zone property.      *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_element_type     Element type (Comp. element date, etc.)      *
    * @param i_element_value    Element value                                *
    * @param i_element          Element ID                                   *
    * @return                   Value from element value                     *
    *                                                                        *
    * @author                   Ariel Geraldo Machado                        *
    * @version                  1.0 (2.4.4)                                  *
    * @since                    2009/01/26                                   *
    *************************************************************************/
    FUNCTION get_value_properties
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_element_type  IN doc_element.flg_type%TYPE,
        i_element_value IN doc_macro_version_det.value%TYPE
    ) RETURN VARCHAR2 IS
        l_properties doc_macro_version_det.value_properties%TYPE;
        l_value      table_varchar2;
    
    BEGIN
        CASE i_element_type
            WHEN g_elem_flg_type_comp_date THEN
                --Compound date element
                IF (instr(upper(i_element_value), upper(pk_date_utils.g_dateformat)) != 0)
                THEN
                    --If it's a date and hour value then the property value is the timezone
                    l_properties := pk_date_utils.get_timezone(i_lang, i_prof);
                ELSE
                    l_properties := NULL;
                END IF;
            
            WHEN g_elem_flg_type_comp_numeric THEN
                --compound element for number
            
                -- Checks if number has an unit of measure (UOM). 
                -- Format <num_value>|<UOM>
                l_value := pk_utils.str_split(i_element_value, '|');
                IF l_value.count != 2
                THEN
                    l_properties := NULL;
                ELSE
                    l_properties := l_value(2);
                END IF;
            
            WHEN g_elem_flg_type_comp_ref_value THEN
                --compound element for number with reference values
            
                -- Checks if number has an unit of measure (UOM) and/or reference values 
                -- Format <num_value>|<id_unit_measure>|<flg_ref_op_min>|<ref_val_min>|<flg_ref_op_min>|<ref_val_max>
                l_value := pk_utils.str_split(i_element_value, '|');
                IF l_value.count != 6
                THEN
                    pk_alertlog.log_error(text            => 'Unexpected number of properties for numeric element with reference values (CR): ' ||
                                                             i_element_value,
                                          object_name     => g_package_name,
                                          sub_object_name => 'get_value_properties');
                    l_properties := NULL;
                ELSE
                    l_properties := l_value(2) || '|' || l_value(3) || '|' || l_value(4) || '|' || l_value(5) || '|' ||
                                    l_value(6);
                END IF;
            ELSE
                l_properties := NULL;
        END CASE;
    
        RETURN l_properties;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_out t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_VALUE',
                                                  l_error_out);
                RETURN NULL;
            
            END;
        
    END get_value_properties;

    /*************************************************************************
    * Procedure used to insert doc_macro history records                     *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/01/19                                   *
    *************************************************************************/
    PROCEDURE ins_dm_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_sysdate IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_tbl_pk  IN NUMBER
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'INS_DM_HIST';
        --l_sql      VARCHAR2(32767);
        --l_rows_out table_varchar;
    
        l_error t_error_out;
    BEGIN
        g_error := 'Start ins_dm_hist build';
    
        INSERT INTO doc_macro_hist
            (dt_doc_macro_hist,
             id_doc_macro,
             id_doc_macro_version,
             id_prof_create,
             id_institution,
             doc_macro_name,
             flg_share,
             flg_status,
             notes,
             dt_creation)
            (SELECT i_sysdate,
                    id_doc_macro,
                    id_doc_macro_version,
                    id_prof_create,
                    id_institution,
                    pk_translation.get_translation_trs(i_code_mess => dm.code_doc_macro),
                    flg_share,
                    flg_status,
                    notes,
                    dt_creation
               FROM doc_macro dm
              WHERE dm.id_doc_macro = i_tbl_pk);
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END ins_dm_hist;

    /*************************************************************************
    * Procedure used to insert doc_macro_soft history records                *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/01/19                                   *
    *************************************************************************/
    PROCEDURE ins_dms_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_sysdate IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_tbl_pk  IN NUMBER
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'INS_DMS_HIST';
    
        l_error t_error_out;
    BEGIN
        g_error := 'Start ins_dms_hist build';
    
        INSERT INTO doc_macro_soft_hist
            (dt_doc_macro_hist, id_doc_macro_soft, id_doc_macro, id_software, flg_status, dt_creation)
            (SELECT i_sysdate, id_doc_macro_soft, id_doc_macro, id_software, flg_status, dt_creation
               FROM doc_macro_soft dms
              WHERE dms.id_doc_macro = i_tbl_pk);
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END ins_dms_hist;

    /*************************************************************************
    * Procedure used to insert doc_macro_prof history records                *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/01/19                                   *
    *************************************************************************/
    PROCEDURE ins_dmp_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_sysdate IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT current_timestamp,
        i_tbl_pk  IN NUMBER
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'INS_DMP_HIST';
    
        l_error t_error_out;
    BEGIN
        g_error := 'Start ins_dms_hist build';
    
        INSERT INTO doc_macro_prof_hist
            (dt_doc_macro_hist, id_doc_macro_prof, id_doc_macro, id_professional, flg_status, dt_creation)
            (SELECT i_sysdate, id_doc_macro_prof, id_doc_macro, id_professional, flg_status, dt_creation
               FROM doc_macro_prof dmp
              WHERE dmp.id_doc_macro = i_tbl_pk);
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END ins_dmp_hist;

    /*************************************************************************
    * Procedure used to create \ edit a template macro                       *
    *                                                                        *
    * @param i_lang               Preferred language ID for this professional*
    * @param i_prof               Object (professional ID, institution ID,   *
    *                             software ID)                               *
    * @param i_doc_area           Doc Area identifier                        *
    * @param i_doc_template       Doc template identifier                    *
    * @param i_macro_name         Doc macro name                             *
    * @param i_software_macro     List of softwares were macro applies       *
    * @param i_flg_status         Doc macro flag status(A-Active, I-Inactive)*
    * @param i_macro_notes        Doc macro notes                            *
    * @param i_doc_macro          Doc macro identifier (for edition)         *
    * @param i_flg_type           Action type                                *
    *                             (N - New, E-Edition, O-No changes)         *
    * @param i_documentation      Documentation list                         *
    * @param i_doc_element        Doc element list                           *
    * @param i_doc_element_crit   Doc element crit list                      *
    * @param i_dcmvd_value        Doc macro version detail values list       *
    * @param i_dcmv_notes         Doc macro version notes                    *
    * @param i_doc_element_qualif Doc element qualifiers list                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/01/19                                   *
    *************************************************************************/
    PROCEDURE save_macro
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE,
        i_macro_name         IN VARCHAR2,
        i_software_macro     IN table_number,
        i_flg_status         IN doc_macro.flg_status%TYPE,
        i_macro_notes        IN doc_macro.notes%TYPE,
        i_doc_macro          IN doc_macro.id_doc_macro%TYPE,
        i_flg_type           IN VARCHAR2,
        i_documentation      IN table_number,
        i_doc_element        IN table_number,
        i_doc_element_crit   IN table_number,
        i_dcmvd_value        IN table_varchar,
        i_dcmv_notes         IN doc_macro_version.notes%TYPE,
        i_doc_element_qualif IN table_table_number,
        o_doc_macro          OUT doc_macro.id_doc_macro%TYPE,
        o_doc_macro_version  OUT doc_macro_version.id_doc_macro_version%TYPE
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'SAVE_MACRO';
    
        l_rows_out                   table_varchar := table_varchar();
        l_rows_dcmvd                 table_varchar := table_varchar();
        l_rows_dcmvq                 table_varchar := table_varchar();
        l_rows_ins_dcms              table_varchar := table_varchar();
        l_rows_upd_dcms              table_varchar := table_varchar();
        l_dcmv_notes                 doc_macro_version.notes%TYPE;
        l_next_doc_macro_version     doc_macro_version.id_doc_macro_version%TYPE;
        l_next_doc_macro_version_det doc_macro_version_det.id_doc_macro_version_det%TYPE;
        l_next_doc_macro_version_qlf doc_macro_version_qlf.id_doc_macro_version_qlf%TYPE;
        l_doc_macro_version          doc_macro_version.id_doc_macro_version%TYPE;
        l_next_doc_macro             doc_macro.id_doc_macro%TYPE;
        l_next_doc_macro_prof        doc_macro_prof.id_doc_macro_prof%TYPE;
        l_next_doc_macro_soft        doc_macro_soft.id_doc_macro_soft%TYPE;
        l_element_type               doc_element.flg_type%TYPE;
        l_dcmvd_value                doc_macro_version_det.value%TYPE;
        l_dcmvd_properties           doc_macro_version_det.value_properties%TYPE;
    
        l_error t_error_out;
    BEGIN
        g_sysdate := current_timestamp;
    
        --For edition actions (Edit; No Changes), the table origin and record ID are required
        IF (i_flg_type = g_flg_edition_type_edit AND i_doc_macro IS NULL)
        THEN
            g_error := 'Record edition without ID_DOC_MACRO_VERSION parameter';
            RAISE g_exception;
        END IF;
    
        --When is a new record previous record ID is not used
        IF i_flg_type = g_flg_edition_type_new
        THEN
            l_doc_macro_version := NULL;
        ELSE
            SELECT dm.id_doc_macro_version
              INTO l_doc_macro_version
              FROM doc_macro dm
             WHERE dm.id_doc_macro = i_doc_macro;
        END IF;
    
        l_dcmv_notes := i_dcmv_notes;
    
        g_error                  := 'GET SEQ_DOC_MACRO_VERSION.NEXTVAL';
        l_next_doc_macro_version := ts_doc_macro_version.next_key(sequence_in => 'SEQ_DOC_MACRO_VERSION');
    
        g_error    := 'INSERT DOC_MACRO_VERSION';
        l_rows_out := table_varchar();
        ts_doc_macro_version.ins(id_doc_macro_version_in => l_next_doc_macro_version,
                                 id_professional_in      => i_prof.id,
                                 dt_creation_in          => g_sysdate,
                                 id_prof_last_update_in  => i_prof.id,
                                 dt_last_update_in       => g_sysdate,
                                 flg_status_in           => g_dcmv_flg_status_active,
                                 flg_edition_type_in     => i_flg_type,
                                 id_doc_area_in          => i_doc_area,
                                 id_doc_template_in      => i_doc_template,
                                 notes_in                => l_dcmv_notes,
                                 id_parent_in            => l_doc_macro_version,
                                 --id_epis_context_in            => i_epis_context,
                                 --id_episode_context_in         => i_episode_context,
                                 rows_out => l_rows_out);
    
        g_error := 'CALL PROCESS_INSERT FOR DOC_MACRO_VERSION';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_MACRO_VERSION',
                                      i_rowids     => l_rows_out,
                                      o_error      => l_error);
    
        -- If this is an edition then sets previous record as outdated36
        IF (i_doc_macro IS NOT NULL AND i_flg_type = g_flg_edition_type_edit)
        THEN
            g_error    := 'UPDATE DOC_MACRO_VERSION';
            l_rows_out := table_varchar();
            ts_doc_macro_version.upd(id_doc_macro_version_in => l_doc_macro_version,
                                     flg_status_in           => g_dcmv_flg_status_outd,
                                     rows_out                => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE FOR DOC_MACRO_VERSION';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO_VERSION',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        END IF;
    
        -- Create NEW DETAIL LINES for doc_macro_version     
        --Editions of type New,Edit,Agree,Update. 
        --Creates lines of detail from arguments passed to function
    
        g_error := 'I_DOCUMENTATION LOOP';
        FOR i IN 1 .. i_documentation.count
        LOOP
            g_error := 'Get element_type for doc_element : ' || i_doc_element(i);
            SELECT de.flg_type
              INTO l_element_type
              FROM doc_element de
             WHERE de.id_doc_element = i_doc_element(i);
        
            -- Macros should not save vital sign elements, so they are ignored 
            IF l_element_type != pk_touch_option.g_elem_flg_type_vital_sign
            THEN
                l_dcmvd_value      := get_value(i_lang, l_element_type, i_dcmvd_value(i));
                l_dcmvd_properties := get_value_properties(i_lang, i_prof, l_element_type, i_dcmvd_value(i));
            
                g_error                      := 'GET SEQ_DOC_MACRO_VERSION_DET.NEXTVAL';
                l_next_doc_macro_version_det := ts_doc_macro_version_det.next_key(sequence_in => 'SEQ_DOC_MACRO_VERSION_DET');
            
                g_error    := 'INSERT DOC_MACRO_VERSION_DET';
                l_rows_out := table_varchar();
                ts_doc_macro_version_det.ins(id_doc_macro_version_det_in => l_next_doc_macro_version_det,
                                             id_doc_macro_version_in     => l_next_doc_macro_version,
                                             id_documentation_in         => i_documentation(i),
                                             id_doc_element_in           => i_doc_element(i),
                                             id_doc_element_crit_in      => i_doc_element_crit(i),
                                             value_in                    => l_dcmvd_value,
                                             value_properties_in         => l_dcmvd_properties,
                                             rows_out                    => l_rows_out);
            
                l_rows_dcmvd := l_rows_dcmvd MULTISET UNION DISTINCT l_rows_out;
            
                --Verifica se o elemento inserido tem qualificação e/ ou quantificador associada (id_doc_element_qualif)
                IF nvl(i_doc_element_qualif(i).count, 0) > 0
                THEN
                    FOR j IN i_doc_element_qualif(i).first .. i_doc_element_qualif(i).last
                    LOOP
                        IF i_doc_element_qualif(i) (j) IS NOT NULL
                        THEN
                            g_error                      := 'GET SEQ_DOC_MACRO_VERSION_QLF.NEXTVAL';
                            l_next_doc_macro_version_qlf := ts_doc_macro_version_qlf.next_key(sequence_in => 'SEQ_DOC_MACRO_VERSION_QLF');
                        
                            g_error    := 'INSERT DOC_MACRO_VERSION_QLF';
                            l_rows_out := table_varchar();
                            ts_doc_macro_version_qlf.ins(id_doc_macro_version_qlf_in => l_next_doc_macro_version_qlf,
                                                         id_doc_macro_version_det_in => l_next_doc_macro_version_det,
                                                         id_doc_element_qualif_in    => i_doc_element_qualif(i) (j),
                                                         rows_out                    => l_rows_out);
                        
                            l_rows_dcmvq := l_rows_dcmvq MULTISET UNION DISTINCT l_rows_out;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'CALL PROCESS_INSERT FOR DOC_MACRO_VERSION_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_MACRO_VERSION_DET',
                                      i_rowids     => l_rows_dcmvd,
                                      o_error      => l_error);
    
        g_error := 'CALL PROCESS_UPDATE FOR DOC_MACRO_VERSION_QLF';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_MACRO_VERSION_QLF',
                                      i_rowids     => l_rows_dcmvq,
                                      o_error      => l_error);
    
        IF (i_doc_macro IS NOT NULL AND i_flg_type IN (g_flg_edition_type_edit, g_flg_edition_type_nochanges))
        THEN
            g_error := 'INSERT HISTORY FOR DOC_MACRO';
            ins_dm_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => i_doc_macro);
        
            g_error    := 'UPDATE DOC_MACRO';
            l_rows_out := table_varchar();
            ts_doc_macro.upd(id_doc_macro_in         => i_doc_macro,
                             id_doc_macro_version_in => l_next_doc_macro_version,
                             id_prof_create_in       => i_prof.id,
                             id_institution_in       => i_prof.institution,
                             --doc_macro_name_in       => i_macro_name,
                             flg_share_in  => pk_alert_constant.g_no,
                             flg_status_in => i_flg_status,
                             notes_in      => i_macro_notes,
                             rows_out      => l_rows_out);
        
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => 'ALERT.DOC_MACRO.CODE_DOC_MACRO.' || i_doc_macro,
                                                  i_desc   => i_macro_name,
                                                  i_module => g_doc_macro_module);
        
            g_error := 'CALL PROCESS_UPDATE FOR DOC_MACRO';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        
            g_error := 'INSERT HISTORY FOR DOC_MACRO_SOFT';
            ins_dms_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => i_doc_macro);
        
            g_error    := 'Outdate all doc_mac_soft records - ' || 'id_doc_macro = ' || i_doc_macro ||
                          ' AND id_software NOT IN (' ||
                          pk_utils.concat_table(i_tab => i_software_macro, i_delim => ',') || ')';
            l_rows_out := table_varchar();
            ts_doc_macro_soft.upd(flg_status_in => g_dcms_flg_status_inactive,
                                  where_in      => 'id_doc_macro = ' || i_doc_macro || ' AND id_software NOT IN (' ||
                                                   pk_utils.concat_table(i_tab => i_software_macro, i_delim => ',') || ')',
                                  rows_out      => l_rows_out);
        
            l_rows_upd_dcms := l_rows_upd_dcms MULTISET UNION DISTINCT l_rows_out;
        
            g_error := 'PROCESS SOFTWARE_MACRO LIST';
            FOR j IN 1 .. i_software_macro.count
            LOOP
                l_rows_out := table_varchar();
                g_error    := 'UPDATE DOC_MACRO_SOFT - ' || 'ID_DOC_MACRO = ' || i_doc_macro || ' AND ID_SOFTWARE = ' ||
                              i_software_macro(j);
                ts_doc_macro_soft.upd(flg_status_in  => g_dcms_flg_status_active,
                                      dt_creation_in => g_sysdate,
                                      where_in       => 'ID_DOC_MACRO = ' || i_doc_macro || ' AND ID_SOFTWARE = ' ||
                                                        i_software_macro(j),
                                      rows_out       => l_rows_out);
            
                IF l_rows_out.count = 0
                THEN
                    g_error               := 'GET SEQ_DOC_MACRO_SOFT.NEXTVAL';
                    l_next_doc_macro_soft := ts_doc_macro_soft.next_key(sequence_in => 'SEQ_DOC_MACRO_SOFT');
                
                    g_error    := 'INSERT DOC_MACRO_SOFT';
                    l_rows_out := table_varchar();
                    ts_doc_macro_soft.ins(id_doc_macro_soft_in => l_next_doc_macro_soft,
                                          id_doc_macro_in      => i_doc_macro,
                                          id_software_in       => i_software_macro(j),
                                          flg_status_in        => g_dcmp_flg_status_active,
                                          dt_creation_in       => g_sysdate,
                                          rows_out             => l_rows_out);
                
                    l_rows_ins_dcms := l_rows_ins_dcms MULTISET UNION DISTINCT l_rows_out;
                ELSE
                    l_rows_upd_dcms := l_rows_upd_dcms MULTISET UNION DISTINCT l_rows_out;
                END IF;
            END LOOP;
        
            g_error := 'CALL PROCESS_UPDATE FOR DOC_MACRO_SOFT';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO_SOFT',
                                          i_rowids     => l_rows_upd_dcms,
                                          o_error      => l_error);
        
            g_error := 'CALL PROCESS_INSERT FOR DOC_MACRO_SOFT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO_SOFT',
                                          i_rowids     => l_rows_ins_dcms,
                                          o_error      => l_error);
        
            g_error := 'INSERT HISTORY FOR DOC_MACRO_PROF';
            ins_dmp_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => i_doc_macro);
        
            /*                            
            
            g_error               := 'GET SEQ_DOC_MACRO_PROF.NEXTVAL';
            l_next_doc_macro_prof := ts_doc_macro_prof.next_key(sequence_in => 'SEQ_DOC_MACRO_PROF');
            
            g_error := 'INSERT DOC_MACRO_PROF';
            ts_doc_macro_prof.ins(id_doc_macro_prof_in => l_next_doc_macro_prof,
                                  id_professional_in   => i_prof.id,
                                  id_doc_macro_in      => i_doc_macro,
                                  flg_status_in        => g_dcmp_flg_status_active,
                                  dt_creation_in       => g_sysdate,
                                  rows_out             => l_rows_out);
            
            g_error := 'CALL PROCESS_INSERT FOR DOC_MACRO_PROF';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO_PROF',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);*/
        
        ELSE
            g_error          := 'GET SEQ_DOC_MACRO.NEXTVAL';
            l_next_doc_macro := ts_doc_macro.next_key(sequence_in => 'SEQ_DOC_MACRO');
        
            g_error    := 'INSERT DOC_MACRO';
            l_rows_out := table_varchar();
            ts_doc_macro.ins(id_doc_macro_in         => l_next_doc_macro,
                             id_doc_macro_version_in => l_next_doc_macro_version,
                             id_prof_create_in       => i_prof.id,
                             id_institution_in       => i_prof.institution,
                             --doc_macro_name_in       => i_macro_name,
                             flg_share_in   => pk_alert_constant.g_no,
                             flg_status_in  => i_flg_status,
                             notes_in       => i_macro_notes,
                             dt_creation_in => g_sysdate,
                             rows_out       => l_rows_out);
        
            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                  i_code   => 'ALERT.DOC_MACRO.CODE_DOC_MACRO.' || l_next_doc_macro,
                                                  i_desc   => i_macro_name,
                                                  i_module => g_doc_macro_module);
        
            g_error := 'CALL PROCESS_INSERT FOR DOC_MACRO';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        
            g_error := 'PROCESS SOFTWARE_MACRO LIST';
            FOR j IN 1 .. i_software_macro.count
            LOOP
                g_error               := 'GET SEQ_DOC_MACRO_SOFT.NEXTVAL';
                l_next_doc_macro_soft := ts_doc_macro_soft.next_key(sequence_in => 'SEQ_DOC_MACRO_SOFT');
            
                g_error    := 'INSERT DOC_MACRO_SOFT';
                l_rows_out := table_varchar();
                ts_doc_macro_soft.ins(id_doc_macro_soft_in => l_next_doc_macro_soft,
                                      id_doc_macro_in      => l_next_doc_macro,
                                      id_software_in       => i_software_macro(j),
                                      flg_status_in        => g_dcmp_flg_status_active,
                                      dt_creation_in       => g_sysdate,
                                      rows_out             => l_rows_out);
            
                l_rows_ins_dcms := l_rows_ins_dcms MULTISET UNION DISTINCT l_rows_out;
            END LOOP;
        
            g_error := 'CALL PROCESS_INSERT FOR DOC_MACRO_SOFT';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO_SOFT',
                                          i_rowids     => l_rows_ins_dcms,
                                          o_error      => l_error);
        
            g_error               := 'GET SEQ_DOC_MACRO_PROF.NEXTVAL';
            l_next_doc_macro_prof := ts_doc_macro_prof.next_key(sequence_in => 'SEQ_DOC_MACRO_PROF');
        
            g_error    := 'INSERT DOC_MACRO_PROF';
            l_rows_out := table_varchar();
            ts_doc_macro_prof.ins(id_doc_macro_prof_in => l_next_doc_macro_prof,
                                  id_professional_in   => i_prof.id,
                                  id_doc_macro_in      => l_next_doc_macro,
                                  flg_status_in        => g_dcmp_flg_status_active,
                                  dt_creation_in       => g_sysdate,
                                  rows_out             => l_rows_out);
        
            g_error := 'CALL PROCESS_INSERT FOR DOC_MACRO_PROF';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO_PROF',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        END IF;
    
        o_doc_macro         := l_next_doc_macro;
        o_doc_macro_version := l_next_doc_macro_version;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END save_macro;

    /*************************************************************************
    * Procedure used to return action list for a doc_area, doc_template,     *
    * institution and professional                                           *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_doc_area         Documentation Area identifier                *
    * @param i_doc_template     Documentation Template identifier            *
    * @param i_subject          Action subject                               *
    * @param i_from_state       Action initial state                         *
    *                                                                        *
    * @param o_doc_macro_list   Actions list                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    PROCEDURE get_templates_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template   IN doc_macro_version.id_doc_template%TYPE,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN action.from_state%TYPE,
        o_doc_macro_list OUT pk_types.cursor_type
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_templates_actions';
        l_pending_desc sys_domain.desc_val%TYPE;
    
        l_error t_error_out;
    BEGIN
        l_pending_desc := '(' || pk_sysdomain.get_domain(i_code_dom => 'DOC_MACRO.FLG_STATUS',
                                                         i_val      => g_dcm_flg_status_pending,
                                                         i_lang     => i_lang) || ')';
    
        g_error := 'Fetch template actions list for id_doc_area: ' || i_doc_area || ', id_doc_template: ' ||
                   i_doc_template || ', subject: ' || i_subject || ', i_from_state: ' || i_from_state;
        OPEN o_doc_macro_list FOR
            SELECT dm.id_doc_macro_version id_action,
                   (SELECT tfa.id_action
                      FROM TABLE(pk_action.tf_get_actions(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_subject    => i_subject,
                                                          i_from_state => i_from_state)) tfa
                     WHERE tfa.to_state = g_action_template_apply) id_parent,
                   2 level_nr,
                   NULL from_state,
                   NULL to_state,
                   pk_string_utils.clob_to_sqlvarchar2(pk_translation.get_translation_trs(i_code_mess => dm.code_doc_macro)) ||
                   CASE dm.flg_status
                       WHEN g_dcm_flg_status_pending THEN
                        chr(10) || l_pending_desc
                   END desc_action,
                   NULL icon,
                   NULL flg_default,
                   g_action_apply_name action,
                   pk_alert_constant.g_active flg_active,
                   dm.id_doc_macro,
                   dm.flg_status
              FROM doc_macro dm, doc_macro_soft dms
             WHERE dm.id_prof_create = i_prof.id
               AND dm.id_institution = i_prof.institution
               AND dm.flg_status IN (g_dcm_flg_status_active, g_dcm_flg_status_pending)
               AND dm.id_doc_macro = dms.id_doc_macro
               AND dms.id_software = i_prof.software
               AND EXISTS (SELECT 1
                      FROM doc_macro_version dmv
                     WHERE dmv.id_doc_macro_version = dm.id_doc_macro_version
                       AND dmv.flg_status = g_dcmv_flg_status_active
                       AND dmv.id_doc_area = i_doc_area
                       AND dmv.id_doc_template = i_doc_template)
            UNION ALL
            SELECT tfa.id_action,
                   tfa.id_parent,
                   tfa.level_nr,
                   tfa.from_state,
                   tfa.to_state,
                   tfa.desc_action,
                   tfa.icon,
                   tfa.flg_default,
                   tfa.action,
                   tfa.flg_active,
                   NULL            id_doc_macro,
                   NULL            flg_status
              FROM TABLE(pk_action.tf_get_actions(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_subject    => i_subject,
                                                  i_from_state => i_from_state)) tfa
            
             ORDER BY desc_action;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
        
            RAISE;
    END get_templates_actions;

    /*************************************************************************
    * Procedure used to return macros list                                   *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    PROCEDURE get_doc_macros_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template   IN doc_macro_version.id_doc_template%TYPE,
        o_doc_macro_list OUT t_cur_macro_info
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_macros_list';
    
        l_error        t_error_out;
        l_pending_desc sys_domain.desc_val%TYPE;
    BEGIN
    
        l_pending_desc := '(' || pk_sysdomain.get_domain(i_code_dom => 'DOC_MACRO.FLG_STATUS',
                                                         i_val      => g_dcm_flg_status_pending,
                                                         i_lang     => i_lang) || ')';
        g_error        := 'Fetch doc_macro list for id_doc_area: ' || i_doc_area || ' and id_doc_template: ' ||
                          i_doc_template;
        OPEN o_doc_macro_list FOR
            SELECT dm.id_doc_macro,
                   dm.id_doc_macro_version,
                   pk_string_utils.clob_to_sqlvarchar2(pk_translation.get_translation_trs(i_code_mess => dm.code_doc_macro)) ||
                   CASE dm.flg_status
                       WHEN g_dcm_flg_status_pending THEN
                        chr(10) || l_pending_desc
                   END doc_macro_name,
                   dm.flg_status
              FROM doc_macro dm
             WHERE dm.id_prof_create = i_prof.id
               AND dm.id_institution = i_prof.institution
               AND dm.flg_status IN (g_dcm_flg_status_active, g_dcm_flg_status_pending)
               AND EXISTS (SELECT 1
                      FROM doc_macro_version dmv
                     WHERE dmv.id_doc_macro_version = dm.id_doc_macro_version
                       AND dmv.flg_status = g_dcmv_flg_status_active
                       AND dmv.id_doc_area = i_doc_area
                       AND dmv.id_doc_template = i_doc_template)
             ORDER BY doc_macro_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END get_doc_macros_list;

    /*************************************************************************
    * Procedure used to return software list shared for a doc_area,          *
    * doc_template, institution and professional                             *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_doc_area         Documentation Area identifier                *
    * @param i_doc_template     Documentation Template identifier            *
    *                                                                        *
    * @param o_software_list    Software list                                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    PROCEDURE get_shared_macro_software
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_area      IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template  IN doc_macro_version.id_doc_template%TYPE,
        o_software_list OUT pk_types.cursor_type
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_shared_macro_software';
    
        l_error t_error_out;
    BEGIN
        g_error := 'Fetch shared_macro_software list for id_doc_area: ' || i_doc_area || ' and id_doc_template: ' ||
                   i_doc_template;
        OPEN o_software_list FOR
            SELECT s.name, s.desc_software, s.id_software
              FROM prof_soft_inst psi
              JOIN software s
                ON s.id_software = psi.id_software
             WHERE psi.id_professional = i_prof.id
               AND psi.id_institution = i_prof.institution
               AND s.flg_mni = pk_alert_constant.g_yes
               AND EXISTS (SELECT 1
                      FROM TABLE(pk_touch_option_core.tf_doc_templates(i_lang         => i_lang,
                                                                       i_professional => psi.id_professional,
                                                                       i_institution  => psi.id_institution,
                                                                       i_software     => psi.id_software,
                                                                       i_doc_area     => i_doc_area)) dt
                     WHERE dt.id_doc_template = i_doc_template)
               AND EXISTS (SELECT 1
                      FROM TABLE(pk_touch_option_core.tf_doc_areas(i_lang                  => i_lang,
                                                                   i_professional          => psi.id_professional,
                                                                   i_institution           => psi.id_institution,
                                                                   i_software              => psi.id_software,
                                                                   i_check_template_exists => pk_alert_constant.g_no)) x
                     WHERE x.id_doc_area = i_doc_area)
             ORDER BY s.name;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END get_shared_macro_software;

    /*************************************************************************
    * Procedure used to return the values of a template used in a macro      *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_prof              Object (professional ID, institution ID,    *
    *                            software ID)                                *
    * @param i_doc_macro_version Doc macro version identifier                *
    *                                                                        *
    * @param o_macro_documentation Cursor with macro version documentation   *
    *                              values                                    *
    * @param o_element_domain      Cursor with elements domain               *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/27                                   *
    *************************************************************************/
    PROCEDURE get_macro_documentation
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_doc_macro_version   IN doc_macro_version.id_doc_macro_version%TYPE,
        o_macro_documentation OUT pk_types.cursor_type,
        o_element_domain      OUT pk_types.cursor_type
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_macro_documentation';
    
        --elements with dynamic domain (functions)
        CURSOR c_dynamic_functions IS
            SELECT de.id_doc_element,
                   de.code_element_domain id_doc_function,
                   CURSOR (SELECT t_rec_function_param(defp.flg_param_type,
                                                       defp.flg_value_type,
                                                       decode(defp.flg_param_type,
                                                              pk_touch_option.g_flg_param_type_template_elem,
                                                              decode(defp.flg_value_type,
                                                                     pk_touch_option.g_flg_value_type_value, --Value
                                                                     (SELECT edd1.value
                                                                        FROM doc_macro_version_det edd1
                                                                       WHERE edd1.id_doc_macro_version = i_doc_macro_version
                                                                         AND edd1.id_doc_element =
                                                                             to_number(defp.param_value)),
                                                                     pk_touch_option.g_flg_param_type_criteria, --Criteria
                                                                     (SELECT edd1.id_doc_element_crit
                                                                        FROM doc_macro_version_det edd1
                                                                       WHERE edd1.id_doc_macro_version = i_doc_macro_version
                                                                         AND edd1.id_doc_element =
                                                                             to_number(defp.param_value)),
                                                                     defp.param_value),
                                                              defp.param_value)) function_params
                             FROM doc_element_function_param defp
                            WHERE de.id_doc_element = defp.id_doc_element
                              AND de.code_element_domain = defp.id_doc_function
                            ORDER BY defp.rank)                 function_params
              FROM doc_macro_version ed
             INNER JOIN doc_macro_version_det edd
                ON ed.id_doc_macro_version = edd.id_doc_macro_version
             INNER JOIN doc_element de
                ON edd.id_doc_element = de.id_doc_element
             WHERE ed.id_doc_macro_version = i_doc_macro_version
               AND de.flg_element_domain_type = pk_touch_option.g_flg_element_domain_dynamic;
    
        -- local variables
        l_idx             PLS_INTEGER;
        c_function_params SYS_REFCURSOR;
        l_doc_element     doc_element.id_doc_element%TYPE;
        l_function        doc_element.code_element_domain%TYPE;
        --l_id_episode         episode.id_episode%TYPE;
        --l_id_patient         patient.id_patient%TYPE;
        l_data  table_varchar2;
        l_label table_varchar2;
        l_icon  table_varchar2;
        --l_tbl_vsr            table_varchar;
        l_tab_dynamic_domain t_table_rec_element_domain;
    
        l_error t_error_out;
    
        -- Inner function to retrieves a dynamic domain 
        FUNCTION inner_get_dynamic_domain
        (
            i_doc_function    IN doc_function.id_doc_function%TYPE,
            i_function_params IN SYS_REFCURSOR,
            o_data            OUT table_varchar2,
            o_label           OUT table_varchar2,
            o_icon            OUT table_varchar2,
            o_error           OUT t_error_out
        ) RETURN BOOLEAN IS
        
            TYPE function_params_t IS TABLE OF t_rec_function_param INDEX BY BINARY_INTEGER;
            l_function_params function_params_t;
            c_domain          pk_types.cursor_type;
            l_doc_function    doc_function.id_doc_function%TYPE;
            l_tab_dummy1      table_varchar2;
            l_tab_dummy2      table_varchar2;
            l_tab_dummy3      table_varchar2;
            l_tab_dummy4      table_number;
        
        BEGIN
        
            l_doc_function := upper(i_doc_function);
        
            g_error := 'GET FUNCTION PARAMS';
            pk_alertlog.log_debug(text => g_error, object_name => l_function_name, sub_object_name => l_function_name);
            FETCH i_function_params BULK COLLECT
                INTO l_function_params;
            CLOSE i_function_params;
        
            CASE l_doc_function
            --Category list
                WHEN 'LIST.GET_CAT_LIST' THEN
                    g_error := 'CALL PK_LIST.GET_CAT_LIST';
                    IF NOT pk_list.get_cat_list(i_lang => i_lang, o_cat => c_domain, o_error => o_error)
                    THEN
                        RETURN FALSE;
                    ELSE
                        FETCH c_domain BULK COLLECT
                            INTO o_data, l_tab_dummy1, o_label, l_tab_dummy2;
                        CLOSE c_domain;
                    
                        --This function doesn't have icons, then fill the field as null
                        o_icon := table_varchar2();
                        o_icon.extend(o_data.count);
                    END IF;
                
            --Professional list
                WHEN 'LIST.GET_PROF_LIST' THEN
                    g_error := 'CALL PK_LIST.GET_PROF_LIST';
                    IF l_function_params.count() = 5
                    THEN
                        IF NOT pk_list.get_prof_list(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_speciality    => l_function_params(3).param_value,
                                                     i_category      => l_function_params(4).param_value,
                                                     i_dep_clin_serv => l_function_params(5).param_value,
                                                     o_prof          => c_domain,
                                                     o_error         => o_error)
                        THEN
                            RETURN FALSE;
                        ELSE
                        
                            FETCH c_domain BULK COLLECT
                                INTO o_data, o_label;
                            CLOSE c_domain;
                        
                            --This function doesn't have icons, then fill the field as null
                            o_icon := table_varchar2();
                            o_icon.extend(o_data.count);
                        END IF;
                    
                    ELSE
                        g_error := 'ID_DOC_FUNCTION (' || l_doc_function || ') INVALID PARAMETERS NUMBER';
                        RAISE g_exception;
                    END IF;
                    --Institution lise
                WHEN 'PREGNANCY.GET_INST_DOMAIN_TEMPLATE' THEN
                    g_error := 'CALL PREGNANCY.GET_INST_DOMAIN_TEMPLATE';
                    IF l_function_params.count() = 4
                    THEN
                        IF NOT pk_pregnancy.get_inst_domain_template(i_lang        => i_lang,
                                                                     i_prof        => i_prof,
                                                                     i_flg_type    => l_function_params(3).param_value,
                                                                     i_flg_context => l_function_params(4).param_value,
                                                                     o_inst        => c_domain,
                                                                     o_error       => o_error)
                        THEN
                            RETURN FALSE;
                        ELSE
                            FETCH c_domain BULK COLLECT
                                INTO l_tab_dummy1, o_data, o_label, l_tab_dummy3, l_tab_dummy4, l_tab_dummy2;
                            CLOSE c_domain;
                        
                            --This function doesn't have icons, then fill the field as null
                            o_icon := table_varchar2();
                            o_icon.extend(o_data.count);
                        END IF;
                    ELSE
                        g_error := 'ID_DOC_FUNCTION (' || l_doc_function || ') INVALID PARAMETERS NUMBER';
                        RAISE g_exception;
                    END IF;
                ELSE
                    g_error := 'ID_DOC_FUNCTION (' || l_doc_function || ') NOT SUPPORTED';
                    RAISE g_exception;
                
            END CASE;
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                DECLARE
                    l_error_in t_error_in := t_error_in();
                BEGIN
                    l_error_in.set_all(i_lang,
                                       SQLCODE,
                                       SQLERRM,
                                       g_error,
                                       g_package_owner,
                                       g_package_name,
                                       'INNER_GET_DYNAMIC_DOMAIN');
                
                    RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
                
                END;
        END inner_get_dynamic_domain;
    
    BEGIN
    
        g_error := 'GET CURSOR O_MACRO_DOCUMENTATION';
        OPEN o_macro_documentation FOR
            SELECT edd.id_doc_element,
                   edd.id_doc_element_crit,
                   CASE de.flg_type
                       WHEN g_elem_flg_type_comp_date THEN
                       --For date elements display at timezone institution
                        pk_touch_option.get_date_value_insttimezone(i_lang, i_prof, edd.value, edd.value_properties)
                       WHEN g_elem_flg_type_comp_numeric THEN
                       --For numeric elements check if has an unit of measure related and then concatenate value with UOM ID
                        decode(edd.value_properties, NULL, edd.value, edd.value || '|' || edd.value_properties)
                       WHEN g_elem_flg_type_comp_ref_value THEN
                       --For numeric elements with reference values verifies that it has properties, then concatenate them
                        decode(edd.value_properties, NULL, edd.value, edd.value || '|' || edd.value_properties)
                       ELSE
                        edd.value
                   END VALUE,
                   edd.id_documentation,
                   ed.notes notes_docum,
                   edq.id_doc_element_qualif,
                   deq.id_doc_qualification,
                   deq.id_doc_criteria,
                   deq.id_doc_quantification,
                   ed.id_doc_macro_version
              FROM doc_macro_version ed
              LEFT JOIN doc_macro_version_det edd
                ON ed.id_doc_macro_version = edd.id_doc_macro_version
              LEFT JOIN doc_element de
                ON edd.id_doc_element = de.id_doc_element
              LEFT JOIN documentation d
                ON d.id_documentation = de.id_documentation
              LEFT JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
              LEFT JOIN doc_macro_version_qlf edq
                ON edd.id_doc_macro_version_det = edq.id_doc_macro_version_det
              LEFT JOIN doc_element_qualif deq
                ON edq.id_doc_element_qualif = deq.id_doc_element_qualif
             WHERE ed.id_doc_macro_version = i_doc_macro_version
             ORDER BY dtad.rank, de.rank;
    
        --Retrieves dynamic elements domain
        l_idx                := 1;
        l_tab_dynamic_domain := t_table_rec_element_domain();
    
        g_error := 'OPEN c_dynamic_functions';
        OPEN c_dynamic_functions;
        LOOP
            FETCH c_dynamic_functions
                INTO l_doc_element, l_function, c_function_params;
            EXIT WHEN c_dynamic_functions%NOTFOUND;
        
            IF NOT inner_get_dynamic_domain(l_function, c_function_params, l_data, l_label, l_icon, l_error)
            THEN
                pk_types.open_my_cursor(o_macro_documentation);
                pk_types.open_my_cursor(o_element_domain);
                --RETURN FALSE;
                RAISE g_exception;
            ELSE
                FOR i IN 1 .. l_data.count
                LOOP
                    l_tab_dynamic_domain.extend;
                    l_tab_dynamic_domain(l_idx) := t_rec_element_domain(id_doc_element => l_doc_element,
                                                                        data           => l_data(i),
                                                                        label          => l_label(i),
                                                                        icon           => l_icon(i),
                                                                        rank           => NULL);
                    l_idx := l_idx + 1;
                END LOOP;
            END IF;
        END LOOP;
        CLOSE c_dynamic_functions;
    
        g_error := 'GET CURSOR O_ELEMENT_DOMAIN ';
    
        OPEN o_element_domain FOR
        --Domain for sysdomain elements
            SELECT de.id_doc_element, sd.val data, sd.desc_val label, sd.img_name icon, sd.rank
              FROM doc_macro_version ed
             INNER JOIN doc_macro_version_det edd
                ON ed.id_doc_macro_version = edd.id_doc_macro_version
             INNER JOIN doc_element de
                ON edd.id_doc_element = de.id_doc_element
              LEFT JOIN sys_domain sd
                ON sd.code_domain = de.code_element_domain
             WHERE ed.id_doc_macro_version = i_doc_macro_version
               AND de.flg_element_domain_type = pk_touch_option.g_flg_element_domain_sysdomain
               AND sd.flg_available = pk_alert_constant.g_available
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
            
            UNION ALL
            --Domain for dynamic elements
            SELECT t.id_doc_element, t.data data, t.label, t.icon, t.rank
              FROM TABLE(l_tab_dynamic_domain) t
            
             ORDER BY id_doc_element, rank, label;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END get_macro_documentation;

    /*************************************************************************
    * Function to be used as an SQL DML helper to validate permissions       *
    * on the use of a macro based on his dependencies (such as software      *
    * association with professional, software association with doc_area and  *
    * doc_template)                                                          *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_institution      Institution identifier                       *
    * @param i_software         Documentation Template identifier            *
    * @param i_doc_area         Software list                                *
    * @param i_doc_template     Documentation template identifier            *
    *                                                                        *
    * @return                   0 when does'n have permissions               *
    *                           1 when does have permissions                 *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/02/16                                   *
    *************************************************************************/
    FUNCTION check_dm_dependencies
    (
        i_lang         IN language.id_language%TYPE,
        i_prof_id      IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE DEFAULT NULL,
        i_doc_area     IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template IN doc_macro_version.id_doc_template%TYPE
    ) RETURN NUMBER IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_dm_dependencies';
    
        l_count NUMBER;
    
        l_error t_error_out;
    BEGIN
        g_error := 'Fetch shared_macro_software list for id_doc_area: ' || i_doc_area || ' and id_doc_template: ' ||
                   i_doc_template;
        SELECT decode(COUNT(1), 0, 0, 1) l_count
          INTO l_count
          FROM prof_soft_inst psi
          JOIN software s
            ON s.id_software = psi.id_software
         WHERE psi.id_professional = i_prof_id
           AND psi.id_institution = i_institution
           AND psi.id_software = nvl(i_software, psi.id_software)
           AND s.flg_mni = pk_alert_constant.g_yes
           AND EXISTS (SELECT 1
                  FROM TABLE(pk_touch_option_core.tf_doc_templates(i_lang         => i_lang,
                                                                   i_professional => psi.id_professional,
                                                                   i_institution  => psi.id_institution,
                                                                   i_software     => psi.id_software,
                                                                   i_doc_area     => i_doc_area)) dt
                 WHERE dt.id_doc_template = i_doc_template);
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END check_dm_dependencies;

    /*************************************************************************
    * Procedure that resolves bind variables required for the filter         *
    * TOTMacroDocumentation                                                  *
    *                                                                        *
    * @param i_context_ids  Static contexts (i_prof, i_lang, i_episode,...)  *
    * @param i_context_vals Custom contexts, sent from the user interface    *
    * @param i_name         Name of the bind variable to get                 *
    * @param  o_vc2         Varchar2 value returned by the procedure         *
    * @param  o_num         Numeric value returned by the procedure          *
    * @param  o_id          NUMBER(24) value returned by the procedure       *
    * @param  o_tstz        Timestamp value returned by the procedure        *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  2.6.2.1                                      *
    * @since                    2012/03/08                                   *
    *************************************************************************/
    PROCEDURE init_fltr_params_doc_macro
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'init_fltr_params_doc_macro';
    
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    BEGIN
        g_error := 'i_name validation : ' || i_name;
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            ELSE
                -- Unexpected bind variable
                RAISE pk_touch_option_core.e_invalid_parameter;
        END CASE;
    
        pk_alertlog.log_debug(text            => 'Value of bind variable ' || nvl(i_name, '<null>') || ' : ' ||
                                                 nvl(coalesce(o_vc2, to_char(o_num), to_char(o_id), to_char(o_tstz)),
                                                     '<null>'),
                              object_name     => g_package_name,
                              sub_object_name => l_function_name);
    EXCEPTION
        WHEN pk_touch_option_core.e_invalid_parameter THEN
            DECLARE
                l_instance PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_parameter',
                                                   err_instance_id_out => l_instance,
                                                   text_in             => g_error,
                                                   name1_in            => 'PACKAGE',
                                                   value1_in           => g_package_name,
                                                   name2_in            => 'METHOD',
                                                   value2_in           => l_function_name);
                RAISE;
            END;
    END init_fltr_params_doc_macro;

    /*************************************************************************
    * Sets status for macro record (Active/Inactive/Cancelled)               *
    *                                                                        *
    * @param   i_lang           Professional preferred language              *
    * @param   i_prof           Professional identification and its context  *
    *                           (institution and software)                   *
    * @param   i_doc_macro      Doc_Macro ID                                 *
    * @param   i_flg_status     Doc macro status                             *
    *                           A - Active; I - Inactive; C - Canceled       *
    *                                                                        *
    * @catches                                                               *
    * @throws                                                                *
    *                                                                        *
    * @author  GUSTAVO.SERRANO                                               *
    * @version 2.6.2                                                         *
    * @since   2012/03/09                                                    *
    *************************************************************************/
    PROCEDURE set_macro_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_doc_macro  IN doc_macro.id_doc_macro%TYPE,
        i_flg_status IN doc_macro.flg_status%TYPE
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_macro_status';
    
        l_rows_out table_varchar := table_varchar();
        l_chk      NUMBER(1);
        l_error    t_error_out;
    BEGIN
        g_sysdate := current_timestamp;
    
        SELECT COUNT(1)
          INTO l_chk
          FROM doc_macro dm
         WHERE dm.id_doc_macro = i_doc_macro
           AND dm.id_prof_create = i_prof.id
           AND dm.id_institution = i_prof.institution
           AND dm.flg_status != i_flg_status;
    
        IF l_chk = 1
        THEN
        
            g_error := 'INSERT HISTORY FOR DOC_MACRO_SOFT';
            ins_dms_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => i_doc_macro);
        
            g_error := 'INSERT HISTORY FOR DOC_MACRO_PROF';
            ins_dmp_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => i_doc_macro);
        
            g_error := 'INSERT HISTORY FOR DOC_MACRO';
            ins_dm_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => i_doc_macro);
        
            ts_doc_macro.upd(id_doc_macro_in => i_doc_macro, flg_status_in => i_flg_status, rows_out => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE FOR DOC_MACRO';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'DOC_MACRO',
                                          i_rowids     => l_rows_out,
                                          o_error      => l_error);
        ELSE
            RAISE e_ux_exception;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RAISE;
    END set_macro_status;

    /*************************************************************************
    * Procedure used to return information for macro edition                 *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_prof              Object (professional ID, institution ID,    *
    *                            software ID)                                *
    * @param i_doc_macro         Doc macro identifier                        *
    *                                                                        *
    * @param o_macro_info          Cursor with macro information             *                 
    * @param o_macro_documentation Cursor with macro version documentation   *
    *                              values                                    *
    * @param o_element_domain      Cursor with elements domain               *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/09                                   *
    *************************************************************************/
    PROCEDURE get_macro_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_doc_macro           IN doc_macro_version.id_doc_macro_version%TYPE,
        o_macro_info          OUT pk_types.cursor_type,
        o_macro_documentation OUT pk_types.cursor_type,
        o_element_domain      OUT pk_types.cursor_type
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_macro_info';
    
        l_doc_macro_version doc_macro_version.id_doc_macro_version%TYPE;
        l_error             t_error_out;
    BEGIN
    
        g_error := 'Fetch DOC_MACRO version identifier';
        pk_alertlog.log_debug(text => g_error, object_name => l_function_name, sub_object_name => l_function_name);
        SELECT dm.id_doc_macro_version
          INTO l_doc_macro_version
          FROM doc_macro dm
         WHERE dm.id_doc_macro = i_doc_macro;
    
        g_error := 'Fetch DOC_MACRO information';
        pk_alertlog.log_debug(text => g_error, object_name => l_function_name, sub_object_name => l_function_name);
        OPEN o_macro_info FOR
            SELECT dm.id_doc_macro,
                   dm.id_doc_macro_version,
                   pk_string_utils.clob_to_sqlvarchar2(i_clob => pk_translation.get_translation_trs(i_code_mess => dm.code_doc_macro)) doc_macro_name,
                   dm.flg_share,
                   dm.flg_status,
                   dm.notes,
                   dmv.id_doc_area,
                   dmv.id_doc_template,
                   pk_translation.get_translation(i_lang, 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || dmv.id_doc_template) desc_doc_template,
                   pk_utils.concatenate_list(CURSOR (SELECT dms.id_software
                                                FROM doc_macro_soft dms
                                               WHERE dms.id_doc_macro = dm.id_doc_macro
                                                 AND dms.flg_status = 'A'
                                               ORDER BY dms.id_software),
                                             ',') id_software_lst
              FROM doc_macro dm
             INNER JOIN doc_macro_version dmv
                ON dmv.id_doc_macro_version = dm.id_doc_macro_version
             WHERE dm.id_doc_macro = i_doc_macro
               AND dm.id_prof_create = i_prof.id
               AND id_institution = i_prof.institution;
    
        g_error := 'Fetch DOC_MACRO documentation information';
        pk_alertlog.log_debug(text => g_error, object_name => l_function_name, sub_object_name => l_function_name);
        get_macro_documentation(i_lang                => i_lang,
                                i_prof                => i_prof,
                                i_doc_macro_version   => l_doc_macro_version,
                                o_macro_documentation => o_macro_documentation,
                                o_element_domain      => o_element_domain);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RAISE;
    END get_macro_info;

    /*************************************************************************
    * Function used to get a full phrase associated to an element quantified *
    * based on pk_touch_option.get_epis_doc_quantification                   *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_doc_macro_version_det  Doc macro version detail identifier    *
    *                                                                        *
    * @return Full phrase associated with the element quantified             *
    *         (example: "Mild pain")                                         *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/13                                   *
    *************************************************************************/
    FUNCTION get_doc_macro_quantification
    (
        i_lang                  IN language.id_language%TYPE,
        i_doc_macro_version_det IN doc_macro_version_det.id_doc_macro_version_det%TYPE
    ) RETURN VARCHAR2 IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_macro_quantification';
        l_result VARCHAR2(32767);
    BEGIN
        -- We need to create a new field instead of reusing CODE_DOC_ELEM_QUALIF_CLOSE for compatibility reasons 
        -- to deal with old templates that have in this field the quantifier only (example: "mild") 
        -- and new templates that will use a phrase for the element quantified (example: "Mild pain")
        BEGIN
            SELECT pk_translation.get_translation(i_lang, deq.code_doc_element_quantif_close) desc_quantification
              INTO l_result
              FROM doc_macro_version_qlf dmvq
             INNER JOIN doc_element_qualif deq
                ON dmvq.id_doc_element_qualif = deq.id_doc_element_qualif
             WHERE dmvq.id_doc_macro_version_det = i_doc_macro_version_det
               AND deq.id_doc_quantification IS NOT NULL
               AND deq.id_doc_qualification IS NULL
               AND deq.code_doc_element_quantif_close IS NOT NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_result := NULL;
        END;
    
        RETURN TRIM(TRIM(trailing chr(10) FROM l_result));
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_function_name,
                                                  o_error    => l_error);
            END;
            RETURN NULL;
    END get_doc_macro_quantification;

    /*************************************************************************
    * Function used to get a concatenated list of qualifications associated  *
    * with an element in parentheses.                                        *
    * based on pk_touch_option.get_epis_doc_qualification                    *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_doc_macro_version_det  Doc macro version detail identifier    *
    *                                                                        *
    * @return String with concatenated list of qualifications                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/13                                   *
    *************************************************************************/
    FUNCTION get_doc_macro_qualification
    (
        i_lang                  IN language.id_language%TYPE,
        i_doc_macro_version_det IN doc_macro_version_det.id_doc_macro_version_det%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767);
    BEGIN
        SELECT decode(qll.desc_qualif, NULL, NULL, ' (' || qll.desc_qualif || ')')
          INTO l_result
          FROM (SELECT pk_utils.concatenate_list(CURSOR (SELECT TRIM(TRIM(trailing chr(10) FROM
                                                                   pk_translation.get_translation(i_lang,
                                                                                                  deq.code_doc_elem_qualif_close)))
                                                    FROM doc_macro_version_qlf dmvq
                                                   INNER JOIN doc_element_qualif deq
                                                      ON deq.id_doc_element_qualif = dmvq.id_doc_element_qualif
                                                   WHERE dmvq.id_doc_macro_version_det = i_doc_macro_version_det
                                                     AND deq.id_doc_qualification IS NOT NULL),
                                                 '; ') desc_qualif
                  FROM dual) qll;
        RETURN l_result;
    END get_doc_macro_qualification;

    /*************************************************************************
    * Function used to get the quantifier description associated to an       *
    * element quantified                                                     *
    *                                                                        *
    * This function is used for compatibility purposes to deal with old      *
    * descriptions for element's quantifier in templates.                    *
    * In new template's elements that make use of quantifiers this function  *
    * should return null values, and the new function                        *
    * get_epis_doc_quantification() return the full description for an       *
    * element quantified.                                                    *  
    * based on pk_touch_option.get_epis_doc_quantifier                       *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_doc_macro_version_det  Doc macro version detail identifier    *
    *                                                                        *
    * @return String with description associated with the quantifier         *
    *         (example: "mild")                                              *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/13                                   *
    *************************************************************************/
    FUNCTION get_doc_macro_quantifier
    (
        i_lang                  IN language.id_language%TYPE,
        i_doc_macro_version_det IN doc_macro_version_det.id_doc_macro_version_det%TYPE
    ) RETURN VARCHAR2 IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_macro_quantifier';
        l_result VARCHAR2(32767);
    BEGIN
    
        BEGIN
            SELECT pk_translation.get_translation(i_lang, deq.code_doc_elem_qualif_close) desc_quantifier
              INTO l_result
              FROM doc_macro_version_qlf dmvq
             INNER JOIN doc_element_qualif deq
                ON deq.id_doc_element_qualif = dmvq.id_doc_element_qualif
             WHERE dmvq.id_doc_macro_version_det = i_doc_macro_version_det
               AND deq.id_doc_quantification IS NOT NULL
               AND deq.id_doc_qualification IS NULL
               AND deq.code_doc_elem_qualif_close IS NOT NULL;
        EXCEPTION
            WHEN no_data_found THEN
                l_result := NULL;
        END;
    
        RETURN TRIM(TRIM(trailing chr(10) FROM l_result));
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_function_name,
                                                  o_error    => l_error);
            END;
            RETURN NULL;
    END get_doc_macro_quantifier;

    /**************************************************************************        
    * Return cursor with records for touch option area        
    *                                                                                 
    * @param i_lang                   Language ID                                     
    * @param i_prof                   Profissional ID                                 
    * @param i_id_episode             Episode ID        
    * @param i_id_patient             Patient ID        
    * @param i_doc_area               Documentation area ID        
    * @param i_epis_doc               Table number with id_epis_documentation        
    * @param i_epis_anamn             Table number with id_epis_anamnesis        
    * @param i_epis_rev_sys           Table number with id_epis_review_systems        
    * @param i_epis_obs               Table number with id_epis_observation        
    * @param i_epis_past_fsh          Table number with id_pat_fam_soc_hist        
    * @param i_epis_recomend          Table number with id_epis_recomend        
    * @param i_flg_show_fm            Flag to show (Y) or not (N) patient's family members information        
    * @param i_order                  Order of records returned ('ASC' Ascending , 'DESC' Descending)        
    * @param o_doc_area_register      Cursor with the doc area info register        
    * @param o_doc_area_val           Cursor containing the completed info for episode        
    * @param o_template_layouts       Cursor containing the layout for each template used        
    * @param o_doc_area_component     Cursor containing the components for each template used        
    * @param o_error                  Error message        
    *                                                                                 
    * @author                         Filipe Silva & Ariel Machado                                   
    * @version                        2.6.0.5                                        
    * @since                          2011/02/17                                        
    **************************************************************************/
    PROCEDURE get_doc_area_value_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_id            IN professional.id_professional%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_macro_version  IN table_number,
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        o_doc_area_register  OUT NOCOPY pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT NOCOPY pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT NOCOPY pk_types.cursor_type,
        o_doc_area_component OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) IS
        l_function_name VARCHAR2(30 CHAR) := 'GET_DOC_AREA_VALUE_INTERNAL';
    BEGIN
        g_error := 'OPEN O_DOC_AREA_REGISTER CURSOR';
        pk_alertlog.log_debug(g_error);
        --Returns records that meet the criteria arguments
        OPEN o_doc_area_register FOR
        --Entries done in Touch-option model
            SELECT /*+ dynamic_sampling(t 2) */
             decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - dmv.dt_last_update) order_by_default,
             trunc(SYSDATE) order_default,
             dmv.id_doc_macro_version id_epis_documentation,
             dmv.id_parent PARENT,
             dmv.id_doc_template,
             pk_translation.get_translation(i_lang, 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || dmv.id_doc_template) template_desc,
             pk_date_utils.date_send_tsz(i_lang, dmv.dt_creation, i_prof) dt_creation,
             dmv.dt_creation dt_creation_tstz,
             pk_date_utils.date_char_tsz(i_lang, dmv.dt_last_update, i_prof.institution, i_prof.software) dt_register,
             dmv.id_professional,
             pk_prof_utils.get_name_signature(i_lang, i_prof, dmv.id_professional) nick_name,
             pk_prof_utils.get_spec_signature(i_lang,
                                              i_prof,
                                              dmv.id_professional,
                                              get_doc_macro_version_instit(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_doc_macro_version => dmv.id_doc_macro_version)) desc_speciality,
             dmv.id_doc_area,
             dmv.flg_status,
             decode(dmv.flg_status,
                    pk_alert_constant.g_active,
                    NULL,
                    pk_sysdomain.get_domain('DOC_MACRO.FLG_STATUS', dmv.flg_status, i_lang)) desc_status,
             NULL id_episode,
             pk_alert_constant.g_no flg_current_episode, --@TODO Validate this
             dmv.notes,
             pk_date_utils.date_send_tsz(i_lang, dmv.dt_last_update, i_prof) dt_last_update,
             dmv.dt_last_update dt_last_update_tstz,
             --GS@20120330 - Took this flag to return value for flg_edition_type without changing the type pk_touch_option.t_rec_doc_area_register
             --original value: pk_alert_constant.g_yes flg_detail
             decode(row_number() over(PARTITION BY dmv.id_doc_macro_version ORDER BY dmv.dt_creation),
                    1,
                    dmv.flg_edition_type,
                    g_flg_edition_type_nochanges) flg_detail,
             pk_alert_constant.g_no flg_external,
             decode(dmv.id_doc_template, NULL, pk_summary_page.g_free_text, pk_summary_page.g_touch_option) flg_type_register,
             pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin, -- Record has its origin in the epis_documentation table
             NULL flg_reviewed,
             NULL id_prof_cancel,
             NULL dt_cancel_tstz,
             NULL id_cancel_reason,
             NULL cancel_reason,
             NULL cancel_notes,
             NULL flg_edition_type,
             pk_prof_utils.get_name_signature(i_lang, i_prof, dmv.id_professional) nick_name_prof_create,
             pk_prof_utils.get_spec_signature(i_lang,
                                              i_prof,
                                              dmv.id_professional,
                                              get_doc_macro_version_instit(i_lang              => i_lang,
                                                                           i_prof              => i_prof,
                                                                           i_doc_macro_version => dmv.id_doc_macro_version)) desc_speciality_prof_create,
             NULL dt_clinical,
             NULL dt_clinical_chr,
             NULL signature
              FROM doc_macro_version dmv
             INNER JOIN TABLE(i_doc_macro_version) t
                ON t.column_value = dmv.id_doc_macro_version
             WHERE (dmv.id_doc_area = i_doc_area OR i_doc_area IS NULL)
             ORDER BY order_by_default,
                      row_number() over(PARTITION BY dmv.id_doc_macro_version ORDER BY dmv.dt_creation) DESC;
    
        g_error := 'GET CURSOR O_DOC_AREA_VAL';
        pk_alertlog.log_debug(g_error);
        OPEN o_doc_area_val FOR
            SELECT /*+ index(ed epis_documentation(id_epis_documentation)) */
             dmv.id_doc_macro_version id_epis_documentation,
             dmv.id_parent PARENT,
             d.id_documentation,
             d.id_doc_component,
             decr.id_doc_element_crit,
             pk_date_utils.date_send_tsz(i_lang, dmv.dt_creation, i_prof) dt_reg,
             TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
             dc.flg_type,
             pk_touch_option.get_element_description(i_lang,
                                                     i_prof,
                                                     de.flg_type,
                                                     dmvd.value,
                                                     dmvd.value_properties,
                                                     decr.id_doc_element_crit,
                                                     de.id_unit_measure_reference,
                                                     de.id_master_item,
                                                     decr.code_element_close) desc_element,
             TRIM(pk_translation.get_translation(i_lang, decr.code_element_view)) desc_element_view,
             pk_touch_option.get_formatted_value(i_lang,
                                                 i_prof,
                                                 de.flg_type,
                                                 dmvd.value,
                                                 dmvd.value_properties,
                                                 de.input_mask,
                                                 de.flg_optional_value,
                                                 de.flg_element_domain_type,
                                                 de.code_element_domain,
                                                 dmv.dt_creation) VALUE,
             de.flg_type flg_type_element,
             dmv.id_doc_area,
             dtad.rank rank_component,
             de.rank rank_element,
             de.internal_name,
             get_doc_macro_quantifier(i_lang, dmvd.id_doc_macro_version_det) desc_quantifier,
             get_doc_macro_quantification(i_lang, dmvd.id_doc_macro_version_det) desc_quantification,
             get_doc_macro_qualification(i_lang, dmvd.id_doc_macro_version_det) desc_qualification,
             de.display_format,
             de.separator,
             pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin,
             'A' flg_status, --TODO: Change this code, 
             dmvd.value value_id,
             NULL signature
              FROM doc_macro_version dmv
             INNER JOIN doc_macro_version_det dmvd
                ON dmv.id_doc_macro_version = dmvd.id_doc_macro_version
             INNER JOIN documentation d
                ON d.id_documentation = dmvd.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = dmv.id_doc_template
               AND dtad.id_doc_area = dmv.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = dmvd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             WHERE (dmv.id_doc_area = i_doc_area OR i_doc_area IS NULL)
               AND dmv.id_doc_macro_version IN (SELECT /*+ dynamic_sampling(t 2) */
                                                 t.column_value
                                                  FROM TABLE(i_doc_macro_version) t)
               AND decr.flg_view = pk_summary_page.g_flg_view_summary
            UNION ALL
            SELECT epis_d.id_epis_documentation,
                   NULL PARENT,
                   d.id_documentation,
                   dc.id_doc_component,
                   NULL id_doc_element_crit,
                   NULL dt_reg,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   dc.flg_type,
                   NULL desc_element,
                   NULL desc_element_view,
                   NULL VALUE,
                   NULL flg_type_element,
                   epis_d.id_doc_area,
                   dtad.rank rank_component,
                   NULL rank_element,
                   NULL internal_name,
                   NULL desc_quantifier,
                   NULL desc_quantification,
                   NULL desc_qualification,
                   NULL display_format,
                   NULL separator,
                   pk_touch_option.g_flg_tab_origin_epis_doc flg_table_origin,
                   pk_alert_constant.g_active flg_status,
                   NULL value_id,
                   NULL signature
              FROM documentation d
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
             INNER JOIN (SELECT DISTINCT dmv.id_doc_macro_version id_epis_documentation,
                                         dmv.id_doc_template,
                                         dmv.id_doc_area,
                                         d.id_documentation_parent
                           FROM documentation d
                          INNER JOIN doc_macro_version_det dmvd
                             ON d.id_documentation = dmvd.id_documentation
                          INNER JOIN doc_macro_version dmv
                             ON dmvd.id_doc_macro_version = dmv.id_doc_macro_version
                          INNER JOIN doc_element_crit decr
                             ON dmvd.id_doc_element_crit = decr.id_doc_element_crit
                          WHERE (dmv.id_doc_area = i_doc_area OR i_doc_area IS NULL)
                            AND dmv.id_doc_macro_version IN
                                (SELECT /*+ dynamic_sampling(t 2) */
                                  t.column_value
                                   FROM TABLE(i_doc_macro_version) t)
                            AND d.flg_available = pk_touch_option.g_available
                            AND decr.flg_view = pk_summary_page.g_flg_view_summary
                            AND d.id_documentation_parent IS NOT NULL) epis_d
                ON d.id_documentation = epis_d.id_documentation_parent
             INNER JOIN doc_template_area_doc dtad
                ON epis_d.id_doc_template = dtad.id_doc_template
               AND epis_d.id_doc_area = dtad.id_doc_area
               AND d.id_documentation = dtad.id_documentation
             WHERE dc.flg_type = pk_summary_page.g_doc_title
               AND dc.flg_available = pk_alert_constant.g_available
               AND d.flg_available = pk_alert_constant.g_available
             ORDER BY id_epis_documentation, rank_component, rank_element;
    
        g_error := 'GET CURSOR O_TEMPLATE_LAYOUTS';
        pk_alertlog.log_debug(g_error);
        OPEN o_template_layouts FOR
            SELECT dt.id_doc_template,
                   xmlquery('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]' passing dt.template_layout AS "layout", CAST(i_doc_area AS NUMBER) AS "id_doc_area", CAST(dt.id_doc_template AS NUMBER) AS "id_doc_template" RETURNING content)
                   .getclobval() layout
              FROM doc_template dt
             WHERE dt.id_doc_template IN
                   (SELECT DISTINCT dmv.id_doc_template id_doc_template
                      FROM doc_macro_version dmv
                     WHERE dmv.id_doc_macro_version IN (SELECT /*+ dynamic_sampling(t 2) */
                                                         t.column_value
                                                          FROM TABLE(i_doc_macro_version) t))
               AND xmlexists('declare namespace tlyt="http://www.alert-online.com/2009/TemplateLayout"; $layout/tlyt:TemplateLayout[@idDocTemplate=$id_doc_template]/tlyt:DocArea[@idDocArea=$id_doc_area]'
                             passing dt.template_layout AS "layout",
                             CAST(i_doc_area AS NUMBER) AS "id_doc_area",
                             CAST(dt.id_doc_template AS NUMBER) AS "id_doc_template");
    
        g_error := 'GET CURSOR O_DOC_AREA_COMPONENT';
        pk_alertlog.log_debug(g_error);
        OPEN o_doc_area_component FOR
            SELECT d.id_documentation,
                   dc.flg_type,
                   TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component
              FROM documentation d
             INNER JOIN doc_template_area_doc dtad
                ON d.id_documentation = dtad.id_documentation
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
             WHERE d.flg_available = pk_alert_constant.g_available
               AND dc.flg_available = pk_alert_constant.g_available
               AND (dtad.id_doc_area, dtad.id_doc_template) IN
                   (SELECT DISTINCT dmv.id_doc_area, dmv.id_doc_template
                      FROM doc_macro_version dmv
                     WHERE dmv.id_doc_macro_version IN (SELECT /*+ dynamic_sampling(t 2) */
                                                         t.column_value
                                                          FROM TABLE(i_doc_macro_version) t));
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            /* Open out cursors */
            -- We cannot use open_my_cursor method to open a strong cursor. 
            pk_touch_option.open_cur_doc_area_register(o_doc_area_register);
            pk_touch_option.open_cur_doc_area_val(o_doc_area_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
    END get_doc_area_value_internal;

    /**
    * Returns a set of records done in a touch-option area based on filters criteria and with paging support
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_doc_area           Documentation area ID
    * @param   i_current_episode    Current episode ID
    * @param   i_scope              Scope ID (Episode ID; Visit ID; Patient ID)
    * @param   i_scope_type         Scope type (by episode; by visit; by patient)
    * @param   i_fltr_status        A sequence of flags representing the status that records must comply ('A' Active, 'O' Outdated, 'C' Cancelled) Default 'AOC'
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    * @param   i_fltr_start_date    Begin date (optional)        
    * @param   i_fltr_end_date      End date (optional)        
    * @param   i_paging             Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param   i_start_record       First record. Just considered when paging is used. Default 1
    * @param   i_num_records        Number of records to be retrieved. Just considered when paging is used.  Default 2000
    * @param   o_doc_area_register  Cursor with the doc area info register
    * @param   o_doc_area_val       Cursor containing the completed info for episode
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param   o_error              Error message 
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.4
    * @since   11/09/2010
    */
    PROCEDURE get_doc_area_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_macro          IN doc_macro.id_doc_macro%TYPE,
        i_prof_id            IN professional.id_professional%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_fltr_status        IN VARCHAR2 DEFAULT 'AOC',
        i_order              IN VARCHAR2 DEFAULT 'DESC',
        i_fltr_start_date    IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_fltr_end_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 2000,
        i_flg_hist           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) IS
        TYPE t_rec_doc_entry IS RECORD(
            table_origin VARCHAR2(1 CHAR),
            record_key   NUMBER(24));
        TYPE t_coll_doc_entry IS TABLE OF t_rec_doc_entry;
    
        e_invalid_argument EXCEPTION;
        l_function_name CONSTANT VARCHAR2(30) := 'get_doc_area_value';
    
        l_start_record           NUMBER(24);
        l_end_record             NUMBER(24);
        l_coll_doc_entry         t_coll_doc_entry;
        l_coll_doc_macro_version table_number := table_number();
    
    BEGIN
    
        g_error := 'LOGGING INPUT ARGUMENTS';
        pk_alertlog.log_debug(sub_object_name => l_function_name,
                              text            => 'i_lang: ' || i_lang || ' institution:' || i_prof.institution ||
                                                 ' software:' || i_prof.software || ' i_doc_macro: ' ||
                                                 to_char(i_doc_macro) || ' i_prof_id: ' || to_char(i_prof_id) ||
                                                 ' i_fltr_status:' || i_fltr_status || ' i_order:' || i_order ||
                                                 ' i_fltr_start_date:' || to_char(i_fltr_start_date) ||
                                                 ' i_fltr_end_date:' || to_char(i_fltr_end_date) || ' i_paging:' ||
                                                 i_paging || ' i_start_record:' || to_char(i_start_record) ||
                                                 ' i_num_records:' || to_char(i_num_records));
    
        g_error := 'ANALYSING INPUT ARGUMENTS';
        IF i_doc_macro IS NULL
           OR i_prof_id IS NULL
           OR i_fltr_status IS NULL
           OR i_order IS NULL
           OR i_paging IS NULL
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        g_error := 'ANALYSING DATE INTERVAL WINDOW';
        IF i_fltr_start_date > i_fltr_end_date
        THEN
            g_error := 'Starting date cannot be greater than the ending date';
            RAISE e_invalid_argument;
        END IF;
    
        --Because we need to return how many records there exist we cannot do a Top-N query to optimize the resultset in window rank
        -- (by COUNT STOPKEY ) as example: (rownum < i_start_record + i_num_records) and row_num >= i_start_record)
    
        SELECT table_origin, record_key
          BULK COLLECT
          INTO l_coll_doc_entry
          FROM (
                --Entries done in Touch-option model
                SELECT pk_touch_option.g_flg_tab_origin_epis_doc table_origin,
                        dmv.id_doc_macro_version record_key,
                        decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - dmv.dt_last_update) order_by_default
                  FROM doc_macro dm
                  JOIN doc_macro_version dmv
                    ON dm.id_doc_macro_version = dmv.id_doc_macro_version
                 WHERE dm.id_doc_macro = i_doc_macro
                   AND instr(i_fltr_status, dmv.flg_status) > 0
                   AND dmv.dt_creation >= nvl(i_fltr_start_date, dmv.dt_creation)
                   AND dmv.dt_creation <= nvl(i_fltr_end_date, dmv.dt_creation)
                UNION ALL
                SELECT pk_touch_option.g_flg_tab_origin_epis_doc table_origin,
                        dmv.id_doc_macro_version record_key,
                        decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - dmv.dt_last_update) order_by_default
                  FROM doc_macro_hist dmh
                  JOIN doc_macro_version dmv
                    ON dmh.id_doc_macro_version = dmv.id_doc_macro_version
                 WHERE dmh.id_doc_macro = i_doc_macro
                   AND instr(i_fltr_status, dmv.flg_status) > 0
                   AND dmv.dt_creation >= nvl(i_fltr_start_date, dmv.dt_creation)
                   AND dmv.dt_creation <= nvl(i_fltr_end_date, dmv.dt_creation)
                   AND i_flg_hist = pk_alert_constant.g_yes
                 ORDER BY order_by_default);
    
        o_record_count := l_coll_doc_entry.count;
    
        IF i_paging = 'N'
        THEN
            -- Returns all the resultset
            l_start_record := 1;
            l_end_record   := l_coll_doc_entry.count;
        ELSE
            l_start_record := i_start_record;
            l_end_record   := i_start_record + i_num_records - 1;
        
            IF l_start_record < 1
            THEN
                -- Minimum inbound 
                l_start_record := 1;
            END IF;
        
            IF l_start_record > l_coll_doc_entry.count
            THEN
                -- Force to not return data
                l_start_record := l_coll_doc_entry.count + 1;
            END IF;
        
            IF l_end_record > l_coll_doc_entry.count
            THEN
                -- Maximum outbound 
                l_end_record := l_coll_doc_entry.count;
            END IF;
        END IF;
    
        FOR i IN l_start_record .. l_end_record
        LOOP
            CASE l_coll_doc_entry(i).table_origin
                WHEN pk_touch_option.g_flg_tab_origin_epis_doc THEN
                    l_coll_doc_macro_version.extend;
                    l_coll_doc_macro_version(l_coll_doc_macro_version.last) := l_coll_doc_entry(i).record_key;
            END CASE;
        END LOOP;
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_INTERNAL FUNCTION';
        pk_alertlog.log_debug(g_error);
    
        get_doc_area_value_internal(i_lang               => i_lang,
                                    i_prof               => i_prof,
                                    i_prof_id            => i_prof_id,
                                    i_doc_area           => i_doc_area,
                                    i_doc_macro_version  => l_coll_doc_macro_version,
                                    i_order              => i_order,
                                    o_doc_area_register  => o_doc_area_register,
                                    o_doc_area_val       => o_doc_area_val,
                                    o_template_layouts   => o_template_layouts,
                                    o_doc_area_component => o_doc_area_component,
                                    o_error              => o_error);
    
    EXCEPTION
        WHEN e_invalid_argument THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'An input parameter has an unexpected value',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RAISE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RAISE;
    END get_doc_area_value;

    /*************************************************************************
    * Procedure used to return information for macro detail screen           *
    *                                                                        *
    * @param i_lang              Preferred language ID for this professional *
    * @param i_prof              Object (professional ID, institution ID,    *
    *                            software ID)                                *
    * @param i_doc_macro         Doc macro identifier                        *
    *                                                                        *
    * @param o_macro_detail       Cursor with macro information              *                 
    * @param o_doc_area_register  Cursor with the doc area info register     *
    * @param o_doc_area_val       Cursor with containing the completed info  *
    * @param o_template_layouts   Cursor containing the layout for each      *
    *                             template used                              *
    * @param o_doc_area_component Cursor containing the components for each  *
    *                             template used                              *
    * @param o_record_count       Indicates the number of records that match *
    *                             filters criteria                           *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/09                                   *
    *************************************************************************/
    PROCEDURE get_macro_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_macro          IN doc_macro_version.id_doc_macro_version%TYPE,
        i_flg_hist           IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_macro_detail       OUT pk_types.cursor_type,
        o_doc_area_register  OUT pk_touch_option.t_cur_doc_area_register,
        o_doc_area_val       OUT pk_touch_option.t_cur_doc_area_val,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_macro_detail';
    
        l_prof_id  professional.id_professional%TYPE;
        l_doc_area doc_area.id_doc_area%TYPE;
    BEGIN
    
        g_error := 'Fetch DOC_MACRO version identifier';
        SELECT dm.id_prof_create, dmv.id_doc_area
          INTO l_prof_id, l_doc_area
          FROM doc_macro dm
          JOIN doc_macro_version dmv
            ON dmv.id_doc_macro_version = dm.id_doc_macro_version
         WHERE dm.id_doc_macro = i_doc_macro;
    
        g_error := 'Fetch doc_macro general information';
        /*        OPEN o_macro_detail FOR
        SELECT t.id_doc_macro id_doc_macro,
               t.id_doc_macro_version,
               pk_translation.get_translation_trs(i_code_mess => t.code_doc_macro) doc_macro_name,
               pk_utils.concatenate_list(CURSOR (SELECT pk_utils.get_software_name(i_lang        => i_lang,
                                                                            i_id_software => x.column_value)
                                            FROM TABLE(t.lst_software) x),
                                         '; ') lst_software_desc,
               t.id_doc_area id_doc_area,
               pk_summary_page.get_doc_area_name(i_lang => i_lang, i_prof => i_prof, i_doc_area => t.id_doc_area) doc_area_name,
               t.id_doc_template id_doc_template,
               pk_translation.get_translation(i_lang      => i_lang,
                                              i_code_mess => 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' || t.id_doc_template) doc_template_name,
               t.flg_status flg_status,
               pk_sysdomain.get_domain(i_code_dom => g_dcm_flg_status_sysdomain,
                                       i_val      => t.flg_status,
                                       i_lang     => i_lang) flg_status_desc
          FROM v_tot_macro_documentation t
         WHERE t.id_doc_macro = i_doc_macro;*/
    
        OPEN o_macro_detail FOR
            SELECT flg_history,
                   lag(id_doc_macro_version, 1, id_doc_macro_version) over(ORDER BY dt_orderby) id_doc_macro_version,
                   id_doc_macro_version id_doc_macro_version_new,
                   lag(doc_macro_name, 1, doc_macro_name) over(ORDER BY dt_orderby) doc_macro_name,
                   decode(lag(doc_macro_name, 1, doc_macro_name) over(ORDER BY dt_orderby),
                          doc_macro_name,
                          NULL,
                          doc_macro_name) doc_macro_name_new,
                   --decode(lag(doc_macro_name, 1, doc_macro_name) over(ORDER BY dt_orderby), doc_macro_name, pk_alert_constant.g_no, pk_alert_constant.g_yes) doc_macro_name_changed,
                   pk_sysdomain.get_domain(i_code_dom => g_dcm_flg_status_sysdomain,
                                           i_val      => (lag(flg_status, 1, flg_status) over(ORDER BY dt_orderby)),
                                           i_lang     => i_lang) doc_macro_flg_status,
                   decode(lag(flg_status, 1, flg_status) over(ORDER BY dt_orderby),
                          flg_status,
                          NULL,
                          nvl(pk_sysdomain.get_domain(i_code_dom => g_dcm_flg_status_sysdomain,
                                                      i_val      => flg_status,
                                                      i_lang     => i_lang),
                              '---')) doc_macro_flg_status_new,
                   pk_sysdomain.get_domain(i_code_dom => g_dcm_flg_share_sysdomain,
                                           i_val      => (lag(flg_share, 1, flg_share) over(ORDER BY dt_orderby)),
                                           i_lang     => i_lang) doc_macro_flg_share,
                   decode(lag(flg_share, 1, flg_share) over(ORDER BY dt_orderby),
                          flg_share,
                          NULL,
                          nvl(pk_sysdomain.get_domain(i_code_dom => g_dcm_flg_share_sysdomain,
                                                      i_val      => flg_share,
                                                      i_lang     => i_lang),
                              '---')) doc_macro_flg_share_new,
                   lag(notes, 1, notes) over(ORDER BY dt_orderby) doc_macro_notes,
                   lag(doc_area_name, 1, doc_area_name) over(ORDER BY dt_orderby) doc_area_name,
                   decode(lag(doc_area_name, 1, doc_area_name) over(ORDER BY dt_orderby),
                          doc_area_name,
                          NULL,
                          doc_area_name) doc_area_name_new,
                   lag(doc_template_name, 1, doc_template_name) over(ORDER BY dt_orderby) doc_template_name,
                   decode(lag(doc_template_name, 1, doc_template_name) over(ORDER BY dt_orderby),
                          doc_template_name,
                          NULL,
                          doc_template_name) doc_template_name_new,
                   decode(lag(notes, 1, notes) over(ORDER BY dt_orderby), notes, NULL, notes) doc_macro_notes_new,
                   --decode(lag(notes, 1, notes) over(ORDER BY dt_orderby), notes, pk_alert_constant.g_no, pk_alert_constant.g_yes) doc_macro_notes_changed,
                   lag(software_lst, 1, software_lst) over(ORDER BY dt_orderby) software_lst,
                   decode(lag(software_lst, 1, software_lst) over(ORDER BY dt_orderby),
                          software_lst,
                          NULL,
                          software_lst) software_lst_new,
                   --      decode(software_lst.count, 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)software_lst_changed,
                   lag(prof_lst, 1, prof_lst) over(ORDER BY dt_orderby) prof_lst,
                   decode(lag(prof_lst, 1, prof_lst) over(ORDER BY dt_orderby), prof_lst, NULL, prof_lst) prof_lst_new,
                   pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => id_professional) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_prof_id   => id_professional,
                                                    i_prof_inst => id_institution) desc_speciality,
                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                               i_date => lead(dt_orderby, 1, dt_creation) over(ORDER BY dt_orderby DESC),
                                               i_inst => i_prof.institution,
                                               i_soft => i_prof.software) dt_last_update,
                   id_prof_create,
                   dt_orderby
              FROM (SELECT dm.id_doc_macro_version,
                           pk_string_utils.clob_to_sqlvarchar2(i_clob => pk_translation.get_translation_trs(i_code_mess => dm.code_doc_macro)) doc_macro_name,
                           dm.id_institution,
                           dm.flg_status,
                           dm.flg_share,
                           dm.notes notes,
                           dmv.id_doc_area,
                           pk_summary_page.get_doc_area_name(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_doc_area => dmv.id_doc_area) doc_area_name,
                           dmv.id_doc_template,
                           pk_translation.get_translation(i_lang      => i_lang,
                                                          i_code_mess => 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' ||
                                                                         dmv.id_doc_template) doc_template_name,
                           pk_utils.concatenate_list(p_cursor => CURSOR (SELECT pk_utils.get_software_name(i_lang        => i_lang,
                                                                                                           i_id_software => dms.id_software)
                                                                           FROM doc_macro_soft dms
                                                                          WHERE dms.id_doc_macro = dm.id_doc_macro
                                                                            AND dms.flg_status = g_dcms_flg_status_active
                                                                          ORDER BY dms.id_software),
                                                     p_delim  => ';') software_lst,
                           pk_utils.concatenate_list(p_cursor => CURSOR (SELECT pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                                                 i_prof    => i_prof,
                                                                                                                 i_prof_id => dmp.id_professional)
                                                                           FROM doc_macro_prof dmp
                                                                          WHERE dmp.id_doc_macro = dm.id_doc_macro
                                                                            AND dmp.flg_status = g_dcmp_flg_status_active
                                                                          ORDER BY dmp.id_professional),
                                                     p_delim  => ';') prof_lst,
                           current_timestamp dt_orderby,
                           dm.dt_creation,
                           dm.id_prof_create,
                           dmv.id_professional,
                           pk_alert_constant.g_no flg_history
                      FROM doc_macro dm
                     INNER JOIN doc_macro_version dmv
                        ON dmv.id_doc_macro_version = dm.id_doc_macro_version
                     WHERE dm.id_doc_macro = i_doc_macro
                    UNION ALL
                    SELECT dmh.id_doc_macro_version,
                           dmh.doc_macro_name,
                           dmh.id_institution,
                           dmh.flg_status,
                           dmh.flg_share,
                           dmh.notes notes,
                           dmv.id_doc_area,
                           pk_summary_page.get_doc_area_name(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_doc_area => dmv.id_doc_area) doc_area_name,
                           dmv.id_doc_template,
                           pk_translation.get_translation(i_lang      => i_lang,
                                                          i_code_mess => 'DOC_TEMPLATE.CODE_DOC_TEMPLATE.' ||
                                                                         dmv.id_doc_template) doc_template_name,
                           pk_utils.concatenate_list(p_cursor => CURSOR
                                                                 (SELECT pk_utils.get_software_name(i_lang        => i_lang,
                                                                                                    i_id_software => dmsh.id_software)
                                                                    FROM doc_macro_soft_hist dmsh
                                                                   WHERE dmsh.id_doc_macro = dmh.id_doc_macro
                                                                     AND dmsh.dt_doc_macro_hist = dmh.dt_doc_macro_hist
                                                                     AND dmsh.flg_status = g_dcms_flg_status_active
                                                                   ORDER BY dmsh.id_software),
                                                     p_delim  => ';') software_lst,
                           pk_utils.concatenate_list(p_cursor => CURSOR
                                                                 (SELECT pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                                          i_prof    => i_prof,
                                                                                                          i_prof_id => dmph.id_professional)
                                                                    FROM doc_macro_prof_hist dmph
                                                                   WHERE dmph.id_doc_macro = dmh.id_doc_macro
                                                                     AND dmph.dt_doc_macro_hist = dmh.dt_doc_macro_hist
                                                                     AND dmph.flg_status = g_dcmp_flg_status_active
                                                                   ORDER BY dmph.id_professional),
                                                     p_delim  => ';') prof_lst,
                           dmh.dt_doc_macro_hist dt_orderby,
                           dmh.dt_creation,
                           dmh.id_prof_create,
                           dmv.id_professional,
                           pk_alert_constant.g_yes flg_history
                      FROM doc_macro_hist dmh
                     INNER JOIN doc_macro_version dmv
                        ON dmv.id_doc_macro_version = dmh.id_doc_macro_version
                     WHERE dmh.id_doc_macro = i_doc_macro
                       AND i_flg_hist = pk_alert_constant.g_yes)
             ORDER BY flg_history, dt_orderby DESC;
    
        g_error := 'Fetch doc_macro template information';
        get_doc_area_value(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_doc_macro          => i_doc_macro,
                           i_prof_id            => l_prof_id,
                           i_doc_area           => l_doc_area,
                           i_flg_hist           => i_flg_hist,
                           o_doc_area_register  => o_doc_area_register,
                           o_doc_area_val       => o_doc_area_val,
                           o_template_layouts   => o_template_layouts,
                           o_doc_area_component => o_doc_area_component,
                           o_record_count       => o_record_count,
                           o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RAISE;
    END get_macro_detail;

    /*************************************************************************
    * Procedure to be used as an helper to validate permissions for a list   *
    * of macros based on his dependencies (such as software association      *
    * with professional, software association with doc_area and doc_template)*
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_tbl_doc_macro    List of doc macro identifiers (in case of    *
    *                           null or empty all macros for the user and    *
    *                           institution will be validated                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/03/14                                   *
    *************************************************************************/
    PROCEDURE update_dm_dependencies
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_doc_macro IN table_number DEFAULT NULL
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'update_dm_dependencies';
    
        TYPE t_proc_dm IS TABLE OF NUMBER NOT NULL INDEX BY BINARY_INTEGER;
    
        CURSOR c_dm_deps(l_tbl_dm table_number) IS
            SELECT t.id_doc_macro,
                   t.id_institution,
                   t.dm_status,
                   t.id_doc_area,
                   t.id_doc_template,
                   dt.id_doc_template tf_doc_template,
                   t.id_doc_macro_soft,
                   t.id_software,
                   t.dms_status,
                   t.id_doc_macro_prof,
                   t.id_professional,
                   t.dmp_status,
                   t.id_prof_soft_inst,
                   COUNT(t.id_doc_macro) over(PARTITION BY t.id_doc_macro) - COUNT(t.id_doc_macro) over(PARTITION BY id_doc_macro, nvl2(t.id_prof_soft_inst, nvl2(dt.id_doc_template, 0, 1), 1)) total
              FROM (SELECT dm.id_doc_macro,
                           dm.id_institution,
                           dm.flg_status dm_status,
                           dmv.id_doc_area,
                           dmv.id_doc_template,
                           dms.id_doc_macro_soft,
                           dms.id_software,
                           dms.flg_status dms_status,
                           dmp.id_doc_macro_prof,
                           dmp.id_professional,
                           dmp.flg_status dmp_status,
                           psi.id_prof_soft_inst,
                           CAST(COLLECT(to_number(dmv.id_doc_template)) over(PARTITION BY 1) AS table_number) tbl_doc_template
                      FROM doc_macro dm
                     INNER JOIN doc_macro_version dmv
                        ON dmv.id_doc_macro_version = dm.id_doc_macro_version
                     INNER JOIN doc_macro_soft dms
                        ON dms.id_doc_macro = dm.id_doc_macro
                     INNER JOIN doc_macro_prof dmp
                        ON dmp.id_doc_macro = dm.id_doc_macro
                      LEFT JOIN prof_soft_inst psi
                        ON psi.id_institution = dm.id_institution
                       AND psi.id_software = dms.id_software
                       AND psi.id_professional = dmp.id_professional
                     WHERE dm.id_doc_macro IN (SELECT /*+ dynamic_sampling(t 2) */
                                                t.column_value
                                                 FROM TABLE(l_tbl_dm) t)
                       AND dm.flg_status IN (g_dcm_flg_status_active, g_dcm_flg_status_disabled)
                       AND dmv.flg_status = g_dcmv_flg_status_active
                       AND dms.flg_status IN (g_dcms_flg_status_active, g_dcms_flg_status_disabled)
                       AND dmp.flg_status IN (g_dcmp_flg_status_active, g_dcmp_flg_status_disabled)) t
              LEFT JOIN TABLE(pk_touch_option_core.tf_doc_templates(i_lang => i_lang, i_professional => t.id_professional, i_institution => t.id_institution, i_software => t.id_software, i_doc_area => t.id_doc_area, i_doc_template => t.tbl_doc_template)) dt
                ON dt.id_doc_template = t.id_doc_template;
    
        r_dm_deps       c_dm_deps%ROWTYPE;
        l_tbl_doc_macro table_number;
        l_proc_dm       t_proc_dm;
        l_rows_out      table_varchar := table_varchar();
        l_rows_upd_dcm  table_varchar := table_varchar();
        l_rows_upd_dcms table_varchar := table_varchar();
    
        l_error t_error_out;
    BEGIN
        g_sysdate := current_timestamp;
    
        g_error := 'Evaluate i_tbl_doc_macro';
        IF (i_tbl_doc_macro IS NOT NULL AND i_tbl_doc_macro.count > 0)
        THEN
            l_tbl_doc_macro := i_tbl_doc_macro;
        ELSE
            SELECT dm.id_doc_macro
              BULK COLLECT
              INTO l_tbl_doc_macro
              FROM doc_macro dm
             INNER JOIN doc_macro_prof dmp
                ON dmp.id_doc_macro = dm.id_doc_macro
             WHERE dm.id_institution = i_prof.institution
               AND dmp.id_professional = i_prof.id
               AND dm.flg_status IN (g_dcm_flg_status_active, g_dcm_flg_status_disabled)
               AND dmp.flg_status IN (g_dcmp_flg_status_active, g_dcmp_flg_status_disabled);
        END IF;
    
        IF (l_tbl_doc_macro IS NOT NULL AND l_tbl_doc_macro.count > 0)
        THEN
        
            g_error := 'Process support table variable';
            FOR x IN 1 .. l_tbl_doc_macro.count
            LOOP
                l_proc_dm(l_tbl_doc_macro(x)) := l_tbl_doc_macro(x);
            END LOOP;
        
            g_error := 'Fetch and update permissions for for id_doc_macro list: ' ||
                       pk_utils.concat_table(l_tbl_doc_macro);
            FOR r_dm_deps IN c_dm_deps(l_tbl_doc_macro)
            LOOP
                g_error := 'Start compare items';
                IF ((r_dm_deps.id_prof_soft_inst IS NULL OR r_dm_deps.tf_doc_template IS NULL) AND
                   r_dm_deps.dms_status = g_dcms_flg_status_active)
                THEN
                    g_error := 'INSERT HISTORY FOR DOC_MACRO_SOFT';
                    ins_dms_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => r_dm_deps.id_doc_macro_soft);
                
                    g_error    := 'UPDATE DOC_MACRO_SOFT';
                    l_rows_out := table_varchar();
                    ts_doc_macro_soft.upd(id_doc_macro_soft_in => r_dm_deps.id_doc_macro_soft,
                                          flg_status_in        => g_dcms_flg_status_disabled,
                                          rows_out             => l_rows_out);
                
                    l_rows_upd_dcms := l_rows_upd_dcms MULTISET UNION DISTINCT l_rows_out;
                ELSIF (r_dm_deps.id_prof_soft_inst IS NOT NULL AND r_dm_deps.tf_doc_template IS NOT NULL AND
                      r_dm_deps.dms_status = g_dcms_flg_status_disabled)
                THEN
                    g_error := 'INSERT HISTORY FOR DOC_MACRO_SOFT';
                    ins_dms_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => r_dm_deps.id_doc_macro_soft);
                
                    g_error    := 'UPDATE DOC_MACRO_SOFT';
                    l_rows_out := table_varchar();
                    ts_doc_macro_soft.upd(id_doc_macro_soft_in => r_dm_deps.id_doc_macro_soft,
                                          flg_status_in        => g_dcms_flg_status_active,
                                          rows_out             => l_rows_out);
                
                    l_rows_upd_dcms := l_rows_upd_dcms MULTISET UNION DISTINCT l_rows_out;
                END IF;
            
                g_error := 'Start compare items';
                IF (r_dm_deps.id_prof_soft_inst IS NOT NULL AND r_dm_deps.tf_doc_template IS NOT NULL AND
                   r_dm_deps.dm_status = g_dcm_flg_status_disabled AND r_dm_deps.total = 0 AND
                   l_proc_dm.exists(r_dm_deps.id_doc_macro))
                THEN
                    g_error := 'INSERT HISTORY FOR DOC_MACRO';
                    ins_dm_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => r_dm_deps.id_doc_macro);
                
                    g_error    := 'UPDATE DOC_MACRO';
                    l_rows_out := table_varchar();
                    ts_doc_macro.upd(id_doc_macro_in => r_dm_deps.id_doc_macro,
                                     flg_status_in   => g_dcm_flg_status_active,
                                     rows_out        => l_rows_out);
                
                    l_rows_upd_dcm := l_rows_upd_dcm MULTISET UNION DISTINCT l_rows_out;
                
                    g_error := 'REMOVE ID_DOC_MACRO ' || r_dm_deps.id_doc_macro || ' from list to process';
                    l_proc_dm.delete(r_dm_deps.id_doc_macro);
                ELSIF ((r_dm_deps.id_prof_soft_inst IS NULL OR r_dm_deps.tf_doc_template IS NULL) AND
                      r_dm_deps.dm_status = g_dcm_flg_status_active AND r_dm_deps.total = 0 AND
                      l_proc_dm.exists(r_dm_deps.id_doc_macro))
                THEN
                    g_error := 'INSERT HISTORY FOR DOC_MACRO';
                    ins_dm_hist(i_lang => i_lang, i_sysdate => g_sysdate, i_tbl_pk => r_dm_deps.id_doc_macro);
                
                    g_error    := 'UPDATE DOC_MACRO';
                    l_rows_out := table_varchar();
                    ts_doc_macro.upd(id_doc_macro_in => r_dm_deps.id_doc_macro,
                                     flg_status_in   => g_dcm_flg_status_disabled,
                                     rows_out        => l_rows_out);
                
                    l_rows_upd_dcm := l_rows_upd_dcm MULTISET UNION DISTINCT l_rows_out;
                    g_error        := 'REMOVE ID_DOC_MACRO ' || r_dm_deps.id_doc_macro || ' from list to process';
                    l_proc_dm.delete(r_dm_deps.id_doc_macro);
                END IF;
            END LOOP;
        
            g_error := 'CALL PROCESS_UPDATE FOR DOC_MACRO_SOFT';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'DOC_MACRO_SOFT',
                                          i_rowids       => l_rows_upd_dcms,
                                          o_error        => l_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        
            g_error := 'CALL PROCESS_UPDATE FOR DOC_MACRO';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'DOC_MACRO',
                                          i_rowids       => l_rows_upd_dcm,
                                          o_error        => l_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END update_dm_dependencies;

    /*************************************************************************
    * Fetches the id_institution used to create a doc_macro_version          *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    *                                                                        *
    * @return                   doc_macro.id_institution%TYPE                *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  2.6.2.1                                      *
    * @since                    27/03/2012                                   *
    *************************************************************************/
    FUNCTION get_doc_macro_version_instit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_doc_macro_version IN doc_macro_version.id_doc_macro_version%TYPE
    ) RETURN doc_macro.id_institution%TYPE IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_macro_version_instit';
    
        l_instit doc_macro.id_institution%TYPE;
        l_error  t_error_out;
    BEGIN
        g_error := 'Fetch institution for id_doc_macro_version: ' || i_doc_macro_version;
    
        SELECT MAX(id_institution)
          INTO l_instit
          FROM (SELECT dm.id_institution
                  FROM doc_macro dm
                 WHERE dm.id_doc_macro_version = i_doc_macro_version
                UNION
                SELECT dmh.id_institution
                  FROM doc_macro_hist dmh
                 WHERE dmh.id_doc_macro_version = i_doc_macro_version);
    
        RETURN l_instit;
    
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_function_name,
                                                  l_error);
                RAISE;
            END;
    END get_doc_macro_version_instit;

    /********************************************************************************************
     * Get Products that contains areas and templates
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param o_products               List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        1.0
     * @since                          2012/01/19
    **********************************************************************************************/
    PROCEDURE get_doc_products
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_products OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_products';
        l_inst_market market.id_market%TYPE;
    BEGIN
    
        l_inst_market := pk_core.get_inst_mkt(i_prof.institution);
    
        OPEN o_products FOR
            SELECT pk_utils.get_software_name(i_lang => i_lang, i_id_software => s.id_software) desc_product,
                   s.id_software id_product
              FROM prof_soft_inst psi
             INNER JOIN software s
                ON psi.id_software = s.id_software
             WHERE psi.id_professional = i_prof.id
               AND psi.id_institution = i_prof.institution
               AND s.flg_mni = pk_alert_constant.g_yes
               AND EXISTS
             (SELECT 1
                      FROM TABLE(pk_touch_option_core.tf_doc_areas(i_lang                  => i_lang,
                                                                   i_professional          => i_prof.id,
                                                                   i_institution           => i_prof.institution,
                                                                   i_software              => s.id_software,
                                                                   i_inst_market           => l_inst_market,
                                                                   i_check_template_exists => pk_alert_constant.g_no)))
             ORDER BY s.id_software;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_products);
    END get_doc_products;

    /********************************************************************************************
     * Get list of areas with templates for a specified product.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_product                Id of the product to get areas
     * @param o_doc_areas              List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        1.0
     * @since                          2012/01/19
    **********************************************************************************************/
    PROCEDURE get_doc_areas
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_doc_product IN software.id_software%TYPE,
        o_doc_areas   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_areas';
    BEGIN
        OPEN o_doc_areas FOR
            SELECT tda.id_doc_area,
                   pk_summary_page.get_doc_area_name(i_lang     => i_lang,
                                                     i_software => i_doc_product,
                                                     i_doc_area => tda.id_doc_area) desc_doc_area
              FROM TABLE(pk_touch_option_core.tf_doc_areas(i_lang, i_prof.id, i_prof.institution, i_doc_product)) tda
             ORDER BY desc_doc_area;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_doc_areas);
    END get_doc_areas;

    /********************************************************************************************
     * Get list of templates for a specified product and area.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_product                Id of the product to get areas
     * @param i_area                   Id of the area to get templates
     * @param o_doc_templates          List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                         Daniel Ferreira
     * @version                        1.0
     * @since                          2012/01/19
    **********************************************************************************************/
    PROCEDURE get_doc_templates
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_product   IN software.id_software%TYPE,
        i_doc_area      IN doc_area.id_doc_area%TYPE,
        o_doc_templates OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_doc_templates';
    BEGIN
        OPEN o_doc_templates FOR
            SELECT tdt.id_doc_template, pk_translation.get_translation(i_lang, tdt.code_doc_template) desc_doc_template
              FROM TABLE(pk_touch_option_core.tf_doc_templates(i_lang,
                                                               i_prof.id,
                                                               i_prof.institution,
                                                               i_doc_product,
                                                               i_doc_area)) tdt
             ORDER BY desc_doc_template;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            pk_types.open_my_cursor(o_doc_templates);
    END get_doc_templates;

    /*************************************************************************
    * Procedure used to return information for macro detail screen           *
    *                                                                        *
    * @param i_lang             Preferred language ID for this professional  *
    * @param i_prof             Object (professional ID, institution ID,     *
    *                           software ID)                                 *
    * @param i_doc_area         Doc macro identifier                         *
    * @param i_doc_template     Cursor with macro information                *                 
    * @param i_macro_name       Cursor with the doc area info register       *
    * @param o_doc_macro        Cursor with containing the completed info    *
    *                                                                        *
    * @author                   Gustavo Serrano                              *
    * @version                  1.0                                          *
    * @since                    2012/04/03                                   *
    *************************************************************************/
    PROCEDURE check_doc_macro_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_area     IN doc_area.id_doc_area%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE,
        i_macro_name   IN VARCHAR2,
        o_doc_macro    OUT doc_macro.id_doc_macro%TYPE
    ) IS
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_doc_macro_name';
    
        l_error t_error_out;
    BEGIN
        g_error := 'Searching for doc macro names. Profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || '), doc_area = ' || i_doc_area || ', doc_template = ' || i_doc_template ||
                   ', macro_name = ''' || i_macro_name || '';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        SELECT MAX(dm.id_doc_macro) id_doc_macro
          INTO o_doc_macro
          FROM doc_macro dm
         INNER JOIN doc_macro_version dmv
            ON dmv.id_doc_macro_version = dm.id_doc_macro_version
         WHERE dm.id_prof_create = i_prof.id
           AND dm.id_institution = i_prof.institution
           AND dm.flg_status IN (g_dcm_flg_status_active, g_dcm_flg_status_inactive, g_dcm_flg_status_disabled)
           AND dmv.id_doc_area = i_doc_area
           AND dmv.id_doc_template = i_doc_template
           AND dmv.flg_status = g_dcmv_flg_status_active
           AND upper(TRIM(pk_string_utils.clob_to_sqlvarchar2(pk_translation.get_translation_trs(dm.code_doc_macro)))) =
               upper(TRIM(i_macro_name));
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alertlog.log_debug(text            => 'No data found while checking macro name',
                                  object_name     => g_package_name,
                                  sub_object_name => l_function_name);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => l_error);
            RAISE;
    END check_doc_macro_name;

    /**
    *  Migration of a macro to use another template that replaces the one it was originally used.
    *
    * @param    i_lang         Language 
    * @param    i_doc_macro    Macro ID to migrate
    * @param    i_to_template  Template ID which that will be used for the migration of macro
    * @param    o_error        Error information
    *
    * @return  True or False on sucess or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.3
    * @since   1/15/2013 3:49:17 PM
    */
    FUNCTION set_migrate_macro
    (
        i_lang        IN language.id_language%TYPE,
        i_doc_macro   IN doc_macro.id_doc_macro%TYPE,
        i_to_template IN doc_template.id_doc_template%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        k_function_name       CONSTANT VARCHAR2(30 CHAR) := 'set_migrate_macro';
        k_cfg_prof_background CONSTANT sys_config.id_sys_config%TYPE := 'ID_PROF_BACKGROUND';
        e_cannot_migrate EXCEPTION;
        l_action_message    sys_message.desc_message%TYPE;
        l_error_message     sys_message.desc_message%TYPE;
        l_from_template     doc_template.id_doc_template%TYPE;
        l_doc_area          doc_area.id_doc_area%TYPE;
        r_doc_macro         doc_macro%ROWTYPE;
        r_doc_macro_version doc_macro_version%ROWTYPE;
        l_old_dmv           doc_macro_version.id_doc_macro_version%TYPE;
        l_new_dmv           doc_macro_version.id_doc_macro_version%TYPE;
        l_new_dmvd          doc_macro_version_det.id_doc_macro_version_det%TYPE;
    
        l_lst_tmp_rowid   table_varchar;
        l_lst_rowid_dcmvd table_varchar := table_varchar();
        l_lst_rowid_dcmvq table_varchar := table_varchar();
    
        l_can_migrate     VARCHAR2(1 CHAR);
        l_timestamp       TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_prof_bckgrnd professional.id_professional%TYPE;
        l_prof_background profissional;
    
        CURSOR c_dmv_det
        (
            i_old_dmv IN doc_macro_version.id_doc_macro_version%TYPE,
            i_new_dmv IN doc_macro_version.id_doc_macro_version%TYPE
        ) IS
            SELECT dmvd.id_doc_macro_version_det,
                   i_new_dmv                     id_doc_macro_version,
                   de.id_documentation,
                   de.id_doc_element,
                   dtud.id_doc_element_crit_tgt  id_doc_element_crit,
                   dmvd.value,
                   dmvd.value_properties,
                   NULL                          create_user,
                   NULL                          create_time,
                   NULL                          create_institution,
                   NULL                          update_user,
                   NULL                          update_time,
                   NULL                          update_institution
              FROM doc_macro_version dmv
             INNER JOIN doc_macro_version_det dmvd
                ON dmv.id_doc_macro_version = dmvd.id_doc_macro_version
             INNER JOIN doc_template_update_crit dtud
                ON dmv.id_doc_area = dtud.id_doc_area
               AND dmv.id_doc_template = dtud.id_doc_template_source
               AND dmvd.id_doc_element_crit = dtud.id_doc_element_crit_src
             INNER JOIN doc_element_crit decr
                ON dtud.id_doc_element_crit_tgt = decr.id_doc_element_crit
             INNER JOIN doc_element de
                ON decr.id_doc_element = de.id_doc_element
             WHERE dmvd.id_doc_macro_version = i_old_dmv
               AND dtud.id_doc_template_target = i_to_template;
    
        CURSOR c_dmv_qlf(i_old_dmv IN doc_macro_version.id_doc_macro_version%TYPE) IS
            SELECT seq_doc_macro_version_qlf.nextval id_doc_macro_version_qlf,
                   dmvd.id_doc_macro_version_det,
                   dtuq.id_doc_element_qualif_tgt    id_doc_element_qualif,
                   NULL                              create_user,
                   NULL                              create_time,
                   NULL                              create_institution,
                   NULL                              update_user,
                   NULL                              update_time,
                   NULL                              update_institution
              FROM doc_macro_version dmv
             INNER JOIN doc_macro_version_det dmvd
                ON dmv.id_doc_macro_version = dmvd.id_doc_macro_version
             INNER JOIN doc_macro_version_qlf dmvq
                ON dmvd.id_doc_macro_version_det = dmvq.id_doc_macro_version_det
             INNER JOIN doc_template_update_qualif dtuq
                ON dmv.id_doc_area = dtuq.id_doc_area
               AND dmv.id_doc_template = dtuq.id_doc_template_source
               AND dmvd.id_doc_element_crit = dtuq.id_doc_element_crit_src
               AND dmvq.id_doc_element_qualif = dtuq.id_doc_element_qualif_src
             WHERE dmv.id_doc_macro_version = i_old_dmv
               AND dtuq.id_doc_template_target = i_to_template;
    
        --Hashmap using string key in order to support key values of 24 digits. PLS_INTEGER/BINARY_INTEGER only support key values up to 2^31.
        TYPE t_hash IS TABLE OF NUMBER(24) INDEX BY VARCHAR2(24 CHAR);
    
        -- Nested table
        l_lst_dmv_det ts_doc_macro_version_det.doc_macro_version_det_tc;
        l_lst_dmv_qlf ts_doc_macro_version_qlf.doc_macro_version_qlf_tc;
        --Associative array by PK (hash-maps)
        l_hash_dmv_det_key t_hash;
    
    BEGIN
        l_timestamp := current_timestamp;
    
        SELECT dm.*
          INTO r_doc_macro
          FROM doc_macro dm
         WHERE dm.id_doc_macro = i_doc_macro
           AND dm.flg_status IN (pk_doc_macro.g_dcm_flg_status_active, pk_doc_macro.g_dcm_flg_status_pending);
    
        SELECT dmv.*
          INTO r_doc_macro_version
          FROM doc_macro_version dmv
         WHERE dmv.id_doc_macro_version = r_doc_macro.id_doc_macro_version
           AND dmv.flg_status = pk_doc_macro.g_dcmv_flg_status_active;
    
        l_from_template := r_doc_macro_version.id_doc_template;
        l_doc_area      := r_doc_macro_version.id_doc_area;
    
        IF l_from_template = i_to_template
        THEN
            g_error := 'Assertion Failure - Template source and target is the same!';
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
            RAISE e_cannot_migrate;
        END IF;
    
        --Check if this macro has template to migrate
        g_error := 'Verifying the existence of mapping between templates to migrate macro';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_can_migrate
              FROM doc_template_update dtu
             WHERE dtu.id_doc_area = r_doc_macro_version.id_doc_area
               AND dtu.id_doc_template_source = l_from_template
               AND dtu.id_doc_template_target = i_to_template;
        EXCEPTION
            WHEN no_data_found THEN
                l_can_migrate := pk_alert_constant.g_no;
        END;
    
        IF l_can_migrate = pk_alert_constant.g_no
        THEN
            g_error := 'There are no definitions that allow migration between templates' || to_char(l_from_template) ||
                       '(source) and ' || to_char(i_to_template) || '(target) for the area ' || to_char(l_doc_area);
            g_error := g_error || chr(10) || 'The prefilled template ' || to_char(i_doc_macro) ||
                       ' will not be migrated';
        
            pk_alertlog.log_warn(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
            RAISE e_cannot_migrate;
        END IF;
    
        --Professional ID used in background/automatic processess
        g_error := 'Get Professional ID used in background/automatic processes. SYS_CONFIG: ' || k_cfg_prof_background;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        l_id_prof_bckgrnd := to_number(pk_sysconfig.get_config(i_code_cf => k_cfg_prof_background,
                                                               i_prof    => profissional(NULL,
                                                                                         r_doc_macro.id_institution,
                                                                                         NULL)));
    
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_can_migrate
              FROM professional p
             WHERE p.id_professional = l_id_prof_bckgrnd;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'Invalid professional ID configured in SYS_CONFIG: ' || k_cfg_prof_background;
                pk_alertlog.log_error(text            => g_error,
                                      object_name     => g_package_name,
                                      sub_object_name => k_function_name);
                RAISE e_cannot_migrate;
        END;
        l_prof_background := profissional(l_id_prof_bckgrnd, r_doc_macro.id_institution, NULL);
    
        g_error := 'Migrating prefilled template: ' || to_char(i_doc_macro) || ' using migration between templates ' ||
                   to_char(l_from_template) || '(source) and ' || to_char(i_to_template) || '(target) for the area ' ||
                   to_char(l_doc_area);
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        l_old_dmv := r_doc_macro_version.id_doc_macro_version;
        l_new_dmv := ts_doc_macro_version.next_key();
    
        g_error := 'Creating new entry in DOC_MACRO_VERSION: ' || to_char(l_new_dmv);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        r_doc_macro_version.id_doc_macro_version := l_new_dmv;
        r_doc_macro_version.id_professional      := l_prof_background.id;
        r_doc_macro_version.id_prof_last_update  := l_prof_background.id;
        r_doc_macro_version.dt_creation          := l_timestamp;
        r_doc_macro_version.dt_last_update       := l_timestamp;
        r_doc_macro_version.flg_status           := pk_doc_macro.g_dcmv_flg_status_active;
        r_doc_macro_version.flg_edition_type     := pk_doc_macro.g_flg_edition_type_edit;
        r_doc_macro_version.id_doc_template      := i_to_template;
        r_doc_macro_version.id_parent            := l_old_dmv;
    
        ts_doc_macro_version.ins(rec_in => r_doc_macro_version, gen_pky_in => FALSE);
    
        g_error := 'Open cursor C_DMV_DET';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        OPEN c_dmv_det(i_old_dmv => l_old_dmv, i_new_dmv => l_new_dmv);
        LOOP
            FETCH c_dmv_det BULK COLLECT
                INTO l_lst_dmv_det LIMIT 100;
            EXIT WHEN l_lst_dmv_det.count = 0;
        
            -- Update PK of DOC_MACRO_DET entry and saves the new key into a hashmap indexed by old PK value
            FOR i IN l_lst_dmv_det.first .. l_lst_dmv_det.last
            LOOP
                l_new_dmvd := ts_doc_macro_version_det.next_key();
                l_hash_dmv_det_key(to_char(l_lst_dmv_det(i).id_doc_macro_version_det)) := l_new_dmvd;
                l_lst_dmv_det(i).id_doc_macro_version_det := l_new_dmvd;
            END LOOP;
        
            --Saves entries in bulk insert
            ts_doc_macro_version_det.ins(rows_in => l_lst_dmv_det, rows_out => l_lst_tmp_rowid);
        
            -- workaround because insert methods in TS are not appending rowids (as does the upd method)
            l_lst_rowid_dcmvd := l_lst_rowid_dcmvd MULTISET UNION ALL l_lst_tmp_rowid;
        
            g_error := 'Bulk insert in DOC_MACRO_VERSION_DET';
            g_error := g_error || ' Total number of records inserted so far:' || l_lst_rowid_dcmvd.count;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        END LOOP;
        CLOSE c_dmv_det;
    
        g_error := 'Open cursor C_DMV_QLF';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        OPEN c_dmv_qlf(i_old_dmv => l_old_dmv);
        LOOP
            FETCH c_dmv_qlf BULK COLLECT
                INTO l_lst_dmv_qlf LIMIT 100;
            EXIT WHEN l_lst_dmv_qlf.count = 0;
        
            -- Update FK to DOC_MACRO_DET retriving the new key from hashmap
            FOR i IN l_lst_dmv_qlf.first .. l_lst_dmv_qlf.last
            LOOP
                l_lst_dmv_qlf(i).id_doc_macro_version_det := l_hash_dmv_det_key(to_char(l_lst_dmv_qlf(i)
                                                                                        .id_doc_macro_version_det));
            END LOOP;
            --Saves entries in bulk insert
            ts_doc_macro_version_qlf.ins(rows_in => l_lst_dmv_qlf, rows_out => l_lst_tmp_rowid);
        
            -- workaround because insert methods in TS are not appending rowids (as does the upd method)
            l_lst_rowid_dcmvq := l_lst_rowid_dcmvq MULTISET UNION ALL l_lst_tmp_rowid;
        
            g_error := 'Bulk insert in DOC_MACRO_VERSION_QLF';
            g_error := g_error || ' Total number of records inserted so far:' || l_lst_rowid_dcmvq.count;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        END LOOP;
        CLOSE c_dmv_qlf;
    
        g_error := 'INSERT HISTORY FOR DOC_MACRO_SOFT';
        pk_doc_macro.ins_dms_hist(i_lang => i_lang, i_sysdate => l_timestamp, i_tbl_pk => i_doc_macro);
    
        g_error := 'INSERT HISTORY FOR DOC_MACRO_PROF';
        pk_doc_macro.ins_dmp_hist(i_lang => i_lang, i_sysdate => l_timestamp, i_tbl_pk => i_doc_macro);
    
        g_error := 'Add entry to be modified into DOC_MACRO history';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        pk_doc_macro.ins_dm_hist(i_lang => i_lang, i_sysdate => l_timestamp, i_tbl_pk => i_doc_macro);
    
        g_error := 'Updating prefilled template ' || to_char(i_doc_macro) ||
                   ' with new entry created using the target template' || chr(10);
        g_error := g_error || 'Old id_doc_macro_version: ' || to_char(l_old_dmv) || ' - New id_doc_macro_version: ' ||
                   to_char(l_new_dmv);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
    
        ts_doc_macro.upd(id_doc_macro_in         => i_doc_macro,
                         id_doc_macro_version_in => l_new_dmv,
                         flg_status_in           => pk_doc_macro.g_dcm_flg_status_pending, -- "Pending validation"
                         rows_out                => l_lst_tmp_rowid);
    
        g_error := 'Call process_insert for DOC_MACRO_VERSION_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => l_prof_background,
                                      i_table_name => 'DOC_MACRO_VERSION_DET',
                                      i_rowids     => l_lst_rowid_dcmvd,
                                      o_error      => o_error);
    
        g_error := 'Call process_insert for DOC_MACRO_VERSION_QLF';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => l_prof_background,
                                      i_table_name => 'DOC_MACRO_VERSION_QLF',
                                      i_rowids     => l_lst_rowid_dcmvq,
                                      o_error      => o_error);
    
        g_error := 'Call process_update for DOC_MACRO';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => l_prof_background,
                                      i_table_name => 'DOC_MACRO',
                                      i_rowids     => l_lst_tmp_rowid,
                                      o_error      => o_error);
    
        g_error := 'The prefilled template was migrated sucessfully' || chr(10) || chr(10);
        g_error := g_error || 'Summary of operation result' || chr(10);
        g_error := g_error || ' Migrated prefilled template ID: ' || to_char(i_doc_macro) || chr(10);
        g_error := g_error || ' Area: ' || to_char(l_doc_area) || chr(10);
        g_error := g_error || ' Template source: ' || to_char(l_from_template) || chr(10);
        g_error := g_error || ' Template target: ' || to_char(i_to_template) || chr(10);
        g_error := g_error || ' Old id_doc_macro_version: ' || to_char(l_old_dmv) || chr(10);
        g_error := g_error || ' New id_doc_macro_version: ' || to_char(l_new_dmv) || chr(10);
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => k_function_name);
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_cannot_migrate THEN
            l_error_message  := g_error;
            l_action_message := 'Verify the template ID source / target';
        
            pk_alert_exceptions.process_error(i_lang        => i_lang,
                                              i_sqlcode     => SQLCODE,
                                              i_sqlerrm     => l_error_message,
                                              i_message     => l_action_message,
                                              i_owner       => g_package_owner,
                                              i_package     => g_package_name,
                                              i_function    => k_function_name,
                                              i_action_type => 'U',
                                              i_action_msg  => l_action_message,
                                              o_error       => o_error);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_migrate_macro;

    /**
    * Checks if there are macros that its content has changed as consequence of a migration of template originally used.
    * These macros are marked with status "pending validation" so that the professional can validate the migrated content and change their status.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   o_info         Information about the existence of migrated macros
    * @param   o_error        Error information
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.3.2
    * @since   1/24/2013 12:14:00 PM
    */
    PROCEDURE check_migrated_macro
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'check_migrated_macro';
    BEGIN
        g_error := 'Verifing the existence of migrated prefilled templates';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => k_function_name);
        OPEN o_info FOR
            SELECT COUNT(*) pend_status_cnt
              FROM doc_macro dm
             WHERE dm.id_prof_create = i_prof.id
               AND dm.id_institution = i_prof.institution
               AND dm.flg_status = pk_doc_macro.g_dcm_flg_status_pending;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => k_function_name,
                                              o_error    => o_error);
            RAISE;
    END check_migrated_macro;
BEGIN
    -- Initializes log context

    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_doc_macro;
/