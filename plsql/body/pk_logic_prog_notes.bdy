/*-- Last Change Revision: $Rev: 2027330 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_logic_prog_notes IS

    -- Function and procedure implementations
    PROCEDURE set_physician_note
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PHYSICIAN_NOTE';
        l_error t_error_out;
    
        CURSOR c_note IS
            SELECT i_prof.institution id_institution, pn.id_epis_pn, pn.flg_auto_saved
              FROM epis_pn pn
             WHERE pn.id_pn_note_type = pk_prog_notes_constants.g_note_type_prog_note_3
               AND ROWID IN (SELECT column_value /*+opt_estimate(table,t,scale_rows=0.001)*/
                               FROM TABLE(i_rowids) t);
    
        TYPE t_coll_note IS TABLE OF c_note%ROWTYPE;
        l_note_rows t_coll_note;
    BEGIN
    
        -- validate arguments
        g_error := 'CALL T_DATA_GOV_MNT.VALIDATE_ARGUMENTS';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => 'EPIS_PN',
                                                 i_expected_dg_table_name => 'EPIS_PN',
                                                 i_list_columns           => i_list_columns)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        OPEN c_note;
        FETCH c_note BULK COLLECT
            INTO l_note_rows;
        CLOSE c_note;
    
        IF l_note_rows IS NOT NULL
           AND l_note_rows.count > 0
        THEN
            FOR i IN l_note_rows.first .. l_note_rows.last
            LOOP
                --Call IA event only if the note was saved through the OK button
                IF l_note_rows(i).flg_auto_saved = pk_alert_constant.g_no AND i_list_columns.exists(1)
                THEN    
                IF i_event_type = t_data_gov_mnt.g_event_insert
                THEN
                    pk_ia_event_common.physician_note_new(i_id_institution => l_note_rows(i).id_institution,
                                                          i_id_note        => l_note_rows(i).id_epis_pn);
                ELSIF i_event_type = t_data_gov_mnt.g_event_update
                THEN
                    pk_ia_event_common.physician_note_update(i_id_institution => l_note_rows(i).id_institution,
                                                             i_id_note        => l_note_rows(i).id_epis_pn);
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            RAISE;
    END;

BEGIN
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_logic_prog_notes;
/
