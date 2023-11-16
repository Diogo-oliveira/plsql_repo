CREATE OR REPLACE PACKAGE BODY pk_sample_text_ux IS

    PROCEDURE commit_rollback(i_bool IN BOOLEAN) IS
    BEGIN
    
        IF i_bool
        THEN
            COMMIT;
        ELSE
            ROLLBACK;
        END IF;
    
    END commit_rollback;

    --*************************************************
    PROCEDURE inicialize IS
        k_package VARCHAR2(0100 CHAR) := 'PK_SAMPLE_TEXT_UX';
        k_owner   VARCHAR2(0100 CHAR) := 'ALERT';
    BEGIN
    
        pk_alertlog.who_am_i(owner => k_owner, name => k_package);
    
        pk_alertlog.log_init(object_name => k_package);
    
    END inicialize;

    --*************************************************
    FUNCTION set_sample_text_prof
    (
        i_lang             IN NUMBER,
        i_id_sample_text   IN NUMBER,
        i_sample_text_type IN NUMBER,
        i_prof             IN profissional,
        i_title            IN VARCHAR2,
        i_text             IN VARCHAR2,
        i_rank             IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_sample_text.set_sample_text_prof(i_lang             => i_lang,
                                                      i_id_sample_text   => i_id_sample_text,
                                                      i_sample_text_type => i_sample_text_type,
                                                      i_prof             => i_prof,
                                                      i_title            => i_title,
                                                      i_text             => i_text,
                                                      i_rank             => i_rank,
                                                      o_error            => o_error);
    
        commit_rollback(l_bool);
    
        RETURN l_bool;
    
    END set_sample_text_prof;

    --*******************************************
    FUNCTION cancel_sample_text_prof
    (
        i_lang        IN NUMBER,
        i_sample_text IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_bool BOOLEAN;
    BEGIN
    
        l_bool := pk_sample_text.cancel_sample_text_prof(i_lang        => i_lang,
                                                         i_sample_text => i_sample_text,
                                                         o_error       => o_error);
    
        commit_rollback(l_bool);
    
        RETURN l_bool;
    
    END cancel_sample_text_prof;

    --*******************************************
    FUNCTION get_sample_text_type_list
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_list.get_sample_text_type_list(i_lang  => i_lang,
                                                 i_prof  => i_prof,
                                                 o_list  => o_list,
                                                 o_error => o_error);
    
    END get_sample_text_type_list;

    FUNCTION save_dyn_sample_text
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_sample_text_prof     IN sample_text_prof.id_sample_text_prof%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_real_val             IN table_table_varchar,
        i_value                IN table_table_varchar,
        i_value_clob           IN table_table_clob,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_id_ds_component    NUMBER;
        l_sample_text_type   NUMBER;
        l_title              VARCHAR2(4000);
        l_text               CLOB;
        l_id_stext_type_prof NUMBER;
        l_bool               BOOLEAN;
    
        -------------------------------
        FUNCTION get_comp_by_cmpt(i_id_mkt_rel IN NUMBER) RETURN VARCHAR2 IS
            tbl_id   table_varchar;
            l_return VARCHAR2(4000);
        BEGIN
        
            SELECT internal_name_child
              BULK COLLECT
              INTO tbl_id
              FROM v_ds_cmpt_mkt_rel
             WHERE id_ds_cmpt_mkt_rel = i_id_mkt_rel;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
            RETURN l_return;
        
        END get_comp_by_cmpt;
    
        ------------------------------------
        PROCEDURE map_dyn_to_fields IS
        BEGIN
        
            <<lup_thru_comp>>
            FOR i IN 1 .. i_tbl_ds_internal_name.count
            LOOP
            
                --    l_id_ds_component := get_comp_by_cmpt(i_id_mkt_rel => i_tbl_mkt_rel(i));
            
                CASE i_tbl_ds_internal_name(i)
                    WHEN 'DS_STEXT_AREA' THEN
                        l_sample_text_type := to_number(i_real_val(i) (1));
                    WHEN 'DS_STEXT_DESC' THEN
                        l_title := i_value(i) (1);
                    WHEN 'DS_STEXT_TEXT' THEN
                        l_text := i_value_clob(i) (1);
                    WHEN 'DS_STEXT_ID_PROF' THEN
                        l_id_stext_type_prof := to_number(i_real_val(i) (1));
                    ELSE
                        NULL;
                END CASE;
            
            END LOOP lup_thru_comp;
        
            l_id_stext_type_prof := i_sample_text_prof;
        
        END map_dyn_to_fields;
    
    BEGIN
    
        map_dyn_to_fields();
    
        l_bool := pk_sample_text.set_sample_text_prof(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_id_sample_text   => l_id_stext_type_prof,
                                                      i_sample_text_type => l_sample_text_type,
                                                      i_title            => l_title,
                                                      i_text             => l_text,
                                                      i_rank             => 0,
                                                      o_error            => o_error);
    
        commit_rollback(l_bool);
    
        RETURN l_bool;
    
    END save_dyn_sample_text;

BEGIN

    inicialize();

END pk_sample_text_ux;
