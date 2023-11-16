/*-- Last Change Revision: $Rev: 1960246 $*/
/*-- Last Change by: $Author: adriana.salgueiro $*/
/*-- Date of last change: $Date: 2020-08-05 11:44:11 +0100 (qua, 05 ago 2020) $*/

CREATE OR REPLACE PACKAGE pk_vitalsign_prm IS
    SUBTYPE t_clob IS CLOB;
    SUBTYPE t_big_char IS VARCHAR2(1000 CHAR);
    SUBTYPE t_med_char IS VARCHAR2(0200 CHAR);
    SUBTYPE t_low_char IS VARCHAR2(0030 CHAR);
    SUBTYPE t_flg_char IS VARCHAR2(0001 CHAR);

    -- public types
    TYPE t_rec_vs_freq_config IS RECORD(
        intern_name_vital_sign vital_sign.intern_name_vital_sign%TYPE,
        flg_fill_type          vital_sign.flg_fill_type%TYPE,
        id_content_vs          vital_sign.id_content%TYPE,
        id_unit_measure        alert_default.vs_soft_inst.id_unit_measure%TYPE,
        color_grafh            alert_default.vs_soft_inst.color_grafh%TYPE,
        color_text             alert_default.vs_soft_inst.color_text%TYPE,
        box_type               alert_default.vs_soft_inst.box_type%TYPE,
        val_min                alert_default.vital_sign_unit_measure.val_min%TYPE,
        val_max                alert_default.vital_sign_unit_measure.val_max%TYPE,
        format_num             alert_default.vital_sign_unit_measure.format_num%TYPE,
        decimals               alert_default.vital_sign_unit_measure.decimals%TYPE,
        age_min                alert_default.vital_sign_unit_measure.age_min%TYPE,
        age_max                alert_default.vital_sign_unit_measure.age_max%TYPE);

    -- searcheable loader method signature
    FUNCTION set_vs_soft_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_vs_soft_inst_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vital_sign_um_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_vital_sign_um_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_vital_sign_sa_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_mkt         IN table_number,
        i_vers        IN table_varchar,
        i_software    IN table_number,
        i_id_content  IN table_varchar DEFAULT table_varchar(),
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_vital_sign_sa_search
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN table_number,
        o_result_tbl  OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE set_vs_content
    (
        i_id_vital_sign          vital_sign.id_vital_sign%TYPE,
        i_intern_name_vital_sign vital_sign.intern_name_vital_sign%TYPE,
        i_flg_fill_type          vital_sign.flg_fill_type%TYPE,
        i_id_content             vital_sign.id_content%TYPE
    );

    PROCEDURE set_vs_content_vsi
    (
        i_id_vs_soft_inst alert_default.vs_soft_inst.id_vs_soft_inst%TYPE,
        i_id_vital_sign   alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market       alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software     alert_default.vs_soft_inst.id_software%TYPE,
        i_version         alert_default.vs_soft_inst.version%TYPE,
        i_flg_view        alert_default.vs_soft_inst.flg_view%TYPE,
        i_id_unit_measure alert_default.vs_soft_inst.id_unit_measure%TYPE,
        i_color_grafh     alert_default.vs_soft_inst.color_grafh%TYPE,
        i_color_text      alert_default.vs_soft_inst.color_text%TYPE,
        i_box_type        alert_default.vs_soft_inst.box_type%TYPE,
        i_rank            alert_default.vs_soft_inst.rank%TYPE,
        i_flg_add_remove  VARCHAR2
    );
    --
    PROCEDURE set_vs_content_vsum
    (
        i_id_vital_sign_unit_measure alert_default.vital_sign_unit_measure.id_vital_sign_unit_measure%TYPE,
        i_id_vital_sign              alert_default.vital_sign_unit_measure.id_vital_sign%TYPE,
        i_id_market                  alert_default.vital_sign_unit_measure.id_market%TYPE,
        i_id_software                alert_default.vital_sign_unit_measure.id_software%TYPE,
        i_version                    alert_default.vital_sign_unit_measure.version%TYPE,
        i_id_unit_measure            alert_default.vital_sign_unit_measure.id_unit_measure%TYPE,
        i_val_min                    alert_default.vital_sign_unit_measure.val_min%TYPE,
        i_val_max                    alert_default.vital_sign_unit_measure.val_max%TYPE,
        i_format_num                 alert_default.vital_sign_unit_measure.format_num%TYPE,
        i_decimals                   alert_default.vital_sign_unit_measure.decimals%TYPE,
        i_age_min                    alert_default.vital_sign_unit_measure.age_min%TYPE,
        i_age_max                    alert_default.vital_sign_unit_measure.age_max%TYPE,
        i_flg_add_remove             VARCHAR2
    );
    --
    PROCEDURE set_vs_content_desc
    (
        i_id_vital_sign_desc vital_sign_desc.id_vital_sign_desc%TYPE,
        i_id_vital_sign      vital_sign_desc.id_vital_sign%TYPE,
        i_id_market          vital_sign_desc.id_market%TYPE,
        i_id_content         vital_sign_desc.id_content%TYPE,
        i_rank               vital_sign_desc.rank%TYPE,
        i_value              vital_sign_desc.value%TYPE,
        i_icon               vital_sign_desc.icon%TYPE,
        i_flg_add_remove     VARCHAR2
    );
    --
    FUNCTION tf_vs_prm
    (
        i_lang          IN language.id_language%TYPE,
        i_id_vital_sign vital_sign.id_vital_sign%TYPE DEFAULT NULL
    ) RETURN t_coll_vs_prm;
    --
    FUNCTION tf_vsi_prm
    (
        i_lang          IN language.id_language%TYPE,
        i_id_vital_sign alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market     alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software   alert_default.vs_soft_inst.id_software%TYPE DEFAULT NULL,
        i_flg_view      alert_default.vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        i_version       alert_default.vs_soft_inst.version%TYPE DEFAULT NULL
    ) RETURN t_coll_vsi_prm;
    --
    FUNCTION tf_software(i_screen_name sys_button_prop.screen_name%TYPE) RETURN t_coll_software;
    --
    FUNCTION tf_vsum_prm
    (
        i_lang            IN language.id_language%TYPE,
        i_id_vital_sign   alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market       alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software     alert_default.vs_soft_inst.id_software%TYPE DEFAULT NULL,
        i_version         alert_default.vs_soft_inst.version%TYPE DEFAULT NULL,
        i_id_unit_measure alert_default.vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL
    ) RETURN t_coll_vsum_prm;

    FUNCTION tf_vsum_prm
    (
        i_lang            IN language.id_language%TYPE,
        i_id_vital_sign   alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market       alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software_tab table_number,
        i_version         alert_default.vs_soft_inst.version%TYPE DEFAULT NULL,
        i_id_unit_measure alert_default.vs_soft_inst.id_unit_measure%TYPE DEFAULT NULL
    ) RETURN t_coll_vsum_prm;

    /*********************************************************************************************
    * Get the next id_value available for inserts
    * @param      i_table
    * @param      i_column       column that we want to check (normally the table PK)
    * @param      i_id_max       limits the id (DEFAULT 9999999)
    * @param      i_dblink       searchs on the specified db_link besides the current environment
    *
    * @author     Nuno Alves
    * @since      06/Fev/2015
    *********************************************************************************************/
    FUNCTION get_new_id
    (
        i_table  IN VARCHAR2,
        i_column IN VARCHAR2 DEFAULT NULL,
        i_id_max IN NUMBER DEFAULT 999999999,
        i_dblink IN VARCHAR2 DEFAULT NULL,
        i_owner  IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;
    --
    PROCEDURE set_vs_content_all
    (
        i_id_vital_sign          vital_sign.id_vital_sign%TYPE,
        i_intern_name_vital_sign vital_sign.intern_name_vital_sign%TYPE,
        i_flg_fill_type          vital_sign.flg_fill_type%TYPE,
        i_id_content_vs          vital_sign.id_content%TYPE,
        -- vsi
        i_id_vs_soft_inst table_number,
        i_id_market       alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software     table_number,
        i_version         alert_default.vs_soft_inst.version%TYPE,
        i_flg_view        table_varchar,
        i_id_unit_measure alert_default.vs_soft_inst.id_unit_measure%TYPE,
        i_color_grafh     alert_default.vs_soft_inst.color_grafh%TYPE,
        i_color_text      alert_default.vs_soft_inst.color_text%TYPE,
        i_box_type        alert_default.vs_soft_inst.box_type%TYPE,
        i_rank_vsi        alert_default.vs_soft_inst.rank%TYPE,
        -- vsum
        i_id_vital_sign_unit_measure table_number,
        i_val_min                    alert_default.vital_sign_unit_measure.val_min%TYPE,
        i_val_max                    alert_default.vital_sign_unit_measure.val_max%TYPE,
        i_format_num                 alert_default.vital_sign_unit_measure.format_num%TYPE,
        i_decimals                   alert_default.vital_sign_unit_measure.decimals%TYPE,
        i_age_min                    alert_default.vital_sign_unit_measure.age_min%TYPE,
        i_age_max                    alert_default.vital_sign_unit_measure.age_max%TYPE,
        --vs desc
        i_id_vital_sign_desc table_number,
        i_id_content_vsd     table_varchar,
        i_rank_vsd           table_number,
        i_value              table_varchar,
        i_icon               table_varchar,
        -- VSI Script type ('I' - insert, 'U' - update, 'D' - Delete)
        i_flg_script_type IN VARCHAR2 DEFAULT 'I'
    );
    --
    PROCEDURE set_vs_content_rel
    (
        i_id_vital_sign_relation vital_sign_relation.id_vital_sign_relation%TYPE,
        i_id_vital_sign_parent   vital_sign_relation.id_vital_sign_parent%TYPE,
        i_id_vital_sign_detail   vital_sign_relation.id_vital_sign_detail%TYPE,
        i_relation_domain        vital_sign_relation.relation_domain%TYPE,
        i_rank                   vital_sign_relation.rank%TYPE,
        i_flg_add_remove         VARCHAR2
    );
    --
    PROCEDURE set_vs_content_bp
    (
        i_id_vital_sign_relation table_number,
        i_id_vital_sign_parent   table_number,
        i_id_vital_sign_detail   table_number,
        i_rank                   table_number
    );
    --
    PROCEDURE set_vs_content_glasgow
    (
        i_id_vital_sign_relation table_number,
        i_id_vital_sign_parent   table_number,
        i_id_vital_sign_detail   table_number,
        i_rank                   table_number
    );
    --
    PROCEDURE set_vs_content_scale
    (
        i_id_vital_sign_scales vital_sign_scales.id_vital_sign_scales%TYPE,
        i_id_vital_sign        vital_sign_scales.id_vital_sign%TYPE,
        i_internal_name        vital_sign_scales.internal_name%TYPE,
        i_flg_add_remove       VARCHAR2
    );
    --
    PROCEDURE set_vs_content_vsse
    (
        i_id_vs_scales_element vital_sign_scales_element.id_vs_scales_element%TYPE,
        i_id_vital_sign_scales vital_sign_scales_element.id_vital_sign_scales%TYPE,
        i_internal_name        vital_sign_scales_element.internal_name%TYPE,
        i_value                vital_sign_scales_element.value%TYPE,
        i_min_value            vital_sign_scales_element.min_value%TYPE,
        i_max_value            vital_sign_scales_element.max_value%TYPE,
        i_id_unit_measure      vital_sign_scales_element.id_unit_measure%TYPE,
        i_icon                 vital_sign_scales_element.icon%TYPE,
        i_flg_add_remove       VARCHAR2
    );
    --
    PROCEDURE set_vs_content_attribute
    (
        i_id_vs_attribute vs_attribute.id_vs_attribute%TYPE,
        i_id_parent       vs_attribute.id_parent%TYPE,
        i_flg_free_text   vs_attribute.flg_free_text%TYPE,
        i_id_content      vs_attribute.id_content%TYPE
    );

    /*********************************************************************************************
    * Get the script for versioning through the set_vs_content_all API
    *
    * @author     Nuno Alves
    * @since      06/Mar/2015
    *********************************************************************************************/
    FUNCTION get_script_vs_content_all
    (
        i_id_vital_sign          IN VARCHAR2,
        i_intern_name_vital_sign IN VARCHAR2,
        i_flg_fill_type          IN VARCHAR2,
        i_id_content_vs          IN VARCHAR2,
        i_id_market              IN VARCHAR2,
        i_id_vs_soft_inst        IN VARCHAR2 DEFAULT NULL,
        i_id_software            IN VARCHAR2 DEFAULT NULL,
        
        i_version                IN VARCHAR2 DEFAULT NULL,
        i_flg_view               IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure        IN VARCHAR2 DEFAULT NULL,
        i_color_grafh            IN VARCHAR2 DEFAULT NULL,
        i_color_text             IN VARCHAR2 DEFAULT NULL,
        i_box_type               IN VARCHAR2 DEFAULT NULL,
        i_rank_vsi               IN VARCHAR2 DEFAULT NULL,
        i_val_min                IN VARCHAR2 DEFAULT NULL,
        i_val_max                IN VARCHAR2 DEFAULT NULL,
        i_format_num             IN VARCHAR2 DEFAULT NULL,
        i_decimals               IN VARCHAR2 DEFAULT NULL,
        i_age_min                IN VARCHAR2 DEFAULT NULL,
        i_age_max                IN VARCHAR2 DEFAULT NULL,
        i_num_id_vital_sign_desc IN VARCHAR2 DEFAULT NULL,
        i_id_vital_sign_desc     IN VARCHAR2 DEFAULT NULL,
        i_id_content_vsd         IN VARCHAR2 DEFAULT NULL,
        i_rank_vsd               IN VARCHAR2 DEFAULT NULL,
        i_value                  IN VARCHAR2 DEFAULT NULL,
        i_icon                   IN VARCHAR2 DEFAULT NULL,
        i_flg_script_type        IN VARCHAR2 DEFAULT 'I'
    ) RETURN CLOB;

    /*********************************************************************************************
    * Get the most frequent config values for a vital sign
    *
    * @author     Nuno Alves
    * @since      02/Jun/2015
    *********************************************************************************************/
    FUNCTION get_vs_most_freq_config
    (
        i_lang          language.id_language%TYPE,
        i_id_vital_sign alert_default.vs_soft_inst.id_vital_sign%TYPE,
        i_id_market     alert_default.vs_soft_inst.id_market%TYPE,
        i_id_software   alert_default.vs_soft_inst.id_software%TYPE DEFAULT NULL,
        i_flg_view      alert_default.vs_soft_inst.flg_view%TYPE DEFAULT NULL,
        i_version       alert_default.vs_soft_inst.version%TYPE DEFAULT NULL
    ) RETURN t_rec_vs_freq_config;
    -- global vars
    g_error         t_big_char;
    g_flg_available t_flg_char;
    g_active        t_flg_char;
    g_version       t_low_char;
    g_func_name     t_med_char;

    g_array_size  NUMBER;
    g_array_size1 NUMBER;

    g_flg_script_type_ins CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_flg_script_type_upd CONSTANT VARCHAR2(1 CHAR) := 'U';
    g_flg_script_type_del CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_p11_vsi_collection t_low_char := '1501_11_VSI_COLLECTION';
END pk_vitalsign_prm;
/
/
