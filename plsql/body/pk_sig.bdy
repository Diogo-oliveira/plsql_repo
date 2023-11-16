CREATE OR REPLACE PACKAGE BODY pk_sig IS

    k_yes     CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    k_no      CONSTANT VARCHAR2(0010 CHAR) := 'N';
    k_package CONSTANT VARCHAR2(0200 CHAR) := 'PK_SIG';
    k_owner   CONSTANT VARCHAR2(0200 CHAR) := 'ALERT';

    k_sig_digital    CONSTANT VARCHAR2(0010 CHAR) := 'D';
    k_sig_electronic CONSTANT VARCHAR2(0010 CHAR) := 'E';

    k_flg_status_active CONSTANT VARCHAR2(0010 CHAR) := 'A';
    k_flg_status_cancel CONSTANT VARCHAR2(0010 CHAR) := 'C';

    k_sig_dml_mode_ins CONSTANT VARCHAR2(0050 CHAR) := 'INSERT';
    k_sig_dml_mode_upd CONSTANT VARCHAR2(0050 CHAR) := 'UPDATE';
    k_cud_insert       CONSTANT VARCHAR2(0001 CHAR) := 'C';
    k_cud_update       CONSTANT VARCHAR2(0001 CHAR) := 'U';
    --k_cud_delete CONSTANT VARCHAR2(0001 CHAR) := 'D';

    --***********************************
    FUNCTION count_prof_signatures(i_prof_id IN NUMBER) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM prof_signature ps
         WHERE ps.id_professional = i_prof_id
           AND ps.flg_status != k_flg_status_cancel;
    
        RETURN l_count;
    
    END count_prof_signatures;

    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    END iif;

    FUNCTION get_desc_speciality
    (
        i_lang IN NUMBER,
        i_id   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return   VARCHAR2(4000);
        tbl_return table_varchar;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, s.code_speciality) desc_speciality
          BULK COLLECT
          INTO tbl_return
          FROM prof_specialities ps
          JOIN speciality s
            ON s.id_speciality = ps.id_speciality
         WHERE ps.id_prof_specialities = i_id;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_desc_speciality;

    FUNCTION get_mkt_rel(i_id IN NUMBER) RETURN v_ds_cmpt_mkt_rel%ROWTYPE IS
        l_row v_ds_cmpt_mkt_rel%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO l_row
          FROM v_ds_cmpt_mkt_rel
         WHERE id_ds_cmpt_mkt_rel = i_id;
    
        RETURN l_row;
    
    END get_mkt_rel;

    --function get_address( i_lang in number, i_prof in profissional, i_professional in number )
    FUNCTION get_address(i_professional IN NUMBER) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_sep CONSTANT VARCHAR2(0010 CHAR) := chr(32) || '|' || chr(32);
    
        l_row professional%ROWTYPE;
    
        PROCEDURE get_prof_info IS
        BEGIN
            SELECT *
              INTO l_row
              FROM professional
             WHERE id_professional = i_professional;
        END get_prof_info;
    
        PROCEDURE push_value(i_str IN VARCHAR2) IS
        BEGIN
            IF l_return IS NULL
            THEN
                l_return := i_str;
            ELSE
                l_return := l_return || k_sep || i_str;
            END IF;
        END push_value;
    
    BEGIN
    
        get_prof_info();
    
        push_value(l_row.address);
        push_value(l_row.city);
        push_value(l_row.district);
        push_value(l_row.zip_code);
        push_value(l_row.num_contact);
        push_value(l_row.work_phone);
        push_value(l_row.email);
    
        RETURN l_return;
    
    END get_address;

    --*******************************************************
    PROCEDURE get_prof_sigs_base
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        o_result   OUT pk_types.cursor_type
    ) IS
    BEGIN
    
        OPEN o_result FOR
            SELECT ps.id_signature,
                   ps.sig_name,
                   ps.sig_image,
                   ps.flg_type,
                   CASE
                        WHEN pas.id_signature IS NULL THEN
                         'N'
                        ELSE
                         'Y'
                    END flg_active,
                   pk_prof_utils.get_name_signature(i_lang => i_lang, i_prof => i_prof, i_prof_id => ps.id_professional) prof_name,
                   p.num_order
                   --,pk_sig.get_address( i_lang, i_prof, ps.id_professional ) prof_address
                  ,
                   pk_sig.get_address(ps.id_professional) prof_address
              FROM prof_signature ps
              LEFT JOIN prof_active_signature pas
                ON pas.id_professional = ps.id_professional
              JOIN professional p
                ON p.id_professional = ps.id_professional
             WHERE ps.flg_type = i_flg_type
             ORDER BY ps.flg_type, ps.dt_creation DESC;
    
    END get_prof_sigs_base;

    --*******************************************************
    PROCEDURE get_prof_sigs_digital
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        o_result OUT pk_types.cursor_type
    ) IS
    BEGIN
    
        get_prof_sigs_base(i_lang, i_prof, k_sig_digital, o_result);
    
    END get_prof_sigs_digital;

    --*******************************************************
    PROCEDURE get_prof_sigs_electronic
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        o_result OUT pk_types.cursor_type
    ) IS
    BEGIN
    
        get_prof_sigs_base(i_lang, i_prof, k_sig_electronic, o_result);
    
    END get_prof_sigs_electronic;

    --*******************************************************
    PROCEDURE get_prof_sigs_list
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        o_digital    OUT pk_types.cursor_type,
        o_electronic OUT pk_types.cursor_type
    ) IS
    BEGIN
        get_prof_sigs_base(i_lang, i_prof, k_sig_digital, o_digital);
    
        get_prof_sigs_base(i_lang, i_prof, k_sig_electronic, o_electronic);
    
    END get_prof_sigs_list;

    PROCEDURE upd_prof_sig_base
    (
        i_prof     IN profissional,
        i_flg_type IN VARCHAR2,
        i_id_prof  IN NUMBER,
        i_id_sig   IN NUMBER,
        i_name     IN VARCHAR2,
        i_image    IN BLOB
    ) IS
        l_row prof_signature%ROWTYPE;
    BEGIN
    
        l_row.id_professional  := i_id_prof;
        l_row.id_signature     := i_id_sig;
        l_row.flg_type         := i_flg_type;
        l_row.dt_creation      := current_timestamp;
        l_row.id_prof_creation := i_prof.id;
        l_row.sig_name         := i_name;
        l_row.sig_image        := i_image;
    
        pk_sig_cfg.upd_prof_sig(i_row => l_row);
    
    END upd_prof_sig_base;

    -- ****************************
    PROCEDURE upd_sig_electronic
    (
        i_prof    IN profissional,
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER,
        i_name    IN VARCHAR2,
        i_image   IN BLOB
    ) IS
    BEGIN
    
        upd_prof_sig_base(i_prof     => i_prof,
                          i_id_prof  => i_id_prof,
                          i_id_sig   => i_id_sig,
                          i_flg_type => k_sig_electronic,
                          i_name     => i_name,
                          i_image    => i_image);
    
    END upd_sig_electronic;

    PROCEDURE upd_sig_digital
    (
        i_prof    IN profissional,
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER,
        i_name    IN VARCHAR2,
        i_image   IN BLOB
    ) IS
    BEGIN
    
        upd_prof_sig_base(i_prof     => i_prof,
                          i_id_prof  => i_id_prof,
                          i_id_sig   => i_id_sig,
                          i_flg_type => k_sig_digital,
                          i_name     => i_name,
                          i_image    => i_image);
    
    END upd_sig_digital;

    --***********************************
    PROCEDURE set_active_sig
    (
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER
    ) IS
    BEGIN
    
        --pk_sig_cfg.ins_active_sig(i_id_prof, i_id_sig);
        set_preferential(i_id_prof => i_id_prof, i_id_sig => i_id_sig, i_flg_hist => k_yes);
    
    END set_active_sig;

    FUNCTION check_if_active_exist(i_id_prof IN NUMBER) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM prof_signature
         WHERE id_professional = i_id_prof;
    
        RETURN l_count;
    
    END check_if_active_exist;


    PROCEDURE init_par_sig
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        --k_pos_episode      CONSTANT NUMBER(24) := 5;
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
        --l_msg               VARCHAR2(4000);
        --l_id_episode        NUMBER := -9999999;
        l_time VARCHAR2(1000 CHAR);
        --l_id_sys_alert_type NUMBER;
    
    BEGIN
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_software' THEN
                o_id := l_prof.software;
            WHEN 'msg_not_applicable' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'N/A');
            WHEN 'l_today' THEN
                l_time := to_char(current_timestamp, 'YYYYMMDD') || '000000';
                o_tstz := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                        i_prof      => l_prof,
                                                        i_timestamp => l_time,
                                                        i_timezone  => NULL);
            ELSE
                NULL;
        END CASE;
    
    END init_par_sig;

    --********************************************
    FUNCTION get_prof_cat
    (
        i_id_prof        IN NUMBER,
        i_id_institution IN NUMBER
    ) RETURN NUMBER IS
        l_return   NUMBER;
        tbl_return table_number;
    BEGIN
    
        SELECT id_category
          BULK COLLECT
          INTO tbl_return
          FROM prof_cat
         WHERE id_professional = i_id_prof
           AND id_institution = i_id_institution;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_prof_cat;

    FUNCTION get_sig_edit_values
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_id_sig    IN NUMBER,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_ds_get_value IS
        tbl_result       t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_temp         t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_tree_configs t_dyn_tree_table;
    
        --l_id_category NUMBER;
        --k_code_cat CONSTANT VARCHAR2(0200 CHAR) := 'CATEGORY.CODE_CATEGORY.';
        --l_desc_category VARCHAR2(4000);
        l_value      VARCHAR2(4000);
        l_desc_value VARCHAR2(4000);
        l_lob        CLOB;
    
        CURSOR xsig_c IS
            SELECT t.dt_creation,
                   t.sig_name,
                   CASE
                        WHEN t.id_signature_pas IS NULL THEN
                         'N'
                        ELSE
                         'Y'
                    END flg_active,
                   t.flg_type,
                   pk_sysdomain.get_domain(i_code_dom => 'PROF_SIGNATURE.FLG_TYPE_ABBREV',
                                           i_val      => t.flg_type,
                                           i_lang     => i_lang) flg_type_abbrev,
                   t.id_professional,
                   t.id_signature,
                   t.num_order,
                   pk_sig.get_address(t.id_professional) prof_address,
                   t.sig_prof_name,
                   t.sig_filename,
                   t.sig_obs,
                   t.sig_order_type,
                   t.sig_order_nr,
                   t.sig_address
              FROM v_digital_sig t
             WHERE t.id_signature = i_id_sig
               AND t.id_professional = i_prof.id;
    
        TYPE type_sig IS TABLE OF xsig_c%ROWTYPE;
        tbl_data type_sig;
    
        --------------------------
        PROCEDURE get_sig_data IS
        BEGIN
        
            OPEN xsig_c;
            FETCH xsig_c BULK COLLECT
                INTO tbl_data;
            CLOSE xsig_c;
        
        END get_sig_data;
    
    BEGIN
    
        -- ge components
        tbl_tree_configs := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_patient        => NULL,
                                                    i_component_name => i_root_name,
                                                    i_action         => NULL);
        -- get info                     
        get_sig_data();
    
        <<lup_thru_data>>
        FOR i IN 1 .. tbl_data.count
        LOOP
        
            <<lup_thru_elements>>
            FOR j IN 1 .. tbl_tree_configs.count
            LOOP
            
                l_desc_value := NULL;
                CASE tbl_tree_configs(j).internal_name_child
                    WHEN 'DS_SIG_NAME' THEN
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        l_desc_value := tbl_data(i).sig_name;
                        l_value      := NULL;
                        l_lob        := NULL;
                    WHEN 'DS_SIG_USER_NAME' THEN
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        l_desc_value := tbl_data(i).sig_prof_name;
                        l_value      := NULL;
                        l_lob        := NULL;
                    WHEN 'DS_SIG_ORDER_TYPE' THEN
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        --l_value      := tbl_data(i).sig_order_type;
                        l_desc_value := get_order_type_desc(i_lang => i_lang, i_id => tbl_data(i).sig_order_type);
                        l_value      := tbl_data(i).sig_order_type;
                        l_lob        := NULL;
                    WHEN 'DS_SIG_ORDER_NUM' THEN
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        --l_value      := tbl_data(i).sig_order_nr;
                        l_desc_value := tbl_data(i).sig_order_nr;
                        l_value      := NULL;
                        l_lob        := NULL;
                    WHEN 'DS_SIG_USER_ADDRESS' THEN
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        --l_value      := tbl_data(i).sig_address;
                        l_desc_value := tbl_data(i).sig_address;
                        l_value      := NULL;
                        l_lob        := NULL;
                    WHEN 'DS_SIG_OBS' THEN
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        l_desc_value := NULL;
                        l_value      := tbl_data(i).sig_obs;
                        l_lob        := NULL;
                    WHEN 'DS_SIG_TYPE' THEN
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        l_desc_value := pk_sysdomain.get_domain(i_code_dom => 'PROF_SIGNATURE.FLG_TYPE_ABBREV',
                                                                i_val      => tbl_data(i).flg_type,
                                                                i_lang     => i_lang);
                        l_value      := tbl_data(i).flg_type;
                        l_lob        := NULL;
                    WHEN 'DS_SIG_PREFERENCIAL' THEN
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        --l_value      := tbl_data(i).flg_active;
                        --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                        l_desc_value := pk_sysdomain.get_domain(i_code_dom => 'YES_NO',
                                                                i_val      => tbl_data(i).flg_active,
                                                                i_lang     => i_lang);
                        l_value      := tbl_data(i).flg_active;
                        l_lob        := NULL;
                    ELSE
                        l_desc_value := NULL;
                        l_value      := NULL;
                        l_lob        := NULL;
                    
                END CASE;
            
                --tbl_result(l_count).id_ds_cmpt_mkt_rel := tbl_tree_configs(j).id_ds_cmpt_mkt_rel;
            
                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => tbl_tree_configs(j).id_ds_cmpt_mkt_rel,
                                          id_ds_component    => tbl_tree_configs(j).id_ds_component_child,
                                          internal_name      => tbl_tree_configs(j).internal_name_child,
                                          VALUE              => l_value,
                                          min_value          => NULL,
                                          max_value          => NULL,
                                          desc_value         => l_desc_value,
                                          desc_clob          => NULL,
                                          value_clob         => l_lob,
                                          id_unit_measure    => NULL,
                                          desc_unit_measure  => NULL,
                                          flg_validation     => 'Y',
                                          err_msg            => NULL,
                                          flg_event_type     => 'NA',
                                          flg_multi_status   => NULL,
                                          idx                => 1)
                  BULK COLLECT
                  INTO tbl_temp
                  FROM dual;
            
                tbl_result := tbl_result MULTISET UNION ALL tbl_temp;
            
            END LOOP lup_thru_elements;
        
        END LOOP lup_thru_data;
    
        RETURN tbl_result;
    
    END get_sig_edit_values;

    --********************************************
    FUNCTION get_sig_info
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --i_episode        IN episode.id_episode%TYPE,
        --i_patient        IN patient.id_patient%TYPE,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        l_error VARCHAR2(1000 CHAR);
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        k_action_edit   CONSTANT NUMBER := 235534425; --235534419;
        k_action_add  CONSTANT NUMBER := 235534421;
        k_action_submit CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
        l_action NUMBER;
        --l_flg varchar2(1);
    BEGIN
        --l_flg := 'carlos';
        l_action := nvl(i_action, k_action_add);
    
        CASE l_action
            WHEN k_action_edit THEN
                l_error    := 'get_edit_values';
                tbl_result := get_sig_edit_values(i_lang, i_prof, i_tbl_id_pk(1), i_root_name);
            WHEN k_action_add THEN
                l_error    := 'get_add_values';
                tbl_result := get_sig_add_values(i_lang, i_prof, i_root_name);
            WHEN k_action_submit THEN
                tbl_result := get_sig_submit_values(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_root_name      => i_root_name,
                                                    i_curr_component => i_curr_component,
                                                    i_tbl_id_pk      => i_tbl_id_pk,
                                                    i_tbl_mkt_rel    => i_tbl_mkt_rel,
                                                    i_tbl_int_name   => i_tbl_int_name,
                                                    i_value          => i_value,
                                                    o_error          => o_error);
            ELSE
                NULL;
        END CASE;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              'ALERT',
                                              'PK_SIG',
                                              'GET_SIG_INFO',
                                              o_error);
            RETURN NULL;
    END get_sig_info;

    FUNCTION get_main_prof_specialties(i_prof_id IN NUMBER) RETURN NUMBER IS
        l_return NUMBER;
        tbl_id   table_number;
    BEGIN
    
        SELECT x.id_prof_specialities
          BULK COLLECT
          INTO tbl_id
          FROM prof_specialities x
         WHERE x.id_professional = i_prof_id
           AND x.speciality_main = k_yes;
    
        IF tbl_id.count > 0
        THEN
        
            l_return := tbl_id(1);
        
        END IF;
    
        RETURN l_return;
    
    END get_main_prof_specialties;

    FUNCTION get_prof_info_base
    (
        i_prof_id IN NUMBER,
        i_mode    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        xrow     professional%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO xrow
          FROM professional
         WHERE id_professional = i_prof_id;
    
        CASE i_mode
            WHEN 'NUM_ORDER' THEN
                l_return := xrow.num_order;
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    END get_prof_info_base;

    FUNCTION get_prof_num_order(i_prof_id IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN get_prof_info_base(i_prof_id, 'NUM_ORDER');
    END get_prof_num_order;

    --**********************************
    FUNCTION get_order_type_desc
    (
        i_lang IN NUMBER,
        i_id   IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_return table_varchar;
        l_return   VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, s.code_speciality) xdesc
          BULK COLLECT
          INTO tbl_return
          FROM prof_specialities ps
          JOIN speciality s
            ON s.id_speciality = ps.id_speciality
         WHERE ps.id_prof_specialities = i_id;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_order_type_desc;

    FUNCTION get_sig_add_values
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_ds_get_value IS
        tbl_result       t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_temp         t_tbl_ds_get_value := t_tbl_ds_get_value();
        tbl_tree_configs t_dyn_tree_table;
    
        l_id_category NUMBER;
        --k_code_cat CONSTANT VARCHAR2(0200 CHAR) := 'CATEGORY.CODE_CATEGORY.';
        l_desc_category VARCHAR2(4000);
        l_value         VARCHAR2(4000);
        l_desc_value    VARCHAR2(4000);
        l_lob           CLOB;
        l_flag          VARCHAR2(0010 CHAR);
        k_lf CONSTANT VARCHAR2(0010 CHAR) := chr(32);
    
        FUNCTION count_signature RETURN NUMBER IS
            l_count NUMBER;
        BEGIN
        
            SELECT COUNT(*)
              INTO l_count
              FROM prof_signature
             WHERE flg_status != 'C';
        
            RETURN(l_count + 1);
        
        END count_signature;
    
        --***************************************
        FUNCTION l_get_order_type RETURN NUMBER IS
            --t_list         t_tbl_core_domain := t_tbl_core_domain();
            l_id_prof_spec VARCHAR2(4000);
        BEGIN
        
            --t_list := get_sig_order_list(i_lang => i_lang, i_prof => i_prof);
        
            -- 1: first get main one
            l_id_prof_spec := get_main_prof_specialties(i_prof_id => i_prof.id);
        
            RETURN l_id_prof_spec;
        
        END l_get_order_type;
    
    BEGIN
    
        -- ge components
        tbl_tree_configs := pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_patient        => NULL,
                                                    i_component_name => i_root_name,
                                                    i_action         => NULL);
    
        <<lup_thru_elements>>
        FOR j IN 1 .. tbl_tree_configs.count
        LOOP
        
            l_desc_value := NULL;
            CASE tbl_tree_configs(j).internal_name_child
                WHEN 'DS_SIG_NAME' THEN
                    --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                    l_desc_value := pk_message.get_message(i_lang, 'SIG_NAME_PLACEHOLDER') || k_lf || count_signature();
                    l_value      := NULL;
                    l_lob        := NULL;
                WHEN 'DS_SIG_USER_NAME' THEN
                    --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                    l_desc_value := pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_prof_id => i_prof.id);
                    l_value      := NULL;
                    l_lob        := NULL;
                WHEN 'DS_SIG_ORDER_TYPE' THEN
                    l_id_category := l_get_order_type();
                    IF l_id_category IS NOT NULL
                    THEN
                        l_desc_category := get_order_type_desc(i_lang => i_lang, i_id => l_id_category);
                    END IF;
                    l_desc_value := l_desc_category;
                    l_value      := l_id_category;
                    l_lob           := NULL;
                WHEN 'DS_SIG_ORDER_NUM' THEN
                    --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                    --l_value      := get_prof_num_order(i_prof.id);
                    l_desc_value := get_prof_num_order(i_prof.id);
                    l_value      := NULL;
                    l_lob        := NULL;
                WHEN 'DS_SIG_USER_ADDRESS' THEN
                    --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                    --l_value      := get_address(i_prof.id);
                    l_desc_value := get_address(i_prof.id);
                    l_value      := NULL;
                    l_lob        := NULL;
                WHEN 'DS_SIG_OBS' THEN
                    --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                    --l_value      := NULL;
                    l_desc_value := NULL;
                    l_value      := NULL;
                    l_lob        := NULL;
                WHEN 'DS_SIG_PREFERENCIAL' THEN
                    --l_desc_value := pk_message.get_message(i_lang, tbl_tree_configs(j).code_component_child);
                    IF count_prof_signatures(i_prof_id => i_prof.id) = 0
                    THEN
                        l_flag := k_yes;
                    ELSE
                        l_flag := k_no;
                    END IF;
                    l_desc_value := pk_sysdomain.get_domain(i_code_dom => 'YES_NO', i_val => l_flag, i_lang => i_lang);
                    l_value      := l_flag;
                    l_lob        := NULL;
                ELSE
                    l_desc_value := NULL;
                    l_value      := NULL;
                    l_lob        := NULL;
                
            END CASE;
        
            --tbl_result(l_count).id_ds_cmpt_mkt_rel := tbl_tree_configs(j).id_ds_cmpt_mkt_rel;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => tbl_tree_configs(j).id_ds_cmpt_mkt_rel,
                                      id_ds_component    => tbl_tree_configs(j).id_ds_component_child,
                                      internal_name      => tbl_tree_configs(j).internal_name_child,
                                      VALUE              => l_value,
                                      min_value          => NULL,
                                      max_value          => NULL,
                                      desc_value         => l_desc_value,
                                      desc_clob          => NULL,
                                      value_clob         => l_lob,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => 'Y',
                                      err_msg            => NULL,
                                      flg_event_type     => 'NA',
                                      flg_multi_status   => NULL,
                                      idx                => 1)
              BULK COLLECT
              INTO tbl_temp
              FROM dual;
        
            tbl_result := tbl_result MULTISET UNION ALL tbl_temp;
        
        END LOOP lup_thru_elements;
    
        RETURN tbl_result;
    
    END get_sig_add_values;

    --***************************
    FUNCTION get_internal_name_childs(i_tbl_mkt_rel IN table_number) RETURN table_varchar IS
        l_ret table_varchar;
    BEGIN
        SELECT dcm.internal_name_child
          BULK COLLECT
          INTO l_ret
          FROM v_ds_cmpt_mkt_rel dcm
          JOIN (SELECT /*+ opt_estimate(table dc rows=1)  */
                 rownum rn, column_value id
                  FROM TABLE(i_tbl_mkt_rel) dc) tmr
            ON tmr.id = dcm.id_ds_cmpt_mkt_rel
         WHERE dcm.flg_component_type_child NOT IN ('R', 'N')
        -- dont include toggle for translation
         ORDER BY tmr.rn;
    
        RETURN l_ret;
    
    END get_internal_name_childs;

    --***************************
    FUNCTION save_sig
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_epis_sig    IN NUMBER,
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_table_varchar,
        i_image       IN BLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_ret BOOLEAN := FALSE;
        --l_internal_names table_varchar;
        --l_id_types       table_number;
        --l_bool BOOLEAN;
        e_wrong_args_exception EXCEPTION;
        l_mode VARCHAR2(0050 CHAR);
        --l_func_name VARCHAR2(1000) := 'SAVE_SIG';
    BEGIN
    
        IF i_epis_sig IS NULL
        THEN
            l_mode := k_sig_dml_mode_ins;
        ELSE
            l_mode := k_sig_dml_mode_upd;
        END IF;
    
        save_sig_base(i_lang => i_lang,
                      i_prof => i_prof,
                      --i_id_episode    => i_id_episode,
                      --i_id_patient    => i_id_patient,
                      i_mode        => l_mode,
                      i_epis_sig    => i_epis_sig,
                      i_tbl_mkt_rel => i_tbl_mkt_rel,
                      i_value       => i_value,
                      i_image       => i_image);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang, SQLCODE, SQLERRM, '', k_owner, k_package, 'SAVE_SIG', o_error);
            RETURN FALSE;
    END save_sig;

    PROCEDURE set_preferential
    (
        i_id_prof  IN NUMBER,
        i_id_sig   IN NUMBER,
        i_flg_hist IN VARCHAR2
    ) IS
        l_old_sig prof_signature%ROWTYPE;
        l_new_sig prof_signature%ROWTYPE;
        l_act_sig prof_active_signature%ROWTYPE;
    BEGIN
    
        -- get basic info
        l_act_sig := pk_sig_cfg.get_active_signature(i_id_prof);
        l_old_sig := pk_sig_cfg.get_prof_signature(i_id_prof, l_act_sig.id_signature);
        l_new_sig := pk_sig_cfg.get_prof_signature(i_id_prof, i_id_sig);
    
        -- clean data
        pk_sig_cfg.del_active_sig(i_id_prof);
    
        -- insert new preferential sig
        pk_sig_cfg.ins_active_prof_sig(l_new_sig);
    
        -- do journaling if requested
        IF i_flg_hist = k_yes
        THEN
        
            -- save new
            pk_sig_cfg.set_history(k_cud_update, l_new_sig);
        
        END IF;
    
        -- sig is not the same, save old sig to show loss of preferential
        IF l_new_sig.id_signature != l_old_sig.id_signature
        THEN
            pk_sig_cfg.set_history(k_cud_update, l_old_sig);
        END IF;
    
    END set_preferential;

    PROCEDURE save_sig_base
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_mode        IN VARCHAR2,
        i_epis_sig    IN NUMBER,
        i_tbl_mkt_rel IN table_number,
        i_value       IN table_table_varchar,
        i_image       IN BLOB
    ) IS
        l_row        prof_signature%ROWTYPE;
        l_flg_save   BOOLEAN;
        l_id         NUMBER;
        l_flg_active VARCHAR2(0010 CHAR);
        l_comp_name  VARCHAR2(0200 CHAR);
        l_rel        v_ds_cmpt_mkt_rel%ROWTYPE;
        l_cud        VARCHAR2(0010 CHAR);
    BEGIN
    
        <<lup_thru_components>>
        FOR i IN 1 .. i_tbl_mkt_rel.count
        LOOP
        
            l_flg_save := TRUE;
        
            l_rel := get_mkt_rel(i_tbl_mkt_rel(i));
        
            l_comp_name := l_rel.internal_name_child;
        
            CASE l_comp_name
                WHEN 'DS_SIG_NAME' THEN
                    l_row.sig_name := i_value(i) (1);
                WHEN 'DS_SIG_USER_NAME' THEN
                    l_row.sig_prof_name := i_value(i) (1);
                WHEN 'DS_SIG_TYPE' THEN
                    l_row.flg_type := i_value(i) (1);
                WHEN 'DS_SIG_PREFERENCIAL' THEN
                    l_flg_active := i_value(i) (1);
                WHEN 'DS_SIG_FILE_NAME' THEN
                    l_row.sig_filename := i_value(i) (1);
                WHEN 'DS_SIG_OBS' THEN
                    l_row.sig_obs := i_value(i) (1);
                WHEN 'DS_SIG_ORDER_TYPE' THEN
                    l_row.sig_order_type := i_value(i) (1);
                WHEN 'DS_SIG_ORDER_NUM' THEN
                    l_row.sig_order_nr := i_value(i) (1);
                WHEN 'DS_SIG_USER_ADDRESS' THEN
                    l_row.sig_address := i_value(i) (1);
                ELSE
                    NULL;
            END CASE;
        
        END LOOP lup_thru_components;
    
        l_row.id_signature     := i_epis_sig;
        l_row.id_professional  := i_prof.id;
        l_row.dt_creation      := current_timestamp;
        l_row.id_prof_creation := i_prof.id;
        l_row.sig_image        := i_image;
        l_row.flg_status       := k_flg_status_active;
    
        IF i_mode = k_sig_dml_mode_ins
        THEN
            pk_sig_cfg.ins_prof_sig(l_row, l_id);
            l_row.id_signature := l_id;
            l_cud              := k_cud_insert;
        ELSE
            pk_sig_cfg.upd_prof_sig(l_row);
            l_id := i_epis_sig;
            l_cud := k_cud_update;
        END IF;
    
        IF l_flg_active = k_yes
        THEN
            set_preferential(i_id_prof => i_prof.id, i_id_sig => l_id, i_flg_hist => k_no);
        END IF;
    
        pk_sig_cfg.set_history(l_cud, l_row);
    
    END save_sig_base;

    FUNCTION cancel_signature
    (
        i_lang     IN NUMBER,
        i_prof             IN profissional,
        i_epis_sig IN table_number,
        i_id_cancel_reason IN NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        <<lup_thru_sig_selected>>
        FOR i IN 1 .. i_epis_sig.count
        LOOP
            pk_sig_cfg.cancel_signature(i_prof.id, i_epis_sig(i), i_id_cancel_reason);
        END LOOP lup_thru_sig_selected;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              k_owner,
                                              k_package,
                                              'CANCEL_SIGNATURE',
                                              o_error);
            RETURN FALSE;
        
    END cancel_signature;

    FUNCTION check_if_sig_preferential
    (
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER
    ) RETURN VARCHAR2 IS
        l_count  NUMBER;
        l_return VARCHAR2(0010 CHAR);
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM prof_active_signature
         WHERE id_signature = i_id_sig
           AND id_professional = i_id_prof;
    
        IF l_count > 0
        THEN
            l_return := k_yes;
        ELSE
            l_return := k_no;
        END IF;
    
        RETURN l_return;
    
    END check_if_sig_preferential;

    FUNCTION get_sig_detail
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_sig IN NUMBER,
        o_detail OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_yes  CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_no   CONSTANT VARCHAR2(0010 CHAR) := 'N';
        k_comp CONSTANT VARCHAR2(200 CHAR) := 'DS_COMPONENT.CODE_DS_COMPONENT.';
        l_count NUMBER;
    
        l_desc VARCHAR2(4000);
        l_val  VARCHAR2(4000);
        l_type VARCHAR2(0010 CHAR);
        l_clob CLOB;
        l_bool BOOLEAN;
        --l_flg_clob CLOB;
    
        tbl_sig  t_tbl_sig_data;
        tbl_data t_tab_dd_data := t_tab_dd_data();
    
        --****************************************
        PROCEDURE push(i_row IN t_rec_dd_data) IS
            l_count NUMBER;
        BEGIN
        
            tbl_data.extend();
            l_count := tbl_data.count;
            tbl_data(l_count) := i_row;
        
        END push;
    
        --*****************************************
        PROCEDURE fill_row
        (
            i_desc     IN VARCHAR2,
            i_val      IN VARCHAR2,
            i_flg_type IN VARCHAR2,
            i_clob     IN CLOB,
            i_flg_clob IN VARCHAR2 DEFAULT 'N',
            i_flg_sep  IN VARCHAR2 DEFAULT 'Y'
        ) IS
            l_bool BOOLEAN;
            l_row  t_rec_dd_data;
            l_desc VARCHAR2(4000);
            l_sep  VARCHAR2(0020 CHAR);
        BEGIN
        
            l_bool := i_flg_clob = k_no AND i_val IS NOT NULL;
            l_bool := l_bool OR (i_flg_clob = k_yes AND dbms_lob.getlength(i_clob) > 0);
        
            IF i_flg_type NOT IN ('LP', 'L1', 'WL')
            THEN
            
                l_sep := NULL;
                IF i_flg_sep = k_yes
                THEN
                    l_sep := ': ';
                END IF;
                l_desc := i_desc || l_sep;
            
            ELSE
                l_desc := i_desc;
            END IF;
        
            IF l_bool
               OR (i_flg_type IN ('L1', 'WL'))
            THEN
            
                l_row := t_rec_dd_data(descr    => l_desc, --VARCHAR2(1000 CHAR),
                                       val      => i_val, --VARCHAR2(4000 CHAR),
                                       flg_type => i_flg_type, --VARCHAR2(200 CHAR),
                                       flg_html => k_no, --VARCHAR2(1 CHAR),
                                       val_clob => i_clob, --CLOB,
                                       flg_clob => i_flg_clob --VARCHAR2(1 CHAR)
                                       );
                push(l_row);
            
            END IF;
        
        END fill_row;
    
        -- *************************************************************
        PROCEDURE get_signature(i_row IN t_rec_sig_data) IS
            k_code_documented CONSTANT VARCHAR2(0100 CHAR) := 'CO_SIGN_M025';
            l_code_label          VARCHAR2(0200 CHAR);
            l_id_prof_last_change NUMBER;
            l_date                TIMESTAMP WITH LOCAL TIME ZONE;
            --l_desc_signature      VARCHAR2(4000);
            l_label     VARCHAR2(4000);
            l_signature VARCHAR2(4000);
        BEGIN
        
            l_code_label          := k_code_documented;
            l_id_prof_last_change := i_row.id_professional;
            l_date                := i_row.dt_creation;
        
            l_label      := pk_message.get_message(i_lang, l_code_label);
            l_code_label := iif(l_code_label IS NOT NULL, l_label, NULL);
        
            l_signature := l_code_label;
            l_signature := l_signature || ': ' ||
                           pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_id_prof_last_change);
            l_signature := l_signature || '; ' ||
                           pk_date_utils.date_char_tsz(i_lang, l_date, i_prof.institution, i_prof.software);
        
            --  ( signature )
            l_desc := NULL; --l_label;
            l_val  := l_signature;
            l_clob := NULL;
            l_type := 'LP';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
        END get_signature;
    
    BEGIN
    
        tbl_sig := tf_get_sig_data(i_lang, i_prof, i_id_sig);
        l_count := tbl_sig.count;
    
        <<lup_thru_sig>>
        FOR i IN l_count .. tbl_sig.count
        LOOP
        
            IF tbl_sig(i).id_signature = i_id_sig
            THEN
            
                -- white line
                l_desc := '';
                l_val  := '';
                l_clob := NULL;
                l_type := 'WL';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                -- header
                l_desc := pk_message.get_message(i_lang, k_comp || '2295'); -- DS_SIG_SECT_SIGNATURE;
                l_val  := NULL;
                l_clob := NULL;
                l_type := 'L1';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                -- Name of signature
                l_desc := pk_message.get_message(i_lang, k_comp || '2296'); -- DS_SIG_name
                l_val  := tbl_sig(i).sig_name;
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_flg_sep => k_no);
            
                -- Flg_status
                l_desc := pk_message.get_message(i_lang, 'SIG_STATUS_LABEL'); -- DS_SIG_SECT_SIGNATURE;
                l_val  := tbl_sig(i).flg_status;
                l_val  := pk_sysdomain.get_domain(i_code_dom => 'PROF_SIGNATURE.FLG_STATUS',
                                                  i_val      => l_val,
                                                  i_lang     => i_lang);
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                -- Name of user
                l_desc := pk_message.get_message(i_lang, k_comp || '2298'); -- DS_SIG_user_name
                l_val  := tbl_sig(i).sig_prof_name;
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                -- Professional Order
                l_desc := pk_message.get_message(i_lang, k_comp || '2299'); -- DS_SIG_order_type
                l_val  := get_desc_speciality(i_lang, tbl_sig(i).sig_order_type);
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                -- Order Number
                l_desc := pk_message.get_message(i_lang, k_comp || '2300'); -- DS_SIG_order_num
                l_val  := tbl_sig(i).sig_order_nr;
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                -- Address
                l_desc := pk_message.get_message(i_lang, k_comp || '2301'); -- DS_SIG_user_address
                l_val  := tbl_sig(i).sig_address;
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                -- Obs
                l_desc := pk_message.get_message(i_lang, k_comp || '2302'); -- DS_SIG_obs
                l_val  := tbl_sig(i).sig_obs;
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                -- 
                /*
                l_desc := pk_message.get_message(i_lang, k_comp || '2303'); -- DS_SIG_sect_type
                l_val  := NULL;
                l_clob := NULL;
                l_type := 'L1';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
                
                -- Sig Type
                l_desc := pk_message.get_message(i_lang, k_comp || '2304'); -- DS_SIG_type
                l_val  := tbl_sig(i).flg_type;
                l_val  := pk_sysdomain.get_domain(i_code_dom => 'PROF_SIGNATURE.FLG_TYPE_ABBREV',
                                                  i_val      => l_val,
                                                  i_lang     => i_lang);
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
                */
            
                -- Preferencial
                l_desc := pk_message.get_message(i_lang, k_comp || '2305'); -- DS_SIG_preferencial
                l_val  := check_if_sig_preferential(i_prof.id, i_id_sig);
                l_val  := pk_sysdomain.get_domain(i_code_dom => 'YES_NO', i_val => l_val, i_lang => i_lang);
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
                /*
                            l_desc := 'File Name';
                            l_val  := tbl_sig(i).sig_filename;
                            l_clob := NULL;
                            l_type := 'L2B';
                            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
                */
            
                get_signature(tbl_sig(i));
            
                -- white line
                l_desc := '';
                l_val  := '';
                l_clob := NULL;
                l_type := 'WL';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            END IF;
        
        END LOOP lup_thru_sig;
    
        OPEN o_detail FOR
            SELECT t.*
              FROM TABLE(tbl_data) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            l_bool := pk_alert_exceptions.process_error(i_lang,
                                                        SQLCODE,
                                                        SQLERRM,
                                                        '',
                                                        'ALERT',
                                                        'PK_SIG',
                                                        'GET_SIG_DETAIL',
                                                        o_error);
            RETURN FALSE;
        
    END get_sig_detail;

    FUNCTION tf_get_sig_data
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_signature IN NUMBER
    ) RETURN t_tbl_sig_data IS
        tbl_data t_tbl_sig_data;
    BEGIN
    
        SELECT t_rec_sig_data(id_professional  => ps.id_professional,
                              id_signature     => ps.id_signature,
                              flg_type         => ps.flg_type,
                              dt_creation      => ps.dt_creation,
                              id_prof_creation => ps.id_prof_creation,
                              sig_name         => ps.sig_name,
                              flg_status       => ps.flg_status,
                              sig_filename     => ps.sig_filename,
                              sig_obs          => ps.sig_obs,
                              sig_prof_name    => ps.sig_prof_name,
                              sig_order_type   => ps.sig_order_type,
                              sig_order_nr     => ps.sig_order_nr,
                              sig_address      => ps.sig_address,
                              flg_cud          => ps.flg_cud,
                              flg_pref         => ps.flg_pref)
          BULK COLLECT
          INTO tbl_data
          FROM prof_signature_h ps
         WHERE ps.id_professional = i_prof.id
           AND ps.id_signature = i_id_signature
         ORDER BY ps.dt_creation;
    
        RETURN tbl_data;
    
    END tf_get_sig_data;

    FUNCTION get_sig_detail_h
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_id_sig IN NUMBER,
        o_detail OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';
        --k_update CONSTANT VARCHAR2(0200 CHAR) := 'CO_SIGN_M031'; -- sys_message
        --k_new    CONSTANT VARCHAR2(0200 CHAR) := 'CO_SIGN_M032'; -- sys_message
        l_update VARCHAR2(4000);
        l_new    VARCHAR2(4000);
        k_comp CONSTANT VARCHAR2(200 CHAR) := 'DS_COMPONENT.CODE_DS_COMPONENT.';
    
        k_hist_created CONSTANT VARCHAR2(0100 CHAR) := 'C';
        k_hist_updated CONSTANT VARCHAR2(0100 CHAR) := 'U';
    
        l_desc         VARCHAR2(4000);
        l_val          VARCHAR2(4000);
        l_section_desc VARCHAR2(4000);
        l_type         VARCHAR2(0010 CHAR);
        l_clob         CLOB;
        l_bool         BOOLEAN;
        --l_flg_clob     CLOB;
    
        tbl_sig  t_tbl_sig_data;
        tbl_data t_tbl_hh_data := t_tbl_hh_data();
    
        --****************************************
        PROCEDURE push(i_row IN t_rec_hh_data) IS
            l_count NUMBER;
        BEGIN
        
            tbl_data.extend();
            l_count := tbl_data.count;
            tbl_data(l_count) := i_row;
        
        END push;
    
        --*****************************************
        PROCEDURE fill_row
        (
            i_desc      IN VARCHAR2,
            i_val       IN VARCHAR2,
            i_flg_type  IN VARCHAR2,
            i_clob      IN CLOB,
            i_flg_clob  IN VARCHAR2 DEFAULT 'N',
            i_flg_sep   IN VARCHAR2 DEFAULT 'Y',
            i_order_by1 IN NUMBER
        ) IS\
            l_bool BOOLEAN;
            l_row  t_rec_hh_data;
            l_desc VARCHAR2(4000);
            l_sep  VARCHAR2(0020 CHAR);
        BEGIN
        
            l_bool := i_flg_clob = k_no AND i_val IS NOT NULL;
            l_bool := l_bool OR (i_flg_clob = k_yes AND dbms_lob.getlength(i_clob) > 0);
        
            IF i_flg_type NOT IN ('LP', 'L1', 'WL')
            THEN
                l_sep := NULL;
                IF i_flg_sep = k_yes
                THEN
                    l_sep := ': ';
                END IF;
                l_desc := i_desc || l_sep;
            ELSE
                l_desc := i_desc;
            END IF;
        
            IF l_bool
               OR (i_flg_type IN ('L1', 'WL'))
            THEN
                l_row := t_rec_hh_data(descr     => l_desc, --VARCHAR2(1000 CHAR),
                                       val       => i_val, --VARCHAR2(4000 CHAR),
                                       flg_type  => i_flg_type, --VARCHAR2(200 CHAR),
                                       flg_html  => k_no, --VARCHAR2(1 CHAR),
                                       val_clob  => i_clob, --CLOB,
                                       flg_clob  => i_flg_clob, --VARCHAR2(1 CHAR)
                                       order_by1 => i_order_by1,
                                       order_by2 => 0);
                push(l_row);
            
            END IF;
        
        END fill_row;
    
        -- *************************************************************
        PROCEDURE get_signature
        (
            i_row IN t_rec_sig_data,
            i_idx IN NUMBER
        ) IS
            k_code_documented CONSTANT VARCHAR2(0100 CHAR) := 'CO_SIGN_M025';
            l_code_label          VARCHAR2(0200 CHAR);
            l_id_prof_last_change NUMBER;
            l_date                TIMESTAMP WITH LOCAL TIME ZONE;
            --l_desc_signature      VARCHAR2(4000);
            l_label     VARCHAR2(4000);
            l_signature VARCHAR2(4000);
        BEGIN
        
            l_code_label          := k_code_documented;
            l_id_prof_last_change := i_row.id_professional;
            l_date                := i_row.dt_creation;
        
            l_label      := pk_message.get_message(i_lang, l_code_label);
            l_code_label := iif(l_code_label IS NOT NULL, l_label, NULL);
        
            l_signature := l_code_label;
            l_signature := l_signature || ': ' ||
                           pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_id_prof_last_change);
            l_signature := l_signature || '; ' ||
                           pk_date_utils.date_char_tsz(i_lang, l_date, i_prof.institution, i_prof.software);
        
            --  ( signature )
            l_desc := NULL; --l_label;
            l_val  := l_signature;
            l_clob := NULL;
            l_type := 'LP';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_order_by1 => i_idx);
        
        END get_signature;
    
        --********************************
        PROCEDURE process_hist
        (
            i_lang    IN NUMBER,
            i_idx     IN NUMBER,
            i_desc    IN VARCHAR2,
            i_old_val IN VARCHAR2,
            i_new_val IN VARCHAR2
        ) IS
        
            l_old_val VARCHAR2(4000);
            --l_old_idx NUMBER;
            --tbl_row   table_number := table_number();
            l_pos NUMBER;
        
            --tbl_data t_table_co_sign := t_table_co_sign();
        
            tbl_desc table_varchar := table_varchar();
            tbl_val  table_varchar := table_varchar();
            tbl_type table_varchar := table_varchar();
            tbl_clob table_clob := table_clob();
        
            --************************************
            PROCEDURE init_array IS
            BEGIN
                tbl_desc := table_varchar();
                tbl_val  := table_varchar();
                tbl_type := table_varchar();
                tbl_clob := table_clob();
            END init_array;
            --***********************************
            FUNCTION do_extend RETURN NUMBER IS
            BEGIN
            
                tbl_desc.extend();
                tbl_val.extend();
                tbl_type.extend();
                tbl_clob.extend();
            
                RETURN tbl_type.count;
            
            END do_extend;
        
        BEGIN
        
            init_array();
            l_desc := i_desc;
            l_val  := i_new_val;
            l_clob := NULL;
            l_type := 'L2B';
        
            IF i_idx > 1
            THEN
            
                init_array();
            
                -- check new value
                --l_old_idx := i_idx - 1;
                l_old_val := i_old_val;
            
                IF l_old_val IS NULL
                   AND l_val IS NOT NULL
                THEN
                
                    l_pos := do_extend();
                
                    --tbl_row:= tbl_row( i_idx );
                
                    tbl_desc(l_pos) := l_desc || chr(32) || l_new;
                    tbl_val(l_pos) := l_val;
                    tbl_type(l_pos) := 'L2N';
                
                END IF;
            
                -- check update
                l_bool := (l_old_val IS NOT NULL) AND (l_val IS NOT NULL);
                l_bool := l_bool AND (l_old_val != l_val);
                IF l_bool
                THEN
                
                    -- prepare new value
                    l_pos := do_extend();
                    tbl_desc(l_pos) := l_desc || chr(32) || l_update;
                    tbl_val(l_pos) := l_val;
                    tbl_type(l_pos) := 'L2N'; -- cmf
                
                    -- prepare old value
                    l_pos := do_extend();
                    tbl_desc(l_pos) := l_desc;
                    tbl_val(l_pos) := l_old_val;
                    tbl_type(l_pos) := 'L2B';
                
                END IF;
            
                -- check update
                l_bool := (l_old_val IS NOT NULL) AND (l_val IS NULL);
                IF l_bool
                THEN
                
                    -- prepare new value
                    l_pos := do_extend();
                    tbl_desc(l_pos) := l_desc || chr(32) || l_update;
                    tbl_val(l_pos) := pk_message.get_message(i_lang, 'COMMON_M106');
                    tbl_type(l_pos) := 'L2N';
                
                    /*
                    l_pos := do_extend();
                    tbl_desc(l_pos) := l_desc || chr(32) || l_update;
                    tbl_val(l_pos) := l_old_val;
                    tbl_type(l_pos) := 'L2BN';
                    */
                    -- prepare old value
                    l_pos := do_extend();
                    tbl_desc(l_pos) := l_desc || chr(32);
                    tbl_val(l_pos) := l_old_val;
                    tbl_type(l_pos) := 'L2B'; -- cmf

                
                END IF;
            
            ELSE
                -- when i_idx = 1
                l_pos := do_extend();
            
                tbl_desc(l_pos) := l_desc;
                tbl_val(l_pos) := l_val;
                tbl_type(l_pos) := l_type;
            
            END IF;
        
            <<lup_thru_hist_lines>>
            FOR i IN 1 .. tbl_desc.count
            LOOP
            
                l_desc := tbl_desc(i);
                l_val  := tbl_val(i);
                l_clob := tbl_clob(i);
                l_type := tbl_type(i);
            
                fill_row(i_desc      => l_desc,
                         i_val       => l_val,
                         i_flg_type  => l_type,
                         i_clob      => l_clob,
                         i_order_by1 => i_idx);
            
            END LOOP lup_thru_hist_lines;
        
        END process_hist;
    
        --*****************************
        PROCEDURE do_sig_name(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            -- Name of signature
            l_desc := pk_message.get_message(i_lang, k_comp || '2296'); -- DS_SIG_name
            l_val  := tbl_sig(i_idx).sig_name;
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_sig(l_pos).sig_name;
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END do_sig_name;
    
        --*****************************
        PROCEDURE do_sig_prof_name(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, k_comp || '2298');
            l_val  := tbl_sig(i_idx).sig_prof_name;
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_sig(l_pos).sig_prof_name;
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END do_sig_prof_name;
    
        PROCEDURE do_flg_status(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, 'SIG_STATUS_LABEL');
            l_val  := tbl_sig(i_idx).flg_status;
            l_val  := pk_sysdomain.get_domain(i_code_dom => 'PROF_SIGNATURE.FLG_STATUS',
                                              i_val      => l_val,
                                              i_lang     => i_lang);
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_sig(l_pos).flg_status;
                l_old_val := pk_sysdomain.get_domain(i_code_dom => 'PROF_SIGNATURE.FLG_STATUS',
                                                     i_val      => l_old_val,
                                                     i_lang     => i_lang);
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END do_flg_status;
    
        PROCEDURE do_sig_order_type(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, k_comp || '2299');
            l_val  := tbl_sig(i_idx).sig_order_type;
            l_val  := get_desc_speciality(i_lang, l_val);
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_sig(l_pos).sig_order_type;
                l_old_val := get_desc_speciality(i_lang, l_old_val);
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END do_sig_order_type;
    
        PROCEDURE do_sig_order_nr(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, k_comp || '2300');
            l_val  := tbl_sig(i_idx).sig_order_nr;
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_sig(l_pos).sig_order_nr;
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END do_sig_order_nr;
    
        PROCEDURE do_sig_address(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, k_comp || '2301');
            l_val  := tbl_sig(i_idx).sig_address;
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_sig(l_pos).sig_address;
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END do_sig_address;
    
        PROCEDURE do_sig_obs(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, k_comp || '2302');
            l_val  := tbl_sig(i_idx).sig_obs;
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_sig(l_pos).sig_obs;
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END do_sig_obs;
    
        PROCEDURE do_sig_pref(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
            --l_bool    BOOLEAN;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, k_comp || '2305');
            l_val  := tbl_sig(i_idx).flg_pref;
            l_val  := pk_sysdomain.get_domain(i_code_dom => 'YES_NO', i_val => l_val, i_lang => i_lang);
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_sig(l_pos).flg_pref;
                l_old_val := pk_sysdomain.get_domain(i_code_dom => 'YES_NO', i_val => l_old_val, i_lang => i_lang);
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END do_sig_pref;
    
        --*****************************
        PROCEDURE do_white_line(i_idx IN NUMBER) IS
        BEGIN
        
            -- white line
            l_desc := '';
            l_val  := '';
            l_clob := NULL;
            l_type := 'WL';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_order_by1 => i_idx);
        
        END do_white_line;
    
        --*****************************
        PROCEDURE do_sep_line(i_idx IN NUMBER) IS
        BEGIN
        
            -- white line
            l_desc := '';
            l_val  := '';
            l_clob := NULL;
            l_type := 'L1';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_order_by1 => i_idx);
        
        END do_sep_line;
    
        PROCEDURE do_section_header(i_idx IN NUMBER) IS
        BEGIN
        
            CASE tbl_sig(i_idx).flg_cud
                WHEN k_hist_created THEN
                    l_section_desc := 'DETAIL_COMMON_M015';
                WHEN k_hist_updated THEN
                    l_section_desc := 'DETAIL_COMMON_M016';
                ELSE
                    l_section_desc := NULL;
            END CASE;
            l_section_desc := pk_message.get_message(i_lang, l_section_desc);
        
            l_desc := l_section_desc;
            l_val  := NULL;
            l_clob := NULL;
            l_type := 'L1';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_order_by1 => i_idx);
        
        END do_section_header;
    
    BEGIN
    
        -- ( updated)
        l_update := pk_message.get_message(i_lang, 'CO_SIGN_M031');
        -- (new)
        l_new := pk_message.get_message(i_lang, 'CO_SIGN_M032');
    
        tbl_sig := tf_get_sig_data(i_lang, i_prof, i_id_sig);
    
        <<lup_thru_sig>>
        FOR i IN 1 .. tbl_sig.count
        LOOP
        
            IF tbl_sig(i).id_signature = i_id_sig
            THEN
            
                do_sep_line(i);
                do_white_line(i);
            
                -- header
                do_section_header(i);
            
                -- Name of signature
                do_sig_name(i);
            
                do_flg_status(i);
            
                -- Name of user
                do_sig_prof_name(i);
            
                -- Professional Order
                do_sig_order_type(i);
            
                -- Order Number
                do_sig_order_nr(i);
            
                -- Address
                do_sig_address(i);
            
                -- Obs
                do_sig_obs(i);
            
                -- 
                /*
                l_desc := pk_message.get_message(i_lang, k_comp || '2303'); -- DS_SIG_sect_type
                l_val  := NULL;
                l_clob := NULL;
                l_type := 'L1';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
                
                -- Sig Type
                l_desc := pk_message.get_message(i_lang, k_comp || '2304'); -- DS_SIG_type
                l_val  := tbl_sig(i).flg_type;
                l_val  := pk_sysdomain.get_domain(i_code_dom => 'PROF_SIGNATURE.FLG_TYPE_ABBREV',
                                  i_val      => l_val,
                                  i_lang     => i_lang);
                l_clob := NULL;
                l_type := 'L2B';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
                */
            
                -- Preferencial
                do_sig_pref(i);
            
                /*
                      l_desc := 'File Name';
                      l_val  := tbl_sig(i).sig_filename;
                      l_clob := NULL;
                      l_type := 'L2B';
                      fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
                */
            
                get_signature(tbl_sig(i), i);
            
                -- white line
                do_white_line(i);
            
            END IF;
        
        END LOOP lup_thru_sig;
    
        OPEN o_detail FOR
            SELECT tt.*
              FROM (SELECT rownum rn, t.*
                      FROM TABLE(tbl_data) t) tt
             ORDER BY tt.order_by1 DESC, rn ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            l_bool := pk_alert_exceptions.process_error(i_lang,
                                                        SQLCODE,
                                                        SQLERRM,
                                                        '',
                                                        'ALERT',
                                                        'PK_SIG',
                                                        'GET_SIG_DETAIL',
                                                        o_error);
            RETURN FALSE;
        
    END get_sig_detail_h;

    FUNCTION get_sig_order_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain IS
        l_ret t_tbl_core_domain;
    BEGIN
    
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => 'GET_SIG_ORDER_LIST',
                                         desc_domain   => desc_speciality,
                                         domain_value  => id_prof_specialities,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT ps.id_prof_specialities,
                               ps.id_professional,
                               ps.id_speciality,
                               pk_translation.get_translation(i_lang, s.code_speciality) desc_speciality,
                               ps.spec_ballot,
                               ps.id_institution_ext,
                               ps.speciality_main
                          FROM prof_specialities ps
                          JOIN speciality s
                            ON s.id_speciality = ps.id_speciality
                         WHERE ps.id_professional = i_prof.id
                         ORDER BY ps.rank) xsql) tt;
    
        RETURN l_ret;
    
    END get_sig_order_list;

    FUNCTION get_sig_submit_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        l_idx      NUMBER;
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        --l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_SIG_SUBMIT_VALUES';
        --k_action_submit  CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
        l_bool                 BOOLEAN;
        l_comp_name            VARCHAR2(0200 CHAR);
        l_id_prof_specialities NUMBER;
        l_order_num            VARCHAR2(0200 CHAR);
    
        FUNCTION get_order_num(i_id IN NUMBER) RETURN NUMBER IS
            tbl_return table_varchar;
            l_return   VARCHAR2(0200 CHAR);
        BEGIN
        
            SELECT ps.spec_ballot
              BULK COLLECT
              INTO tbl_return
              FROM prof_specialities ps
             WHERE ps.id_prof_specialities = i_id;
        
            IF tbl_return.count > 0
            THEN
                l_return := tbl_return(1);
            END IF;
        
            RETURN l_return;
        
        END get_order_num;
    
    BEGIN
    
        l_bool := (i_curr_component IS NOT NULL);
    
        IF l_bool
        THEN
            l_idx := pk_utils.search_table_number(i_table => i_tbl_mkt_rel, i_search => i_curr_component);
        
            -- IF01
            IF l_idx != -1
            THEN
            
                l_comp_name := i_tbl_int_name(l_idx);
            
                -- if02      
                IF l_comp_name = 'DS_SIG_ORDER_TYPE'
                THEN
                
                    l_id_prof_specialities := i_value(l_idx) (1);
                
                    l_order_num := get_order_num(l_id_prof_specialities);
                    --l_id_target := pk_utils.search_table_varchar(i_table  => i_tbl_int_name,i_search => 'DS_SIG_ORDER_NUM');
                
                    SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                              id_ds_component    => t.id_ds_component_child,
                                              internal_name      => t.internal_name_child,
                                              VALUE              => t.value,
                                              value_clob         => NULL,
                                              min_value          => NULL,
                                              max_value          => NULL,
                                              desc_value         => t.desc_value,
                                              desc_clob          => NULL,
                                              id_unit_measure    => NULL,
                                              desc_unit_measure  => NULL,
                                              flg_validation     => 'Y',
                                              err_msg            => NULL,
                                              flg_event_type     => t.flg_event_type,
                                              flg_multi_status   => NULL,
                                              idx                => 1)
                      BULK COLLECT
                      INTO tbl_result
                      FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                                   dc.id_ds_component_child,
                                   dc.internal_name_child,
                                   NULL                     VALUE,
                                   l_order_num              desc_value,
                                   dc.flg_event_type
                              FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_patient        => NULL,
                                                                 i_component_name => i_root_name,
                                                                 i_action         => NULL)) dc) t
                     WHERE t.internal_name_child IN ('DS_SIG_ORDER_NUM');
                
                END IF; -- if02
            
            END IF; -- IF01
        
        END IF; -- l_bool
    
        RETURN tbl_result;
    
    END get_sig_submit_values;

END pk_sig;
