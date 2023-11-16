/*-- Last Change Revision: $Rev: 2055616 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:27:24 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_vital_sign AS

    SUBTYPE obj_name IS VARCHAR2(32 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_error VARCHAR2(1000 CHAR);

    -- Graphic (growth charts) related variables
    -- default graphic filter
    c_def_graphic_filter CONSTANT NUMBER(1) := 4;
    -- graphic axis types
    c_axis_type_month      CONSTANT graphic.flg_x_axis_type%TYPE := 'M';
    c_axis_type_year       CONSTANT graphic.flg_x_axis_type%TYPE := 'Y';
    c_axis_type_vital_sign CONSTANT graphic.flg_x_axis_type%TYPE := 'V';

    c_get_vs_desc_v CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_yes           CONSTANT VARCHAR2(1 CHAR) := 'Y';

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_sign_v) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_vital_sign,
                   NULL internal_name,
                   NULL val_min,
                   NULL val_max,
                   NULL rank_conc,
                   NULL id_vital_sign_parent,
                   NULL vs_parent_int_name,
                   NULL relation_type,
                   NULL format_num,
                   NULL flg_fill_type,
                   NULL flg_sum,
                   NULL name_vs,
                   NULL desc_unit_measure,
                   NULL id_unit_measure,
                   NULL dt_server,
                   NULL vs_flg_type,
                   NULL flg_validate,
                   NULL flg_save_to_db,
                   NULL flg_show_description,
                   NULL flg_calculate_trts
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    /************************************************************************************************************
    * This function returns patient age and gender to be used on vital sign functionality
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_patient                   Patient id
    * @param      o_gender                    patient gender
    * @param      o_age                       patient age
    *
    * @return     Vital sign alias or translation
    *
    * @author     Lu�s Maia
    * @version    2.5
    * @since      2011/11/15
    ***********************************************************************************************************/
    FUNCTION get_pat_info
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_gender  OUT patient.gender%TYPE,
        o_age     OUT patient.age%TYPE
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_INFO';
        g_error  debug_msg;
        l_gender patient.gender%TYPE;
        l_age    patient.age%TYPE;
    BEGIN
        g_error := 'get patient gender and age';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => c_function_name);
        IF i_patient IS NOT NULL
        THEN
            SELECT p.gender, nvl(p.age, trunc(months_between(SYSDATE, p.dt_birth) / 12, 0))
              INTO l_gender, l_age
              FROM patient p
             WHERE p.id_patient = i_patient;
        ELSE
            l_gender := NULL;
            l_age    := NULL;
        END IF;
        --
        o_gender := l_gender;
        o_age    := l_age;
        --
        RETURN TRUE;
    END get_pat_info;

    --

    FUNCTION get_vs_um_inst
    (
        i_vital_sign  IN vital_sign.id_vital_sign%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN unit_measure.id_unit_measure%TYPE IS
    
        l_vs_um_inst unit_measure.id_unit_measure%TYPE;
    
    BEGIN
    
        BEGIN
        
            SELECT vsi.id_unit_measure
              INTO l_vs_um_inst
              FROM vs_soft_inst vsi
             WHERE vsi.id_vital_sign = i_vital_sign
               AND vsi.id_institution = i_institution
               AND vsi.id_software = i_software
               AND rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_vs_um_inst := NULL;
        END;
    
        RETURN l_vs_um_inst;
    
    END get_vs_um_inst;

    --

    FUNCTION get_vs_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_short_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pk_translation.t_desc_translation IS
        c_function_name CONSTANT obj_name := 'GET_VS_DESC';
        l_dbg_msg debug_msg;
    
        l_vs_desc pk_translation.t_desc_translation;
    
    BEGIN
        l_dbg_msg := 'get vital sign description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        IF i_vital_sign IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        SELECT CASE i_short_desc
                   WHEN pk_alert_constant.g_yes THEN
                    pk_translation.get_translation(i_lang, vs.code_vs_short_desc)
                   WHEN c_get_vs_desc_v THEN
                    nvl(pk_translation.get_translation(i_lang, vs.code_vs_short_desc),
                        pk_translation.get_translation(i_lang, vs.code_vital_sign))
                   ELSE
                    pk_translation.get_translation(i_lang, vs.code_vital_sign)
               END
          INTO l_vs_desc
          FROM vital_sign vs
         WHERE vs.id_vital_sign = i_vital_sign;
    
        RETURN l_vs_desc;
    
    END get_vs_desc;

    --

    FUNCTION get_vsd_order_val(i_vital_sign_desc IN vital_sign_desc.id_vital_sign_desc%TYPE)
        RETURN vital_sign_desc.order_val%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VSD_ORDER_VAL';
        l_dbg_msg debug_msg;
    
        l_order_val vital_sign_desc.order_val%TYPE;
    
    BEGIN
        IF i_vital_sign_desc IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get the vital_sign_desc order value';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT vsd.order_val
          INTO l_order_val
          FROM vital_sign_desc vsd
         WHERE vsd.id_vital_sign_desc = i_vital_sign_desc;
    
        RETURN l_order_val;
    
    END get_vsd_order_val;

    --

    FUNCTION get_vsd_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_vital_sign_desc IN vital_sign_desc.code_vital_sign_desc%TYPE,
        i_age             IN patient.age%TYPE,
        i_gender          IN patient.gender%TYPE,
        i_short_desc      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pk_translation.t_desc_translation IS
        c_function_name CONSTANT obj_name := 'GET_VSD_DESC';
        l_dbg_msg debug_msg;
    
        l_vs_desc_desc pk_translation.t_desc_translation;
    
    BEGIN
        IF i_vital_sign_desc IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get vital_sign_desc description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT pk_translation.get_translation(i_lang,
                                              nvl((SELECT CASE i_short_desc
                                                             WHEN pk_alert_constant.g_yes THEN
                                                              vsa.code_abreviation_alias
                                                             ELSE
                                                              vsa.code_vital_sign_alias
                                                         END
                                                    FROM vital_sign_alias vsa
                                                   WHERE vsa.id_vital_sign_desc = vsd.id_vital_sign_desc
                                                     AND (i_age IS NULL OR vsa.age IS NULL OR vsa.age >= i_age)
                                                     AND (i_gender IS NULL OR vsa.gender IS NULL OR
                                                         vsa.gender = i_gender)),
                                                  CASE i_short_desc
                                                      WHEN pk_alert_constant.g_yes THEN
                                                       vsd.code_abbreviation
                                                      ELSE
                                                       vsd.code_vital_sign_desc
                                                  END))
          INTO l_vs_desc_desc
          FROM vital_sign_desc vsd
         WHERE vsd.id_vital_sign_desc = i_vital_sign_desc;
    
        RETURN l_vs_desc_desc;
    
    END get_vsd_desc;

    --

    FUNCTION get_vsd_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_vital_sign_desc IN vital_sign_desc.id_vital_sign_desc%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_short_desc      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN pk_translation.t_desc_translation IS
        c_function_name CONSTANT obj_name := 'GET_VSD_DESC';
        l_dbg_msg debug_msg;
        l_gender  patient.gender%TYPE;
        l_age     patient.age%TYPE;
    BEGIN
        IF i_vital_sign_desc IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'CALL FUNCTION GET_PAT_INFO';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => c_function_name);
        IF NOT get_pat_info(i_lang => i_lang, i_patient => i_patient, o_gender => l_gender, o_age => l_age)
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get vital_sign_desc description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        RETURN get_vsd_desc(i_lang            => i_lang,
                            i_vital_sign_desc => i_vital_sign_desc,
                            i_age             => l_age,
                            i_gender          => l_gender,
                            i_short_desc      => i_short_desc);
    
    END get_vsd_desc;

    --

    FUNCTION get_vsse_value(i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE)
        RETURN vital_sign_scales_element.value%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VSSE_VALUE';
        l_dbg_msg debug_msg;
    
        l_value vital_sign_scales_element.value%TYPE;
    
    BEGIN
        IF i_vs_scales_element IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get vital sign scales element value';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT vsse.value
          INTO l_value
          FROM vital_sign_scales_element vsse
         WHERE vsse.id_vs_scales_element = i_vs_scales_element;
    
        RETURN l_value;
    
    END get_vsse_value;

    --

    FUNCTION get_vsse_um
    (
        i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE,
        i_without_um_no_id  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN vital_sign_scales_element.id_unit_measure%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VSSE_UM';
        l_dbg_msg debug_msg;
    
        l_unit_measure vital_sign_scales_element.id_unit_measure%TYPE;
    
    BEGIN
        IF i_vs_scales_element IS NULL
        THEN
            l_unit_measure := CASE i_without_um_no_id
                                  WHEN pk_alert_constant.g_no THEN
                                   c_without_um
                                  ELSE
                                   NULL
                              END;
        
        ELSE
            l_dbg_msg := 'get vital sign scales element value';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
            SELECT vsse.id_unit_measure
              INTO l_unit_measure
              FROM vital_sign_scales_element vsse
             WHERE vsse.id_vs_scales_element = i_vs_scales_element;
        
            IF i_without_um_no_id = pk_alert_constant.g_no
               AND l_unit_measure IS NULL
            THEN
                l_unit_measure := c_without_um;
            END IF;
        
        END IF;
    
        RETURN l_unit_measure;
    
    END get_vsse_um;

    --

    FUNCTION get_vs_parent(i_vital_sign IN vital_sign_relation.id_vital_sign_detail%TYPE)
        RETURN vital_sign_relation.id_vital_sign_parent%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VS_PARENT';
        l_dbg_msg debug_msg;
    
        l_vs_parent vital_sign_relation.id_vital_sign_parent%TYPE;
    
    BEGIN
        IF i_vital_sign IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get the vital sign relation parent, if it has one';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        BEGIN
            SELECT vrel.id_vital_sign_parent
              INTO l_vs_parent
              FROM vital_sign_relation vrel
             WHERE vrel.id_vital_sign_detail = i_vital_sign
               AND vrel.flg_available = pk_alert_constant.g_yes
               AND vrel.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum);
        
        EXCEPTION
            WHEN no_data_found THEN
                l_vs_parent := NULL;
            
        END;
    
        RETURN l_vs_parent;
    
    END get_vs_parent;
    --
    FUNCTION get_vs_parent_triage(i_vital_sign IN vital_sign_relation.id_vital_sign_detail%TYPE)
        RETURN vital_sign_relation.id_vital_sign_parent%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VS_PARENT';
        l_dbg_msg debug_msg;
    
        l_vs_parent vital_sign_relation.id_vital_sign_parent%TYPE;
    
    BEGIN
        IF i_vital_sign IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get the vital sign relation parent, if it has one';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        BEGIN
            SELECT vrel.id_vital_sign_parent
              INTO l_vs_parent
              FROM vital_sign_relation vrel
             WHERE vrel.id_vital_sign_detail = i_vital_sign
               AND vrel.flg_available = pk_alert_constant.g_yes
               AND vrel.relation_domain IN
                   (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_group);
        
        EXCEPTION
            WHEN no_data_found THEN
                l_vs_parent := NULL;
            
        END;
    
        RETURN l_vs_parent;
    
    END get_vs_parent_triage;
    --

    FUNCTION get_vs_relation_domain(i_vital_sign IN vital_sign_relation.id_vital_sign_detail%TYPE)
        RETURN vital_sign_relation.relation_domain%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VS_RELATION_DOMAIN';
        l_dbg_msg debug_msg;
    
        l_relation_domain vital_sign_relation.relation_domain%TYPE;
    
    BEGIN
        IF i_vital_sign IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get the vital sign relation domain, if it has one';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        BEGIN
            SELECT vrel.relation_domain
              INTO l_relation_domain
              FROM vital_sign_relation vrel
             WHERE vrel.id_vital_sign_parent = i_vital_sign
               AND vrel.flg_available = pk_alert_constant.g_yes
               AND vrel.relation_domain != pk_alert_constant.g_vs_rel_percentile
               AND rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_relation_domain := NULL;
            
        END;
    
        RETURN l_relation_domain;
    
    END get_vs_relation_domain;

    /************************************************************************************************************
    * This function returns the last vs read date of specific patient
    *
    * @param      i_vital_sign                Vital sign id (glasgow total id)
    * @param      i_patient                   Patient id
    *
    * @return     dt_vital_sign_read_tstz
    *
    * @author     Lillian Lu
    * @version    2.7.2.4
    * @since      2018/2/8
    ************************************************************************************************************/
    FUNCTION get_last_vs_relation_date
    (
        i_vital_sign vital_sign_read.id_vital_sign%TYPE,
        i_patient    vital_sign_read.id_patient%TYPE
    ) RETURN vital_sign_read.dt_vital_sign_read_tstz%TYPE IS
        l_vital_sign_date vital_sign_read.dt_vital_sign_read_tstz%TYPE;
    BEGIN
        SELECT pvsr.dt_vital_sign_read_tstz
          INTO l_vital_sign_date
          FROM (SELECT vsr.dt_vital_sign_read_tstz,
                       rank() over(PARTITION BY vrel.id_vital_sign_parent ORDER BY vsr.dt_vital_sign_read_tstz DESC) AS rank
                  FROM vital_sign_read vsr
                 INNER JOIN vital_sign_relation vrel
                    ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                 INNER JOIN vital_sign_desc vsd
                    ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
                 WHERE vsr.id_patient = i_patient
                   AND vrel.id_vital_sign_parent = i_vital_sign
                   AND vrel.relation_domain = pk_alert_constant.g_vs_rel_sum
                   AND vrel.flg_available = pk_alert_constant.g_yes
                   AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                 ORDER BY vsr.dt_vital_sign_read_tstz DESC) pvsr
         WHERE pvsr.rank = 1
           AND rownum = 1;
    
        RETURN l_vital_sign_date;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_last_vs_relation_date;

    /************************************************************************************************************
    * This function returns the glasgow total value summing the glasgow eye, motor and verbal values
    *
    * @param      i_vital_sign                Vital sign id (glasgow total id)
    * @param      i_patient                   Patient id
    * @param      i_episode                   Episode id
    * @param      i_dt_vital_sign_read        Vital sign read date
    *
    * @return     Glasgow total value
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/19
    ************************************************************************************************************/
    FUNCTION get_glasgowtotal_value
    (
        i_vital_sign         vital_sign_read.id_vital_sign%TYPE,
        i_patient            vital_sign_read.id_patient%TYPE,
        i_episode            vital_sign_read.id_episode%TYPE,
        i_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN vital_sign_read.value%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_GLASGOWTOTAL_VALUE';
        l_dbg_msg debug_msg;
    
        l_glasgowtotal       vital_sign_read.value%TYPE;
        l_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE := i_dt_vital_sign_read;
    BEGIN
        IF i_vital_sign IS NULL
           OR i_patient IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        IF l_dt_vital_sign_read IS NULL
        THEN
            l_dt_vital_sign_read := get_last_vs_relation_date(i_vital_sign => i_vital_sign, i_patient => i_patient);
        END IF;
    
        l_dbg_msg := 'get glasgow total';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT SUM(vsd.value)
          INTO l_glasgowtotal
          FROM vital_sign_read vsr
         INNER JOIN vital_sign_relation vrel
            ON vsr.id_vital_sign = vrel.id_vital_sign_detail
         INNER JOIN vital_sign_desc vsd
            ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
         WHERE vsr.id_patient = i_patient
           AND ((vsr.id_episode = i_episode) OR (i_episode IS NULL))
           AND vsr.dt_vital_sign_read_tstz = l_dt_vital_sign_read
           AND vrel.id_vital_sign_parent = i_vital_sign
           AND vrel.relation_domain = pk_alert_constant.g_vs_rel_sum
           AND vrel.flg_available = pk_alert_constant.g_yes
           AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0;
    
        l_dbg_msg := 'glasgow total: ' || l_glasgowtotal;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        RETURN l_glasgowtotal;
    
    END get_glasgowtotal_value;
    /************************************************************************************************************
    * This function returns the glasgow total value summing the glasgow eye, motor and verbal values
    *
    * @param      i_vital_sign                Vital sign id (glasgow total id)
    * @param      i_patient                   Patient id
    * @param      i_episode                   Episode id
    * @param      i_dt_vital_sign_read        Vital sign read date
    *
    * @return     Glasgow total value
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/19
    ************************************************************************************************************/
    FUNCTION get_glasgowtotal_value_hist
    (
        i_vital_sign         vital_sign_read.id_vital_sign%TYPE,
        i_patient            vital_sign_read.id_patient%TYPE,
        i_episode            vital_sign_read.id_episode%TYPE,
        i_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE
    ) RETURN vital_sign_read.value%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_GLASGOWTOTAL_VALUE';
        l_dbg_msg debug_msg;
    
        l_glasgowtotal vital_sign_read.value%TYPE;
    
    BEGIN
        IF i_vital_sign IS NULL
           OR i_patient IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get glasgow total';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT SUM(vsd.value)
          INTO l_glasgowtotal
          FROM vital_sign_read vsr
         INNER JOIN vital_sign_relation vrel
            ON vsr.id_vital_sign = vrel.id_vital_sign_detail
         INNER JOIN vital_sign_desc vsd
            ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
         WHERE vsr.id_patient = i_patient
           AND ((vsr.id_episode = i_episode) OR (vsr.id_episode IS NULL AND i_episode IS NULL))
           AND vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read
           AND vrel.id_vital_sign_parent = i_vital_sign
           AND vrel.relation_domain = pk_alert_constant.g_vs_rel_sum
           AND vrel.flg_available = pk_alert_constant.g_yes
           AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
           AND vsr.dt_registry = nvl(i_dt_registry, vsr.dt_registry);
    
        IF l_glasgowtotal = 0
           OR l_glasgowtotal IS NULL
        THEN
            pk_alertlog.log_info(text            => 'get glasgow total hist',
                                 object_name     => g_package_name,
                                 sub_object_name => c_function_name);
            SELECT SUM(vsd.value)
              INTO l_glasgowtotal
              FROM vital_sign_read vsr
             INNER JOIN vital_sign_relation vrel
                ON vsr.id_vital_sign = vrel.id_vital_sign_detail
              JOIN vital_sign_read_hist vsrh
                ON vsrh.id_vital_sign_read = vsr.id_vital_sign_read
             INNER JOIN vital_sign_desc vsd
                ON vsrh.id_vital_sign_desc = vsd.id_vital_sign_desc
             WHERE vsr.id_patient = i_patient
               AND ((vsr.id_episode = i_episode) OR (vsr.id_episode IS NULL AND i_episode IS NULL))
               AND vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read
               AND vrel.id_vital_sign_parent = i_vital_sign
               AND vrel.relation_domain = pk_alert_constant.g_vs_rel_sum
               AND vrel.flg_available = pk_alert_constant.g_yes
               AND pk_delivery.check_vs_read_from_fetus(vsrh.id_vital_sign_read) = 0
               AND vsrh.dt_registry = nvl(i_dt_registry, vsrh.dt_registry)
               AND vsrh.dt_vital_sign_read_tstz = i_dt_vital_sign_read;
        END IF;
    
        l_dbg_msg := 'glasgow total: ' || l_glasgowtotal;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        RETURN l_glasgowtotal;
    
    END get_glasgowtotal_value_hist;
    /************************************************************************************************************
    * This function returns the blood pressure value concatenating the sistolic and diastolic pressure values
    *
    * @param      i_id_vital_sign             Vital sign id (blood pressure id)
    * @param      i_patient                   Patient id
    * @param      i_id_episode                Episode id
    * @param      i_dt_vital_sign_read        Vital sign read date
    * @param      i_decimal_symbol            Decimal symbol
    *
    * @return     Blood pressure value
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/19
    ************************************************************************************************************/
    FUNCTION get_bloodpressure_value
    (
        i_vital_sign         vital_sign_read.id_vital_sign%TYPE,
        i_patient            vital_sign_read.id_patient%TYPE,
        i_episode            vital_sign_read.id_episode%TYPE,
        i_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_decimal_symbol     sys_config.value%TYPE,
        i_pat_pregn_fetus    pat_pregn_fetus.id_pat_pregn_fetus%TYPE DEFAULT NULL,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'GET_BLOODPRESSURE_VALUE';
        l_dbg_msg debug_msg;
    
        l_sistolicpressure  vital_sign_read.value%TYPE;
        l_diastolicpressure vital_sign_read.value%TYPE;
        l_rank              vital_sign_relation.rank%TYPE;
    
    BEGIN
        IF i_vital_sign IS NULL
           OR i_patient IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get sistolic pressure rank';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT MIN(vsrel.rank)
          INTO l_rank
          FROM vital_sign_relation vsrel
         WHERE vsrel.id_vital_sign_parent = i_vital_sign
           AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_conc
           AND vsrel.flg_available = pk_alert_constant.g_yes;
    
        l_dbg_msg := 'get sistolic pressure. i_episode: ' || i_episode || ' i_patient: ' || i_patient ||
                     'i_vital_sign: ' || i_vital_sign;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        IF i_pat_pregn_fetus IS NULL
        THEN
            BEGIN
                SELECT t.value
                  INTO l_sistolicpressure
                  FROM (SELECT t1.value, row_number() over(ORDER BY t1.dt_registry DESC) rn
                          FROM (SELECT vsr.value, vsr.id_vital_sign_read, vsr.dt_registry
                                  FROM vital_sign_read vsr
                                 INNER JOIN vital_sign_relation vsrel
                                    ON vsr.id_vital_sign = vsrel.id_vital_sign_detail
                                 WHERE vsr.id_patient = i_patient
                                   AND ((vsr.id_episode = i_episode) OR (vsr.id_episode IS NULL AND i_episode IS NULL))
                                   AND vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read
                                   AND vsr.dt_registry = nvl(i_dt_registry, vsr.dt_registry)
                                   AND vsrel.id_vital_sign_parent = i_vital_sign
                                   AND vsrel.rank = l_rank
                                   AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_conc
                                   AND vsrel.flg_available = pk_alert_constant.g_yes
                                   AND rownum > 0) t1
                         WHERE pk_delivery.check_vs_read_from_fetus(t1.id_vital_sign_read) = 0) t
                 WHERE t.rn = 1;
            
                l_sistolicpressure := pk_utils.to_str(i_number         => l_sistolicpressure,
                                                      i_decimal_symbol => i_decimal_symbol);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_sistolicpressure := NULL;
            END;
        
        ELSE
            BEGIN
                SELECT DISTINCT vsr.value
                  INTO l_sistolicpressure
                  FROM vital_sign_read vsr
                 INNER JOIN vital_sign_relation vsrel
                    ON vsr.id_vital_sign = vsrel.id_vital_sign_detail
                  JOIN vital_sign_pregnancy vsp
                    ON vsp.id_vital_sign_read = vsr.id_vital_sign_read
                  JOIN pat_pregn_fetus ppf
                    ON ppf.id_pat_pregnancy = vsp.id_pat_pregnancy
                   AND ppf.id_pat_pregn_fetus = i_pat_pregn_fetus
                   AND ppf.fetus_number = vsp.fetus_number
                 WHERE vsr.id_patient = i_patient
                   AND ((vsr.id_episode = i_episode) OR (vsr.id_episode IS NULL AND i_episode IS NULL))
                   AND vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read
                   AND vsr.dt_registry = nvl(i_dt_registry, vsr.dt_registry)
                   AND vsrel.id_vital_sign_parent = i_vital_sign
                   AND vsrel.rank = l_rank
                   AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_conc
                   AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 1
                   AND rownum = 1;
            
                l_sistolicpressure := pk_utils.to_str(i_number         => l_sistolicpressure,
                                                      i_decimal_symbol => i_decimal_symbol);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_sistolicpressure := NULL;
            END;
        END IF;
    
        l_dbg_msg := 'get diastolic pressure rank';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT MAX(vsrel.rank)
          INTO l_rank
          FROM vital_sign_relation vsrel
         WHERE vsrel.id_vital_sign_parent = i_vital_sign
           AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_conc
           AND vsrel.flg_available = pk_alert_constant.g_yes;
    
        l_dbg_msg := 'get diastolic pressure';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        IF i_pat_pregn_fetus IS NULL
        THEN
            BEGIN
                SELECT t.value
                  INTO l_diastolicpressure
                  FROM (SELECT t1.value, row_number() over(ORDER BY t1.dt_registry DESC) rn
                          FROM (SELECT vsr.value, vsr.id_vital_sign_read, vsr.dt_registry
                                  FROM vital_sign_read vsr
                                 INNER JOIN vital_sign_relation vsrel
                                    ON vsr.id_vital_sign = vsrel.id_vital_sign_detail
                                 WHERE vsr.id_patient = i_patient
                                   AND ((vsr.id_episode = i_episode) OR (vsr.id_episode IS NULL AND i_episode IS NULL))
                                   AND vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read
                                   AND vsr.dt_registry = nvl(i_dt_registry, vsr.dt_registry)
                                   AND vsrel.id_vital_sign_parent = i_vital_sign
                                   AND vsrel.rank = l_rank
                                   AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_conc
                                   AND vsrel.flg_available = pk_alert_constant.g_yes
                                   AND rownum > 0) t1
                         WHERE pk_delivery.check_vs_read_from_fetus(t1.id_vital_sign_read) = 0) t
                 WHERE t.rn = 1;
            
                l_diastolicpressure := pk_utils.to_str(i_number         => l_diastolicpressure,
                                                       i_decimal_symbol => i_decimal_symbol);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_diastolicpressure := NULL;
            END;
        ELSE
            BEGIN
                SELECT DISTINCT vsr.value
                  INTO l_diastolicpressure
                  FROM vital_sign_read vsr
                 INNER JOIN vital_sign_relation vsrel
                    ON vsr.id_vital_sign = vsrel.id_vital_sign_detail
                  JOIN vital_sign_pregnancy vsp
                    ON vsp.id_vital_sign_read = vsr.id_vital_sign_read
                  JOIN pat_pregn_fetus ppf
                    ON ppf.id_pat_pregnancy = vsp.id_pat_pregnancy
                   AND ppf.id_pat_pregn_fetus = i_pat_pregn_fetus
                   AND ppf.fetus_number = vsp.fetus_number
                 WHERE vsr.id_patient = i_patient
                   AND ((vsr.id_episode = i_episode) OR (vsr.id_episode IS NULL AND i_episode IS NULL))
                   AND vsr.dt_vital_sign_read_tstz = i_dt_vital_sign_read
                   AND vsr.dt_registry = nvl(i_dt_registry, vsr.dt_registry)
                   AND vsrel.id_vital_sign_parent = i_vital_sign
                   AND vsrel.rank = l_rank
                   AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_conc
                   AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 1
                   AND rownum = 1;
            
                l_diastolicpressure := pk_utils.to_str(i_number         => l_diastolicpressure,
                                                       i_decimal_symbol => i_decimal_symbol);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_diastolicpressure := NULL;
            END;
        END IF;
    
        IF l_sistolicpressure IS NULL
           AND l_diastolicpressure IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        RETURN nvl(s1 => l_sistolicpressure, s2 => '---') || '/' || nvl(s1 => l_diastolicpressure, s2 => '---');
    
    END get_bloodpressure_value;

    FUNCTION get_vsr_inst_um
    (
        i_institution       IN institution.id_institution%TYPE,
        i_vital_sign        IN vital_sign_read.id_vital_sign%TYPE,
        i_unit_measure      IN vital_sign_read.id_unit_measure%TYPE,
        i_vs_scales_element IN vital_sign_read.id_vs_scales_element%TYPE,
        i_software          IN software.id_software%TYPE
    ) RETURN vital_sign_read.id_unit_measure%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VSR_INST_UM';
        l_dbg_msg debug_msg;
    
        l_inst_um      vital_sign_read.id_unit_measure%TYPE;
        l_unit_measure vital_sign_read.id_unit_measure%TYPE;
    
    BEGIN
        l_dbg_msg := 'get vital sign unit measure to use';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        IF i_vs_scales_element IS NOT NULL
        THEN
            l_unit_measure := pk_vital_sign.get_vsse_um(i_vs_scales_element, pk_alert_constant.g_no);
        
        ELSIF i_unit_measure IS NULL
        THEN
            l_unit_measure := pk_vital_sign.c_without_um;
        
        ELSE
            l_inst_um := pk_vital_sign.get_vs_um_inst(i_vital_sign  => i_vital_sign,
                                                      i_institution => i_institution,
                                                      i_software    => i_software);
        
            IF NOT pk_unit_measure.are_convertible(i_unit_meas => i_unit_measure, i_unit_meas_def => l_inst_um)
            THEN
                l_unit_measure := i_unit_measure;
            
            ELSE
                l_unit_measure := l_inst_um;
            
            END IF;
        
        END IF;
    
        RETURN l_unit_measure;
    
    END get_vsr_inst_um;

    FUNCTION get_vsr_row
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vital_sign_read.id_unit_measure%TYPE DEFAULT pk_vital_sign.c_without_um
    ) RETURN vital_sign_read%ROWTYPE IS
        c_function_name CONSTANT obj_name := 'GET_VSR_ROW';
        l_dbg_msg debug_msg;
    
        l_vsr_row         vital_sign_read%ROWTYPE;
        l_vs_parent       vital_sign_relation.id_vital_sign_parent%TYPE;
        l_relation_domain vital_sign_relation.relation_domain%TYPE;
    
    BEGIN
        IF i_vital_sign_read IS NULL
        THEN
            RETURN l_vsr_row;
        END IF;
    
        l_dbg_msg := 'get vital sign record';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT vsr.*
          INTO l_vsr_row
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_read = i_vital_sign_read;
    
        l_vs_parent       := pk_vital_sign.get_vs_parent(i_vital_sign => l_vsr_row.id_vital_sign);
        l_relation_domain := pk_vital_sign.get_vs_relation_domain(i_vital_sign => l_vs_parent);
    
        CASE
            WHEN l_relation_domain = pk_alert_constant.g_vs_rel_sum THEN
                -- glasgow coma scale
                l_vsr_row.value           := pk_vital_sign.get_glasgowtotal_value(i_vital_sign         => l_vs_parent,
                                                                                  i_patient            => l_vsr_row.id_patient,
                                                                                  i_episode            => l_vsr_row.id_episode,
                                                                                  i_dt_vital_sign_read => l_vsr_row.dt_vital_sign_read_tstz);
                l_vsr_row.id_unit_measure := pk_vital_sign.c_without_um;
            
            WHEN l_relation_domain = pk_alert_constant.g_vs_rel_conc THEN
                -- blood pressures
                l_vsr_row.value := NULL;
            
            WHEN l_vsr_row.id_vs_scales_element IS NOT NULL THEN
                -- vital signs scales
                l_vsr_row.value := pk_vital_sign.get_vsse_value(i_vs_scales_element => l_vsr_row.id_vs_scales_element);
            
            WHEN l_vsr_row.id_vital_sign_desc IS NOT NULL THEN
                -- multichoices
                l_vsr_row.value := pk_vital_sign.get_vsd_order_val(i_vital_sign_desc => l_vsr_row.id_vital_sign_desc);
            
            WHEN i_inst_um != pk_vital_sign.c_without_um
                 OR l_vsr_row.id_unit_measure IS NOT NULL THEN
                -- numeric vital signs with unit measure
                l_dbg_msg := 'check if it is convertible to the vs_patient_ea unit measure. i_unit_meas: ' ||
                             l_vsr_row.id_unit_measure || ', i_unit_meas_def: ' || i_inst_um;
                pk_alertlog.log_info(text            => l_dbg_msg,
                                     object_name     => g_package_name,
                                     sub_object_name => c_function_name);
            
                IF l_vsr_row.id_unit_measure = pk_vital_sign.c_without_um
                   OR i_inst_um = pk_vital_sign.c_without_um
                THEN
                    IF l_vsr_row.id_unit_measure IS NULL
                    THEN
                        l_vsr_row.id_unit_measure := pk_vital_sign.c_without_um;
                    END IF;
                ELSE
                    IF NOT pk_unit_measure.are_convertible(i_unit_meas     => l_vsr_row.id_unit_measure,
                                                           i_unit_meas_def => i_inst_um)
                    THEN
                        pk_alert_exceptions.raise_error(error_name_in => 'CONFIGURATION ERROR: missing unit measure conversion formula in unit_measure_convert table for id_unit_measure1:' ||
                                                                         l_vsr_row.id_unit_measure ||
                                                                         ' and id_unit_measure2:' || i_inst_um);
                    END IF;
                
                    l_dbg_msg := 'convert the value to the vs_patient_ea unit measure';
                    pk_alertlog.log_info(text            => l_dbg_msg,
                                         object_name     => g_package_name,
                                         sub_object_name => c_function_name);
                    l_vsr_row.value := pk_unit_measure.get_unit_mea_conversion(i_value         => l_vsr_row.value,
                                                                               i_unit_meas     => l_vsr_row.id_unit_measure,
                                                                               i_unit_meas_def => i_inst_um);
                
                END IF;
            
            ELSE
                -- numeric vital signs without unit measure
                l_vsr_row.id_unit_measure := pk_vital_sign.c_without_um;
            
        END CASE;
    
        RETURN l_vsr_row;
    
    END get_vsr_row;

    FUNCTION is_lower
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vital_sign_read.id_unit_measure%TYPE,
        i_new_value       IN vital_sign_read.value%TYPE,
        i_new_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'IS_LOWER';
        l_dbg_msg debug_msg;
    
        l_vsr_row vital_sign_read%ROWTYPE;
    
    BEGIN
        IF i_vital_sign_read IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'get vital sign read row';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        l_vsr_row := pk_vital_sign.get_vsr_row(i_vital_sign_read => i_vital_sign_read, i_inst_um => i_inst_um);
    
        IF i_new_value IS NULL
           OR l_vsr_row.value IS NULL
        THEN
            pk_alert_exceptions.raise_error(error_name_in => 'comparison error');
        
        END IF;
    
        IF i_new_value < l_vsr_row.value
           OR (i_new_value = l_vsr_row.value AND i_new_dt_read > l_vsr_row.dt_vital_sign_read_tstz)
        THEN
            RETURN TRUE;
        
        END IF;
    
        RETURN FALSE;
    
    END is_lower;

    FUNCTION is_greater
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vital_sign_read.id_unit_measure%TYPE,
        i_new_value       IN vital_sign_read.value%TYPE,
        i_new_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'IS_GREATER';
        l_dbg_msg debug_msg;
    
        l_vsr_row vital_sign_read%ROWTYPE;
    
    BEGIN
        IF i_vital_sign_read IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'get vital sign read row';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        l_vsr_row := pk_vital_sign.get_vsr_row(i_vital_sign_read => i_vital_sign_read, i_inst_um => i_inst_um);
    
        IF i_new_value IS NULL
           OR l_vsr_row.value IS NULL
        THEN
            pk_alert_exceptions.raise_error(error_name_in => 'comparison error');
        
        END IF;
    
        IF i_new_value > l_vsr_row.value
           OR (i_new_value = l_vsr_row.value AND i_new_dt_read > l_vsr_row.dt_vital_sign_read_tstz)
        THEN
            RETURN TRUE;
        
        END IF;
    
        RETURN FALSE;
    
    END is_greater;

    FUNCTION is_older
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vital_sign_read.id_unit_measure%TYPE,
        i_new_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'IS_OLDER';
        l_dbg_msg debug_msg;
    
        l_vsr_row vital_sign_read%ROWTYPE;
    
    BEGIN
        IF i_vital_sign_read IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'get vital sign read row';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        l_vsr_row := pk_vital_sign.get_vsr_row(i_vital_sign_read => i_vital_sign_read, i_inst_um => i_inst_um);
    
        IF i_new_dt_read > l_vsr_row.dt_vital_sign_read_tstz
        THEN
            RETURN TRUE;
        
        END IF;
    
        RETURN FALSE;
    
    END is_older;

    FUNCTION has_same_date
    (
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_inst_um         IN vs_patient_ea.id_unit_measure%TYPE,
        i_new_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'HAS_SAME_DATE';
        l_dbg_msg debug_msg;
    
        l_vsr_row vital_sign_read%ROWTYPE;
    
    BEGIN
        IF i_vital_sign_read IS NULL
        THEN
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'get vital sign read row';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        l_vsr_row := pk_vital_sign.get_vsr_row(i_vital_sign_read => i_vital_sign_read, i_inst_um => i_inst_um);
    
        IF i_new_dt_read = l_vsr_row.dt_vital_sign_read_tstz
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN FALSE;
    
    END has_same_date;

    FUNCTION get_fst_vsr
    (
        i_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_visit        IN episode.id_visit%TYPE DEFAULT NULL
    ) RETURN vital_sign_read.id_vital_sign_read%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_FST_VSR';
        l_dbg_msg debug_msg;
    
        l_vital_sign_read vital_sign_read.id_vital_sign_read%TYPE;
    
    BEGIN
        l_dbg_msg := 'get first record for vital sign, unit measure and patient';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT ovsr.id_vital_sign_read
          INTO l_vital_sign_read
          FROM (SELECT t.id_vital_sign_read
                  FROM (SELECT /*+ use_nl(vsr vrel) */
                         vsr.id_vital_sign_read,
                         vsr.dt_vital_sign_read_tstz,
                         vsr.id_episode,
                         vsr.id_institution_read,
                         vsr.id_vital_sign,
                         vsr.id_unit_measure,
                         vsr.id_vs_scales_element,
                         vsr.id_software_read
                          FROM vital_sign_read vsr
                          LEFT OUTER JOIN vital_sign_relation vrel
                            ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                           AND vrel.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                           AND vrel.flg_available = pk_alert_constant.g_yes
                         WHERE vsr.id_vital_sign = i_vital_sign
                           AND vsr.id_patient = i_patient
                           AND vsr.flg_state = pk_alert_constant.g_active
                        UNION
                        SELECT /*+ use_nl(vsr vrel) */
                         vsr.id_vital_sign_read,
                         vsr.dt_vital_sign_read_tstz,
                         vsr.id_episode,
                         vsr.id_institution_read,
                         vsr.id_vital_sign,
                         vsr.id_unit_measure,
                         vsr.id_vs_scales_element,
                         vsr.id_software_read
                          FROM vital_sign_read vsr
                          LEFT OUTER JOIN vital_sign_relation vrel
                            ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                           AND vrel.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                           AND vrel.flg_available = pk_alert_constant.g_yes
                         WHERE vrel.id_vital_sign_parent = i_vital_sign
                           AND vsr.id_patient = i_patient
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND rownum > 0) t
                 WHERE (i_visit IS NULL OR i_visit = (SELECT pk_episode.get_id_visit(t.id_episode)
                                                        FROM dual))
                   AND pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read) = 0
                   AND pk_vital_sign.get_vsr_inst_um(t.id_institution_read,
                                                     t.id_vital_sign,
                                                     t.id_unit_measure,
                                                     t.id_vs_scales_element,
                                                     t.id_software_read) = i_unit_measure
                 ORDER BY t.dt_vital_sign_read_tstz ASC) ovsr
         WHERE rownum = 1;
    
        RETURN l_vital_sign_read;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_fst_vsr;

    PROCEDURE get_min_max_vsr
    (
        i_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_visit        IN episode.id_visit%TYPE DEFAULT NULL,
        o_min_vsr      OUT vital_sign_read.id_vital_sign_read%TYPE,
        o_max_vsr      OUT vital_sign_read.id_vital_sign_read%TYPE
    ) IS
        c_proc_name CONSTANT obj_name := 'GET_MIN_MAX_VSR';
        l_dbg_msg debug_msg;
    
        CURSOR vsr_cur
        (
            i_vs  IN vital_sign_read.id_vital_sign%TYPE,
            i_um  IN vital_sign_read.id_unit_measure%TYPE,
            i_pat IN vital_sign_read.id_patient%TYPE,
            i_vis IN episode.id_visit%TYPE DEFAULT NULL
        ) IS
            SELECT pvsr.id_vital_sign_read
              FROM (SELECT t.id_vital_sign_read,
                           rank() over(PARTITION BY t.dt_vital_sign_read_tstz ORDER BY t.id_vital_sign_read ASC) AS rank
                      FROM (SELECT /*+ use_nl(vsr vrel) */
                             vsr.id_vital_sign_read,
                             vsr.dt_vital_sign_read_tstz,
                             vsr.id_episode,
                             vsr.id_institution_read,
                             vsr.id_vital_sign,
                             vsr.id_unit_measure,
                             vsr.id_vs_scales_element,
                             vsr.id_software_read
                              FROM vital_sign_read vsr
                              LEFT OUTER JOIN vital_sign_relation vrel
                                ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                               AND vrel.relation_domain IN
                                   (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                               AND vrel.flg_available = pk_alert_constant.g_yes
                             WHERE vsr.id_vital_sign = i_vs
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND vsr.id_patient = i_pat
                            UNION
                            SELECT /*+ use_nl(vsr vrel) */
                             vsr.id_vital_sign_read,
                             vsr.dt_vital_sign_read_tstz,
                             vsr.id_episode,
                             vsr.id_institution_read,
                             vsr.id_vital_sign,
                             vsr.id_unit_measure,
                             vsr.id_vs_scales_element,
                             vsr.id_software_read
                              FROM vital_sign_read vsr
                              LEFT OUTER JOIN vital_sign_relation vrel
                                ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                               AND vrel.relation_domain IN
                                   (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                               AND vrel.flg_available = pk_alert_constant.g_yes
                             WHERE vrel.id_vital_sign_parent = i_vs
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND vsr.id_patient = i_pat
                               AND rownum > 0) t
                     WHERE (i_vis IS NULL OR i_vis = (SELECT pk_episode.get_id_visit(t.id_episode)
                                                        FROM dual))
                       AND pk_vital_sign.get_vsr_inst_um(t.id_institution_read,
                                                         t.id_vital_sign,
                                                         t.id_unit_measure,
                                                         t.id_vs_scales_element,
                                                         t.id_software_read) = i_um
                       AND pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read) = 0
                     ORDER BY t.dt_vital_sign_read_tstz ASC) pvsr
             WHERE pvsr.rank = 1;
    
        l_vsr_row vital_sign_read%ROWTYPE;
        l_min_val vital_sign_read.value%TYPE;
        l_max_val vital_sign_read.value%TYPE;
    
    BEGIN
        l_dbg_msg := 'get min and max record for vital sign, unit measure and patient';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_proc_name);
    
        o_min_vsr := NULL;
        o_max_vsr := NULL;
    
        FOR vc IN vsr_cur(i_vs => i_vital_sign, i_um => i_unit_measure, i_pat => i_patient, i_vis => i_visit)
        LOOP
            l_vsr_row := pk_vital_sign.get_vsr_row(i_vital_sign_read => vc.id_vital_sign_read,
                                                   i_inst_um         => i_unit_measure);
        
            IF o_min_vsr IS NULL
               AND o_max_vsr IS NULL
            THEN
                IF l_vsr_row.value IS NULL
                THEN
                    RETURN;
                END IF;
            
                o_min_vsr := l_vsr_row.id_vital_sign_read;
                l_min_val := l_vsr_row.value;
            
                o_max_vsr := vc.id_vital_sign_read;
                l_max_val := l_vsr_row.value;
            
            ELSE
                IF l_vsr_row.value < l_min_val
                THEN
                    o_min_vsr := l_vsr_row.id_vital_sign_read;
                    l_min_val := l_vsr_row.value;
                END IF;
            
                IF l_vsr_row.value > l_max_val
                THEN
                    o_max_vsr := vc.id_vital_sign_read;
                    l_max_val := l_vsr_row.value;
                END IF;
            END IF;
        END LOOP;
    
    END get_min_max_vsr;

    PROCEDURE get_lst_vsr
    (
        i_vital_sign   IN vital_sign_read.id_vital_sign%TYPE,
        i_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_visit        IN episode.id_visit%TYPE DEFAULT NULL,
        o_lst3_vsr     OUT vital_sign_read.id_vital_sign_read%TYPE,
        o_lst2_vsr     OUT vital_sign_read.id_vital_sign_read%TYPE,
        o_lst1_vsr     OUT vital_sign_read.id_vital_sign_read%TYPE
    ) IS
        c_proc_name CONSTANT obj_name := 'GET_LST_VSR';
        l_dbg_msg debug_msg;
    
        CURSOR vsr_cur
        (
            i_vs  IN vital_sign_read.id_vital_sign%TYPE,
            i_um  IN vital_sign_read.id_unit_measure%TYPE,
            i_pat IN vital_sign_read.id_patient%TYPE,
            i_vis IN episode.id_visit%TYPE DEFAULT NULL
        ) IS
            SELECT pvsr.id_vital_sign_read
              FROM (SELECT t.id_vital_sign_read,
                           rank() over(PARTITION BY t.dt_vital_sign_read_tstz ORDER BY t.id_vital_sign_read ASC) AS rank
                      FROM (SELECT /*+ use_nl(vsr vrel) */
                             vsr.id_vital_sign_read,
                             vsr.dt_vital_sign_read_tstz,
                             vsr.id_institution_read,
                             vsr.id_vital_sign,
                             vsr.id_unit_measure,
                             vsr.id_vs_scales_element,
                             vsr.id_software_read,
                             vsr.id_episode,
                             vrel.id_vital_sign_parent
                              FROM vital_sign_read vsr
                              LEFT OUTER JOIN vital_sign_relation vrel
                                ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                               AND vrel.relation_domain IN
                                   (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                               AND vrel.flg_available = pk_alert_constant.g_yes
                             WHERE vsr.id_patient = i_pat
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND vsr.id_vital_sign = i_vs
                            UNION
                            SELECT /*+ use_nl(vsr vrel) */
                             vsr.id_vital_sign_read,
                             vsr.dt_vital_sign_read_tstz,
                             vsr.id_institution_read,
                             vsr.id_vital_sign,
                             vsr.id_unit_measure,
                             vsr.id_vs_scales_element,
                             vsr.id_software_read,
                             vsr.id_episode,
                             vrel.id_vital_sign_parent
                              FROM vital_sign_read vsr
                              LEFT OUTER JOIN vital_sign_relation vrel
                                ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                               AND vrel.relation_domain IN
                                   (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                               AND vrel.flg_available = pk_alert_constant.g_yes
                             WHERE vsr.id_patient = i_pat
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND vrel.id_vital_sign_parent = i_vs
                               AND rownum > 0) t
                     WHERE pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read) = 0
                       AND pk_vital_sign.get_vsr_inst_um(t.id_institution_read,
                                                         t.id_vital_sign,
                                                         t.id_unit_measure,
                                                         t.id_vs_scales_element,
                                                         t.id_software_read) = i_um
                       AND (i_vis IS NULL OR i_vis = (SELECT pk_episode.get_id_visit(t.id_episode)
                                                        FROM dual))
                     ORDER BY t.dt_vital_sign_read_tstz DESC) pvsr
             WHERE pvsr.rank = 1
               AND rownum <= 3;
    
    BEGIN
        l_dbg_msg := 'get last three records for vital sign, unit measure and patient';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_proc_name);
    
        o_lst3_vsr := NULL;
        o_lst2_vsr := NULL;
        o_lst1_vsr := NULL;
    
        OPEN vsr_cur(i_vs => i_vital_sign, i_um => i_unit_measure, i_pat => i_patient, i_vis => i_visit);
    
        FETCH vsr_cur
            INTO o_lst1_vsr;
    
        FETCH vsr_cur
            INTO o_lst2_vsr;
    
        FETCH vsr_cur
            INTO o_lst3_vsr;
    
        CLOSE vsr_cur;
    
    END get_lst_vsr;

    FUNCTION vs_has_notes(i_vital_sign_notes IN vital_sign_notes.id_vital_sign_notes%TYPE) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'VS_HAS_NOTES';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'test if vital_sign_read has notes';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        RETURN CASE WHEN i_vital_sign_notes IS NULL THEN pk_alert_constant.g_no ELSE pk_alert_constant.g_yes END;
    
    END vs_has_notes;

    FUNCTION check_vs_notes(i_vs_read IN vital_sign_read.id_vital_sign_read%TYPE) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'CHECK_VS_NOTES';
        l_dbg_msg          debug_msg;
        l_vital_sign_notes vital_sign_notes.id_vital_sign_notes%TYPE;
    
    BEGIN
        l_dbg_msg := 'test if vital_sign_read has notes';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        SELECT vr.id_vital_sign_notes
          INTO l_vital_sign_notes
          FROM vital_sign_read vr
         WHERE vr.id_vital_sign_read = i_vs_read;
    
        RETURN CASE WHEN l_vital_sign_notes IS NULL THEN pk_alert_constant.g_no ELSE pk_alert_constant.g_yes END;
    
    END check_vs_notes;

    FUNCTION get_vs_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN vital_sign_read.id_patient%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_vital_sign         IN vital_sign_read.id_vital_sign%TYPE,
        i_value              IN vital_sign_read.value%TYPE,
        i_vs_unit_measure    IN vital_sign_read.id_unit_measure%TYPE,
        i_vital_sign_desc    IN vital_sign_read.id_vital_sign_desc%TYPE,
        i_vs_scales_element  IN vital_sign_read.id_vs_scales_element%TYPE,
        i_dt_vital_sign_read IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_ea_unit_measure    IN vital_sign_read.id_unit_measure%TYPE DEFAULT NULL,
        i_short_desc         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_decimal_symbol     IN sys_config.value%TYPE DEFAULT NULL,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'GET_VS_VALUE';
        l_dbg_msg debug_msg;
    
        l_decimal_symbol  sys_config.value%TYPE;
        l_relation_domain vital_sign_relation.relation_domain%TYPE;
        l_return          VARCHAR2(1000 CHAR);
    BEGIN
        IF i_decimal_symbol IS NOT NULL
        THEN
            l_decimal_symbol := i_decimal_symbol;
        ELSE
            l_dbg_msg := 'get sysconfig DECIMAL_SYMBOL';
            pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
            l_decimal_symbol := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                        i_prof_inst => i_prof.institution,
                                                        i_prof_soft => i_prof.software);
        END IF;
    
        l_relation_domain := get_vs_relation_domain(i_vital_sign => i_vital_sign);
    
        l_return := pk_vital_sign_core.get_vs_value(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_patient          => i_patient,
                                                    i_id_episode          => i_episode,
                                                    i_id_vital_sign       => i_vital_sign,
                                                    i_id_vital_sign_desc  => CASE
                                                                                 WHEN l_relation_domain IS NULL THEN
                                                                                  i_vital_sign_desc
                                                                                 ELSE
                                                                                  NULL
                                                                             END,
                                                    i_dt_vital_sign_read  => i_dt_vital_sign_read,
                                                    i_id_unit_measure_vsr => i_vs_unit_measure,
                                                    i_id_unit_measure_vsi => i_ea_unit_measure,
                                                    i_value               => i_value,
                                                    i_decimal_symbol      => l_decimal_symbol,
                                                    i_relation_domain     => l_relation_domain,
                                                    i_dt_registry         => i_dt_registry,
                                                    i_short_desc          => i_short_desc);
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_vs_value;

    /**************************************************************************
     * Get list of vital signs configured for instit/soft/flg_view            *
     * Based on pk_vital_sign.get_vs_header.                                  *
     *                                                                        *
     * @param i_lang                   Preferred language ID for this         *
     *                                 professional                           *
     * @param i_prof                   Object (professional ID,               *
     *                                 institution ID, software ID)           *
     * @param i_flg_view               View mode                              *
     * @param i_institution            Institution id                         *
     * @param i_software               Software id                            *
     * @param i_dt_end                 Date end                               *
     *                                                                        *
     * @return                         Cursor with vital signs structure      *
     *                                                                        *
     * @author                         Gustavo Serrano                        *
     * @version                        2.6.1                                  *
     * @since                          08-Fev-2011                            *
    **************************************************************************/
    FUNCTION tf_get_vs_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_view    IN vs_soft_inst.flg_view%TYPE,
        i_institution IN vs_soft_inst.id_institution%TYPE,
        i_software    IN vs_soft_inst.id_software%TYPE,
        i_dt_end      IN st_varchar2_200,
        i_patient     IN vital_sign_read.id_patient%TYPE
    ) RETURN t_coll_vs_header DETERMINISTIC
        PIPELINED IS
        l_function_name CONSTANT VARCHAR2(30) := 'tf_get_vs_header';
        l_rec_vs_header t_rec_vs_header;
        l_error         t_error_out;
        l_dbg_msg       debug_msg;
        l_age           vital_sign_unit_measure.age_min%TYPE;
    BEGIN
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        l_dbg_msg := 'GET CURSOR o_vs_header';
        FOR l_rec_vs_header IN (SELECT vsi.id_vital_sign,
                                       (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                                   i_prof            => i_prof,
                                                                                   i_id_vital_sign   => vsi.id_vital_sign,
                                                                                   i_id_unit_measure => vsi.id_unit_measure,
                                                                                   i_id_institution  => vsi.id_institution,
                                                                                   i_id_software     => vsi.id_software,
                                                                                   i_age             => l_age)
                                          FROM dual) val_min,
                                       (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                                   i_prof            => i_prof,
                                                                                   i_id_vital_sign   => vsi.id_vital_sign,
                                                                                   i_id_unit_measure => vsi.id_unit_measure,
                                                                                   i_id_institution  => vsi.id_institution,
                                                                                   i_id_software     => vsi.id_software,
                                                                                   i_age             => l_age)
                                          FROM dual) val_max,
                                       vsi.rank,
                                       vsi.rank_conc,
                                       vsi.id_vital_sign_parent,
                                       vsi.relation_type,
                                       (SELECT pk_vital_sign_core.get_vsum_format_num(i_lang            => i_lang,
                                                                                      i_prof            => i_prof,
                                                                                      i_id_vital_sign   => vsi.id_vital_sign,
                                                                                      i_id_unit_measure => vsi.id_unit_measure,
                                                                                      i_id_institution  => vsi.id_institution,
                                                                                      i_id_software     => vsi.id_software,
                                                                                      i_age             => l_age)
                                          FROM dual) format_num,
                                       vsi.flg_fill_type,
                                       vsi.flg_sum,
                                       vsi.name_vs,
                                       vsi.desc_unit_measure,
                                       vsi.id_unit_measure,
                                       i_dt_end,
                                       vsi.flg_view,
                                       vsi.id_institution,
                                       vsi.id_software
                                
                                  FROM ( -- Vital signs configured for a view
                                        SELECT vsi.id_vital_sign,
                                                vsi.rank,
                                                NULL AS rank_conc,
                                                vsrel.id_vital_sign_parent,
                                                vsrel.relation_domain AS relation_type,
                                                CASE (SELECT COUNT(1)
                                                    FROM vital_sign_relation vrpar
                                                   WHERE vsi.id_vital_sign = vrpar.id_vital_sign_parent
                                                     AND vrpar.relation_domain = pk_alert_constant.g_vs_rel_sum
                                                     AND vrpar.flg_available = pk_alert_constant.g_yes)
                                                    WHEN 0 THEN
                                                     vs.flg_fill_type
                                                    ELSE
                                                     'X'
                                                END AS flg_fill_type,
                                                CASE vsrel.relation_domain
                                                    WHEN pk_alert_constant.g_vs_rel_sum THEN
                                                     pk_alert_constant.g_yes
                                                    ELSE
                                                     pk_alert_constant.g_no
                                                END AS flg_sum,
                                                pk_translation.get_translation(i_lang, vs.code_vital_sign) AS name_vs,
                                                pk_translation.get_translation(i_lang, um.code_unit_measure) AS desc_unit_measure,
                                                vsi.id_unit_measure,
                                                vsi.flg_view,
                                                vsi.id_institution,
                                                vsi.id_software
                                        
                                          FROM vs_soft_inst vsi
                                        
                                         INNER JOIN vital_sign vs
                                            ON vsi.id_vital_sign = vs.id_vital_sign
                                           AND vs.flg_available = pk_alert_constant.g_yes
                                        
                                          LEFT OUTER JOIN unit_measure um
                                            ON vsi.id_unit_measure = um.id_unit_measure
                                           AND um.flg_available = pk_alert_constant.g_yes
                                        
                                          LEFT OUTER JOIN vital_sign_relation vsrel
                                            ON vsi.id_vital_sign = vsrel.id_vital_sign_detail
                                           AND vsrel.flg_available = pk_alert_constant.g_yes
                                           AND vsrel.relation_domain IN
                                               (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                                         WHERE vsi.id_software = i_software
                                           AND vsi.id_institution = i_institution
                                              -- ALERT-154864 - M�rio Mineiro - Changed because Periodic Observation, when flg_view is null present all.                                          
                                              -- AND (i_flg_view IS NULL OR vsi.flg_view = i_flg_view)
                                           AND vsi.flg_view = decode(i_flg_view, NULL, vsi.flg_view, i_flg_view)
                                        
                                        UNION ALL
                                        
                                        -- Details (vital signs chidren) of vital signs (blood pressures) configured for a view
                                        SELECT vsrel.id_vital_sign_detail AS id_vital_sign,
                                                vsi.rank,
                                                vsrel.rank AS rank_conc,
                                                vsrel.id_vital_sign_parent,
                                                vsrel.relation_domain AS relation_type,
                                                vs.flg_fill_type,
                                                pk_alert_constant.g_no AS flg_sum,
                                                pk_translation.get_translation(i_lang, vs.code_vital_sign) AS name_vs,
                                                pk_translation.get_translation(i_lang, um.code_unit_measure) AS desc_unit_measure,
                                                vsi.id_unit_measure,
                                                vsi.flg_view,
                                                vsi.id_institution,
                                                vsi.id_software
                                        
                                          FROM (SELECT vsi.id_vital_sign,
                                                        vsi.rank,
                                                        vsi.id_unit_measure,
                                                        vsi.id_institution,
                                                        vsi.id_software,
                                                        vsi.flg_view
                                                   FROM vs_soft_inst vsi
                                                  INNER JOIN vital_sign vs
                                                     ON vsi.id_vital_sign = vs.id_vital_sign
                                                    AND vs.flg_available = pk_alert_constant.g_yes
                                                  WHERE vsi.id_software = i_software
                                                    AND vsi.id_institution = i_institution
                                                       -- ALERT-154864 - M�rio Mineiro - Changed because Periodic Observation, when flg_view is null present all.                                                  
                                                       --    AND (i_flg_view IS NULL OR vsi.flg_view = i_flg_view)
                                                    AND vsi.flg_view = decode(i_flg_view, NULL, vsi.flg_view, i_flg_view)) vsi
                                        
                                         INNER JOIN vital_sign_relation vsrel
                                            ON vsi.id_vital_sign = vsrel.id_vital_sign_parent
                                           AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_conc
                                           AND vsrel.flg_available = pk_alert_constant.g_yes
                                        
                                         INNER JOIN vital_sign vs
                                            ON vsrel.id_vital_sign_detail = vs.id_vital_sign
                                           AND vs.flg_available = pk_alert_constant.g_yes
                                        
                                          LEFT OUTER JOIN unit_measure um
                                            ON vsi.id_unit_measure = um.id_unit_measure
                                           AND um.flg_available = pk_alert_constant.g_yes
                                        
                                        ) vsi
                                
                                 ORDER BY vsi.rank ASC,
                                          translate(upper(name_vs),
                                                    '������������������������ ',
                                                    'AEIOUAEIOUAEIOUAOCAEIOUN%'))
        LOOP
            PIPE ROW(l_rec_vs_header);
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN;
    END tf_get_vs_header;

    /************************************************************************************************************
    * This function returns all the vital signs for a specific view and its details.
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional, institution and software id's
    * @param      i_patient         Patient id
    * @param      i_episode         Episode id
    * @param      i_flg_view        Vital signs view
    * @param      o_sign_v          Output cursor
    * @param      o_dt_ini          Date from which it is possible to register vital signs
    * @param      o_dt_end          Date as far it is possible to register vital signs
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2010/11/10
    ************************************************************************************************************/
    FUNCTION get_vs_header
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT t_cur_vs_header,
        o_dt_ini   OUT VARCHAR2,
        o_dt_end   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_VS_HEADER';
        l_dbg_msg debug_msg;
    
        l_confs       PLS_INTEGER;
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
    
    BEGIN
        l_dbg_msg := 'CALL TO GET_VS_LIMIT_DATES';
        IF NOT get_vs_date_limits(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  i_patient           => i_patient,
                                  i_episode           => i_episode,
                                  i_id_monitorization => NULL,
                                  o_dt_ini            => o_dt_ini,
                                  o_dt_end            => o_dt_end,
                                  o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_dbg_msg := 'COUNT VITAL SIGN CONFS FOR SOFTWARE AND INSTITUTION';
        IF i_flg_view IS NULL
        THEN
            l_software    := i_prof.software;
            l_institution := i_prof.institution;
        ELSE
            SELECT COUNT(1)
              INTO l_confs
              FROM vs_soft_inst vsi
             INNER JOIN vital_sign vs
                ON vsi.id_vital_sign = vs.id_vital_sign
               AND vs.flg_available = pk_alert_constant.g_yes
             WHERE vsi.id_software = i_prof.software
               AND vsi.id_institution = i_prof.institution
               AND vsi.flg_view = i_flg_view;
        
            IF l_confs > 0
            THEN
                l_software    := i_prof.software;
                l_institution := i_prof.institution;
            END IF;
        END IF;
        l_dbg_msg := 'OPEN CURSOR O_SIGN_V';
        OPEN o_sign_v FOR
            SELECT id_vital_sign,
                   val_min,
                   val_max,
                   rank,
                   rank_conc,
                   id_vital_sign_parent,
                   relation_type,
                   format_num,
                   flg_fill_type,
                   flg_sum,
                   name_vs,
                   desc_unit_measure,
                   id_unit_measure,
                   dt_server,
                   flg_view,
                   id_institution,
                   id_software
              FROM TABLE(pk_vital_sign.tf_get_vs_header(i_lang,
                                                        i_prof,
                                                        i_flg_view,
                                                        l_institution,
                                                        l_software,
                                                        o_dt_end,
                                                        i_patient));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_sign_v);
            o_dt_ini := NULL;
            o_dt_end := NULL;
            RETURN FALSE;
        
    END get_vs_header;

    /************************************************************************************************************
    * This function returns all the vital signs for a specific view and its details.
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional, institution and software id's
    * @param      i_flg_view        Vital signs view
    * @param      o_sign_v          Output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/27
    ************************************************************************************************************/
    FUNCTION get_vs_header
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT t_cur_vs_header,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dummy VARCHAR2(200 CHAR);
    
    BEGIN
        RETURN get_vs_header(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_patient  => NULL,
                             i_episode  => NULL,
                             i_flg_view => i_flg_view,
                             o_sign_v   => o_sign_v,
                             o_dt_ini   => l_dummy,
                             o_dt_end   => l_dummy,
                             o_error    => o_error);
    
    END get_vs_header;

    /**********************************************************************************************
    * Obter lista dos profissionais da institui��o
    *
    * @param i_lang                   Language id
    * @param i_prof                   professional, software and institution ids
    * @param i_id_vital_sign          vital sign id
    * @param i_patient                patient id
    * @param i_dt_max_reg             Max date that is considered to return results
    * @param o_value_desc             Vital Sign description
    * @param o_dt_vital_sign_read     Date of regestry of this vital sign
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Lu�s Maia
    * @since                          18-Nov-2011
    **********************************************************************************************/
    FUNCTION get_pat_lst_vsr_value
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_patient            IN vital_signs_ea.id_patient%TYPE,
        i_dt_max_reg         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_value_desc         OUT st_varchar2_200,
        o_dt_vital_sign_read OUT vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_LST_VSR_VALUE';
        l_dbg_msg debug_msg;
        --
        l_short_desc     VARCHAR2(1) := pk_alert_constant.g_no;
        l_decimal_symbol sys_config.value%TYPE;
    BEGIN
        l_dbg_msg := 'get sysconfig DECIMAL_SYMBOL';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                    i_prof_inst => i_prof.institution,
                                                    i_prof_soft => i_prof.software);
        --
        l_dbg_msg := 'OPEN CURSOR O_LST_IMC';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_patient            => tmp.id_patient,
                                          i_episode            => tmp.id_episode,
                                          i_vital_sign         => tmp.id_vital_sign,
                                          i_value              => tmp.value,
                                          i_vs_unit_measure    => tmp.id_unit_measure,
                                          i_vital_sign_desc    => tmp.id_vital_sign_desc,
                                          i_vs_scales_element  => tmp.id_vs_scales_element,
                                          i_dt_vital_sign_read => tmp.dt_vital_sign_read_tstz,
                                          i_ea_unit_measure    => tmp.id_unit_measure,
                                          i_short_desc         => l_short_desc,
                                          i_decimal_symbol     => l_decimal_symbol,
                                          i_dt_registry        => tmp.dt_registry) || ' ' ||
               pk_vital_sign.get_vital_sign_unit_measure(i_lang, tmp.id_unit_measure, tmp.id_vs_scales_element) AS vs_description,
               tmp.dt_vital_sign_read_tstz
          INTO o_value_desc, o_dt_vital_sign_read
          FROM (SELECT vsr2.*
                  FROM (SELECT vsr.id_patient,
                               vsr.id_episode,
                               vsr.id_vital_sign,
                               vsr.value,
                               vsr.id_unit_measure,
                               vsr.id_vital_sign_desc,
                               vsr.id_vs_scales_element,
                               vsr.dt_vital_sign_read_tstz,
                               vsr.dt_registry
                          FROM vital_sign_read vsr
                         WHERE vsr.id_vital_sign = i_id_vital_sign
                           AND vsr.id_patient = i_patient
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.dt_vital_sign_read_tstz <= nvl(i_dt_max_reg, current_timestamp)
                         ORDER BY vsr.dt_vital_sign_read_tstz DESC) vsr2
                 WHERE rownum = 1) tmp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_lst_vsr_value;

    /**********************************************************************************************
    **********************************************************************************************/
    FUNCTION get_pat_vs_value_unit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_vital_sign   IN vital_sign.id_vital_sign%TYPE,
        i_patient         IN vital_signs_ea.id_patient%TYPE,
        i_dt_max_reg      IN vital_sign_read.dt_vital_sign_read_tstz%TYPE DEFAULT NULL,
        o_vs_value        OUT VARCHAR2,
        o_vs_unit_measure OUT NUMBER,
        o_vs_um_desc      OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_VS_VALUE_UNIT';
        l_dbg_msg debug_msg;
        --
        l_short_desc     VARCHAR2(1) := pk_alert_constant.g_no;
        l_decimal_symbol sys_config.value%TYPE;
    BEGIN
        l_dbg_msg := 'get sysconfig DECIMAL_SYMBOL';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                    i_prof_inst => i_prof.institution,
                                                    i_prof_soft => i_prof.software);
        --
        l_dbg_msg := 'OPEN CURSOR O_LST_IMC';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_patient            => tmp.id_patient,
                                          i_episode            => tmp.id_episode,
                                          i_vital_sign         => tmp.id_vital_sign,
                                          i_value              => tmp.value,
                                          i_vs_unit_measure    => tmp.id_unit_measure,
                                          i_vital_sign_desc    => tmp.id_vital_sign_desc,
                                          i_vs_scales_element  => tmp.id_vs_scales_element,
                                          i_dt_vital_sign_read => tmp.dt_vital_sign_read_tstz,
                                          i_ea_unit_measure    => tmp.id_unit_measure,
                                          i_short_desc         => l_short_desc,
                                          i_decimal_symbol     => l_decimal_symbol,
                                          i_dt_registry        => tmp.dt_registry) vs_value,
               tmp.id_unit_measure vs_unit_measure,
               pk_vital_sign.get_vital_sign_unit_measure(i_lang, tmp.id_unit_measure, tmp.id_vs_scales_element) vs_um_desc
          INTO o_vs_value, o_vs_unit_measure, o_vs_um_desc
          FROM (SELECT vsr2.*
                  FROM (SELECT vsr.id_patient,
                               vsr.id_episode,
                               vsr.id_vital_sign,
                               vsr.value,
                               vsr.id_unit_measure,
                               vsr.id_vital_sign_desc,
                               vsr.id_vs_scales_element,
                               vsr.dt_vital_sign_read_tstz,
                               vsr.dt_registry
                          FROM vital_sign_read vsr
                         WHERE vsr.id_vital_sign = i_id_vital_sign
                           AND vsr.id_patient = i_patient
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.dt_vital_sign_read_tstz <= nvl(i_dt_max_reg, current_timestamp)
                         ORDER BY vsr.dt_vital_sign_read_tstz DESC) vsr2
                 WHERE rownum = 1) tmp;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_vs_value        := NULL;
            o_vs_unit_measure := NULL;
            o_vs_um_desc      := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_vs_value_unit;

    /**********************************************************************************************
    * Obter lista dos profissionais da institui��o
    *
    * @param i_lang                   Language id
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param o_lst_imc                Last active values of Weight and Height Vital Signs
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Lu�s Maia
    * @since                          29-Set-2011
    **********************************************************************************************/
    FUNCTION get_pat_lst_imc_values
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN vital_signs_ea.id_patient%TYPE,
        o_lst_imc OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_PAT_LST_IMC_VALUES';
        l_dbg_msg debug_msg;
        --
        l_id_vital_sign_weight vital_sign.id_vital_sign%TYPE := pk_sysconfig.get_config(i_code_cf => 'VITAL_SIGN_WEIGHT',
                                                                                        i_prof    => i_prof);
        l_id_vital_sign_height vital_sign.id_vital_sign%TYPE := pk_sysconfig.get_config(i_code_cf => 'VITAL_SIGN_HEIGHT',
                                                                                        i_prof    => i_prof);
    
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    BEGIN
        l_dbg_msg := 'OPEN CURSOR O_LST_IMC';
        OPEN o_lst_imc FOR
            SELECT t.id_episode,
                   t.id_patient,
                   t.id_visit,
                   t.id_vital_sign,
                   pk_translation.get_translation(i_lang, t.code_vital_sign) vital_sign_desc,
                   pk_vital_sign.get_vital_sign_unit_measure(i_lang, t.id_unit_measure, t.id_vs_scales_element) unit_measure_desc,
                   pk_date_utils.date_send_tsz(i_lang, t.dt_vital_sign_read, i_prof) dt_vital_sign_read_str,
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                              i_prof               => i_prof,
                                              i_patient            => t.id_patient,
                                              i_episode            => t.id_episode,
                                              i_vital_sign         => t.id_vital_sign,
                                              i_value              => t.vital_sign_val,
                                              i_vs_unit_measure    => t.id_unit_measure,
                                              i_vital_sign_desc    => t.id_vital_sign_desc,
                                              i_vs_scales_element  => t.id_vs_scales_element,
                                              i_dt_vital_sign_read => t.dt_vital_sign_read,
                                              i_ea_unit_measure    => t.id_unit_measure,
                                              i_short_desc         => pk_alert_constant.g_no,
                                              i_decimal_symbol     => l_decimal_symbol,
                                              i_dt_registry        => t.dt_registry) vital_sign_value,
                   t.id_prof_read,
                   t.intern_name_vital_sign
              FROM (SELECT vse.id_episode,
                           vse.id_patient,
                           vse.id_visit,
                           vs.id_vital_sign,
                           vs.code_vital_sign,
                           um.code_unit_measure,
                           vse.dt_vital_sign_read,
                           vse.value vital_sign_val,
                           vse.id_prof_read,
                           vse.id_vital_sign_desc,
                           vse.id_unit_measure,
                           vse.id_vs_scales_element,
                           vs.intern_name_vital_sign,
                           vsr.dt_registry,
                           row_number() over(PARTITION BY vs.id_vital_sign ORDER BY vs.id_vital_sign, vse.dt_vital_sign_read DESC NULLS LAST) rn
                      FROM vital_signs_ea vse
                     INNER JOIN vital_sign vs
                        ON (vs.id_vital_sign = vse.id_vital_sign)
                      JOIN vital_sign_read vsr
                        ON vsr.id_vital_sign_read = vse.id_vital_sign_read
                      LEFT JOIN unit_measure um
                        ON (um.id_unit_measure = vse.id_unit_measure)
                     WHERE vse.id_vital_sign IN (l_id_vital_sign_weight, l_id_vital_sign_height)
                       AND vse.flg_state = pk_alert_constant.g_active
                       AND vse.id_patient = i_patient) t
             WHERE t.rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_lst_imc);
            RETURN FALSE;
    END get_pat_lst_imc_values;

    FUNCTION get_vital_signs
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN vital_signs_ea.id_patient%TYPE,
        i_visit    IN vital_signs_ea.id_visit%TYPE DEFAULT NULL,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_EPIS_VITAL_SIGN';
        l_dbg_msg debug_msg;
    
    BEGIN
        l_dbg_msg := 'OPEN CURSOR O_SIGN_V';
        OPEN o_sign_v FOR
            SELECT vs.*
              FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang, i_prof, i_patient, i_visit, i_flg_view)) vs;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_sign_v);
            RETURN FALSE;
        
    END get_vital_signs;
    --
    FUNCTION get_epis_vital_sign
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN get_vital_signs(i_lang     => i_lang,
                               i_patient  => pk_episode.get_id_patient(i_episode => i_episode),
                               i_visit    => pk_episode.get_id_visit(i_episode => i_episode),
                               i_prof     => i_prof,
                               i_flg_view => i_flg_view,
                               o_sign_v   => o_sign_v,
                               o_error    => o_error);
    END get_epis_vital_sign;
    --
    FUNCTION get_pat_vital_sign
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN vital_sign_read.id_patient%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_sign_v   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_vital_signs(i_lang     => i_lang,
                               i_patient  => i_patient,
                               i_prof     => i_prof,
                               i_flg_view => i_flg_view,
                               o_sign_v   => o_sign_v,
                               o_error    => o_error);
    END get_pat_vital_sign;

    --

    FUNCTION get_pat_vs_grid_list
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN vital_sign_read.id_patient%TYPE,
        i_prof       IN profissional,
        i_flg_view   IN vs_soft_inst.flg_view%TYPE,
        i_flg_screen IN VARCHAR2,
        o_time       OUT pk_types.cursor_type,
        o_sign_v     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_vital_sign_core.get_vs_grid_list(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_flg_view   => i_flg_view,
                                                   i_flg_screen => i_flg_screen,
                                                   i_scope      => i_patient,
                                                   i_scope_type => pk_alert_constant.g_scope_type_patient,
                                                   o_time       => o_time,
                                                   o_sign_v     => o_sign_v,
                                                   o_error      => o_error);
    END get_pat_vs_grid_list;
    --
    FUNCTION get_biometric_grid_list
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN vital_sign_read.id_patient%TYPE,
        i_prof       IN profissional,
        i_flg_screen IN VARCHAR2,
        o_time       OUT pk_types.cursor_type,
        o_bio        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_vital_sign_core.get_vs_grid_list(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_flg_view   => pk_alert_constant.g_vs_view_v3,
                                                   i_flg_screen => i_flg_screen,
                                                   i_scope      => i_patient,
                                                   i_scope_type => pk_alert_constant.g_scope_type_patient,
                                                   o_time       => o_time,
                                                   o_sign_v     => o_bio,
                                                   o_error      => o_error);
    END get_biometric_grid_list;

    /************************************************************************************************************
    * This function returns the concatenation of a Vital Sign to be used with copy/paste tool
    *
    * @param      i_lang                      Prefered language from professional
    * @param      i_prof                      professional (identifier, institution, software)
    * @param      i_name_vs                   Vital Sign name
    * @param      i_value_desc                Value Description
    * @param      i_desc_unit_measure         Unit Measure Description
    * @param      i_dt_registry               Registry Date/Time
    *
    * @return                                 String with the format of Vital Signs to copy/paste
    *
    * @author                                 Ant�nio Neto
    * @version                                2.6.1.2
    * @since                                  02-Aug-2011
    ************************************************************************************************************/
    FUNCTION get_vs_copy_paste
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_name_vs           IN VARCHAR2,
        i_value_desc        IN VARCHAR2,
        i_desc_unit_measure IN VARCHAR2,
        i_dt_registry       IN vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) RETURN VARCHAR2 IS
        g_new_line CONSTANT VARCHAR2(2 CHAR) := chr(13) || chr(10);
        g_new_item CONSTANT VARCHAR2(4 CHAR) := ': ';
        g_space    CONSTANT VARCHAR2(1 CHAR) := ' ';
    BEGIN
        RETURN pk_date_utils.date_chr_short_read_tsz(i_lang => i_lang,
                                                     i_date => i_dt_registry,
                                                     i_inst => i_prof.institution,
                                                     i_soft => i_prof.software) || g_new_line || --
        g_space || g_space || g_space || g_space || --
        pk_string_utils.surround(pk_date_utils.date_char_hour_tsz(i_lang => i_lang,
                                                                  i_date => i_dt_registry,
                                                                  i_inst => i_prof.institution,
                                                                  i_soft => i_prof.software),
                                 pk_string_utils.g_pattern_parenthesis) || g_space --
        || i_name_vs || g_new_item || i_value_desc || --
        CASE WHEN i_desc_unit_measure IS NOT NULL THEN g_space || i_desc_unit_measure ELSE '' END;
    END get_vs_copy_paste;

    --

    FUNCTION get_pat_vs_grid_all
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN vital_sign_read.id_patient%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_val_vs   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_vital_sign_core.get_vs_grid_new(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_flg_view   => i_flg_view,
                                                  i_scope      => i_patient,
                                                  i_scope_type => pk_alert_constant.g_scope_type_patient,
                                                  o_val_vs     => o_val_vs,
                                                  o_error      => o_error);
    END get_pat_vs_grid_all;
    --
    FUNCTION get_biometric_grid_all
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN vital_sign_read.id_patient%TYPE,
        i_prof    IN profissional,
        o_val_bio OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_vital_sign_core.get_vs_grid_new(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_flg_view   => pk_alert_constant.g_vs_view_v3,
                                                  i_scope      => i_patient,
                                                  i_scope_type => pk_alert_constant.g_scope_type_patient,
                                                  o_val_vs     => o_val_bio,
                                                  o_error      => o_error);
    END get_biometric_grid_all;
    --
    FUNCTION get_epis_vs_grid_val
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN vital_sign_read.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_val_vs   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_vital_sign_core.get_vs_grid_new(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_flg_view   => i_flg_view,
                                                  i_scope      => pk_episode.get_id_visit(i_episode => i_episode),
                                                  i_scope_type => pk_alert_constant.g_scope_type_visit,
                                                  o_val_vs     => o_val_vs,
                                                  o_error      => o_error);
    END get_epis_vs_grid_val;
    --
    FUNCTION get_pat_vs_grid_val
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN vital_sign_read.id_patient%TYPE,
        i_prof     IN profissional,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        o_val_vs   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_vital_sign_core.get_vs_grid_new(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_flg_view    => i_flg_view,
                                                  i_all_details => pk_alert_constant.g_no,
                                                  i_scope       => i_patient,
                                                  i_scope_type  => pk_alert_constant.g_scope_type_patient,
                                                  o_val_vs      => o_val_vs,
                                                  o_error       => o_error);
    END get_pat_vs_grid_val;
    --
    FUNCTION get_biometric_graph
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN vital_sign_read.id_patient%TYPE,
        i_prof    IN profissional,
        o_val_bio OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_vital_sign_core.get_vs_grid_new(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_flg_view    => pk_alert_constant.g_vs_view_v3,
                                                  i_all_details => pk_alert_constant.g_yes,
                                                  i_scope       => i_patient,
                                                  i_scope_type  => pk_alert_constant.g_scope_type_patient,
                                                  o_val_vs      => o_val_bio,
                                                  o_error       => o_error);
    END get_biometric_graph;

    /************************************************************************************************************
    * This function returns the vital sign scale id of a vital sign scale element 
    *
    * @param      i_vs_scales_element      Vital sign scale element id
    *
    * @return     Vital sign scale id
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/21
    ************************************************************************************************************/
    FUNCTION get_vs_scale(i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE)
        RETURN vital_sign_scales.id_vital_sign_scales%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VS_SCALE';
        l_dbg_msg debug_msg;
    
        l_id_vs_scale vital_sign_scales_element.id_vital_sign_scales%TYPE;
    
    BEGIN
        IF i_vs_scales_element IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get vital sign scale id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT vsse.id_vital_sign_scales
          INTO l_id_vs_scale
          FROM vital_sign_scales_element vsse
         WHERE vsse.id_vs_scales_element = i_vs_scales_element;
    
        RETURN l_id_vs_scale;
    
    END get_vs_scale;
    /************************************************************************************************************
    * This function returns the maximum value to a vital sign that uses a scale
    *
    * @param      i_vs_scales_element      Vital sign scale element id
    *
    * @return     Vital sign max value
    *
    * @author     Jos?Silva
    * @version    2.5
    * @since      2011/10/07
    ************************************************************************************************************/
    FUNCTION get_vs_scale_max_value(i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE)
        RETURN vital_sign_scales.id_vital_sign_scales%TYPE IS
        c_function_name CONSTANT obj_name := 'GET_VS_SCALE_MAX_VALUE';
        l_dbg_msg debug_msg;
    
        l_max_value vital_sign_scales_element.max_value%TYPE;
    
    BEGIN
        IF i_vs_scales_element IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get vital sign scale id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT vsse.max_value
          INTO l_max_value
          FROM vital_sign_scales_element vsse
         WHERE vsse.id_vs_scales_element = i_vs_scales_element
              -- scales filled with description values shouldn appear in the vital signs graph
           AND vsse.id_vital_sign_desc IS NULL;
    
        RETURN l_max_value;
    
    END get_vs_scale_max_value;

    FUNCTION get_vs_scale_min_value(i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE)
        RETURN vital_sign_scales.id_vital_sign_scales%TYPE IS
        c_function_name CONSTANT obj_name := 'get_vs_scale_MIN_value';
        l_dbg_msg debug_msg;
    
        l_min_value vital_sign_scales_element.min_value%TYPE;
    
    BEGIN
        IF i_vs_scales_element IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get vital sign scale id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT vsse.min_value
          INTO l_min_value
          FROM vital_sign_scales_element vsse
         WHERE vsse.id_vs_scales_element = i_vs_scales_element
              -- scales filled with description values shouldn appear in the vital signs graph
           AND vsse.id_vital_sign_desc IS NULL;
    
        RETURN l_min_value;
    
    END get_vs_scale_min_value;
    /************************************************************************************************************
    * This function returns the vital sign scale short description of a vital sign scale element 
    *
    * @param      i_lang                   Prefered language
    * @param      i_vs_scales_element      Vital sign scale element id
    *
    * @return     Vital sign scale short description
    *
    * @author     Paulo Fonseca
    * @version    2.5
    * @since      2009/08/21
    ************************************************************************************************************/
    FUNCTION get_vs_scale_shortdesc
    (
        i_lang              IN language.id_language%TYPE,
        i_vs_scales_element IN vital_sign_read.id_vs_scales_element%TYPE
    ) RETURN VARCHAR2 IS
        c_function_name CONSTANT obj_name := 'GET_VS_SCALE_SHORTDESC';
        l_dbg_msg debug_msg;
        l_error   t_error_out;
    
        l_scale_shortdesc pk_translation.t_desc_translation;
    
    BEGIN
        IF i_vs_scales_element IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'GET VS SCALE SHORT DESC';
        SELECT pk_translation.get_translation(i_lang, vss.code_vital_sign_scales_short)
          INTO l_scale_shortdesc
          FROM vital_sign_scales vss
         INNER JOIN vital_sign_scales_element vsse
            ON vss.id_vital_sign_scales = vsse.id_vital_sign_scales
         WHERE vsse.id_vs_scales_element = i_vs_scales_element;
    
        RETURN l_scale_shortdesc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => l_error);
            RETURN NULL;
        
    END get_vs_scale_shortdesc;

    -------------------------------------------------------------------------------------------------------------

    /*******************************************************************************************************************************************
    *  GET_SCALE_ELEMENTS   This function returns the scales elements available to the episode.  The evaluation of the availability of the scale depends on institution, software and department .*
    *                                                                                                                                          *
    * @param I_LANG                   Language identifier                                                                                      *
    * @param I_PROF                   Profissioanal, institution and software identifiers                                                      *
    * @param I_EPISODE                Episode identifier                                                                                       *
    * @param ID_VITAL_SIGN_SCALE      Scale identifier                                                                                         *
    * @PARAM I_ID_TRIAGE_TYPE         triage type identifier                                                                                        *   
    * @param SCALE_ELEMENT_CURSOR     Output cursor                                                                       *
    * @param VALUE                    Scale value                                                                                              *
    * @param ICON                     Icon name                                                                                                *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         True if no errors found and false otherwise                                                              *
    *                                                                                                                                          *
    * @raises                         No parametrization found                                                                                 *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2009/01/06                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_scale_elements
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_vital_sign_scale IN vital_sign_scales.id_vital_sign_scales%TYPE,
        i_id_triage_type      IN triage_type.id_triage_type%TYPE,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE,
        scale_element_cursor  OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
        l_dbg_msg debug_msg;
        l_error   t_error_out;
        --
    BEGIN
        l_dbg_msg := 'GET SCALES';
    
        IF i_id_triage_type IS NULL
        THEN
            OPEN scale_element_cursor FOR
                SELECT aux.id_vital_sign_scales,
                       aux.id_vs_scales_element,
                       aux.id_vital_sign_desc,
                       aux.value,
                       aux.icon,
                       aux.description,
                       aux.title,
                       aux.unit_measure,
                       aux.id_unit_measure,
                       aux.internal_name
                  FROM (SELECT vss.id_vital_sign_scales,
                               vsse.id_vs_scales_element,
                               vsse.id_vital_sign_desc,
                               vsse.value,
                               vsse.icon,
                               pk_translation.get_translation(i_lang, vsse.code_vss_element) description,
                               pk_translation.get_translation(i_lang, vsse.code_vss_element_title) title,
                               pk_translation.get_translation(i_lang, um.code_unit_measure) unit_measure,
                               um.id_unit_measure,
                               vssa.flg_available,
                               vss.internal_name,
                               row_number() over(PARTITION BY vssa.id_vital_sign_scales, vsse.id_vs_scales_element ORDER BY vssa.id_institution DESC, vssa.id_software DESC) rn
                          FROM vital_sign_scales vss
                          JOIN vital_sign_scales_element vsse
                            ON vsse.id_vital_sign_scales = vss.id_vital_sign_scales
                          JOIN unit_measure um
                            ON um.id_unit_measure = vsse.id_unit_measure
                          JOIN vital_sign_scales_access vssa
                            ON vssa.id_vital_sign_scales = vss.id_vital_sign_scales
                           AND vssa.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                           AND vssa.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                         WHERE vss.id_vital_sign_scales = nvl(i_id_vital_sign_scale, vss.id_vital_sign_scales)
                           AND vss.id_vital_sign = nvl(i_id_vital_sign, vss.id_vital_sign)
                           AND NOT EXISTS (SELECT 1
                                  FROM vital_sign_scales_triage vsst
                                 WHERE vsst.id_vital_sign_scales = vss.id_vital_sign_scales
                                   AND vsst.flg_scale_type = pk_edis_triage.g_manchester)) aux
                 WHERE aux.rn = 1
                   AND aux.flg_available = pk_alert_constant.g_yes
                 ORDER BY aux.id_vital_sign_scales DESC, aux.value ASC;
        ELSE
        
            OPEN scale_element_cursor FOR
                SELECT aux.id_vital_sign_scales,
                       aux.id_vs_scales_element,
                       aux.id_vital_sign_desc,
                       aux.value_vital_signdesc,
                       aux.value,
                       aux.icon,
                       aux.description,
                       aux.title,
                       aux.unit_measure,
                       aux.id_unit_measure,
                       aux.internal_name
                  FROM (SELECT vss.id_vital_sign_scales,
                               vsse.id_vs_scales_element,
                               vsse.id_vital_sign_desc,
                               get_vsd_desc(i_lang, vsse.id_vital_sign_desc, NULL) value_vital_signdesc,
                               vsse.value,
                               vsse.icon,
                               pk_translation.get_translation(i_lang, vsse.code_vss_element) description,
                               pk_translation.get_translation(i_lang, vsse.code_vss_element_title) title,
                               pk_translation.get_translation(i_lang, um.code_unit_measure) unit_measure,
                               um.id_unit_measure,
                               vssa.flg_available,
                               vss.internal_name,
                               row_number() over(PARTITION BY vssa.id_vital_sign_scales, vsse.id_vs_scales_element ORDER BY vssa.id_institution DESC, vssa.id_software DESC) rn
                          FROM vital_sign_scales vss
                          JOIN vital_sign_scales_element vsse
                            ON vsse.id_vital_sign_scales = vss.id_vital_sign_scales
                          JOIN vital_sign_scales_triage vsst
                            ON (vsst.id_vital_sign_scales = vss.id_vital_sign_scales AND
                               vsst.id_triage_type = i_id_triage_type)
                          JOIN unit_measure um
                            ON um.id_unit_measure = vsse.id_unit_measure
                          JOIN vital_sign_scales_access vssa
                            ON vssa.id_vital_sign_scales = vss.id_vital_sign_scales
                           AND vssa.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                           AND vssa.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                         WHERE vss.id_vital_sign_scales = nvl(i_id_vital_sign_scale, vss.id_vital_sign_scales)
                           AND vss.id_vital_sign = nvl(i_id_vital_sign, vss.id_vital_sign)) aux
                 WHERE aux.rn = 1
                   AND aux.flg_available = pk_alert_constant.g_yes
                 ORDER BY aux.id_vital_sign_scales DESC, aux.value ASC;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCALE_ELEMENTS',
                                              l_error);
            RETURN FALSE;
    END get_scale_elements;

    --

    FUNCTION scale_rank
    (
        t_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        l_clinical_service    IN clinical_service.id_clinical_service%TYPE,
        t_id_institution      IN institution.id_institution%TYPE,
        l_institution         IN institution.id_institution%TYPE,
        t_id_software         IN software.id_software%TYPE,
        l_software            IN software.id_software%TYPE
    ) RETURN INTEGER IS
    BEGIN
        IF t_id_clinical_service = l_clinical_service
        THEN
            IF t_id_institution = l_institution
            THEN
                IF t_id_software = l_software
                THEN
                    RETURN 1000000;
                ELSIF t_id_software = 0
                THEN
                    RETURN 100000;
                END IF;
            ELSIF t_id_institution = 0
            THEN
                IF t_id_software = l_software
                THEN
                    RETURN 100000;
                ELSIF t_id_software = 0
                THEN
                    RETURN 10000;
                END IF;
            END IF;
        ELSIF t_id_clinical_service IS NULL
        THEN
            IF t_id_institution = l_institution
            THEN
                IF t_id_software = l_software
                THEN
                    RETURN 1000;
                ELSIF t_id_software = 0
                THEN
                    RETURN 100;
                END IF;
            ELSIF t_id_institution = 0
            THEN
                IF t_id_software = l_software
                THEN
                    RETURN 100;
                ELSIF t_id_software = 0
                THEN
                    RETURN 10;
                END IF;
            END IF;
        END IF;
        RETURN 0;
    END scale_rank;
    /*******************************************************************************************************************************************
    *  GET_ALL_SCALES  This function returns the scales available to the episode.  The evaluation of the availability of the scale depends on institution, software and department .*
    *                                                                                                                                          *
    * @param I_LANG                   Language identifier                                                                                      *
    * @param I_PROF                   Profissioanal, institution and software identifiers                                                      *
    * @param I_EPISODE                Episode identifier                                                                                       *
    * @param ID_VITAL_SIGN_SCALE      Scale identifier                                                                                         *
    * @param I_ID_TRIAGE_TYPE         Triage type identifier                                                                                        *
    * @param O_SCALE_CURSOR           Output cursor                                                                                        *
    *                                                                                                                                          *
    * @return                         True if no errors found and false otherwise                                                              *
    *                                                                                                                                          *
    * @raises                         No parametrization found                                                                                 *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2009/01/05                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_all_scales
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_id_vital_sign_scale IN vital_sign_scales.id_vital_sign_scales%TYPE,
        i_id_triage_type      IN triage_type.id_triage_type%TYPE,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE,
        o_scale_cursor        OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
        l_dbg_msg debug_msg;
        l_error   t_error_out;
        --
    BEGIN
    
        IF (i_id_triage_type IS NOT NULL)
        THEN
            l_dbg_msg := 'get_all_scales triage';
            OPEN o_scale_cursor FOR
                SELECT aux.id_vital_sign_scales,
                       aux.description,
                       aux.description_short,
                       aux.id_vital_sign,
                       aux.rank,
                       aux.flg_scale_type,
                       aux.internal_name
                  FROM (SELECT vss.id_vital_sign_scales,
                               vss.id_vital_sign,
                               pk_translation.get_translation(i_lang, vss.code_vital_sign_scales) description,
                               pk_translation.get_translation(i_lang, vss.code_vital_sign_scales_short) description_short,
                               nvl(vssa.rank, 0) rank,
                               vsst.flg_scale_type,
                               row_number() over(PARTITION BY vssa.id_vital_sign_scales ORDER BY vssa.id_institution DESC, vssa.id_software DESC) rn,
                               vss.internal_name,
                               vssa.flg_available
                          FROM vital_sign_scales vss
                          JOIN vital_sign_scales_triage vsst
                            ON vsst.id_vital_sign_scales = vss.id_vital_sign_scales
                           AND vsst.id_triage_type = i_id_triage_type
                          JOIN vital_sign_scales_access vssa
                            ON vssa.id_vital_sign_scales = vss.id_vital_sign_scales
                           AND vssa.id_institution IN (i_prof.institution)
                           AND vssa.id_software IN (i_prof.software)
                         WHERE vss.id_vital_sign_scales = nvl(i_id_vital_sign_scale, vss.id_vital_sign_scales)
                           AND vss.id_vital_sign = nvl(i_id_vital_sign, vss.id_vital_sign)) aux
                 WHERE aux.rn = 1
                   AND aux.flg_available = pk_alert_constant.g_yes
                 ORDER BY aux.rank ASC, aux.description ASC;
        ELSE
            l_dbg_msg := 'get_all_scales';
            OPEN o_scale_cursor FOR
                SELECT aux.id_vital_sign_scales,
                       aux.description,
                       aux.description_short,
                       aux.id_vital_sign,
                       aux.rank,
                       aux.flg_scale_type,
                       aux.internal_name
                  FROM (SELECT vss.id_vital_sign_scales,
                               vss.id_vital_sign,
                               pk_translation.get_translation(i_lang, vss.code_vital_sign_scales) description,
                               pk_translation.get_translation(i_lang, vss.code_vital_sign_scales_short) description_short,
                               nvl(vssa.rank, 0) rank,
                               row_number() over(PARTITION BY vssa.id_vital_sign_scales ORDER BY vssa.id_institution DESC, vssa.id_software DESC) rn,
                               vss.internal_name,
                               NULL flg_scale_type,
                               vssa.flg_available
                          FROM vital_sign_scales vss
                          JOIN vital_sign_scales_access vssa
                            ON vssa.id_vital_sign_scales = vss.id_vital_sign_scales
                           AND vssa.id_institution IN (i_prof.institution)
                           AND vssa.id_software IN (i_prof.software)
                         WHERE vss.id_vital_sign_scales = nvl(i_id_vital_sign_scale, vss.id_vital_sign_scales)
                           AND vss.id_vital_sign = nvl(i_id_vital_sign, vss.id_vital_sign)
                           AND NOT EXISTS (SELECT 1
                                  FROM vital_sign_scales_triage vsst
                                 WHERE vsst.id_vital_sign_scales = vss.id_vital_sign_scales
                                   AND vsst.flg_scale_type = pk_edis_triage.g_manchester)) aux
                 WHERE aux.rn = 1
                   AND aux.flg_available = pk_alert_constant.g_yes
                 ORDER BY aux.rank ASC, aux.description ASC;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ALL_SCALES',
                                              l_error);
            pk_types.open_my_cursor(o_scale_cursor);
            RETURN FALSE;
    END get_all_scales;

    FUNCTION get_scale
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_vital_sign       IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_scale IN vital_sign_scales.id_vital_sign_scales%TYPE,
        o_scale               OUT pk_types.cursor_type,
        o_scale_elem          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dbg_msg debug_msg;
        --
    BEGIN
    
        l_dbg_msg := 'OPEN o_scale_elem';
        OPEN o_scale FOR
            SELECT pk_translation.get_translation(i_lang, vss.code_vital_sign_scales) description,
                   pk_translation.get_translation(i_lang, vss.code_vital_sign_scales_short) description_short,
                   vss.internal_name
              FROM vital_sign_scales vss
             WHERE vss.id_vital_sign_scales = i_id_vital_sign_scale
               AND vss.id_vital_sign = i_id_vital_sign;
    
        l_dbg_msg := 'OPEN o_scale_elem';
        OPEN o_scale_elem FOR
            SELECT vsse.id_vs_scales_element,
                   vsse.id_vital_sign_desc,
                   vsse.value,
                   vsse.icon,
                   pk_translation.get_translation(i_lang, vsse.code_vss_element) description,
                   pk_translation.get_translation(i_lang, vsse.code_vss_element_title) title,
                   pk_translation.get_translation(i_lang, um.code_unit_measure) unit_measure,
                   um.id_unit_measure
              FROM vital_sign_scales vss
              JOIN vital_sign_scales_element vsse
                ON vsse.id_vital_sign_scales = vss.id_vital_sign_scales
              JOIN unit_measure um
                ON um.id_unit_measure = vsse.id_unit_measure
             WHERE vss.id_vital_sign_scales = i_id_vital_sign_scale
               AND vss.id_vital_sign = i_id_vital_sign
             ORDER BY vsse.value ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCALE',
                                              o_error);
            pk_types.open_my_cursor(o_scale);
            pk_types.open_my_cursor(o_scale_elem);
        
            RETURN FALSE;
    END get_scale;
    /************************************************************************************************************
    * This function returns the vital sign alias if exists
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_id_patient                patient id
    * @param      i_code_vital_sign_desc      Vital sign unit description code for translation
    *
    * @return     Vital sign alias or translation
    *
    * @author     Rui Spratley
    * @version    2.4.3
    * @since      2008/05/28
    ***********************************************************************************************************/
    FUNCTION get_vs_alias
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_code_vital_sign_desc IN vital_sign_desc.code_vital_sign_desc%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        c_function_name CONSTANT obj_name := 'GET_VS_ALIAS';
        l_dbg_msg         debug_msg;
        l_vital_sign_desc vital_sign_desc.id_vital_sign_desc%TYPE;
    BEGIN
        IF i_code_vital_sign_desc IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get patient gender and age';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT vsd.id_vital_sign_desc
          INTO l_vital_sign_desc
          FROM vital_sign_desc vsd
         WHERE vsd.code_vital_sign_desc = i_code_vital_sign_desc;
    
        l_dbg_msg := 'get vital_sign_desc description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        RETURN get_vsd_desc(i_lang => i_lang, i_vital_sign_desc => l_vital_sign_desc, i_patient => i_id_patient);
    
    END get_vs_alias;

    /************************************************************************************************************
    * This function returns the vital sign alias if exists
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_gender                    patient gender
    * @param      i_age                       patient age
    * @param      i_code_vital_sign_desc      Vital sign unit description code for translation
    *
    * @return     Vital sign alias or translation
    *
    * @author     Alexandre Santos
    * @version    2.5
    * @since      2009/06/30
    ***********************************************************************************************************/
    FUNCTION get_vs_alias
    (
        i_lang                 IN language.id_language%TYPE,
        i_gender               IN patient.gender%TYPE,
        i_age                  IN patient.age%TYPE,
        i_code_vital_sign_desc IN vital_sign_desc.code_vital_sign_desc%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        c_function_name CONSTANT obj_name := 'GET_VS_ALIAS';
        l_dbg_msg         debug_msg;
        l_vital_sign_desc vital_sign_desc.id_vital_sign_desc%TYPE;
    BEGIN
        IF i_code_vital_sign_desc IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get patient gender and age';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT vsd.id_vital_sign_desc
          INTO l_vital_sign_desc
          FROM vital_sign_desc vsd
         WHERE vsd.code_vital_sign_desc = i_code_vital_sign_desc;
    
        l_dbg_msg := 'get vital_sign_desc description';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        RETURN get_vsd_desc(i_lang            => i_lang,
                            i_vital_sign_desc => l_vital_sign_desc,
                            i_age             => i_age,
                            i_gender          => i_gender);
    
    END get_vs_alias;

    /*******************************************************************************************************************************************
    *GET_VITAL_SIGN_UNIT_MEASURE Vital sign unit measure                                                                                       *
    *                                                                                                                                          *
    * @param I_LANG                   Language identifier                                                                                      *
    * @param I_PROF                   Professional, institution an software identifiers                                                        *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @return                         Return vital sign unit measure                                                                           *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Carlos Vieira                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2009/01/08                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_vital_sign_unit_measure
    (
        i_lang              IN language.id_language%TYPE,
        i_unit_measure      IN unit_measure.id_unit_measure%TYPE,
        i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE
    ) RETURN VARCHAR2 IS
        l_return pk_translation.t_desc_translation;
    
        CURSOR c_get_unit_measure IS
            SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
              FROM unit_measure um
             WHERE um.id_unit_measure = i_unit_measure;
        CURSOR c_get_unit_measure_scale IS
            SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
              FROM vital_sign_scales_element vsse, unit_measure um
             WHERE vsse.id_unit_measure = um.id_unit_measure
               AND vsse.id_vs_scales_element = i_vs_scales_element;
    
        l_dbg_msg debug_msg;
        l_error   t_error_out;
    
    BEGIN
        IF i_vs_scales_element IS NOT NULL
        THEN
            l_dbg_msg := 'GET UNIT_MEASURE_SCALE';
            OPEN c_get_unit_measure_scale;
            FETCH c_get_unit_measure_scale
                INTO l_return;
            CLOSE c_get_unit_measure_scale;
        ELSE
            l_dbg_msg := 'GET UNIT_MEASURE';
            OPEN c_get_unit_measure;
            FETCH c_get_unit_measure
                INTO l_return;
            CLOSE c_get_unit_measure;
        END IF;
        --
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VITAL_SIGN_UNIT_MEASURE',
                                              l_error);
            RETURN NULL;
    END get_vital_sign_unit_measure;

    /************************************************************************************************************
    * Esta fun��o retorna a parte do nome de um parametro da Biometria. Estes parametros s�o guardados como
    * 'nome (periodo de tempo)'.
    *
    * @param      i_lang              L�ngua registada como prefer�ncia do profissional
    * @param      i_vs_name           Nome completo do parametro da Biometria
    *
    * @return     nome do par�metro
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/02
    ***********************************************************************************************************/
    FUNCTION get_graph_menu_name(i_vs_name IN VARCHAR2) RETURN VARCHAR2 IS
        l_end_name NUMBER := 0;
    
    BEGIN
        IF i_vs_name IS NULL
        THEN
            RETURN NULL;
        END IF;
        l_end_name := instr(i_vs_name, '(');
        IF l_end_name = 0
        THEN
            --tamanho da string....
            l_end_name := length(i_vs_name);
        ELSE
            l_end_name := l_end_name - 1;
        END IF;
        RETURN substr(i_vs_name, 0, l_end_name);
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_graph_menu_name;
    /************************************************************************************************************
    * Esta fun��o retorna a parte do periodo de tempo de um parametro da Biometria. Estes parametros s�o guardados como
    * 'nome (periodo de tempo)'.
    *
    * @param      i_lang              L�ngua registada como prefer�ncia do profissional
    * @param      i_vs_name           Nome completo do parametro da Biometria
    *
    * @return     per�odo de tempo do par�metro
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/02
    ***********************************************************************************************************/
    FUNCTION get_graph_menu_time_period(i_vs_name IN VARCHAR2) RETURN VARCHAR2 IS
        l_time_period VARCHAR2(50 CHAR) := NULL;
        l_start_time  NUMBER := 0;
        l_end_time    NUMBER := 0;
    BEGIN
        IF i_vs_name IS NULL
        THEN
            RETURN l_time_period;
        END IF;
        l_start_time := instr(i_vs_name, '(');
        l_end_time   := instr(i_vs_name, ')');
        IF l_start_time = 0
           OR l_end_time = 0
        THEN
            --n�o existe nada entre () - o nome ?retornado na primeira linha
            l_time_period := NULL;
        ELSE
            l_time_period := substr(i_vs_name, l_start_time, l_end_time);
        END IF;
        RETURN l_time_period;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_graph_menu_time_period;

    /************************************************************************************************************
    * Devolve um array de varchar com as strings dos filtros para a biometria.
    *
    * @param      i_lang              L�ngua registada como prefer�ncia do profissional
    *
    * @return
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/02
    ***********************************************************************************************************/
    FUNCTION get_biometric_graph_filters(i_lang IN language.id_language%TYPE) RETURN table_info IS
        l_filter_temp   sys_message.desc_message%TYPE;
        l_inc_corrent   NUMBER := 0;
        l_table_filters table_info := table_info();
        l_dbg_msg       debug_msg;
        l_error         t_error_out;
    BEGIN
        --filtro 1
        l_filter_temp := pk_message.get_message(i_lang, 'BIOMETRICS_T007');
        IF l_filter_temp IS NOT NULL
        THEN
            l_table_filters.extend;
            l_inc_corrent := l_inc_corrent + 1;
            l_table_filters(l_inc_corrent) := info(l_inc_corrent, l_filter_temp, NULL);
        END IF;
        --filtro 2
        l_filter_temp := pk_message.get_message(i_lang, 'BIOMETRICS_T008');
        IF l_filter_temp IS NOT NULL
        THEN
            l_table_filters.extend;
            l_inc_corrent := l_inc_corrent + 1;
            l_table_filters(l_inc_corrent) := info(l_inc_corrent, l_filter_temp, NULL);
        END IF;
        --filtro 3
        l_filter_temp := pk_message.get_message(i_lang, 'BIOMETRICS_T009');
        IF l_filter_temp IS NOT NULL
        THEN
            l_table_filters.extend;
            l_inc_corrent := l_inc_corrent + 1;
            l_table_filters(l_inc_corrent) := info(l_inc_corrent, l_filter_temp, NULL);
        END IF;
        --filtro 4
        l_filter_temp := pk_message.get_message(i_lang, 'BIOMETRICS_T010');
        IF l_filter_temp IS NOT NULL
        THEN
            l_table_filters.extend;
            l_inc_corrent := l_inc_corrent + 1;
            l_table_filters(l_inc_corrent) := info(l_inc_corrent, l_filter_temp, NULL);
        END IF;
        RETURN l_table_filters;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BIOMETRIC_GRAPH_FILTERS',
                                              l_error);
            RETURN table_info();
    END get_biometric_graph_filters;

    /**
    * Get axis value in years.
    *
    * @param i_axis_type    axis type
    * @param i_axis_val     axis value
    *
    * @return               axis value (in years)
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.0
    * @since                2009/01/26
    */
    FUNCTION get_year_value
    (
        i_axis_type IN graphic.flg_x_axis_type%TYPE,
        i_axis_val  IN graphic.x_axis_end%TYPE
    ) RETURN graphic.x_axis_end%TYPE IS
    
    BEGIN
        RETURN CASE i_axis_type WHEN c_axis_type_month THEN i_axis_val / 12 WHEN c_axis_type_year THEN i_axis_val ELSE NULL END;
    
    END get_year_value;
    --
    FUNCTION check_age
    (
        i_lang           IN language.id_language%TYPE,
        l_pat_age_months IN graphic.age_min%TYPE,
        l_pat_age_years  IN graphic.age_min%TYPE,
        i_type           IN graphic.flg_x_axis_type%TYPE,
        i_x_axis_start   IN graphic.x_axis_start%TYPE,
        i_x_axis_end     IN graphic.x_axis_end%TYPE,
        i_age_min        IN graphic.age_min%TYPE,
        i_age_max        IN graphic.age_min%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR);
    BEGIN
    
        CASE
            WHEN i_type = c_axis_type_month
                 AND l_pat_age_months >= nvl(i_x_axis_start, l_pat_age_months)
            --AND l_pat_age_months <= nvl(i_x_axis_end, l_pat_age_months) 
             THEN
                l_ret := pk_alert_constant.g_yes;
            
            WHEN i_type = c_axis_type_year
                 AND l_pat_age_years >= nvl(i_x_axis_start, l_pat_age_years)
            --AND l_pat_age_years <= nvl(i_x_axis_end, l_pat_age_years) 
             THEN
                l_ret := pk_alert_constant.g_yes;
            
            WHEN i_type = c_axis_type_vital_sign
                 AND l_pat_age_months >= nvl(i_age_min, l_pat_age_months)
            --AND l_pat_age_months <= nvl(i_age_max, l_pat_age_months) 
             THEN
                l_ret := pk_alert_constant.g_yes;
            
            ELSE
                l_ret := pk_alert_constant.g_no;
        END CASE;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END check_age;

    /************************************************************************************************************
    * Devolve uma lista de IDs dos gr�ficos dispon�veis para o paciente indicado
    *
    * @param      i_lang              L�ngua registada como prefer�ncia do profissional
    * @param      i_prof              logged professional structure
    * @param      i_patient           ID do paciente
    * @param      o_graphs            available graphic identifiers
    * @param      o_error             error
    *
    * @return     array com os IDs dos gr�ficos.
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/11
    ***********************************************************************************************************/
    FUNCTION get_graphics_by_patient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_graphs  OUT table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_age_years  patient.age%TYPE;
        l_pat_age_months patient.age%TYPE;
        l_pat_gender     patient.gender%TYPE;
        l_dbg_msg        debug_msg;
    BEGIN
        --get patient age
        l_dbg_msg        := 'CALL pk_patient.get_pat_age';
        l_pat_age_years  := pk_patient.get_pat_age(i_lang        => i_lang,
                                                   i_dt_birth    => NULL,
                                                   i_dt_deceased => NULL,
                                                   i_age         => NULL,
                                                   i_age_format  => 'YEARS',
                                                   i_patient     => i_patient);
        l_pat_age_months := pk_patient.get_pat_age(i_lang        => i_lang,
                                                   i_dt_birth    => NULL,
                                                   i_dt_deceased => NULL,
                                                   i_age         => NULL,
                                                   i_age_format  => 'MONTHS',
                                                   i_patient     => i_patient);
    
        pk_alertlog.log_debug(l_dbg_msg);
        -- get patient gender
        l_dbg_msg := 'CALL pk_patient.get_pat_gender';
        pk_alertlog.log_debug(l_dbg_msg);
        l_pat_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
    
        -- fetch graphics
        l_dbg_msg := 'o_graphs BULK COLLECT';
        SELECT g.id_graphic
          BULK COLLECT
          INTO o_graphs
          FROM graphic g
          JOIN graphic_soft_inst gsi
            ON g.id_graphic = gsi.id_graphic
         WHERE g.patient_gender = l_pat_gender
           AND gsi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
           AND gsi.id_institution IN (i_prof.institution)
              --AND (l_pat_age BETWEEN pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_start) AND
              --    pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_end) OR
              --    l_pat_age > pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_end))
           AND pk_vital_sign.check_age(i_lang           => i_lang,
                                       l_pat_age_months => l_pat_age_months,
                                       l_pat_age_years  => l_pat_age_years,
                                       i_type           => g.flg_x_axis_type,
                                       i_x_axis_start   => g.x_axis_start,
                                       i_x_axis_end     => g.x_axis_end,
                                       i_age_min        => g.age_min,
                                       i_age_max        => g.age_max) = 'Y'
         ORDER BY gsi.rank;
    
        IF (o_graphs.count = 0)
        THEN
        
            SELECT g.id_graphic
              BULK COLLECT
              INTO o_graphs
              FROM graphic g
              JOIN graphic_soft_inst gsi
                ON g.id_graphic = gsi.id_graphic
             WHERE g.patient_gender = l_pat_gender
               AND gsi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
               AND gsi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
                  --AND (l_pat_age BETWEEN pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_start) AND
                  --    pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_end) OR
                  --    l_pat_age > pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_end))
               AND pk_vital_sign.check_age(i_lang           => i_lang,
                                           l_pat_age_months => l_pat_age_months,
                                           l_pat_age_years  => l_pat_age_years,
                                           i_type           => g.flg_x_axis_type,
                                           i_x_axis_start   => g.x_axis_start,
                                           i_x_axis_end     => g.x_axis_end,
                                           i_age_min        => g.age_min,
                                           i_age_max        => g.age_max) = 'Y'
             ORDER BY gsi.rank;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_GRAPHICS_BY_PATIENT',
                                              o_error    => o_error);
            RETURN FALSE;
        
    END get_graphics_by_patient;

    /************************************************************************************************************
    *  Determina qual o gr�fico que deve ficar seleccionado
    *
    * @param      i_id_vital_sign     ID do sinal vital seleccionado
    * @param      i_graphs            available graphic list
    *
    * @return     selected graphic identifier
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/11
    ***********************************************************************************************************/
    FUNCTION get_selected_graphic
    (
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_graphs        IN table_number
    ) RETURN graphic.id_graphic%TYPE IS
        l_graphic graphic.id_graphic%TYPE;
    
        CURSOR c_graphics IS
            SELECT g.id_graphic
              FROM graphic g
             WHERE g.id_graphic IN (SELECT column_value id_graphic
                                      FROM TABLE(i_graphs))
               AND g.id_related_object = i_id_vital_sign
             ORDER BY get_year_value(g.flg_x_axis_type, g.x_axis_end) DESC;
    BEGIN
        OPEN c_graphics;
        FETCH c_graphics
            INTO l_graphic;
        CLOSE c_graphics;
    
        RETURN l_graphic;
    
    END get_selected_graphic;
    --
    /************************************************************************************************************
    * Get the graphic date bounds.
    *
    * @param      i_patient     ID do paciente
    * @param      i_x_axis_end  valor m�ximo da escala do gr�fico
    * @param      i_x_axis_type tipo de escala do gr�fico (M- meses, Y anos)
    *
    * @return     data m�xima considerada para os valores registados.
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/13
    ***********************************************************************************************************/
    PROCEDURE get_graphic_bounds
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_x_axis_start IN graphic.x_axis_start%TYPE,
        i_x_axis_end   IN graphic.x_axis_end%TYPE,
        i_x_axis_type  IN graphic.flg_x_axis_type%TYPE,
        o_max          OUT vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_min          OUT vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_age          OUT vital_sign_read.dt_vital_sign_read_tstz%TYPE
    ) IS
        l_dt_birth     patient.dt_birth%TYPE;
        l_age          patient.age%TYPE;
        l_months_start PLS_INTEGER;
        l_months_end   PLS_INTEGER;
        l_min          vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_age_dt       vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_max          vital_sign_read.dt_vital_sign_read_tstz%TYPE;
    BEGIN
        SELECT p.dt_birth, p.age
          INTO l_dt_birth, l_age
          FROM patient p
         WHERE p.id_patient = i_patient;
    
        IF i_x_axis_type = c_axis_type_month
        THEN
            l_months_start := i_x_axis_start;
            l_months_end   := i_x_axis_end;
        ELSE
            l_months_start := i_x_axis_start * 12;
            l_months_end   := i_x_axis_end * 12;
        END IF;
    
        IF l_dt_birth IS NULL
        THEN
            l_age_dt := pk_date_utils.add_to_ltstz(i_timestamp => current_timestamp,
                                                   i_amount    => nvl(l_age, 0) * -1,
                                                   i_unit      => 'YEAR');
        ELSE
            l_age_dt := pk_date_utils.convert_dt_tsz(i_lang, i_prof, l_dt_birth); --CAST(l_dt_birth AS TIMESTAMP WITH LOCAL TIME ZONE);
        END IF;
    
        l_min := pk_date_utils.add_to_ltstz(i_timestamp => l_age_dt, i_amount => l_months_start, i_unit => 'MONTH');
    
        l_max := pk_date_utils.add_to_ltstz(i_timestamp => l_min,
                                            i_amount    => l_months_end - l_months_start,
                                            i_unit      => 'MONTH');
    
        o_min := l_min;
        o_max := l_max;
        o_age := l_age_dt;
    END get_graphic_bounds;
    --
    FUNCTION get_decode_value_vs
    (
        i_vsr_unit_measure IN vital_sign_read.id_unit_measure%TYPE,
        i_vsi_unit_measure IN vs_soft_inst.id_unit_measure%TYPE,
        i_value            IN vital_sign_read.value%TYPE
    ) RETURN vital_sign_read.value%TYPE IS
    
    BEGIN
        RETURN CASE i_vsr_unit_measure WHEN i_vsi_unit_measure THEN i_value ELSE nvl(n1 => pk_unit_measure.get_unit_mea_conversion(i_value         => i_value,
                                                                                                                                   i_unit_meas     => i_vsr_unit_measure,
                                                                                                                                   i_unit_meas_def => i_vsi_unit_measure),
                                                                                     n2 => i_value) END;
    
    END get_decode_value_vs;
    --
    /************************************************************************************************************
    *  Valida e retorna o valor a aplicar nos filtros
    *
    * @param      i_actual_value  valor actual do id do profissional
    * @param      i_filter_value  valor do profissional a aplicar no filtro
    * @param      i_id_filter     id do filtro a aplicar
    *
    * @return     retorna o valor a aplicar ao filtro
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/13
    ***********************************************************************************************************/
    FUNCTION get_filter_prof_condition
    (
        i_actual_value IN professional.id_professional%TYPE,
        i_filter_value IN professional.id_professional%TYPE,
        i_id_filter    IN NUMBER
    ) RETURN professional.id_professional%TYPE IS
    BEGIN
        IF i_id_filter = 1
           OR i_id_filter = 2
        THEN
            RETURN i_filter_value;
        END IF;
    
        RETURN i_actual_value;
    END get_filter_prof_condition;
    --
    /************************************************************************************************************
    *  Valida e retorna o valor a aplicar nos filtros para os clinical services (tipo de consulta)
    *
    * @param      i_actual_value  valor actual do clinical service
    * @param      i_filter_value  valor do clinical service a aplicar no filtro
    * @param      i_id_filter     id do filtro a aplicar
    *
    * @return     retorna o valor a aplicar ao filtro
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/14
    ***********************************************************************************************************/
    FUNCTION get_filter_cs_condition
    (
        i_actual_value IN clinical_service.id_clinical_service%TYPE,
        i_filter_value IN clinical_service.id_clinical_service%TYPE,
        i_id_filter    IN NUMBER
    ) RETURN clinical_service.id_clinical_service%TYPE IS
    BEGIN
        IF i_id_filter = 1
           OR i_id_filter = 3
        THEN
            RETURN i_filter_value;
        END IF;
    
        RETURN i_actual_value;
    END get_filter_cs_condition;
    --
    /************************************************************************************************************
    *  Calcula o valor do clinical service que corresponde ao episodio actual do paciente.
    *
    * @param      i_lang              L�ngua registada como prefer�ncia do profissional
    * @param      i_prof              ID do profissional, software e institui��o
    * @param      i_patient           ID do paciente
    *
    * @return     o valor do clinical service
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/12/14
    ***********************************************************************************************************/
    FUNCTION get_patient_clinical_service
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN clinical_service.id_clinical_service%TYPE IS
        --
        l_result_value clinical_service.id_clinical_service%TYPE;
        l_dbg_msg      debug_msg;
        l_error        t_error_out;
    BEGIN
        SELECT e.id_clinical_service
          INTO l_result_value
          FROM episode e
         WHERE e.id_episode = i_episode;
        RETURN l_result_value;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATIENT_CLINICAL_SERVICE',
                                              l_error);
            RETURN NULL;
    END get_patient_clinical_service;
    --
    /********************************************************************************************
    * This function writes a set of vital sign reads at once.
    * The arrays are read in the same order according to each line of
    * I_VS_ID.
    *
    * @param i_lang             Language ID
    * @param i_episode          Episode ID
    * @param i_prof             professional, software, institution ids
    * @param i_pat              patient id
    * @param i_vs_id            Array of IDs of SVs read
    * @param i_vs_val           Array of the SVs reads (vital sign value)
    * @param i_id_monit         Monitorization ID
    * @param i_unit_meas        Measurements IDs
    * @param i_notes            notes
    * @param i_prof_cat_type    category of professional
    * @param i_flg_pain         flag pain scale used
    * @param o_vital_sign_read  Array of vital sign read IDs
    * @param o_error            Error message
    *
    * @return                   TRUE if sucess, FALSE otherwise
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/09/01
    ********************************************************************************************/
    FUNCTION set_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN table_varchar,
        i_epis_triage        IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert  IN table_number,
        i_vs_val_high        IN table_number DEFAULT table_number(),
        i_vs_val_low         IN table_number DEFAULT table_number(),
        i_fetus_vs           IN NUMBER DEFAULT NULL,
        o_vital_sign_read    OUT table_number,
        o_dt_registry        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_EPIS_VITAL_SIGN';
        l_exception EXCEPTION;
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'call set_epis_vital_sign';
        IF NOT set_epis_vital_sign(i_lang               => i_lang,
                                   i_episode            => i_episode,
                                   i_prof               => i_prof,
                                   i_pat                => i_pat,
                                   i_vs_id              => i_vs_id,
                                   i_vs_val             => i_vs_val,
                                   i_id_monit           => i_id_monit,
                                   i_unit_meas          => i_unit_meas,
                                   i_vs_scales_elements => i_vs_scales_elements,
                                   i_notes              => i_notes,
                                   i_prof_cat_type      => i_prof_cat_type,
                                   i_dt_vs_read         => i_dt_vs_read,
                                   i_epis_triage        => i_epis_triage,
                                   i_unit_meas_convert  => i_unit_meas_convert,
                                   i_tbtb_attribute     => table_table_number(),
                                   i_tbtb_free_text     => table_table_clob(),
                                   i_vs_val_high        => i_vs_val_high,
                                   i_vs_val_low         => i_vs_val_low,
                                   i_fetus_vs           => i_fetus_vs,
                                   o_vital_sign_read    => o_vital_sign_read,
                                   o_dt_registry        => o_dt_registry,
                                   o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            o_vital_sign_read := table_number();
            RETURN FALSE;
        
    END set_epis_vital_sign;

    FUNCTION set_epis_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN table_varchar,
        i_epis_triage        IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert  IN table_number,
        i_tbtb_attribute     IN table_table_number,
        i_tbtb_free_text     IN table_table_clob,
        i_vs_val_high        IN table_number DEFAULT table_number(),
        i_vs_val_low         IN table_number DEFAULT table_number(),
        i_fetus_vs           IN NUMBER DEFAULT NULL,
        o_vital_sign_read    OUT table_number,
        o_dt_registry        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_EPIS_VITAL_SIGN';
        l_exception EXCEPTION;
        l_dbg_msg debug_msg;
    BEGIN
        l_dbg_msg := 'call set_epis_vital_sign';
        IF NOT set_epis_vital_sign(i_lang               => i_lang,
                                   i_episode            => i_episode,
                                   i_prof               => i_prof,
                                   i_pat                => i_pat,
                                   i_vs_id              => i_vs_id,
                                   i_vs_val             => i_vs_val,
                                   i_id_monit           => i_id_monit,
                                   i_unit_meas          => i_unit_meas,
                                   i_vs_scales_elements => i_vs_scales_elements,
                                   i_notes              => i_notes,
                                   i_prof_cat_type      => i_prof_cat_type,
                                   i_dt_vs_read         => i_dt_vs_read,
                                   i_epis_triage        => i_epis_triage,
                                   i_unit_meas_convert  => i_unit_meas_convert,
                                   i_tbtb_attribute     => i_tbtb_attribute,
                                   i_tbtb_free_text     => i_tbtb_free_text,
                                   i_id_edit_reason     => table_number(),
                                   i_notes_edit         => table_clob(),
                                   i_vs_val_high        => i_vs_val_high,
                                   i_vs_val_low         => i_vs_val_low,
                                   i_fetus_vs           => i_fetus_vs,
                                   o_vital_sign_read    => o_vital_sign_read,
                                   o_dt_registry        => o_dt_registry,
                                   o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            o_vital_sign_read := table_number();
            RETURN FALSE;
        
    END set_epis_vital_sign;

    FUNCTION set_epis_vital_sign
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN vital_sign_read.id_episode%TYPE,
        i_prof                  IN profissional,
        i_pat                   IN vital_sign_read.id_patient%TYPE,
        i_vs_id                 IN table_number,
        i_vs_val                IN table_number,
        i_id_monit              IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas             IN table_number,
        i_vs_scales_elements    IN table_number,
        i_notes                 IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_dt_vs_read            IN table_varchar,
        i_epis_triage           IN epis_triage.id_epis_triage%TYPE,
        i_unit_meas_convert     IN table_number,
        i_tbtb_attribute        IN table_table_number,
        i_tbtb_free_text        IN table_table_clob,
        i_id_edit_reason        IN table_number,
        i_notes_edit            IN table_clob,
        i_vs_val_high           IN table_number DEFAULT table_number(),
        i_vs_val_low            IN table_number DEFAULT table_number(),
        i_fetus_vs              IN NUMBER DEFAULT NULL,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_vital_sign_read       OUT table_number,
        o_dt_registry           OUT VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_EPIS_VITAL_SIGN';
        l_dbg_msg debug_msg;
        l_exception EXCEPTION;
        l_found                 NUMBER(6);
        l_pat                   vital_sign_read.id_patient%TYPE;
        l_next                  vital_sign_read.id_vital_sign_read%TYPE;
        l_next_notes            vital_sign_notes.id_vital_sign_notes%TYPE;
        l_flg                   vital_sign.flg_fill_type%TYPE;
        l_vs_read_pre_hosp      table_number;
        rows_vsr_out            table_varchar;
        l_id_vital_sign_desc_in vital_sign_read.id_vital_sign_desc%TYPE;
        l_value_in              vital_sign_read.value%TYPE;
        l_dt_vs_read            vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_prof_cat_type         category.flg_type%TYPE;
        l_vs_scales_elements    vital_sign_read.id_vs_scales_element%TYPE;
        l_id_unit_measure_sel   unit_measure.id_unit_measure%TYPE;
        l_id_vital_sign_read    vital_sign_read.id_vital_sign_read%TYPE;
        l_id_edit_reason        vital_sign_read.id_edit_reason%TYPE;
        l_notes_edit            CLOB;
    
        l_vs_val_high table_number := i_vs_val_high;
        l_vs_val_low  table_number := i_vs_val_low;
    
        l_vs_bmi_calc CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'VS_BMI_CALC',
                                                                                i_prof    => i_prof);
        l_cnt_bmi NUMBER(3, 0);
    BEGIN
        ---------------------------------------
        IF nvl(cardinality(i_vs_id), 0) > 0
        THEN
            -----------
            IF NOT l_vs_val_high.exists(1)
            THEN
                l_vs_val_high.extend(i_vs_id.count);
            END IF;
            -----------
            IF NOT l_vs_val_low.exists(1)
            THEN
                l_vs_val_low.extend(i_vs_id.count);
            END IF;
        END IF;
    
        IF g_sysdate_tstz IS NULL
        THEN
            g_sysdate_tstz := current_timestamp;
        END IF;
    
        IF (i_prof_cat_type IS NULL)
        THEN
            l_dbg_msg := 'CALL pk_prof_utils.get_category';
            pk_alertlog.log_debug(l_dbg_msg);
            l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        ELSE
            l_prof_cat_type := i_prof_cat_type;
        END IF;
    
        l_dbg_msg := 'GET PATIENT ID';
        pk_alertlog.log_debug(l_dbg_msg);
        IF i_pat IS NULL
           AND i_episode IS NOT NULL
        THEN
            SELECT e.id_patient
              INTO l_pat
              FROM episode e
             WHERE e.id_episode = i_episode;
        
        ELSE
            l_pat := i_pat;
        
        END IF;
    
        l_dbg_msg := 'SET VS NOTES';
        pk_alertlog.log_debug(l_dbg_msg);
        IF i_notes IS NOT NULL
        THEN
            l_dbg_msg := 'GET SEQ_VITAL_SIGN_NOTES.NEXTVAL';
            pk_alertlog.log_debug(l_dbg_msg);
            SELECT seq_vital_sign_notes.nextval
              INTO l_next_notes
              FROM dual;
        
            l_dbg_msg := 'INSERT VITAL_SIGN_NOTES';
            pk_alertlog.log_debug(l_dbg_msg);
            INSERT INTO vital_sign_notes
                (id_vital_sign_notes, notes, flg_available, dt_notes_tstz, id_professional, id_episode)
            VALUES
                (l_next_notes, i_notes, pk_alert_constant.g_yes, g_sysdate_tstz, i_prof.id, i_episode);
        
        END IF;
    
        l_dbg_msg := 'OPEN L_VITAL_SIGN_READ';
        pk_alertlog.log_debug(l_dbg_msg);
        o_vital_sign_read := table_number();
        o_vital_sign_read .extend(i_vs_id.count);
    
        -- Loop over the array of IDs of vital signs read
        l_found := 0;
        FOR i IN 1 .. i_vs_id.count
        LOOP
        
            IF l_vs_val_high.exists(i) = FALSE
            THEN
                l_vs_val_high.extend;
                l_vs_val_high(i) := NULL;
            END IF;
            IF l_vs_val_low.exists(i) = FALSE
            THEN
                l_vs_val_low.extend;
                l_vs_val_low(i) := NULL;
            END IF;
        
            IF i_vs_val(i) IS NOT NULL
            THEN
                l_found := 1;
            
                l_dbg_msg := 'GET DT_VS_READ';
                pk_alertlog.log_debug(l_dbg_msg);
                IF i_dt_vs_read.count > 0
                   AND i_dt_vs_read(i) IS NOT NULL
                THEN
                    l_dt_vs_read := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_timestamp => i_dt_vs_read(i),
                                                                  i_timezone  => NULL);
                ELSE
                    l_dt_vs_read := g_sysdate_tstz;
                END IF;
            
                l_dbg_msg := 'CALL pk_date_utils.trunc_insttimezone';
                pk_alertlog.log_debug(l_dbg_msg);
                IF i_fetus_vs IS NOT NULL
                THEN
                    l_dt_vs_read := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                     i_timestamp => l_dt_vs_read,
                                                                     i_format    => 'SS') +
                                    numtodsinterval(i_fetus_vs, 'second');
                ELSE
                    l_dt_vs_read := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                     i_timestamp => l_dt_vs_read,
                                                                     i_format    => 'MI');
                END IF;
            
                --check to see if the its an edition                 
                l_id_vital_sign_read := NULL;
            
                IF i_vs_scales_elements.exists(i)
                   AND i_vs_scales_elements(i) IS NOT NULL
                THEN
                    BEGIN
                        SELECT vsr.id_vital_sign_read, pk_date_utils.date_send_tsz(i_lang, vsr.dt_registry, i_prof)
                          INTO l_id_vital_sign_read, o_dt_registry
                          FROM vital_sign_read vsr
                         WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                           AND vsr.id_patient = i_pat
                           AND vsr.id_vital_sign = i_vs_id(i)
                           AND vsr.id_vs_scales_element = i_vs_scales_elements(i)
                           AND vsr.flg_state != c_flg_status_cancelled;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_id_vital_sign_read := NULL;
                    END;
                ELSE
                
                    BEGIN
                        SELECT vsr.id_vital_sign_read, pk_date_utils.date_send_tsz(i_lang, vsr.dt_registry, i_prof)
                          INTO l_id_vital_sign_read, o_dt_registry
                          FROM vital_sign_read vsr
                         WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                           AND vsr.id_patient = i_pat
                           AND vsr.id_vital_sign = i_vs_id(i)
                           AND vsr.flg_state != c_flg_status_cancelled;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_id_vital_sign_read := NULL;
                    END;
                
                END IF;
            
                IF l_id_vital_sign_read IS NOT NULL
                THEN
                    IF i_id_edit_reason.exists(i)
                    THEN
                        l_id_edit_reason := i_id_edit_reason(i);
                    ELSE
                        l_id_edit_reason := NULL;
                    END IF;
                
                    IF i_notes_edit.exists(i)
                    THEN
                        l_notes_edit := i_notes_edit(i);
                    ELSE
                        l_notes_edit := NULL;
                    END IF;
                
                    IF NOT pk_vital_sign.edit_vital_sign(i_lang                    => i_lang,
                                                         i_prof                    => i_prof,
                                                         i_id_vital_sign_read      => table_number(l_id_vital_sign_read),
                                                         i_value                   => table_number(i_vs_val(i)),
                                                         i_id_unit_measure         => table_number(i_unit_meas(i)),
                                                         i_dt_vital_sign_read_tstz => i_dt_vs_read(i),
                                                         i_dt_registry             => i_dt_vs_read(i),
                                                         i_id_unit_measure_sel     => table_number(i_unit_meas_convert(i)),
                                                         i_tbtb_attribute          => i_tbtb_attribute,
                                                         i_tbtb_free_text          => i_tbtb_free_text,
                                                         i_id_edit_reason          => l_id_edit_reason,
                                                         i_notes_edit              => l_notes_edit,
                                                         i_value_high              => table_number(l_vs_val_high(i)),
                                                         i_value_low               => table_number(l_vs_val_low(i)),
                                                         i_id_epis_documentation   => i_id_epis_documentation,
                                                         o_error                   => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                    SELECT pk_date_utils.date_send_tsz(i_lang, vsr.dt_registry, i_prof)
                      INTO o_dt_registry
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign_read = l_id_vital_sign_read;
                
                    o_vital_sign_read(i) := l_id_vital_sign_read;
                
                ELSE
                    l_dbg_msg := 'GET VS FLG FILL TYPE';
                    pk_alertlog.log_debug(l_dbg_msg);
                    SELECT flg_fill_type
                      INTO l_flg
                      FROM vital_sign
                     WHERE id_vital_sign = i_vs_id(i);
                
                    l_dbg_msg := 'GET VITAL_SIGN_READ NEXTKEY';
                    pk_alertlog.log_debug(l_dbg_msg);
                    l_next := ts_vital_sign_read.next_key();
                    o_vital_sign_read(i) := l_next;
                
                    IF i_vs_scales_elements.exists(i)
                       AND i_vs_scales_elements(i) IS NOT NULL
                    THEN
                    
                        l_vs_scales_elements := i_vs_scales_elements(i);
                        l_dbg_msg            := 'GET id_vital_sign_desc. id_vs_scales_element: ' ||
                                                i_vs_scales_elements(i);
                        pk_alertlog.log_debug(l_dbg_msg);
                        SELECT id_vital_sign_desc
                          INTO l_id_vital_sign_desc_in
                          FROM vital_sign_scales_element vs
                         WHERE vs.id_vs_scales_element = i_vs_scales_elements(i);
                    
                        IF l_id_vital_sign_desc_in IS NULL
                        THEN
                            IF i_unit_meas_convert.exists(i)
                               AND i_unit_meas_convert(i) IS NOT NULL
                               AND i_unit_meas(i) IS NOT NULL
                               AND i_unit_meas_convert(i) <> i_unit_meas(i)
                            THEN
                                l_value_in := pk_unit_measure.get_unit_mea_conversion(i_vs_val(i),
                                                                                      i_unit_meas_convert(i),
                                                                                      i_unit_meas(i));
                            ELSE
                                l_value_in := i_vs_val(i);
                            END IF;
                        ELSE
                            l_value_in := NULL;
                        END IF;
                    ELSE
                        l_vs_scales_elements := NULL;
                        CASE l_flg
                            WHEN pk_alert_constant.g_vs_ft_multichoice THEN
                                l_id_vital_sign_desc_in := i_vs_val(i);
                                l_value_in              := NULL;
                            ELSE
                                l_id_vital_sign_desc_in := NULL;
                                IF i_unit_meas_convert.exists(i)
                                   AND i_unit_meas_convert(i) IS NOT NULL
                                   AND i_unit_meas(i) IS NOT NULL
                                   AND i_unit_meas_convert(i) <> i_unit_meas(i)
                                THEN
                                    l_value_in := pk_unit_measure.get_unit_mea_conversion(i_vs_val(i),
                                                                                          i_unit_meas_convert(i),
                                                                                          i_unit_meas(i));
                                ELSE
                                    l_value_in := i_vs_val(i);
                                END IF;
                        END CASE;
                    END IF;
                
                    IF i_unit_meas_convert.exists(i)
                       AND i_unit_meas_convert(i) IS NOT NULL
                    THEN
                        l_id_unit_measure_sel := i_unit_meas_convert(i);
                    ELSE
                        l_id_unit_measure_sel := i_unit_meas(i);
                    END IF;
                
                    l_dbg_msg := 'INSERT VITAL_SIGN_READ';
                    pk_alertlog.log_debug(l_dbg_msg);
                    ts_vital_sign_read.ins(id_vital_sign_read_in        => l_next,
                                           dt_vital_sign_read_tstz_in   => l_dt_vs_read,
                                           id_vital_sign_in             => i_vs_id(i),
                                           id_episode_in                => i_episode,
                                           id_vital_sign_desc_in        => l_id_vital_sign_desc_in,
                                           value_in                     => l_value_in,
                                           id_unit_measure_in           => i_unit_meas(i),
                                           flg_state_in                 => pk_alert_constant.g_active,
                                           id_prof_read_in              => i_prof.id,
                                           id_patient_in                => l_pat,
                                           id_monitorization_vs_plan_in => i_id_monit,
                                           id_institution_read_in       => i_prof.institution,
                                           id_software_read_in          => i_prof.software,
                                           id_vital_sign_notes_in       => l_next_notes,
                                           dt_registry_in               => g_sysdate_tstz,
                                           id_vs_scales_element_in      => l_vs_scales_elements,
                                           id_epis_triage_in            => i_epis_triage,
                                           id_unit_measure_sel_in       => l_id_unit_measure_sel,
                                           value_high_in                => l_vs_val_high(i),
                                           value_low_in                 => l_vs_val_low(i),
                                           id_epis_documentation_in     => i_id_epis_documentation,
                                           rows_out                     => rows_vsr_out);
                
                    o_dt_registry := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'VITAL_SIGN_READ',
                                                  i_rowids     => rows_vsr_out,
                                                  o_error      => o_error);
                
                    -- insert attributes        
                    IF i_tbtb_attribute.exists(i)
                       AND i_tbtb_free_text.exists(i)
                    THEN
                        l_dbg_msg := 'call pk_vital_sign_core.set_vs_read_attribute';
                        pk_alertlog.log_debug(l_dbg_msg);
                        IF NOT pk_vital_sign_core.set_vs_read_attribute(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_id_vital_sign_read => l_next,
                                                                        i_tb_attribute       => i_tbtb_attribute(i),
                                                                        i_tb_free_text       => i_tbtb_free_text(i),
                                                                        o_error              => o_error)
                        THEN
                            RAISE l_exception;
                        END IF;
                    END IF;
                END IF;
            
                -----------------------------------------------------------------
                -- try to cancel percentile vital sign (internally it verifies if it exists)
                IF NOT pk_percentile.set_percentile_vs(i_lang               => i_lang,
                                                       i_prof               => i_prof,
                                                       i_patient            => i_pat,
                                                       i_episode            => i_episode,
                                                       i_id_vital_sign_read => o_vital_sign_read(i),
                                                       o_error              => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                -----------------------------------------------------------------
                -- try to set bmi if 'VS_BMI_CALC' is configured as 'Y' (internally it verifies if it exists)
                IF (l_vs_bmi_calc = pk_alert_constant.g_yes AND (g_vs_weight = i_vs_id(i) OR g_vs_height = i_vs_id(i)))
                THEN
                    -- check if bmi vital sign included in this saving info, if no, then set bmi
                    BEGIN
                        SELECT COUNT(*)
                          INTO l_cnt_bmi
                          FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                 column_value id_vital_sign, rownum rn
                                  FROM TABLE(i_vs_id) t) tt1,
                               (SELECT /*+opt_estimate(table t rows=1)*/
                                 column_value dt_vs_read, rownum rn
                                  FROM TABLE(i_dt_vs_read) t) tt2
                         WHERE tt1.rn = tt2.rn
                           AND tt1.id_vital_sign = g_vs_bmi
                           AND tt2.dt_vs_read = i_dt_vs_read(i);
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_cnt_bmi := 0;
                    END;
                
                    IF l_cnt_bmi IS NULL
                       OR l_cnt_bmi = 0
                    THEN
                        IF NOT pk_vital_sign.set_vs_bmi_auto(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_id_episode         => i_episode,
                                                             i_id_patient         => i_pat,
                                                             i_id_vital_sign_read => o_vital_sign_read(i),
                                                             o_error              => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        IF i_episode IS NOT NULL
           AND i_episode != -1
           AND l_found = 1
        THEN
            l_dbg_msg := 'CALL TO SET_FIRST_OBS';
            pk_alertlog.log_debug(l_dbg_msg);
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => l_pat,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => l_prof_cat_type,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RETURN FALSE;
            
            END IF;
        
            IF l_next IS NOT NULL
            THEN
                l_dbg_msg := 'WRITTING INTO THE STATUS LOG';
                pk_alertlog.log_debug(l_dbg_msg);
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_id_episode => i_episode,
                                        i_flg_status => pk_alert_constant.g_active,
                                        i_id_record  => l_next,
                                        i_flg_type   => pk_alert_constant.g_ti_type_vs,
                                        o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            l_dbg_msg := 'SET PRE_HOSP VS_READ';
            pk_alertlog.log_debug(l_dbg_msg);
            IF NOT pk_pre_hosp_accident.update_pre_hosp_vs(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_episode    => i_episode,
                                                           i_vs_read    => o_vital_sign_read,
                                                           i_flg_commit => FALSE,
                                                           o_vs_read    => l_vs_read_pre_hosp,
                                                           o_error      => o_error)
            THEN
                RETURN FALSE;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            o_vital_sign_read := table_number();
            RETURN FALSE;
        
    END set_epis_vital_sign;

    /**************************************************************************
    * Returns the data of all the required vital signs in a set of discriminators.
    *   
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_tbl_vital_sign         Table with vital signs IDs
    * @param i_flg_view               Area of the application
    * @param i_relation_domain        Relation domain. 'M'- TRTS; 'T' - Others
    * @param o_sign_v                 Cursor with the vital sign data
    * @param o_error                  Error message
    *
    * @return                         TRUE / FALSE
    *                        
    * @author                         Jos?Brito
    * @version                        2.6
    * @since                          23/11/2009
    **************************************************************************/
    FUNCTION get_vs_triage_header
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_vital_sign  IN table_number,
        i_flg_view        IN vs_soft_inst.flg_view%TYPE,
        i_relation_domain IN vital_sign_relation.relation_domain%TYPE DEFAULT pk_alert_constant.g_vs_rel_group,
        i_patient         IN patient.id_patient%TYPE,
        o_sign_v          OUT cursor_sign_v,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name obj_name := 'GET_VS_TRIAGE_HEADER';
        l_sysdate_char CONSTANT VARCHAR2(50 CHAR) := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        l_param_error EXCEPTION;
        l_dbg_msg    debug_msg;
        l_trts_vs_id table_number;
        l_age        vital_sign_unit_measure.age_min%TYPE;
        l_id_trts    vital_sign.id_vital_sign%TYPE;
    BEGIN
    
        l_dbg_msg := 'VALIDATE PARAMETERS';
        IF NOT i_tbl_vital_sign.exists(1)
        THEN
            l_dbg_msg := 'EMPTY ARRAY';
            RAISE l_param_error;
        END IF;
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', i_patient);
    
        SELECT vsr.id_vital_sign_detail
          BULK COLLECT
          INTO l_trts_vs_id
          FROM vital_sign_relation vsr
          JOIN vital_sign vs
            ON vs.id_vital_sign = vsr.id_vital_sign_detail
         WHERE vsr.id_vital_sign_parent IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             column_value id_vital_sign
                                              FROM TABLE(i_tbl_vital_sign) t)
           AND vsr.relation_domain = i_relation_domain
           AND vsr.flg_available = pk_alert_constant.g_yes;
    
        IF l_trts_vs_id.count > 0
        THEN
        
            SELECT vs.id_vital_sign
              INTO l_id_trts
              FROM vital_sign vs
             WHERE vs.intern_name_vital_sign = pk_edis_triage.g_vs_trts;
        
        END IF;
        l_dbg_msg := 'GET CURSOR O_SIGN_V';
        pk_alertlog.log_debug(l_dbg_msg);
        OPEN o_sign_v FOR
            SELECT a.id_vital_sign,
                   a.internal_name,
                   (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => a.id_vital_sign,
                                                               i_id_unit_measure => a.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) val_min,
                   (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => a.id_vital_sign,
                                                               i_id_unit_measure => a.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => l_age)
                      FROM dual) val_max,
                   a.rank_conc,
                   a.id_vital_sign_parent,
                   (SELECT vs.intern_name_vital_sign
                      FROM vital_sign vs
                     WHERE vs.id_vital_sign = a.id_vital_sign_parent) vs_parent_int_name,
                   a.relation_type,
                   (SELECT pk_vital_sign_core.get_vsum_format_num(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_id_vital_sign   => a.id_vital_sign,
                                                                  i_id_unit_measure => a.id_unit_measure,
                                                                  i_id_institution  => i_prof.institution,
                                                                  i_id_software     => i_prof.software,
                                                                  i_age             => l_age)
                      FROM dual) format_num,
                   a.flg_fill_type,
                   a.flg_sum,
                   a.name_vs,
                   a.desc_unit_measure,
                   a.id_unit_measure,
                   a.dt_server,
                   a.vs_flg_type,
                   a.flg_validate,
                   a.flg_save_to_db,
                   a.flg_show_description,
                   a.flg_calculate_trts
              FROM (
                    -- Normal vital signs + Glasgow Total + Blood pressure (parent)
                    SELECT vs.id_vital_sign,
                            vs.intern_name_vital_sign internal_name,
                            0 rank_conc,
                            NULL id_vital_sign_parent,
                            decode((SELECT COUNT(*)
                                     FROM vital_sign_relation vsr
                                    WHERE vsr.id_vital_sign_parent = vs.id_vital_sign
                                      AND vsr.relation_domain = pk_alert_constant.g_vs_rel_group),
                                   0,
                                   pk_alert_constant.g_vs_rel_sum,
                                   pk_alert_constant.g_vs_rel_group) relation_type,
                            decode((SELECT COUNT(*)
                                     FROM vital_sign_relation vsr
                                    WHERE vsr.id_vital_sign_parent = vs.id_vital_sign
                                      AND vsr.relation_domain = pk_alert_constant.g_vs_rel_group),
                                   0,
                                   CASE vs.intern_name_vital_sign
                                       WHEN 'GLASGOW' THEN
                                        'X'
                                       ELSE
                                        vs.flg_fill_type
                                   END,
                                   pk_alert_constant.g_vs_rel_group) flg_fill_type,
                            CASE vs.intern_name_vital_sign
                                WHEN 'GLASGOW' THEN
                                 pk_alert_constant.g_no
                                ELSE
                                 pk_alert_constant.g_yes
                            END flg_sum,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            CASE
                                 WHEN vsi.id_unit_measure IS NULL THEN
                                  NULL
                                 ELSE
                                  pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                             END desc_unit_measure,
                            vsi.id_unit_measure,
                            l_sysdate_char dt_server,
                            NULL vs_flg_type,
                            -- Flags used by Flash to process vital sign data:
                            -- FLG_VALIDATE: Vital signs used to validade discriminator. Sent as parameter in VALIDATE_DISCRIMINATOR_VS.
                            --               If the vital sign is registered in TRIAGE_TYPE_VS/TRIAGE_VS_AREA it should be sent for validation,
                            --               except for Blood Pressure (parent).
                            CASE vs.intern_name_vital_sign
                                WHEN 'BLOOD_PRESSURE' THEN
                                 pk_alert_constant.g_no
                                ELSE
                                 pk_alert_constant.g_yes
                            END flg_validate,
                            -- FLG_SAVE_TO_DB: Vital sign records saved in Database (VITAL_SIGN_READ).
                            CASE
                                 WHEN vs.intern_name_vital_sign IN ('BLOOD_PRESSURE', 'GLASGOW') THEN
                                  pk_alert_constant.g_no
                                 WHEN vs.intern_name_vital_sign = 'Pupilles' THEN
                                  pk_alert_constant.g_no
                                 ELSE
                                  decode((SELECT COUNT(*)
                                           FROM vital_sign_relation vsr
                                          WHERE vsr.id_vital_sign_parent = vs.id_vital_sign
                                            AND vsr.relation_domain = pk_alert_constant.g_vs_rel_group),
                                         0,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no)
                             END flg_save_to_db,
                            -- FLG_SHOW_DESCRIPTION: Vital sign labels shown in the discriminator list.
                            pk_alert_constant.g_yes flg_show_description,
                            -- FLG_CALCULATE_TRTS: Indicates which vital signs are necessary to calculate the value of TRTS
                            pk_alert_constant.g_no flg_calculate_trts,
                            vsi.rank               db_rank
                      FROM vital_sign vs
                      JOIN vs_soft_inst vsi
                        ON vsi.id_vital_sign = vs.id_vital_sign
                     WHERE vs.flg_available = pk_alert_constant.g_yes
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = i_flg_view
                       AND EXISTS (SELECT 1
                              FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                     column_value id_vital_sign
                                      FROM TABLE(i_tbl_vital_sign) t) a
                             WHERE a.id_vital_sign = vs.id_vital_sign)
                       AND vs.id_vital_sign NOT IN
                           (SELECT vr.id_vital_sign_parent
                              FROM vital_sign_relation vr
                             WHERE vr.relation_domain = pk_alert_constant.g_vs_rel_man
                               AND vr.flg_available = pk_alert_constant.g_yes)
                    UNION ALL
                    -- Blood Pressure (Systolic + Diastolic)
                    SELECT DISTINCT vs.id_vital_sign,
                                     vs.intern_name_vital_sign internal_name,
                                     vr_conc.rank rank_conc,
                                     vr_conc.id_vital_sign_parent,
                                     pk_alert_constant.g_vs_rel_conc relation_type,
                                     vs.flg_fill_type,
                                     pk_alert_constant.g_no flg_sum,
                                     pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                                     pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL) desc_unit_measure,
                                     vsi.id_unit_measure,
                                     l_sysdate_char dt_server,
                                     NULL vs_flg_type,
                                     -- Flags used by Flash to process vital sign data
                                     pk_alert_constant.g_yes flg_validate,
                                     pk_alert_constant.g_yes flg_save_to_db,
                                     pk_alert_constant.g_no  flg_show_description,
                                     pk_alert_constant.g_no  flg_calculate_trts,
                                     vsi.rank                db_rank
                      FROM vital_sign vs
                      JOIN vital_sign_relation vr_conc
                        ON vr_conc.id_vital_sign_detail = vs.id_vital_sign
                      JOIN vs_soft_inst vsi
                        ON vr_conc.id_vital_sign_parent = vsi.id_vital_sign
                     WHERE vs.flg_available = pk_alert_constant.g_yes
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = i_flg_view
                       AND vr_conc.flg_available = pk_alert_constant.g_yes
                       AND vr_conc.id_vital_sign_parent IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             column_value id_vital_sign
                              FROM TABLE(i_tbl_vital_sign) t)
                       AND vr_conc.relation_domain = pk_alert_constant.g_vs_rel_conc
                    UNION ALL
                    
                    -- Glasgow details (Eye + Verbal + Motor)
                    SELECT DISTINCT vs.id_vital_sign,
                                     vs.intern_name_vital_sign internal_name,
                                     vr_conc.rank rank_conc,
                                     vr_conc.id_vital_sign_parent,
                                     pk_alert_constant.g_vs_rel_sum relation_type,
                                     vs.flg_fill_type,
                                     pk_alert_constant.g_yes flg_sum,
                                     pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                                     CASE
                                         WHEN vsi.id_unit_measure IS NULL THEN
                                          NULL
                                         ELSE
                                          pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                                     END desc_unit_measure,
                                     vsi.id_unit_measure,
                                     l_sysdate_char dt_server,
                                     NULL vs_flg_type,
                                     -- Flags used by Flash to process vital sign data
                                     pk_alert_constant.g_no  flg_validate,
                                     pk_alert_constant.g_yes flg_save_to_db,
                                     pk_alert_constant.g_no  flg_show_description,
                                     pk_alert_constant.g_no  flg_calculate_trts,
                                     vsi.rank                db_rank
                      FROM vital_sign vs
                      JOIN vital_sign_relation vr_conc
                        ON vr_conc.id_vital_sign_detail = vs.id_vital_sign
                      JOIN vs_soft_inst vsi
                        ON vsi.id_vital_sign = vs.id_vital_sign
                     WHERE vs.flg_available = pk_alert_constant.g_yes
                       AND vr_conc.id_vital_sign_parent IN
                           (SELECT /*+opt_estimate(table t rows=1)*/
                             column_value id_vital_sign
                              FROM TABLE(i_tbl_vital_sign) t)
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = i_flg_view
                       AND vr_conc.relation_domain = pk_alert_constant.g_vs_rel_sum
                       AND vr_conc.flg_available = pk_alert_constant.g_yes
                    
                    UNION ALL
                    
                    -- TRTS vital signs: Resp. Rate + Glasgow + Blood Pressure
                    SELECT vsr.id_vital_sign_detail,
                            vs.intern_name_vital_sign internal_name,
                            CASE vs.intern_name_vital_sign
                                WHEN 'BLOOD_PRESSURE' THEN
                                 0
                                WHEN 'BLOOD_PRESSURE_S' THEN
                                 1
                                WHEN 'BLOOD_PRESSURE_D' THEN
                                 2
                                WHEN 'GLASGOW' THEN
                                 decode(i_relation_domain, pk_alert_constant.g_vs_rel_man, 0, vsr.rank)
                                ELSE
                                 vsr.rank
                            END rank_conc,
                            vsr.id_vital_sign_parent,
                            vsr.relation_domain relation_type,
                            decode(vs.intern_name_vital_sign, 'GLASGOW', 'X', vs.flg_fill_type) flg_fill_type,
                            CASE vsr.relation_domain
                                WHEN pk_alert_constant.g_vs_rel_sum THEN
                                 CASE vs.intern_name_vital_sign
                                     WHEN 'GLASGOW' THEN
                                      pk_alert_constant.g_no
                                     ELSE
                                      pk_alert_constant.g_yes
                                 END
                                ELSE
                                 pk_alert_constant.g_no
                            END flg_sum,
                            pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                            CASE
                                WHEN vsi.id_unit_measure IS NULL THEN
                                 NULL
                                ELSE
                                 pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                            END desc_unit_measure,
                            vsi.id_unit_measure,
                            l_sysdate_char dt_server,
                            NULL vs_flg_type,
                            -- Flags used by Flash to process vital sign data
                            pk_alert_constant.g_no flg_validate,
                            CASE vs.intern_name_vital_sign
                                WHEN 'BLOOD_PRESSURE' THEN
                                 pk_alert_constant.g_no
                                WHEN 'GLASGOW' THEN
                                 pk_alert_constant.g_no
                                ELSE
                                 pk_alert_constant.g_yes
                            END flg_save_to_db,
                            pk_alert_constant.g_no flg_show_description,
                            CASE vs.intern_name_vital_sign
                                WHEN 'BLOOD_PRESSURE' THEN
                                 pk_alert_constant.g_no
                                ELSE
                                 pk_alert_constant.g_yes
                            END flg_calculate_trts,
                            vsi.rank db_rank
                      FROM vital_sign vs
                      JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_detail = vs.id_vital_sign
                       AND vsr.relation_domain = i_relation_domain
                       AND vsr.flg_available = pk_alert_constant.g_yes
                      JOIN vs_soft_inst vsi
                        ON vsi.id_vital_sign = vs.id_vital_sign
                       AND vs.flg_available = pk_alert_constant.g_yes
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = i_flg_view
                     WHERE vs.id_vital_sign IN ((SELECT /*+opt_estimate(table t rows=1)*/
                                                 column_value
                                                  FROM TABLE(l_trts_vs_id) t))
                    
                    UNION
                    
                    SELECT DISTINCT vsr.id_vital_sign_detail,
                                     vs.intern_name_vital_sign internal_name,
                                     CASE vs.intern_name_vital_sign
                                         WHEN 'BLOOD_PRESSURE' THEN
                                          0
                                         WHEN 'BLOOD_PRESSURE_S' THEN
                                          1
                                         WHEN 'BLOOD_PRESSURE_D' THEN
                                          2
                                     
                                         ELSE
                                          vsr.rank
                                     END rank_conc,
                                     CASE nvl(vsr.id_vital_sign_relation, 0)
                                         WHEN 0 THEN
                                          vsr.id_vital_sign_parent
                                         ELSE
                                          decode(i_relation_domain, pk_alert_constant.g_vs_rel_man, l_id_trts, NULL)
                                     END id_vital_sign_parent,
                                     -- vsr.id_vital_sign_parent id_vital_sign_parent,
                                     nvl(vsr.relation_domain, vsr.relation_domain) relation_type,
                                     decode(vs.intern_name_vital_sign, 'GLASGOW', 'X', vs.flg_fill_type) flg_fill_type,
                                     CASE vsr.relation_domain
                                         WHEN pk_alert_constant.g_vs_rel_sum THEN
                                          CASE vs.intern_name_vital_sign
                                              WHEN 'GLASGOW' THEN
                                               pk_alert_constant.g_no
                                              ELSE
                                               pk_alert_constant.g_yes
                                          END
                                         ELSE
                                          pk_alert_constant.g_no
                                     END flg_sum,
                                     pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                                     CASE
                                         WHEN vsi.id_unit_measure IS NULL THEN
                                          NULL
                                         ELSE
                                          pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                                     END desc_unit_measure,
                                     vsi.id_unit_measure,
                                     l_sysdate_char dt_server,
                                     NULL vs_flg_type,
                                     -- Flags used by Flash to process vital sign data
                                     pk_alert_constant.g_no flg_validate,
                                     CASE vs.intern_name_vital_sign
                                         WHEN 'BLOOD_PRESSURE' THEN
                                          pk_alert_constant.g_no
                                         WHEN 'GLASGOW' THEN
                                          pk_alert_constant.g_no
                                         ELSE
                                          pk_alert_constant.g_yes
                                     END flg_save_to_db,
                                     pk_alert_constant.g_no flg_show_description,
                                     CASE vs.intern_name_vital_sign
                                         WHEN 'BLOOD_PRESSURE' THEN
                                          pk_alert_constant.g_no
                                         ELSE
                                          pk_alert_constant.g_yes
                                     END flg_calculate_trts,
                                     vsi.rank db_rank
                      FROM vital_sign vs
                      JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_detail = vs.id_vital_sign
                       AND vsr.relation_domain != pk_alert_constant.g_vs_rel_group
                      JOIN vs_soft_inst vsi
                        ON vsi.id_vital_sign = vs.id_vital_sign
                       AND vs.flg_available = pk_alert_constant.g_yes
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = i_flg_view
                     WHERE vsr.id_vital_sign_parent IN ((SELECT /*+opt_estimate(table t rows=1)*/
                                                         column_value
                                                          FROM TABLE(l_trts_vs_id) t))
                       AND vsr.flg_available = pk_alert_constant.g_yes
                    
                    UNION ALL
                    -- TRTS (parent)
                    SELECT DISTINCT vs.id_vital_sign,
                                     vs.intern_name_vital_sign internal_name,
                                     decode(i_relation_domain, pk_alert_constant.g_vs_rel_man, 99, 0) rank_conc,
                                     NULL id_vital_sign_parent,
                                     vsr.relation_domain relation_type,
                                     'TRTS' flg_fill_type,
                                     pk_alert_constant.g_no flg_sum,
                                     pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                                     CASE
                                         WHEN vsi.id_unit_measure IS NULL THEN
                                          NULL
                                         ELSE
                                          pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                                     END desc_unit_measure,
                                     vsi.id_unit_measure,
                                     l_sysdate_char dt_server,
                                     pk_alert_constant.g_vs_rel_man vs_flg_type,
                                     -- Flags used by Flash to process vital sign data
                                     pk_alert_constant.g_yes flg_validate,
                                     pk_alert_constant.g_yes flg_save_to_db,
                                     pk_alert_constant.g_yes flg_show_description,
                                     pk_alert_constant.g_no  flg_calculate_trts,
                                     vsi.rank                db_rank
                      FROM vital_sign vs
                      JOIN vs_soft_inst vsi
                        ON vsi.id_vital_sign = vs.id_vital_sign
                      JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_parent = vs.id_vital_sign
                     WHERE vs.id_vital_sign IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                 column_value id_vital_sign
                                                  FROM TABLE(i_tbl_vital_sign) t)
                       AND vsr.relation_domain = pk_alert_constant.g_vs_rel_man
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsr.flg_available = pk_alert_constant.g_yes
                    
                    UNION
                    
                    SELECT DISTINCT vsr.id_vital_sign_detail,
                                     vs.intern_name_vital_sign internal_name,
                                     vsr.rank rank_conc,
                                     vsr.id_vital_sign_parent,
                                     vsr.relation_domain relation_type,
                                     vs.flg_fill_type,
                                     pk_alert_constant.g_no flg_sum,
                                     pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                                     CASE
                                         WHEN vsi.id_unit_measure IS NULL THEN
                                          NULL
                                         ELSE
                                          pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL)
                                     END desc_unit_measure,
                                     vsi.id_unit_measure,
                                     l_sysdate_char dt_server,
                                     NULL vs_flg_type,
                                     -- Flags used by Flash to process vital sign data
                                     pk_alert_constant.g_no flg_validate,
                                     decode(vsr.id_vital_sign_parent,
                                            NULL,
                                            pk_alert_constant.g_no,
                                            pk_alert_constant.g_yes) flg_save_to_db,
                                     pk_alert_constant.g_no flg_show_description,
                                     pk_alert_constant.g_yes flg_calculate_trts,
                                     vsi.rank db_rank
                      FROM vital_sign vs
                      JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_detail = vs.id_vital_sign
                       AND vsr.relation_domain = pk_alert_constant.g_vs_rel_group
                      JOIN vs_soft_inst vsi
                        ON vsi.id_vital_sign = vs.id_vital_sign
                       AND vs.flg_available = pk_alert_constant.g_yes
                       AND vsi.id_software = i_prof.software
                       AND vsi.id_institution = i_prof.institution
                       AND vsi.flg_view = i_flg_view
                     WHERE vsr.id_vital_sign_detail IN ((SELECT /*+opt_estimate(table t rows=1)*/
                                                         column_value
                                                          FROM TABLE(l_trts_vs_id) t))
                       AND vsr.flg_available = pk_alert_constant.g_yes
                       AND NOT EXISTS (SELECT 1
                              FROM vital_sign_relation vsr1
                             WHERE vsr1.relation_domain = pk_alert_constant.g_vs_rel_man
                               AND vsr1.id_vital_sign_detail = vsr.id_vital_sign_detail)) a
            
             ORDER BY a.db_rank ASC, a.rank_conc ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_param_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              'PARAM ERROR',
                                              'INVALID PARAMETER FOUND',
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            open_my_cursor(o_sign_v);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            open_my_cursor(o_sign_v);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vs_triage_header;
    --
    /********************************************************************************************
    * Obter todas as notas dos sinais vitais associadas ao epis�dio
        *
    * @param i_vs_parent        ID da rela��o dos sinais vitais da press�o arterial
        * @param i_episode          episode id
    *
    * @return                   description
    *
    * @author                   Emilia Taborda
    * @version                  1.0
    * @since                    2006/08/30
    ********************************************************************************************/
    FUNCTION get_vital_sign_val_bp
    (
        i_vs_parent      IN vital_sign_relation.id_vital_sign_parent%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_decimal_symbol IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_val_bp_d VARCHAR2(20 CHAR);
        l_val_bp_s VARCHAR2(20 CHAR);
        --
        --PRESS�O ARTERIAL
        CURSOR c_bp
        (
            i_episode   IN NUMBER,
            i_vs_parent IN vital_sign_relation.id_vital_sign_parent%TYPE
        ) IS
            SELECT pk_utils.to_str(ea.value, i_decimal_symbol) VALUE
              FROM vital_signs_ea ea, vital_sign vs
             WHERE ea.id_episode = i_episode
               AND ea.id_vital_sign IN (SELECT id_vital_sign_detail
                                          FROM vital_sign_relation
                                         WHERE relation_domain = pk_alert_constant.g_vs_rel_conc
                                           AND id_vital_sign_parent = i_vs_parent
                                           AND flg_available = pk_alert_constant.g_yes)
               AND ea.flg_state = pk_alert_constant.g_active
               AND vs.id_vital_sign = ea.id_vital_sign
               AND pk_delivery.check_vs_read_from_fetus(ea.id_vital_sign_read) = 0
             ORDER BY vs.intern_name_vital_sign;
    BEGIN
        -- TRATAMENTO DA PRESS�O ARTERIAL
        FOR wrec_bp IN c_bp(i_episode, i_vs_parent)
        LOOP
            IF nvl(l_val_bp_d, -1) = -1
            THEN
                l_val_bp_d := to_char(wrec_bp.value);
            ELSE
                l_val_bp_s := to_char(wrec_bp.value);
            END IF;
        END LOOP;
        RETURN l_val_bp_s || '/' || l_val_bp_d;
    END;

    --
    FUNCTION cancel_biometric_read
    (
        i_lang  IN language.id_language%TYPE,
        i_vs    IN vital_sign_read.id_vital_sign_read%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Cancelar uma leitura de SV
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional
                   I_PATIENT - ID do paciente
                 I_VS - SV q se pretende cancelar
                 I_PROF - prof. respons�vel pelo cancelamento
                  Saida: O_ERROR - erro
          CRIA��O: ASM 2007/01/10
          ALTERA��O:
          NOTAS:
        *********************************************************************************/
        l_char VARCHAR2(1 CHAR);
        --
        CURSOR c_vs IS
            SELECT 'X'
              FROM vital_sign_read
             WHERE id_vital_sign_read = i_vs
               AND flg_state = pk_alert_constant.g_cancelled;
        -- denormalization variables
        rows_vsr_out table_varchar;
        l_found      BOOLEAN;
        l_sysdate_tstz CONSTANT vital_sign_read.dt_cancel_tstz%TYPE := current_timestamp;
        l_dbg_msg debug_msg;
        l_vs      vital_sign.id_vital_sign%TYPE;
        l_exception EXCEPTION;
    BEGIN
        l_dbg_msg := 'GET CURSOR C_VS';
        OPEN c_vs;
        FETCH c_vs
            INTO l_char;
        l_found := c_vs%FOUND;
        CLOSE c_vs;
        --
        IF l_found
        THEN
            l_dbg_msg := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'), '@1', 'sinal vital');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_BIOMETRIC_READ',
                                              o_error);
            RETURN FALSE;
        END IF;
        l_dbg_msg := 'UPDATE OTHER VS';
        -- CHAMAR O UPDATE DO PACKAGE TS_VITAL_SIGN_READ
        ts_vital_sign_read.upd(id_vital_sign_read_in    => i_vs,
                               dt_cancel_tstz_in        => l_sysdate_tstz,
                               flg_state_in             => pk_alert_constant.g_cancelled,
                               id_prof_cancel_in        => i_prof.id,
                               id_institution_cancel_in => i_prof.institution,
                               id_software_cancel_in    => i_prof.software,
                               rows_out                 => rows_vsr_out);
    
        -- CHAMAR O PROCEDIMENTO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => NULL,
                                      i_table_name => 'VITAL_SIGN_READ',
                                      i_rowids     => rows_vsr_out,
                                      o_error      => o_error);
        BEGIN
            SELECT vsr.id_vital_sign
              INTO l_vs
              FROM vital_sign_read vsr
             WHERE id_vital_sign_read = i_vs;
        EXCEPTION
            WHEN no_data_found THEN
                l_vs := NULL;
        END;
        --notify pdms that a vital sign was cancelled
        l_dbg_msg := 'call pk_api_pdms_core_in.cancel_vs_pdms';
        IF NOT pk_api_pdms_core_in.cancel_vs_pdms(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_id_vs      => table_number(l_vs),
                                                  i_id_vs_read => table_number(i_vs),
                                                  o_error      => o_error)
        THEN
        
            RAISE l_exception;
        END IF;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_BIOMETRIC_READ',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /************************************************************************************************************
    * Esta fun��o calcula o valor para o eixo dos Xs. Este valor corresponde ?diferen�a entre a data
    * do registo do par�metro e a data de nascimento do paciente convertida para a escala do gr�fico.
    *
    * @param      i_data_str          Data do registo
    * @param      i_patient           ID do paciente
    * @param      i_flg_x             Tipo da escala do gr�fico (M ou Y)
    *
    * @return     o valor do eixo do Xs na respectiva escala
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/11/05
    ***********************************************************************************************************/
    FUNCTION get_graph_x_value
    (
        i_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_read_min IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_flg_x       IN graphic.flg_x_axis_type%TYPE
    ) RETURN NUMBER IS
        l_result NUMBER;
    BEGIN
        IF i_flg_x = c_axis_type_month
        THEN
            l_result := round(months_between(CAST(i_dt_read AS DATE), CAST(i_dt_read_min AS DATE)), 2);
        ELSIF i_flg_x = c_axis_type_year
        THEN
            l_result := pk_date_utils.get_timestamp_diff(i_timestamp_1 => i_dt_read, i_timestamp_2 => i_dt_read_min);
            l_result := round((l_result / 365), 2);
        END IF;
    
        RETURN l_result;
    END get_graph_x_value;
    /************************************************************************************************************
    * Esta fun��o retorna a informa��o para construir o menu lateral dos ecr�s dos gr�ficos
    * na biometria.
    *
    * @param      i_lang              L�ngua registada como prefer�ncia do profissional
    * @param      i_prof              ID do profissional, software e institui��o
    * @param      i_patient           ID do paciente
    * @param      i_id_biometry       ID de um par�metro da biometria, ou null
    *
    * @param      o_menu_title        Label com o t�tulo do menu
    * @param      o_menu              Cursor com a informa��o dos menus
    * @param      o_menu_filters      Cursor com a informa��o dos filtros do ecr?
    * @param      o_error             Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/10/31
    ***********************************************************************************************************/
    FUNCTION get_biometric_graphs_menu
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        o_menu_title    OUT sys_message.desc_message%TYPE,
        o_menu          OUT pk_types.cursor_type,
        o_menu_filters  OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dbg_msg     debug_msg;
        l_graphs      table_number := table_number();
        l_sel_graphic graphic.id_graphic%TYPE;
    
    BEGIN
        o_menu_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'BIOMETRICS_T006');
    
        -- get available graphics
        l_dbg_msg := 'CALL get_graphics_by_patient';
        IF NOT get_graphics_by_patient(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => i_patient,
                                       o_graphs  => l_graphs,
                                       o_error   => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_menu);
            pk_types.open_my_cursor(i_cursor => o_menu_filters);
            RETURN FALSE;
        END IF;
    
        -- get graphic that should be selected
        l_sel_graphic := CASE
                             WHEN i_id_vital_sign IS NULL THEN
                              NULL
                             ELSE
                              get_selected_graphic(i_id_vital_sign => i_id_vital_sign, i_graphs => l_graphs)
                         END;
    
        --devolve a informa��o para construir o menu
        OPEN o_menu FOR
            SELECT g.id_graphic AS id,
                   pk_vital_sign.get_graph_menu_name(pk_translation.get_translation(i_lang, g.code_graphic)) AS menu_name,
                   pk_vital_sign.get_graph_menu_time_period(pk_translation.get_translation(i_lang, g.code_graphic)) AS menu_time_period,
                   g.rank,
                   g.graphic_color AS color_grafh,
                   g.graphic_text_color AS color_text,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, g.id_unit_measure) AS unit_measure,
                   CASE
                        WHEN l_sel_graphic IS NULL THEN
                         CASE rownum
                             WHEN 1 THEN
                              'true'
                             ELSE
                              'false'
                         END
                        ELSE
                         CASE g.id_graphic
                             WHEN l_sel_graphic THEN
                              'true'
                             ELSE
                              'false'
                         END
                    END AS selected
              FROM (SELECT g.id_graphic,
                           g.code_graphic,
                           g.rank,
                           g.graphic_color,
                           g.graphic_text_color,
                           g.id_unit_measure,
                           g.id_related_object
                      FROM graphic g
                     WHERE g.id_graphic IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             t.column_value AS id_graphic
                                              FROM TABLE(l_graphs) t)
                     ORDER BY g.rank) g;
    
        --tratamentos dos filtros
        --envia a lista de filtros indicando qual o filtro seleccionado por defeito
        --TODO: Este valor devia ser parametrizado!
        OPEN o_menu_filters FOR
            SELECT filters.id,
                   filters.desc_info,
                   CASE filters.id
                       WHEN c_def_graphic_filter THEN
                        'true'
                       ELSE
                        'false'
                   END AS selected
              FROM TABLE(pk_vital_sign.get_biometric_graph_filters(i_lang)) filters;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_BIOMETRIC_GRAPHS_MENU',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_menu);
            pk_types.open_my_cursor(i_cursor => o_menu_filters);
            RETURN FALSE;
        
    END get_biometric_graphs_menu;

    /**
    * Get available graphics. Adapted from GET_BIOMETRIC_GRAPHS_MENU.
    * For reports layer usage only.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_menu         available graphics cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.6
    * @since                2011/07/19
    */
    FUNCTION get_biometric_graphs_rep
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_menu    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dbg_msg        debug_msg;
        l_pat_age_years  patient.age%TYPE;
        l_pat_age_months patient.age%TYPE;
        l_pat_gender     patient.gender%TYPE;
        l_graphs         table_number := table_number();
    BEGIN
        --get patient age
        l_dbg_msg        := 'CALL pk_patient.get_pat_age';
        l_pat_age_years  := pk_patient.get_pat_age(i_lang        => i_lang,
                                                   i_dt_birth    => NULL,
                                                   i_dt_deceased => NULL,
                                                   i_age         => NULL,
                                                   i_age_format  => 'YEARS',
                                                   i_patient     => i_patient);
        l_pat_age_months := pk_patient.get_pat_age(i_lang        => i_lang,
                                                   i_dt_birth    => NULL,
                                                   i_dt_deceased => NULL,
                                                   i_age         => NULL,
                                                   i_age_format  => 'MONTHS',
                                                   i_patient     => i_patient);
    
        pk_alertlog.log_debug(l_dbg_msg);
    
        -- get patient gender
        l_dbg_msg := 'CALL pk_patient.get_pat_gender';
        pk_alertlog.log_debug(l_dbg_msg);
        l_pat_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
    
        -- check available graphics
        l_dbg_msg := 'SELECT l_graphs ranged';
        SELECT g.id_graphic
          BULK COLLECT
          INTO l_graphs
          FROM graphic g
          JOIN graphic_soft_inst gsi
            ON g.id_graphic = gsi.id_graphic
         WHERE g.patient_gender = l_pat_gender
           AND gsi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
           AND gsi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution)
              --AND l_pat_age BETWEEN pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_start) AND
              --    pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_end);
           AND pk_vital_sign.check_age(i_lang           => i_lang,
                                       l_pat_age_months => l_pat_age_months,
                                       l_pat_age_years  => l_pat_age_years,
                                       i_type           => g.flg_x_axis_type,
                                       i_x_axis_start   => g.x_axis_start,
                                       i_x_axis_end     => g.x_axis_end,
                                       i_age_min        => g.age_min,
                                       i_age_max        => g.age_max) = 'Y'
         ORDER BY gsi.rank;
    
        IF l_graphs.count = 0
        THEN
            l_dbg_msg := 'SELECT l_graphs no range';
            SELECT id_graphic
              BULK COLLECT
              INTO l_graphs
              FROM (SELECT g.id_graphic,
                           row_number() over(PARTITION BY g.id_related_object --
                           ORDER BY pk_vital_sign.get_year_value(g.flg_x_axis_type, g.x_axis_end) DESC) rn
                      FROM graphic g
                      JOIN graphic_soft_inst gsi
                        ON g.id_graphic = gsi.id_graphic
                     WHERE g.patient_gender = l_pat_gender
                       AND gsi.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                       AND gsi.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution))
             WHERE rn = 1;
        END IF;
    
        l_dbg_msg := 'OPEN o_menu';
        OPEN o_menu FOR
            SELECT g.id_graphic AS id,
                   pk_vital_sign.get_graph_menu_name(pk_translation.get_translation(i_lang, g.code_graphic)) AS menu_name,
                   pk_vital_sign.get_graph_menu_time_period(pk_translation.get_translation(i_lang, g.code_graphic)) AS menu_time_period,
                   g.rank,
                   g.graphic_color AS color_grafh,
                   g.graphic_text_color AS color_text,
                   pk_unit_measure.get_unit_measure_description(i_lang, i_prof, g.id_unit_measure) AS unit_measure,
                   'false' AS selected
              FROM (SELECT g.id_graphic,
                           g.code_graphic,
                           g.rank,
                           g.graphic_color,
                           g.graphic_text_color,
                           g.id_unit_measure,
                           g.id_related_object
                      FROM graphic g
                     WHERE g.id_graphic IN (SELECT /*+opt_estimate(table t rows=1)*/
                                             t.column_value AS id_graphic
                                              FROM TABLE(l_graphs) t)
                     ORDER BY g.rank) g;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_BIOMETRIC_GRAPHS_REP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_menu);
            RETURN FALSE;
    END get_biometric_graphs_rep;

    /************************************************************************************************************
    * Esta fun��o retorna a informa��o para construir o menu lateral dos ecr�s dos gr�ficos
    * na biometria.
    *
    * @param      i_lang              L�ngua registada como prefer�ncia do profissional
    * @param      i_prof              ID do profissional, software e institui��o
    * @param      i_patient           ID do paciente
    * @param      i_id_biometry       ID de um par�metro da biometria, ou null
    * @param      i_id_filter         Identifica��o do filtro a aplicar as valores (neste tipo de consulta, neste epis�dio, etc)
    *
    * @param      o_x_label           Label para o eixo dos Xs
    * @param      o_y_label           Label para o eixo dos Ys
    *
    * @param      o_graph_axis_x      Array com os valores da escala do eixo dos Xs
    * @param      o_graph_axis_y      Array com os valores da escala do eixo dos Ys
    * @param      o_graph_lines       Cursor com a informa��o das linhas do gr�fico seleccionado
    * @param      o_graph_points      Cursor com a informa��o dos pontos para cada linha do gr�fico
    * @param      o_graph_values      Cursor com os valores a representar no gr�fico
    * @param      o_error             Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/10/31
    ***********************************************************************************************************/
    FUNCTION get_biometric_grid_values
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_id_graphic   IN graphic.id_graphic%TYPE,
        i_id_filter    IN NUMBER,
        o_graph_values OUT pk_types.cursor_type,
        o_type         OUT graphic.flg_x_axis_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_unit_measure_desc_x translation.desc_lang_1%TYPE;
        l_unit_measure_desc_y translation.desc_lang_1%TYPE;
        l_id_filter           NUMBER(2);
        l_dbg_msg             debug_msg;
        l_dt_read_max         vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_dt_read_min         vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_age_dt              vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
        l_graphic graphic%ROWTYPE;
    BEGIN
        -- set default filter value
        IF i_id_filter IS NULL
        THEN
            l_id_filter := c_def_graphic_filter;
        ELSE
            l_id_filter := i_id_filter;
        END IF;
        --detalhes do gr�fico
        l_dbg_msg := 'GET_GRAPHIC_INFO';
        SELECT *
          INTO l_graphic
          FROM graphic g
         WHERE g.id_graphic = i_id_graphic;
    
        o_type                := l_graphic.flg_x_axis_type;
        l_unit_measure_desc_y := pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_unit_measure => l_graphic.id_unit_measure);
    
        IF l_graphic.flg_x_axis_type = c_axis_type_vital_sign
        THEN
            l_unit_measure_desc_x := pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_unit_measure => l_graphic.id_unit_measure_x);
        
            l_dbg_msg := 'CALL get_graphic_bounds';
            get_graphic_bounds(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_patient      => i_patient,
                               i_x_axis_start => nvl(l_graphic.age_min, 0),
                               i_x_axis_end   => nvl(l_graphic.age_max, 1800),
                               i_x_axis_type  => c_axis_type_month,
                               o_max          => l_dt_read_max,
                               o_min          => l_dt_read_min,
                               o_age          => l_age_dt);
        
            OPEN o_graph_values FOR
                SELECT t.x_value,
                       t.y_value,
                       t.y_value || ' ' || l_unit_measure_desc_y || ' / ' || t.x_value || ' ' || l_unit_measure_desc_x desc_values
                  FROM (SELECT aux.v_x,
                               pk_utils.to_str(CASE aux.v_um_x
                                                   WHEN aux.id_unit_measure_x THEN
                                                    aux.v_x
                                                   ELSE
                                                    nvl((SELECT pk_unit_measure.get_unit_mea_conversion(aux.v_x,
                                                                                                       aux.v_um_x,
                                                                                                       aux.id_unit_measure_x)
                                                          FROM dual),
                                                        aux.v_x)
                                               END,
                                               l_decimal_symbol) x_value,
                               
                               pk_utils.to_str(CASE aux.v_um_y
                                                   WHEN aux.id_unit_measure_y THEN
                                                    aux.v_y
                                                   ELSE
                                                    nvl((SELECT pk_unit_measure.get_unit_mea_conversion(aux.v_y,
                                                                                                       aux.v_um_y,
                                                                                                       aux.id_unit_measure_y)
                                                          FROM dual),
                                                        aux.v_y)
                                               END,
                                               l_decimal_symbol) y_value,
                               aux.id_prof_read_x,
                               aux.id_clinical_service_x,
                               aux.id_vital_sign_read_x,
                               aux.id_prof_read_y,
                               aux.id_clinical_service_y,
                               aux.id_vital_sign_read_y
                        
                          FROM (SELECT g.id_unit_measure id_unit_measure_y,
                                       g.id_unit_measure_x,
                                       vsr_y.value v_y,
                                       vsr_x.value v_x,
                                       vsr_y.id_unit_measure v_um_y,
                                       vsr_x.id_unit_measure v_um_x,
                                       row_number() over(PARTITION BY vsr_x.dt_vital_sign_read_tstz, vsr_y.dt_vital_sign_read_tstz ORDER BY vsr_x.dt_registry, vsr_y.dt_registry DESC NULLS LAST) rn,
                                       vsr_x.id_prof_read id_prof_read_x,
                                       e_x.id_clinical_service id_clinical_service_x,
                                       vsr_x.id_vital_sign_read id_vital_sign_read_x,
                                       vsr_y.id_prof_read id_prof_read_y,
                                       e_y.id_clinical_service id_clinical_service_y,
                                       vsr_y.id_vital_sign_read id_vital_sign_read_y
                                
                                  FROM graphic g
                                
                                  JOIN vital_sign_read vsr_y
                                    ON vsr_y.id_vital_sign = g.id_related_object
                                   AND vsr_y.id_patient = i_patient
                                   AND vsr_y.flg_state = pk_alert_constant.g_active
                                  JOIN vital_sign vs_y
                                    ON vs_y.id_vital_sign = vsr_y.id_vital_sign
                                   AND vs_y.flg_available = pk_alert_constant.g_yes
                                  JOIN episode e_y
                                    ON vsr_y.id_episode = e_y.id_episode
                                
                                  JOIN vital_sign_read vsr_x
                                    ON vsr_x.id_vital_sign = g.id_related_object_x
                                   AND vsr_x.id_patient = i_patient
                                   AND vsr_x.flg_state = pk_alert_constant.g_active
                                  JOIN vital_sign vs_x
                                    ON vs_x.id_vital_sign = vsr_x.id_vital_sign
                                   AND vs_x.flg_available = pk_alert_constant.g_yes
                                  JOIN episode e_x
                                    ON vsr_x.id_episode = e_x.id_episode
                                
                                 WHERE g.id_graphic = i_id_graphic
                                   AND vsr_x.dt_vital_sign_read_tstz BETWEEN l_dt_read_min AND l_dt_read_max
                                   AND vsr_y.dt_vital_sign_read_tstz BETWEEN l_dt_read_min AND l_dt_read_max
                                   AND vsr_x.dt_vital_sign_read_tstz = vsr_y.dt_vital_sign_read_tstz
                                   AND rownum > 0) aux
                        
                         WHERE aux.rn = 1) t
                
                 WHERE t.id_prof_read_x = (SELECT get_filter_prof_condition(t.id_prof_read_x, i_prof.id, l_id_filter)
                                             FROM dual)
                   AND t.id_clinical_service_x =
                       (SELECT get_filter_cs_condition(t.id_clinical_service_x,
                                                       (SELECT get_patient_clinical_service(i_lang, i_episode)
                                                          FROM dual),
                                                       l_id_filter)
                          FROM dual)
                   AND (SELECT pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read_x)
                          FROM dual) = 0
                   AND t.id_prof_read_y = (SELECT get_filter_prof_condition(t.id_prof_read_y, i_prof.id, l_id_filter)
                                             FROM dual)
                   AND t.id_clinical_service_y =
                       (SELECT get_filter_cs_condition(t.id_clinical_service_y,
                                                       (SELECT get_patient_clinical_service(i_lang, i_episode)
                                                          FROM dual),
                                                       l_id_filter)
                          FROM dual)
                   AND (SELECT pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read_y)
                          FROM dual) = 0
                 ORDER BY t.v_x ASC;
        
        ELSE
        
            l_dbg_msg := 'CALL get_graphic_bounds';
            get_graphic_bounds(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_patient      => i_patient,
                               i_x_axis_start => l_graphic.x_axis_start,
                               i_x_axis_end   => l_graphic.x_axis_end,
                               i_x_axis_type  => l_graphic.flg_x_axis_type,
                               o_max          => l_dt_read_max,
                               o_min          => l_dt_read_min,
                               o_age          => l_age_dt);
        
            l_unit_measure_desc_x := pk_unit_measure.get_uom_abbreviation(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_unit_measure => CASE
                                                                                                WHEN l_graphic.flg_x_axis_type = c_axis_type_month THEN
                                                                                                 1127
                                                                                                ELSE
                                                                                                 10373
                                                                                            END);
        
            -- Tratamento dos valores
            l_dbg_msg := 'OPEN o_graph_values';
            OPEN o_graph_values FOR
                SELECT t.x_value,
                       t.y_value,
                       t.y_value || ' ' || l_unit_measure_desc_y || ' / ' ||
                       pk_utils.to_str(t.x_value, l_decimal_symbol) || ' ' || l_unit_measure_desc_x desc_values
                  FROM (SELECT (SELECT pk_vital_sign.get_graph_x_value(t.dt_vital_sign_read_tstz,
                                                                       l_age_dt,
                                                                       l_graphic.flg_x_axis_type)
                                  FROM dual) x_value,
                               pk_utils.to_str(CASE t.id_unit_measure
                                                   WHEN l_graphic.id_unit_measure THEN
                                                    t.value
                                                   ELSE
                                                    nvl((SELECT pk_unit_measure.get_unit_mea_conversion(t.value,
                                                                                                       t.id_unit_measure,
                                                                                                       l_graphic.id_unit_measure)
                                                          FROM dual),
                                                        t.value)
                                               END,
                                               l_decimal_symbol) y_value
                          FROM (SELECT vsr.id_prof_read,
                                       vsr.id_vital_sign_read,
                                       vsr.dt_vital_sign_read_tstz,
                                       vsr.id_unit_measure,
                                       vsr.value,
                                       e.id_clinical_service
                                  FROM vital_sign_read vsr, vital_sign vs, episode e
                                 WHERE vs.id_vital_sign = vsr.id_vital_sign
                                   AND vs.flg_available = pk_alert_constant.g_yes
                                   AND vsr.id_patient = i_patient
                                   AND vsr.flg_state = pk_alert_constant.g_active
                                   AND vsr.id_vital_sign = l_graphic.id_related_object
                                      --filtrar os valores do gr�fico consoante a idade do paciente
                                   AND vsr.dt_vital_sign_read_tstz BETWEEN l_dt_read_min AND l_dt_read_max
                                      --filtros
                                   AND vsr.id_episode = e.id_episode
                                   AND rownum > 0) t
                         WHERE t.id_prof_read = (SELECT get_filter_prof_condition(t.id_prof_read, i_prof.id, l_id_filter)
                                                   FROM dual)
                           AND t.id_clinical_service =
                               (SELECT get_filter_cs_condition(t.id_clinical_service,
                                                               (SELECT get_patient_clinical_service(i_lang, i_episode)
                                                                  FROM dual),
                                                               l_id_filter)
                                  FROM dual)
                           AND (SELECT pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read)
                                  FROM dual) = 0) t
                 ORDER BY t.x_value;
        END IF;
    
        RETURN TRUE;
        --Exceptions
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BIOMETRIC_GRID_VALUES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_graph_values);
            RETURN FALSE;
    END get_biometric_grid_values;

    /**
    * Get graphic values. Adapted from GET_BIOMETRIC_GRID_VALUES.
    * For reports layer usage only.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_graphic      graphic identifier
    * @param o_values       graphic values cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.6
    * @since                2011/07/13
    */
    FUNCTION get_biometric_grid_values_rep
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_graphic IN graphic.id_graphic%TYPE,
        o_values  OUT pk_types.cursor_type,
        o_type    OUT graphic.flg_x_axis_type%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dbg_msg     debug_msg;
        l_dt_read_max vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_dt_read_min vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_age_dt      vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
        l_x_axis_desc pk_translation.t_desc_translation;
        l_y_axis_desc pk_translation.t_desc_translation;
        l_graphic     graphic%ROWTYPE;
    BEGIN
        --detalhes do gr�fico
        l_dbg_msg := 'GET_GRAPHIC_INFO';
        SELECT *
          INTO l_graphic
          FROM graphic g
         WHERE g.id_graphic = i_graphic;
    
        l_x_axis_desc := pk_translation.get_translation(i_lang, l_graphic.code_x_axis_label);
        l_y_axis_desc := pk_translation.get_translation(i_lang, l_graphic.code_y_axis_label);
    
        o_type := l_graphic.flg_x_axis_type;
    
        -- extended data values cursor (apply no filters)
        l_dbg_msg := 'OPEN o_values';
        IF l_graphic.flg_x_axis_type = c_axis_type_vital_sign
        THEN
        
            l_dbg_msg := 'CALL get_graphic_bounds';
            get_graphic_bounds(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_patient      => i_patient,
                               i_x_axis_start => nvl(l_graphic.age_min, 0),
                               i_x_axis_end   => nvl(l_graphic.age_max, 1800),
                               i_x_axis_type  => c_axis_type_month,
                               o_max          => l_dt_read_max,
                               o_min          => l_dt_read_min,
                               o_age          => l_age_dt);
        
            OPEN o_values FOR
                SELECT (SELECT get_vs_desc(i_lang, t.id_vital_sign_x)
                          FROM dual) vs_desc_x,
                       (SELECT get_vs_desc(i_lang, t.id_vital_sign_y)
                          FROM dual) vs_desc_y,
                       t.x_value,
                       t.y_value,
                       l_x_axis_desc x_axis_desc,
                       l_y_axis_desc y_axis_desc,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_registry_x, i_prof.institution, i_prof.software) dt_register_x,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_registry_y, i_prof.institution, i_prof.software) dt_register_y,
                       pk_date_utils.date_send_tsz(i_lang, t.dt_registry_x, i_prof) dt_register_serial_x,
                       pk_date_utils.date_send_tsz(i_lang, t.dt_registry_y, i_prof) dt_register_serial_y,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   t.dt_vital_sign_read_tstz_x,
                                                   i_prof.institution,
                                                   i_prof.software) dt_read_x,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   t.dt_vital_sign_read_tstz_y,
                                                   i_prof.institution,
                                                   i_prof.software) dt_read_y,
                       pk_date_utils.date_send_tsz(i_lang, t.dt_vital_sign_read_tstz_x, i_prof) dt_read_serial_x,
                       pk_date_utils.date_send_tsz(i_lang, t.dt_vital_sign_read_tstz_y, i_prof) dt_read_serial_y,
                       pk_alert_constant.g_active flg_status,
                       --
                       (SELECT pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', pk_alert_constant.g_active, i_lang)
                          FROM dual) desc_status,
                       (SELECT pk_unit_measure.get_unit_measure_description(i_lang, i_prof, l_graphic.id_unit_measure_x)
                          FROM dual) unit_measure_desc_x,
                       (SELECT pk_unit_measure.get_unit_measure_description(i_lang, i_prof, l_graphic.id_unit_measure)
                          FROM dual) unit_measure_desc_y,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_read_x) prof_name_x,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_read_y) prof_name_y,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        t.id_prof_read_x,
                                                        t.dt_registry_x,
                                                        t.id_episode_x) prof_specialty_x,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        t.id_prof_read_y,
                                                        t.dt_registry_y,
                                                        t.id_episode_y) prof_specialty_y
                
                  FROM (SELECT aux.v_x,
                               pk_utils.to_str(CASE aux.v_um_x
                                                   WHEN aux.id_unit_measure_x THEN
                                                    aux.v_x
                                                   ELSE
                                                    nvl((SELECT pk_unit_measure.get_unit_mea_conversion(aux.v_x,
                                                                                                       aux.v_um_x,
                                                                                                       aux.id_unit_measure_x)
                                                          FROM dual),
                                                        aux.v_x)
                                               END,
                                               l_decimal_symbol) x_value,
                               
                               pk_utils.to_str(CASE aux.v_um_y
                                                   WHEN aux.id_unit_measure_y THEN
                                                    aux.v_y
                                                   ELSE
                                                    nvl((SELECT pk_unit_measure.get_unit_mea_conversion(aux.v_y,
                                                                                                       aux.v_um_y,
                                                                                                       aux.id_unit_measure_y)
                                                          FROM dual),
                                                        aux.v_y)
                                               END,
                                               l_decimal_symbol) y_value,
                               aux.id_vital_sign_x,
                               aux.id_vital_sign_y,
                               aux.dt_registry_x,
                               aux.dt_registry_y,
                               aux.dt_vital_sign_read_tstz_x,
                               aux.dt_vital_sign_read_tstz_y,
                               aux.id_prof_read_x,
                               aux.id_prof_read_y,
                               aux.id_episode_x,
                               aux.id_episode_y
                          FROM (SELECT g.id_unit_measure id_unit_measure_y,
                                       g.id_unit_measure_x,
                                       vsr_y.value v_y,
                                       vsr_x.value v_x,
                                       vsr_y.id_unit_measure v_um_y,
                                       vsr_x.id_unit_measure v_um_x,
                                       row_number() over(PARTITION BY vsr_x.dt_vital_sign_read_tstz, vsr_y.dt_vital_sign_read_tstz ORDER BY vsr_x.dt_registry, vsr_y.dt_registry DESC NULLS LAST) rn,
                                       vsr_x.id_vital_sign id_vital_sign_x,
                                       vsr_y.id_vital_sign id_vital_sign_y,
                                       vsr_x.dt_registry dt_registry_x,
                                       vsr_y.dt_registry dt_registry_y,
                                       vsr_x.dt_vital_sign_read_tstz dt_vital_sign_read_tstz_x,
                                       vsr_y.dt_vital_sign_read_tstz dt_vital_sign_read_tstz_y,
                                       vsr_x.id_prof_read id_prof_read_x,
                                       vsr_y.id_prof_read id_prof_read_y,
                                       vsr_x.id_episode id_episode_x,
                                       vsr_y.id_episode id_episode_y
                                
                                  FROM graphic g
                                
                                  JOIN vital_sign_read vsr_y
                                    ON vsr_y.id_vital_sign = g.id_related_object
                                   AND vsr_y.id_patient = i_patient
                                   AND vsr_y.flg_state = pk_alert_constant.g_active
                                  JOIN vital_sign vs_y
                                    ON vs_y.id_vital_sign = vsr_y.id_vital_sign
                                   AND vs_y.flg_available = pk_alert_constant.g_yes
                                
                                  JOIN vital_sign_read vsr_x
                                    ON vsr_x.id_vital_sign = g.id_related_object_x
                                   AND vsr_x.id_patient = i_patient
                                   AND vsr_x.flg_state = pk_alert_constant.g_active
                                  JOIN vital_sign vs_x
                                    ON vs_x.id_vital_sign = vsr_x.id_vital_sign
                                   AND vs_x.flg_available = pk_alert_constant.g_yes
                                
                                 WHERE g.id_graphic = i_graphic
                                   AND vsr_x.dt_vital_sign_read_tstz BETWEEN l_dt_read_min AND l_dt_read_max
                                   AND vsr_y.dt_vital_sign_read_tstz BETWEEN l_dt_read_min AND l_dt_read_max
                                   AND vsr_x.dt_vital_sign_read_tstz = vsr_y.dt_vital_sign_read_tstz
                                   AND rownum > 0) aux
                        
                         WHERE aux.rn = 1) t
                
                 ORDER BY t.v_x ASC;
        ELSE
        
            l_dbg_msg := 'CALL get_graphic_bounds';
            get_graphic_bounds(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_patient      => i_patient,
                               i_x_axis_start => l_graphic.x_axis_start,
                               i_x_axis_end   => l_graphic.x_axis_end,
                               i_x_axis_type  => l_graphic.flg_x_axis_type,
                               o_max          => l_dt_read_max,
                               o_min          => l_dt_read_min,
                               o_age          => l_age_dt);
        
            OPEN o_values FOR
                SELECT (SELECT get_vs_desc(i_lang, l_graphic.id_related_object)
                          FROM dual) vs_desc,
                       pk_vital_sign.get_graph_x_value(t.dt_vital_sign_read_tstz, l_age_dt, l_graphic.flg_x_axis_type) x_value,
                       pk_utils.to_str(CASE t.id_unit_measure
                                           WHEN l_graphic.id_unit_measure THEN
                                            t.value
                                           ELSE
                                            nvl(pk_unit_measure.get_unit_mea_conversion(t.value,
                                                                                        t.id_unit_measure,
                                                                                        l_graphic.id_unit_measure),
                                                t.value)
                                       END,
                                       l_decimal_symbol) y_value,
                       l_x_axis_desc x_axis_desc,
                       pk_date_utils.date_char_tsz(i_lang, t.dt_registry, i_prof.institution, i_prof.software) dt_register,
                       pk_date_utils.date_send_tsz(i_lang, t.dt_registry, i_prof) dt_register_serial,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   t.dt_vital_sign_read_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_read,
                       pk_date_utils.date_send_tsz(i_lang, t.dt_vital_sign_read_tstz, i_prof) dt_read_serial,
                       pk_alert_constant.g_active flg_status,
                       (SELECT pk_sysdomain.get_domain('VITAL_SIGN_READ.FLG_STATE', pk_alert_constant.g_active, i_lang)
                          FROM dual) desc_status,
                       (SELECT pk_unit_measure.get_unit_measure_description(i_lang, i_prof, l_graphic.id_unit_measure)
                          FROM dual) unit_measure_desc,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_read)
                          FROM dual) prof_name,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                t.id_prof_read,
                                                                t.dt_registry,
                                                                t.id_episode)
                          FROM dual) prof_specialty
                  FROM (SELECT vsr.dt_vital_sign_read_tstz,
                               vsr.id_unit_measure,
                               vsr.value,
                               vsr.dt_registry,
                               vsr.id_prof_read,
                               vsr.id_episode,
                               vsr.id_vital_sign_read
                          FROM vital_sign_read vsr
                         WHERE vsr.id_patient = i_patient
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.id_vital_sign = l_graphic.id_related_object
                              --filtrar os valores do gr�fico consoante a idade do paciente
                           AND vsr.dt_vital_sign_read_tstz BETWEEN l_dt_read_min AND l_dt_read_max
                           AND rownum > 0) t
                 WHERE (SELECT pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read)
                          FROM dual) = 0
                 ORDER BY x_value;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_BIOMETRIC_GRID_VALUES_REP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_values);
            RETURN FALSE;
    END get_biometric_grid_values_rep;

    /************************************************************************************************************
    * Esta fun��o retorna a informa��o para construir o menu lateral dos ecr�s dos gr�ficos
    * na biometria.
    *
    * @param      i_lang              L�ngua registada como prefer�ncia do profissional
    * @param      i_prof              ID do profissional, software e institui��o
    * @param      i_patient           ID do paciente
    * @param      i_id_biometry       ID de um par�metro da biometria, ou null
    *
    * @param      o_x_label           Label para o eixo dos Xs
    * @param      o_y_label           Label para o eixo dos Ys
    *
    * @param      o_graph_axis_x      Array com os valores da escala do eixo dos Xs
    * @param      o_graph_axis_y      Array com os valores da escala do eixo dos Ys
    * @param      o_graph_lines       Cursor com a informa��o das linhas do gr�fico seleccionado
    * @param      o_graph_points      Cursor com a informa��o dos pontos para cada linha do gr�fico
    * @param      o_graph_values      Cursor com os valores a representar no gr�fico
    * @param      o_error             Erro
    *
    * @return     true em caso de sucesso e false caso contr�rio
    * @author     Orlando Antunes
    * @version    0.1
    * @since      2007/10/31
    ***********************************************************************************************************/
    FUNCTION get_biometric_graph_grid
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_id_graphic        IN graphic.id_graphic%TYPE,
        o_x_label           OUT VARCHAR2,
        o_y_label           OUT VARCHAR2,
        o_graph_axis_x      OUT table_number,
        o_graph_axis_y      OUT table_number,
        o_graph_lines       OUT pk_types.cursor_type,
        o_graph_line_points OUT pk_types.cursor_type,
        o_graph_values      OUT pk_types.cursor_type,
        o_type              OUT graphic.flg_x_axis_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        --vari�veis para o eixo dos Xs
        l_x_start graphic.x_axis_start%TYPE;
        l_x_end   graphic.x_axis_end%TYPE;
        l_x_inc   graphic.x_axis_increment%TYPE;
        l_x_type  graphic.flg_x_axis_type%TYPE;
        --vari�veis para o eixo dos Ys
        l_y_start graphic.y_axis_start%TYPE;
        l_y_end   graphic.y_axis_end%TYPE;
        l_y_inc   graphic.y_axis_increment%TYPE;
        --
        --vari�veis auxiliares
        l_inc_corrent NUMBER := 1;
        l_max         NUMBER := 0;
        --Exceptions
        biometry_not_found   EXCEPTION;
        error_getting_values EXCEPTION;
        l_dbg_msg debug_msg;
    
    BEGIN
        --Inicializa os arrays para os eixos
        o_graph_axis_x := table_number();
        o_graph_axis_y := table_number();
    
        l_dbg_msg := 'SELECT graph data';
        SELECT gph.x_axis_start,
               gph.x_axis_end,
               gph.x_axis_increment,
               gph.y_axis_start,
               gph.y_axis_end,
               gph.y_axis_increment,
               pk_translation.get_translation(i_lang, gph.code_x_axis_label),
               pk_translation.get_translation(i_lang, gph.code_y_axis_label),
               gph.flg_x_axis_type
          INTO l_x_start, l_x_end, l_x_inc, l_y_start, l_y_end, l_y_inc, o_x_label, o_y_label, l_x_type
          FROM graphic gph
         WHERE gph.id_graphic = i_id_graphic;
    
        --tratamento do eixo dos Xs
        l_dbg_msg := 'FILL o_graph_axis_x';
        IF l_x_start IS NOT NULL
           AND l_x_end IS NOT NULL
           AND l_x_inc IS NOT NULL
           AND l_x_end >= l_x_start
        THEN
            l_max := l_x_start;
            WHILE ((l_inc_corrent * l_x_inc) + l_x_start) <= l_x_end
            LOOP
                o_graph_axis_x.extend;
                o_graph_axis_x(l_inc_corrent) := l_max;
                --Incrementa
                l_inc_corrent := l_inc_corrent + 1;
                l_max         := l_max + l_x_inc;
            END LOOP;
            --Adiciona a ultima posi��o dos Xs
            o_graph_axis_x.extend;
            o_graph_axis_x(l_inc_corrent) := l_max;
        END IF;
    
        l_inc_corrent := 1;
        l_max         := 0;
    
        --tratamento do eixo dos Ys
        l_dbg_msg := 'FILL o_graph_axis_y';
        IF l_y_start IS NOT NULL
           AND l_y_end IS NOT NULL
           AND l_y_inc IS NOT NULL
           AND l_y_end >= l_y_start
        THEN
            l_max := l_y_start;
            WHILE ((l_inc_corrent * l_y_inc) + l_y_start) <= l_y_end
            LOOP
                o_graph_axis_y.extend;
                o_graph_axis_y(l_inc_corrent) := l_max;
                --Incrementa
                l_inc_corrent := l_inc_corrent + 1;
                l_max         := l_max + l_y_inc;
            END LOOP;
            --Adiciona a ultima posi��o dos Xs
            o_graph_axis_y.extend;
            o_graph_axis_y(l_inc_corrent) := l_max;
        END IF;
        --tratamento das linha
        l_dbg_msg := 'OPEN o_graph_lines';
        OPEN o_graph_lines FOR
            SELECT gl.id_graphic_line id,
                   gl.id_graphic      id_graphic,
                   gl.line_label      label,
                   gl.line_weight     weight,
                   gl.line_color      color
              FROM graphic_line gl, graphic g
             WHERE gl.id_graphic = g.id_graphic
               AND g.id_graphic = i_id_graphic;
        --l_lines
        --tratamento dos pontos do gr�fico
        l_dbg_msg := 'OPEN o_graph_line_points';
        OPEN o_graph_line_points FOR
            SELECT glp.id_graphic_line_point id,
                   glp.id_graphic_line       id_line,
                   glp.point_value_x         x_value,
                   glp.point_value_y         y_value
              FROM graphic_line_point glp, graphic_line gl, graphic g
             WHERE glp.id_graphic_line = gl.id_graphic_line
               AND gl.id_graphic = g.id_graphic
               AND g.id_graphic = i_id_graphic
             ORDER BY glp.rank;
        --tratamento dos valores
        l_dbg_msg := 'CALL get_biometric_grid_values';
        IF NOT get_biometric_grid_values(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_patient      => i_patient,
                                         i_episode      => i_episode,
                                         i_id_graphic   => i_id_graphic,
                                         i_id_filter    => NULL,
                                         o_graph_values => o_graph_values,
                                         o_type         => o_type,
                                         o_error        => o_error)
        THEN
            RAISE error_getting_values;
        END IF;
        RETURN TRUE;
        --Exceptions
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BIOMETRIC_GRAPH_GRID',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_graph_lines);
            pk_types.open_my_cursor(o_graph_line_points);
            pk_types.open_my_cursor(o_graph_values);
            RETURN FALSE;
    END get_biometric_graph_grid;
    --
    FUNCTION get_has_vital_sign_v2
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN vital_sign_read.id_episode%TYPE,
        i_prof    IN profissional,
        o_return  OUT PLS_INTEGER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_HAS_VITAL_SIGN_V2';
        l_dbg_msg debug_msg;
    
        l_default_view sys_config.value%TYPE;
        l_id_visit     episode.id_visit%TYPE;
    
    BEGIN
        l_dbg_msg := 'get the vital signs grid default view';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        l_default_view := pk_sysconfig.get_config(i_code_cf   => 'VS_GRID_DEFAULT_VIEW',
                                                  i_prof_inst => i_prof.institution,
                                                  i_prof_soft => i_prof.software);
    
        CASE l_default_view
            WHEN pk_alert_constant.g_vs_view_v1 THEN
                o_return := 0;
            
            WHEN pk_alert_constant.g_vs_view_v2 THEN
                o_return := 1;
            
            ELSE
                l_dbg_msg := 'get the visit id';
                pk_alertlog.log_info(text            => l_dbg_msg,
                                     object_name     => g_package_name,
                                     sub_object_name => c_function_name);
                l_id_visit := pk_episode.get_id_visit(i_episode => i_episode);
            
                l_dbg_msg := 'count the number of records only visible in V2 view';
                pk_alertlog.log_info(text            => l_dbg_msg,
                                     object_name     => g_package_name,
                                     sub_object_name => c_function_name);
                SELECT COUNT(1)
                  INTO o_return
                  FROM vital_signs_ea vsea
                 INNER JOIN vital_sign vs
                    ON vsea.id_vital_sign = vs.id_vital_sign
                  LEFT OUTER JOIN vital_sign_relation vsrel
                    ON vsea.id_vital_sign = vsrel.id_vital_sign_detail
                   AND vsrel.flg_available = pk_alert_constant.g_yes
                   AND vsrel.relation_domain != pk_alert_constant.g_vs_rel_percentile
                 INNER JOIN vs_soft_inst vsi
                    ON nvl(vsrel.id_vital_sign_parent, vsea.id_vital_sign) = vsi.id_vital_sign
                 WHERE vsea.flg_state != pk_alert_constant.g_cancelled
                   AND vsea.id_visit = l_id_visit
                   AND vs.flg_available = pk_alert_constant.g_yes
                   AND vsi.id_institution = i_prof.institution
                   AND vsi.id_software = i_prof.software
                   AND vsi.flg_view = pk_alert_constant.g_vs_view_v2
                   AND pk_delivery.check_vs_read_from_fetus(vsea.id_vital_sign_read) = 0
                   AND NOT EXISTS (SELECT 1
                          FROM vs_soft_inst vsi1
                         WHERE vsi.id_vital_sign = vsi1.id_vital_sign
                           AND vsi.id_institution = vsi1.id_institution
                           AND vsi.id_software = vsi1.id_software
                           AND vsi1.flg_view = pk_alert_constant.g_vs_view_v1);
            
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            o_return := 0;
            RETURN FALSE;
        
    END get_has_vital_sign_v2;

    /************************************************************************************************************
    * This function validates if a vital measure has already been entered for this vital sign with same date
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional structure
    * @param      i_patient         Patient ID
    * @param      i_episode         Espisode ID
    * @param      i_vital_sign      Vital Sign ID
    * @param      i_dt_vs_read      Vital Sign ID
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Filipe Machado
    * @version    2.5.1.2.1
    * @since      22-Dec-2010
    ************************************************************************************************************/
    FUNCTION srv_exist_vs_date_hour
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN vital_sign_read.id_patient%TYPE,
        i_episode      IN vital_sign_read.id_episode%TYPE,
        i_vital_sign   IN vital_sign_read.value%TYPE,
        i_dt_vs_read   IN VARCHAR2,
        o_value_exists OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SRV_EXIST_VS_DATE_HOUR(1)';
    BEGIN
        IF NOT srv_exist_vs_date_hour(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_patient         => i_patient,
                                      i_episode         => i_episode,
                                      i_vital_sign      => i_vital_sign,
                                      i_dt_vs_read      => i_dt_vs_read,
                                      i_vital_sign_read => NULL,
                                      o_value_exists    => o_value_exists,
                                      o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END srv_exist_vs_date_hour;

    /************************************************************************************************************
    * This function validates if a vital measure has already been entered for this vital sign with same date
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional structure
    * @param      i_patient         Patient ID
    * @param      i_episode         Espisode ID
    * @param      i_vital_sign      Vital Sign ID
    * @param      i_vital_sign_read List of VSR to exclude from validation and used when editing a measurement. Otherwise NULL.
    * @param      i_dt_vs_read      Vital Sign ID
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Filipe Machado & Ariel Machado
    * @version    2.6.1.0.2
    * @since      17-Mai-2011
    ************************************************************************************************************/
    FUNCTION srv_exist_vs_date_hour
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN vital_sign_read.id_patient%TYPE,
        i_episode         IN vital_sign_read.id_episode%TYPE,
        i_vital_sign      IN vital_sign_read.value%TYPE,
        i_dt_vs_read      IN VARCHAR2,
        i_vital_sign_read IN table_number,
        o_value_exists    OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_vital_signs_elements table_number := table_number(i_vital_sign);
        c_function_name CONSTANT obj_name := 'SRV_EXIST_VS_DATE_HOUR';
        l_dbg_msg debug_msg;
    
    BEGIN
        IF NOT srv_exist_list_vs_dt(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_patient         => i_patient,
                                    i_episode         => i_episode,
                                    i_vital_sign      => l_vital_signs_elements,
                                    i_dt_vs_read      => i_dt_vs_read,
                                    i_vital_sign_read => i_vital_sign_read,
                                    o_value_exists    => o_value_exists,
                                    o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END srv_exist_vs_date_hour;
    /************************************************************************************************************
    * This function validates if a vital measure has already been entered for any of the vital signs with same date
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional structure
    * @param      i_patient         Patient ID
    * @param      i_episode         Espisode ID
    * @param      i_vital_sign      List of Vital Sign ID
    * @param      i_dt_vs_read      Clinical date
    * @param      i_vital_sign_read List of VSR to exclude from validation and used when editing a measurement. Otherwise NULL.
    * @param      o_value_exists    Flag indicating if value exists
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Anna Kurowska
    * @version    2.6.3.6
    * @since      10-Mai-2013
    ************************************************************************************************************/
    FUNCTION srv_exist_list_vs_dt
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN vital_sign_read.id_patient%TYPE,
        i_episode         IN vital_sign_read.id_episode%TYPE,
        i_vital_sign      IN table_number,
        i_dt_vs_read      IN VARCHAR2,
        i_vital_sign_read IN table_number,
        o_value_exists    OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count  NUMBER := 0;
        l_detail vital_sign_relation.id_vital_sign_detail%TYPE;
        l_parent vital_sign_relation.id_vital_sign_parent%TYPE;
        c_function_name CONSTANT obj_name := 'SRV_EXIST_LIST_VS_DT';
        l_dbg_msg debug_msg;
    
    BEGIN
    
        -- when vital sign is parent -> l_detail is filled out
        BEGIN
            SELECT v.id_vital_sign_detail
              INTO l_detail
              FROM vital_sign_relation v
             WHERE v.id_vital_sign_parent IN (SELECT /*+opt_estimate(table t rows=1)*/
                                               column_value
                                                FROM TABLE(i_vital_sign) t)
               AND v.flg_available = pk_alert_constant.g_yes
               AND v.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_detail := NULL;
        END;
    
        IF l_detail IS NOT NULL
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM (SELECT vsr.*
                      FROM vital_sign_read vsr
                     WHERE EXISTS
                     (SELECT 1
                              FROM vital_sign_relation v
                             WHERE v.id_vital_sign_parent IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                               column_value
                                                                FROM TABLE(i_vital_sign) t)
                               AND v.id_vital_sign_detail = vsr.id_vital_sign
                               AND v.flg_available = pk_alert_constant.g_yes
                               AND v.relation_domain != pk_alert_constant.g_vs_rel_percentile)
                       AND vsr.id_patient = i_patient
                       AND vsr.id_episode = i_episode
                       AND vsr.flg_state != pk_alert_constant.g_cancelled
                       AND vsr.id_vital_sign_read NOT IN
                           (SELECT /*+ opt_estimate(table t rows=1) */
                             t.column_value
                              FROM TABLE(i_vital_sign_read) t)
                    UNION ALL
                    SELECT vsr.*
                      FROM vital_sign_read vsr
                     WHERE EXISTS
                     (SELECT 1
                              FROM vital_sign_relation v
                             WHERE v.id_vital_sign_parent IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                               column_value
                                                                FROM TABLE(i_vital_sign) t)
                               AND v.id_vital_sign_detail = vsr.id_vital_sign
                               AND v.flg_available = pk_alert_constant.g_yes
                               AND v.relation_domain != pk_alert_constant.g_vs_rel_percentile)
                       AND vsr.id_patient = i_patient
                       AND vsr.id_episode = i_episode
                       AND vsr.flg_state != pk_alert_constant.g_cancelled
                       AND i_vital_sign_read IS NULL) t
             WHERE (SELECT pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read)
                      FROM dual) = 0
               AND (SELECT pk_date_utils.date_send_tsz(i_lang, t.dt_vital_sign_read_tstz, i_prof)
                      FROM dual) = i_dt_vs_read;
        
        ELSE
            -- when vital sign is child -> l_parent is filled out
            BEGIN
                SELECT v.id_vital_sign_parent
                  INTO l_parent
                  FROM vital_sign_relation v
                 WHERE v.id_vital_sign_detail IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                   column_value
                                                    FROM TABLE(i_vital_sign) t)
                   AND v.flg_available = pk_alert_constant.g_yes
                   AND v.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_parent := NULL;
            END;
        
            IF l_parent IS NOT NULL
            THEN
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM (SELECT vsr.*
                          FROM vital_sign_read vsr
                         WHERE EXISTS (SELECT 1
                                  FROM vital_sign_relation v
                                 WHERE v.id_vital_sign_parent = l_parent
                                   AND v.id_vital_sign_detail = vsr.id_vital_sign
                                   AND v.flg_available = pk_alert_constant.g_yes
                                   AND v.relation_domain != pk_alert_constant.g_vs_rel_percentile)
                           AND vsr.id_patient = i_patient
                           AND vsr.id_episode = i_episode
                           AND vsr.flg_state != pk_alert_constant.g_cancelled
                           AND vsr.id_vital_sign_read NOT IN
                               (SELECT /*+ opt_estimate(table t rows=1) */
                                 t.column_value
                                  FROM TABLE(i_vital_sign_read) t)
                        UNION ALL
                        SELECT vsr.*
                          FROM vital_sign_read vsr
                         WHERE EXISTS (SELECT 1
                                  FROM vital_sign_relation v
                                 WHERE v.id_vital_sign_parent = l_parent
                                   AND v.id_vital_sign_detail = vsr.id_vital_sign
                                   AND v.flg_available = pk_alert_constant.g_yes
                                   AND v.relation_domain != pk_alert_constant.g_vs_rel_percentile)
                           AND vsr.id_patient = i_patient
                           AND vsr.id_episode = i_episode
                           AND vsr.flg_state != pk_alert_constant.g_cancelled
                           AND i_vital_sign_read IS NULL) t
                 WHERE (SELECT pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read)
                          FROM dual) = 0
                   AND (SELECT pk_date_utils.date_send_tsz(i_lang, t.dt_vital_sign_read_tstz, i_prof)
                          FROM dual) = i_dt_vs_read;
            END IF;
        
            IF (l_count = 0)
            THEN
                -- when is a 'normal' vital sign 
                SELECT COUNT(1)
                  INTO l_count
                  FROM (SELECT vsr.*
                          FROM vital_sign_read vsr
                         WHERE vsr.id_vital_sign IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                      column_value
                                                       FROM TABLE(i_vital_sign))
                           AND vsr.id_patient = i_patient
                           AND vsr.id_episode = i_episode
                           AND vsr.flg_state != pk_alert_constant.g_cancelled
                           AND vsr.id_vital_sign_read NOT IN
                               (SELECT /*+ opt_estimate(table t rows=1) */
                                 t.column_value
                                  FROM TABLE(i_vital_sign_read) t)
                        UNION ALL
                        SELECT vsr.*
                          FROM vital_sign_read vsr
                         WHERE vsr.id_vital_sign IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                      column_value
                                                       FROM TABLE(i_vital_sign) t)
                           AND vsr.id_patient = i_patient
                           AND vsr.id_episode = i_episode
                           AND vsr.flg_state != pk_alert_constant.g_cancelled
                           AND i_vital_sign_read IS NULL) t
                 WHERE (SELECT pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read)
                          FROM dual) = 0
                   AND (SELECT pk_date_utils.date_send_tsz(i_lang, t.dt_vital_sign_read_tstz, i_prof)
                          FROM dual) = i_dt_vs_read;
            
            END IF;
        
        END IF;
    
        o_value_exists := CASE l_count
                              WHEN 0 THEN
                               pk_alert_constant.g_no
                              ELSE
                               pk_alert_constant.g_yes
                          END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END srv_exist_list_vs_dt;
    /************************************************************************************************************
    * This function returns all the vital signs for a specific view and its details.
    *
    * @param      i_lang            Prefered language
    * @param      i_prof            Profissional structure
    * @param      i_patient         Patient ID
    * @param      i_area            Area calling actions
    * @param      o_actions         Actions cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Rui Duarte
    * @version    2.6.1
    * @since      17-FEV-2011
    ************************************************************************************************************/
    FUNCTION get_biometric_graph_views
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN vital_sign_read.id_patient%TYPE,
        i_area    IN VARCHAR2,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        --Constants
        c_function_name   CONSTANT obj_name := 'GET_BIOMETRIC_GRAPH_VIEWS';
        c_subject         CONSTANT obj_name := 'BIOMETRIC_VIEWS';
        c_growth_chart_id CONSTANT obj_name := 'GROWTH_CHART';
        --Local variaables
        l_pat_age             patient.age%TYPE;
        l_pat_gender          patient.gender%TYPE;
        l_active_growth_chart VARCHAR2(1);
        g_male                VARCHAR2(1);
        g_female              VARCHAR2(1);
        l_error               debug_msg;
        l_dbg_msg             debug_msg;
    BEGIN
        g_male    := 'M';
        g_female  := 'F';
        l_pat_age := pk_patient.get_pat_age(i_lang        => i_lang,
                                            i_dt_birth    => NULL,
                                            i_dt_deceased => NULL,
                                            i_age         => NULL,
                                            i_age_format  => 'YEARS',
                                            i_patient     => i_patient);
        pk_alertlog.log_debug(l_dbg_msg);
    
        l_dbg_msg := 'CALL pk_patient.get_pat_gender';
        pk_alertlog.log_debug(l_dbg_msg);
        l_pat_gender := pk_patient.get_pat_gender(i_id_patient => i_patient);
        -- che if active status on
        IF (l_pat_age IS NULL OR l_pat_gender <> g_male AND l_pat_gender <> g_female)
        THEN
            l_active_growth_chart := pk_alert_constant.g_inactive;
        ELSE
            l_active_growth_chart := pk_alert_constant.g_active;
        END IF;
    
        --get cursor
        OPEN o_actions FOR
            SELECT id_action,
                   pk_message.get_message(i_lang, code_action) desc_action, --action's description
                   decode(a.internal_name,
                          i_area,
                          pk_alert_constant.g_inactive,
                          c_growth_chart_id,
                          l_active_growth_chart,
                          pk_alert_constant.g_active) flg_active,
                   internal_name action
              FROM action a
             WHERE subject = c_subject
             ORDER BY rank, desc_action;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_biometric_graph_views;

    /************************************************************************************************************
    * This function creates a record in the history table for vital signs read
    *
    * @param        i_lang                       Language id
    * @param        i_prof                       Professional, software and institution ids
    * @param        i_id_vital_sign_read         Vital Sign Read ID
    * @param        i_value                      Vital sign value
    * @param        i_id_unit_measure            Measure unit ID
    * @param        i_dt_vital_sign_read_tstz    Date when vital sign was read
    * @param        i_flg_edit_type              Edit type. Values: E-edit, C-cancel
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/
    FUNCTION set_vital_sign_read_hist
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_flg_edit_type           IN VARCHAR2,
        i_value_high              IN vital_sign_read.value_high%TYPE DEFAULT NULL,
        i_value_low               IN vital_sign_read.value_low%TYPE DEFAULT NULL,
        o_id_vital_sign_read_hist OUT vital_sign_read_hist.id_vital_sign_read_hist%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_vital_sign_read      vital_sign_read.id_vital_sign_read%TYPE;
        l_value                   vital_sign_read_hist.value%TYPE;
        l_value_high              vital_sign_read_hist.value_high%TYPE;
        l_value_low               vital_sign_read_hist.value_low%TYPE;
        l_flg_status              vital_sign_read_hist.flg_status%TYPE;
        l_id_prof_read            vital_sign_read_hist.id_prof_read%TYPE;
        l_id_unit_measure         vital_sign_read_hist.id_unit_measure%TYPE;
        l_dt_vital_sign_read_tstz vital_sign_read_hist.dt_vital_sign_read_tstz%TYPE;
        l_dt_vital_sign_read_char VARCHAR2(20);
        l_vs_fill_type            vital_sign.flg_fill_type%TYPE;
        l_id_unit_measure_sel     vital_sign_read_hist.id_unit_measure_sel%TYPE;
        l_next                    vital_sign_read_hist.id_vital_sign_read_hist%TYPE;
        l_dt_registry             vital_sign_read.dt_registry%TYPE;
        c_function_name CONSTANT obj_name := 'SET_VITAL_SIGN_READ_HIST';
        l_flg_value_changed      VARCHAR(1);
        l_flg_status_changed     VARCHAR(1);
        l_flg_dt_vs_read_changed VARCHAR(1);
        l_flg_id_prof_changed    VARCHAR(1);
        l_flg_id_unit_changed    VARCHAR(1);
        l_desc_vs                NUMBER(12);
        l_dbg_msg                debug_msg;
        l_id_edit_reason         vital_sign_read.id_edit_reason%TYPE;
        l_notes_edit             CLOB;
    BEGIN
    
        l_dbg_msg := 'get vital_sign data to store in history table. id_vital_sign_read = ' || i_id_vital_sign_read;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        SELECT vsr.id_vital_sign_read,
               vsr.value,
               vsr.id_prof_read,
               vsr.id_unit_measure,
               pk_date_utils.date_send_tsz(i_lang, vsr.dt_vital_sign_read_tstz, i_prof),
               vsr.dt_vital_sign_read_tstz,
               vsr.dt_registry,
               vsr.flg_state,
               vsr.id_vital_sign_desc,
               vs.flg_fill_type,
               vsr.id_unit_measure_sel,
               vsr.id_edit_reason,
               pk_translation.get_translation_trs(vsr.code_notes_edit) notes_edit,
               vsr.value_high,
               vsr.value_low
          INTO l_id_vital_sign_read,
               l_value,
               l_id_prof_read,
               l_id_unit_measure,
               l_dt_vital_sign_read_char,
               l_dt_vital_sign_read_tstz,
               l_dt_registry,
               l_flg_status,
               l_desc_vs,
               l_vs_fill_type,
               l_id_unit_measure_sel,
               l_id_edit_reason,
               l_notes_edit,
               l_value_high,
               l_value_low
          FROM vital_sign_read vsr
          JOIN vital_sign vs
            ON vs.id_vital_sign = vsr.id_vital_sign
         WHERE vsr.id_vital_sign_read = i_id_vital_sign_read;
    
        IF i_flg_edit_type = c_edit_type_cancel
        THEN
            l_flg_status_changed     := 'Y';
            l_flg_status             := c_flg_status_active;
            l_flg_value_changed      := 'N';
            l_flg_dt_vs_read_changed := 'N';
            l_flg_id_prof_changed    := 'N';
            l_flg_id_unit_changed    := 'N';
        ELSE
            -- when editing values, status can never change
            l_flg_status_changed := 'N';
        
            -- compare values to determine if values were changed
        
            IF l_vs_fill_type IN (g_fill_type_multichoice) -- in multichoice casa change description and not the value
            THEN
                IF l_value <> i_value
                THEN
                    l_flg_value_changed := 'Y';
                ELSE
                    l_flg_value_changed := 'N';
                END IF;
            ELSE
                IF nvl(l_value, -1) != nvl(i_value, -1)
                   OR nvl(l_value_high, -1) != nvl(i_value_high, -1)
                   OR nvl(l_value_low, -1) != nvl(i_value_low, -1)
                THEN
                    l_flg_value_changed := 'Y';
                ELSE
                    l_flg_value_changed := 'N';
                END IF;
            END IF;
        
            IF l_dt_vital_sign_read_char <> i_dt_vital_sign_read_tstz
            THEN
                l_flg_dt_vs_read_changed := 'Y';
            ELSE
                l_flg_dt_vs_read_changed := 'N';
            END IF;
        
            IF l_id_prof_read <> i_prof.id
            THEN
                l_flg_id_prof_changed := 'Y';
            ELSE
                l_flg_id_prof_changed := 'N';
            END IF;
        
            IF l_id_unit_measure <> i_id_unit_measure
            THEN
                l_flg_id_unit_changed := 'Y';
            ELSE
                l_flg_id_unit_changed := 'N';
            END IF;
        END IF;
    
        l_dbg_msg := 'insert data into history table. id_vital_sign_read = ' || i_id_vital_sign_read;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        l_next := ts_vital_sign_read_hist.next_key();
        IF l_vs_fill_type IN (g_fill_type_multichoice)
        THEN
            ts_vital_sign_read_hist.ins(id_vital_sign_read_hist_in => l_next,
                                        id_vital_sign_read_in      => l_id_vital_sign_read,
                                        id_vital_sign_desc_in      => l_desc_vs,
                                        value_in                   => l_value,
                                        flg_status_in              => l_flg_status,
                                        id_unit_measure_in         => l_id_unit_measure,
                                        id_prof_read_in            => l_id_prof_read,
                                        dt_vital_sign_read_tstz_in => l_dt_vital_sign_read_tstz,
                                        dt_registry_in             => l_dt_registry,
                                        flg_value_changed_in       => l_flg_value_changed,
                                        flg_status_changed_in      => l_flg_status_changed,
                                        flg_dt_vs_read_changed_in  => l_flg_dt_vs_read_changed,
                                        flg_id_prof_changed_in     => l_flg_id_prof_changed,
                                        flg_id_unit_changed_in     => l_flg_id_unit_changed,
                                        id_unit_measure_sel_in     => l_id_unit_measure_sel,
                                        id_edit_reason_in          => l_id_edit_reason,
                                        notes_edit_in              => l_notes_edit);
        ELSE
            ts_vital_sign_read_hist.ins(id_vital_sign_read_hist_in => l_next,
                                        id_vital_sign_read_in      => l_id_vital_sign_read,
                                        value_in                   => l_value,
                                        flg_status_in              => l_flg_status,
                                        id_unit_measure_in         => l_id_unit_measure,
                                        id_prof_read_in            => l_id_prof_read,
                                        dt_vital_sign_read_tstz_in => l_dt_vital_sign_read_tstz,
                                        dt_registry_in             => l_dt_registry,
                                        flg_value_changed_in       => l_flg_value_changed,
                                        flg_status_changed_in      => l_flg_status_changed,
                                        flg_dt_vs_read_changed_in  => l_flg_dt_vs_read_changed,
                                        flg_id_prof_changed_in     => l_flg_id_prof_changed,
                                        flg_id_unit_changed_in     => l_flg_id_unit_changed,
                                        id_unit_measure_sel_in     => l_id_unit_measure_sel,
                                        id_edit_reason_in          => l_id_edit_reason,
                                        notes_edit_in              => l_notes_edit,
                                        value_high_in              => l_value_high,
                                        value_low_in               => l_value_low);
        END IF;
        o_id_vital_sign_read_hist := l_next;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_vital_sign_read_hist;

    /************************************************************************************************************
    * This function is called when editing a vital sign
    *
    * @param        i_lang                    Language id
    * @param        i_prof                    Professional, software and institution ids
    * @param        id_vital_sign_read        Vital Sign reading ID
    * @param        i_value                   Vital sign value
    * @param        id_unit_measure           Measure unit ID
    * @param        dt_vital_sign_read_tstz   Date when vital sign was read
    *
    * @author       Sergio Dias
    * @version      2.6.1
    * @since        18-Feb-2011
    ************************************************************************************************************/
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN vital_sign_read.id_unit_measure_sel%TYPE,
        i_tb_attribute            IN table_number,
        i_tb_free_text            IN table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        i_value_high              IN vital_sign_read.value_high%TYPE DEFAULT NULL,
        i_value_low               IN vital_sign_read.value_low%TYPE DEFAULT NULL,
        i_fetus_vs                IN NUMBER DEFAULT NULL,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'EDIT_VITAL_SIGN';
        l_dbg_msg debug_msg;
        l_exception EXCEPTION;
    BEGIN
        IF NOT pk_vital_sign.edit_vital_sign(i_lang                    => i_lang,
                                             i_prof                    => i_prof,
                                             i_id_vital_sign_read      => i_id_vital_sign_read,
                                             i_value                   => i_value,
                                             i_id_unit_measure         => i_id_unit_measure,
                                             i_dt_vital_sign_read_tstz => i_dt_vital_sign_read_tstz,
                                             i_dt_registry             => i_dt_registry,
                                             i_id_unit_measure_sel     => i_id_unit_measure_sel,
                                             i_tb_attribute            => i_tb_attribute,
                                             i_tb_free_text            => i_tb_free_text,
                                             i_id_edit_reason          => i_id_edit_reason,
                                             i_notes_edit              => i_notes_edit,
                                             i_value_high              => i_value_high,
                                             i_value_low               => i_value_low,
                                             i_fetus_vs                => i_fetus_vs,
                                             i_update_pdms             => TRUE,
                                             i_id_epis_documentation   => i_id_epis_documentation,
                                             o_error                   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END edit_vital_sign;

    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_value                   IN vital_sign_read.value%TYPE,
        i_id_unit_measure         IN vital_sign_read.id_unit_measure%TYPE,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN vital_sign_read.id_unit_measure_sel%TYPE,
        i_tb_attribute            IN table_number,
        i_tb_free_text            IN table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        i_value_high              IN vital_sign_read.value_high%TYPE DEFAULT NULL,
        i_value_low               IN vital_sign_read.value_low%TYPE DEFAULT NULL,
        i_fetus_vs                IN NUMBER DEFAULT NULL,
        i_update_pdms             IN BOOLEAN,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        rows_vsr_out table_varchar := table_varchar();
        c_function_name CONSTANT obj_name := 'EDIT_VITAL_SIGN';
        c_sysdate_tstz             vital_sign_read.dt_vital_sign_read_tstz%TYPE := current_timestamp();
        l_dt_vs_read               TIMESTAMP WITH LOCAL TIME ZONE;
        l_dbg_msg                  debug_msg;
        l_id_vital_sign            vital_sign.id_vital_sign%TYPE;
        l_bmi                      VARCHAR2(6 CHAR);
        l_bsa                      VARCHAR2(6 CHAR);
        l_dt_registry              vital_sign_read.dt_registry%TYPE;
        l_height                   vital_sign_read.value%TYPE;
        l_height_um                vital_sign_read.id_unit_measure%TYPE;
        l_weight                   vital_sign_read.value%TYPE;
        l_weight_um                vital_sign_read.id_unit_measure%TYPE;
        l_id_vs_read_height        vital_sign_read.id_vital_sign_read%TYPE;
        l_id_vs_read_weight        vital_sign_read.id_vital_sign_read%TYPE;
        l_id_vs_read_bmi           vital_sign_read.id_vital_sign_read%TYPE;
        l_id_vs_read_bsa           vital_sign_read.id_vital_sign_read%TYPE;
        l_id_unit_measure_bmi      vital_sign_read.id_unit_measure%TYPE;
        l_id_unit_measure_bsa      vital_sign_read.id_unit_measure%TYPE;
        l_value                    vital_sign_read.value%TYPE;
        l_value_high               vital_sign_read.value_high%TYPE;
        l_value_low                vital_sign_read.value_low%TYPE;
        l_id_vs_read_height_weight vital_sign_read.id_vital_sign_read%TYPE;
        l_rows_vsr_hw              table_varchar;
        l_id_episode               vital_sign_read.id_episode%TYPE;
        l_id_vital_sign_read_hist  vital_sign_read_hist.id_vital_sign_read_hist%TYPE;
        --Viatl sign type (Multichoice, numeric, etc)
        l_vs_fill_type vital_sign.flg_fill_type%TYPE;
        l_exception EXCEPTION;
        l_id_vs_scales_element vital_sign_read.id_vs_scales_element%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_value IS NOT NULL
        THEN
            IF i_dt_registry IS NULL
            THEN
                c_sysdate_tstz := g_sysdate_tstz;
            ELSE
                c_sysdate_tstz := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_timestamp => i_dt_registry,
                                                                i_timezone  => NULL);
            END IF;
        
            IF i_dt_vital_sign_read_tstz IS NOT NULL
            THEN
                l_dt_vs_read := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_vital_sign_read_tstz, NULL);
            ELSE
                l_dt_vs_read := g_sysdate_tstz;
            END IF;
        
            l_dbg_msg := 'CALL pk_date_utils.trunc_insttimezone';
            pk_alertlog.log_debug(l_dbg_msg);
            IF i_fetus_vs IS NOT NULL
            THEN
                l_dt_vs_read := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                 i_timestamp => l_dt_vs_read,
                                                                 i_format    => 'SS') +
                                numtodsinterval(i_fetus_vs, 'second');
            ELSE
                l_dt_vs_read := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                 i_timestamp => l_dt_vs_read,
                                                                 i_format    => 'MI');
            END IF;
        
            SELECT vsr.id_vital_sign, vsr.dt_registry, vs.flg_fill_type, vsr.id_episode, vsr.id_vs_scales_element
              INTO l_id_vital_sign, l_dt_registry, l_vs_fill_type, l_id_episode, l_id_vs_scales_element
              FROM vital_sign_read vsr
              JOIN vital_sign vs
                ON vs.id_vital_sign = vsr.id_vital_sign
             WHERE vsr.id_vital_sign_read = i_id_vital_sign_read;
        
            --get real value
            IF i_id_unit_measure_sel IS NOT NULL
               AND i_id_unit_measure IS NOT NULL
               AND i_id_unit_measure_sel <> i_id_unit_measure
            THEN
                l_dbg_msg    := 'call function pk_unit_measure.get_unit_mea_conversion';
                l_value      := pk_unit_measure.get_unit_mea_conversion(i_value,
                                                                        i_id_unit_measure_sel,
                                                                        i_id_unit_measure);
                l_value_high := pk_unit_measure.get_unit_mea_conversion(i_value_high,
                                                                        i_id_unit_measure_sel,
                                                                        i_id_unit_measure);
                l_value_low  := pk_unit_measure.get_unit_mea_conversion(i_value_low,
                                                                        i_id_unit_measure_sel,
                                                                        i_id_unit_measure);
            ELSE
                l_value      := i_value;
                l_value_high := i_value_high;
                l_value_low  := i_value_low;
            END IF;
        
            l_dbg_msg := 'call function to insert into history table. id_vital_sign_read = ' || i_id_vital_sign_read;
            pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
            IF NOT set_vital_sign_read_hist(i_lang                    => i_lang,
                                            i_prof                    => i_prof,
                                            i_id_vital_sign_read      => i_id_vital_sign_read,
                                            i_value                   => l_value,
                                            i_id_unit_measure         => i_id_unit_measure,
                                            i_dt_vital_sign_read_tstz => pk_date_utils.date_send_tsz(i_lang,
                                                                                                     l_dt_vs_read,
                                                                                                     i_prof),
                                            i_flg_edit_type           => c_edit_type_edit,
                                            i_value_high              => l_value_high,
                                            i_value_low               => l_value_low,
                                            o_id_vital_sign_read_hist => l_id_vital_sign_read_hist,
                                            o_error                   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_dbg_msg := 'call set_vs_read_hist_atttrib';
            IF NOT set_vs_read_hist_atttrib(i_lang                    => i_lang,
                                            i_prof                    => i_prof,
                                            i_id_vital_sign_read      => i_id_vital_sign_read,
                                            i_id_vital_sign_read_hist => l_id_vital_sign_read_hist,
                                            o_error                   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -- update attributes      
            l_dbg_msg := 'call pk_vital_sign_core.set_vs_read_attribute';
            IF NOT pk_vital_sign_core.set_vs_read_attribute(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_id_vital_sign_read => i_id_vital_sign_read,
                                                            i_tb_attribute       => i_tb_attribute,
                                                            i_tb_free_text       => i_tb_free_text,
                                                            o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            l_dbg_msg := 'update record with edited values. id_vital_sign_read = ' || i_id_vital_sign_read;
            pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        
            IF l_id_vs_scales_element IS NOT NULL
            THEN
                BEGIN
                    SELECT b.id_vs_scales_element
                      INTO l_id_vs_scales_element
                      FROM vital_sign_scales_element b
                     WHERE b.id_vital_sign_scales =
                           (SELECT a.id_vital_sign_scales
                              FROM vital_sign_scales_element a
                             WHERE a.id_vs_scales_element = l_id_vs_scales_element)
                       AND b.value = l_value;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
            END IF;
        
            IF l_vs_fill_type IN (g_fill_type_multichoice)
            THEN
                ts_vital_sign_read.upd(id_vital_sign_read_in      => i_id_vital_sign_read,
                                       id_vital_sign_desc_in      => l_value,
                                       id_unit_measure_in         => i_id_unit_measure,
                                       id_prof_read_in            => i_prof.id,
                                       dt_vital_sign_read_tstz_in => l_dt_vs_read,
                                       dt_registry_in             => c_sysdate_tstz,
                                       id_edit_reason_in          => i_id_edit_reason,
                                       id_edit_reason_nin         => FALSE,
                                       id_vs_scales_element_in    => l_id_vs_scales_element,
                                       value_high_in              => l_value_high,
                                       value_low_in               => l_value_low,
                                       id_epis_documentation_in   => i_id_epis_documentation,
                                       rows_out                   => rows_vsr_out);
            
                pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                      i_code   => pk_vital_sign.g_trs_notes_edit || i_id_vital_sign_read,
                                                      i_desc   => i_notes_edit,
                                                      i_module => 'VITAL_SIGN');
            
            ELSE
                ts_vital_sign_read.upd(id_vital_sign_read_in      => i_id_vital_sign_read,
                                       value_in                   => l_value,
                                       id_unit_measure_in         => i_id_unit_measure,
                                       id_prof_read_in            => i_prof.id,
                                       dt_vital_sign_read_tstz_in => l_dt_vs_read,
                                       dt_registry_in             => c_sysdate_tstz,
                                       id_unit_measure_sel_in     => nvl(i_id_unit_measure_sel, i_id_unit_measure),
                                       id_edit_reason_in          => i_id_edit_reason,
                                       id_edit_reason_nin         => FALSE,
                                       id_vs_scales_element_in    => l_id_vs_scales_element,
                                       value_high_in              => l_value_high,
                                       value_low_in               => l_value_low,
                                       id_epis_documentation_in   => i_id_epis_documentation,
                                       rows_out                   => rows_vsr_out);
                --notify pdms that a vital sign was updated
                IF i_update_pdms
                THEN
                    l_dbg_msg := 'call pk_api_pdms_core_in.update_vs_pdms';
                    IF NOT pk_api_pdms_core_in.update_vs_pdms(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_id_vs      => table_number(l_id_vital_sign),
                                                              i_id_vs_read => table_number(i_id_vital_sign_read),
                                                              i_value_vs   => table_number(l_value),
                                                              o_error      => o_error)
                    THEN
                    
                        RAISE l_exception;
                    END IF;
                END IF;
                pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                      i_code   => pk_vital_sign.g_trs_notes_edit || i_id_vital_sign_read,
                                                      i_desc   => i_notes_edit,
                                                      i_module => 'VITAL_SIGN');
            
            END IF;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'VITAL_SIGN_READ',
                                          i_rowids     => rows_vsr_out,
                                          o_error      => o_error);
        
            -----------------------------------------------------------------
            -- try to cancel percentile vital sign (internally it verifies if it exists)
            IF NOT pk_percentile.set_percentile_vs(i_lang               => i_lang,
                                                   i_prof               => i_prof,
                                                   i_id_vital_sign_read => i_id_vital_sign_read,
                                                   o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            -----------------------------------------------------------------
            -- if vital sign is Height or Weight 
            IF l_id_vital_sign IN (g_vs_weight)
            THEN
                BEGIN
                    -- retrieve HEIGHT info
                    BEGIN
                    
                        SELECT aux.id_vital_sign_read, aux.value, aux.id_unit_measure
                          INTO l_id_vs_read_height, l_height, l_height_um
                          FROM (SELECT vsr.id_vital_sign_read,
                                       vsr.value,
                                       vsr.id_unit_measure,
                                       row_number() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.dt_registry DESC NULLS LAST) rn
                                  FROM vital_sign_read vsr
                                 WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                                   AND vsr.id_vital_sign = g_vs_height
                                   AND vsr.id_episode = l_id_episode) aux
                         WHERE aux.rn = 1;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            -- NOTE:
                            -- If there is no previus data it will not be possible to register BMI or BSA
                            l_id_vs_read_height := NULL;
                            l_height            := NULL;
                            l_height_um         := NULL;
                    END;
                
                    IF l_id_vs_read_height IS NOT NULL
                    THEN
                    
                        l_id_vs_read_height_weight := l_id_vs_read_height;
                    
                        -- -- --
                        -- BMI
                        -- -- --
                        -- retrieve BMI info       
                        BEGIN
                        
                            SELECT aux.id_vital_sign_read, aux.id_unit_measure
                              INTO l_id_vs_read_bmi, l_id_unit_measure_bmi
                              FROM (SELECT vsr.id_vital_sign_read,
                                           vsr.id_unit_measure,
                                           row_number() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.dt_registry DESC NULLS LAST) rn
                                      FROM vital_sign_read vsr
                                     WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                                       AND vsr.id_vital_sign = g_vs_bmi
                                       AND vsr.id_episode = l_id_episode) aux
                             WHERE aux.rn = 1;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_vs_read_bmi      := NULL;
                                l_id_unit_measure_bmi := NULL;
                        END;
                    
                        IF l_id_vs_read_bmi IS NOT NULL
                        THEN
                            -- calculation of the new BMI
                            l_bmi := pk_calc.get_bmi(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_weight    => l_value,
                                                     i_weight_um => i_id_unit_measure,
                                                     i_height    => l_height,
                                                     i_height_um => l_height_um);
                        
                            l_bmi := REPLACE(l_bmi, ',', '.');
                        
                            l_dbg_msg := 'call function to insert into history table. id_vital_sign_read = ' ||
                                         l_id_vs_read_bmi;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => g_package_name,
                                                 sub_object_name => c_function_name);
                            IF NOT set_vital_sign_read_hist(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_id_vital_sign_read      => l_id_vs_read_bmi,
                                                            i_value                   => to_number(l_bmi, '999.999'),
                                                            i_id_unit_measure         => l_id_unit_measure_bmi,
                                                            i_dt_vital_sign_read_tstz => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                     l_dt_vs_read,
                                                                                                                     i_prof),
                                                            i_flg_edit_type           => c_edit_type_edit,
                                                            o_id_vital_sign_read_hist => l_id_vital_sign_read_hist,
                                                            o_error                   => o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            l_dbg_msg := 'update record with edited values. id_vital_sign_read = ' || l_id_vs_read_bmi;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => g_package_name,
                                                 sub_object_name => c_function_name);
                        
                            -- update new BMI
                            ts_vital_sign_read.upd(id_vital_sign_read_in => l_id_vs_read_bmi,
                                                   value_in              => to_number(l_bmi, '999.999'),
                                                   id_unit_measure_in    => l_id_unit_measure_bmi,
                                                   dt_registry_in        => c_sysdate_tstz,
                                                   id_prof_read_in       => i_prof.id,
                                                   id_edit_reason_in     => i_id_edit_reason,
                                                   id_edit_reason_nin    => FALSE,
                                                   rows_out              => rows_vsr_out);
                            --notify pdms that a vital sign was update
                            IF i_update_pdms
                            THEN
                                l_dbg_msg := 'call pk_api_pdms_core_in.update_vs_pdms';
                                IF NOT pk_api_pdms_core_in.update_vs_pdms(i_lang       => i_lang,
                                                                          i_prof       => i_prof,
                                                                          i_id_vs      => table_number(g_vs_bmi),
                                                                          i_id_vs_read => table_number(l_id_vs_read_bmi),
                                                                          i_value_vs   => table_number(to_number(l_bmi,
                                                                                                                 '999.999')),
                                                                          o_error      => o_error)
                                THEN
                                
                                    RAISE l_exception;
                                END IF;
                            END IF;
                            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                                  i_code   => pk_vital_sign.g_trs_notes_edit ||
                                                                              l_id_vs_read_bmi,
                                                                  i_desc   => i_notes_edit,
                                                                  i_module => 'VITAL_SIGN');
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'VITAL_SIGN_READ',
                                                          i_rowids     => rows_vsr_out,
                                                          o_error      => o_error);
                        END IF;
                    
                        -- -- --
                        -- BSA
                        -- -- --
                        -- retrieve BSA info       
                        BEGIN
                        
                            SELECT aux.id_vital_sign_read, aux.id_unit_measure
                              INTO l_id_vs_read_bsa, l_id_unit_measure_bsa
                              FROM (SELECT vsr.id_vital_sign_read,
                                           vsr.id_unit_measure,
                                           row_number() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.dt_registry DESC NULLS LAST) rn
                                      FROM vital_sign_read vsr
                                     WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                                       AND vsr.id_vital_sign = g_vs_bsa
                                       AND vsr.id_episode = l_id_episode) aux
                             WHERE aux.rn = 1;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_vs_read_bsa      := NULL;
                                l_id_unit_measure_bsa := NULL;
                        END;
                    
                        IF l_id_vs_read_bsa IS NOT NULL
                        THEN
                            l_bsa := pk_calc.get_bsa(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_weight    => l_value,
                                                     i_weight_um => i_id_unit_measure,
                                                     i_height    => l_height,
                                                     i_height_um => l_height_um);
                        
                            l_bsa := REPLACE(l_bsa, ',', '.');
                        
                            l_dbg_msg := 'call function to insert into history table. id_vital_sign_read = ' ||
                                         l_id_vs_read_bsa;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => g_package_name,
                                                 sub_object_name => c_function_name);
                            IF NOT set_vital_sign_read_hist(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_id_vital_sign_read      => l_id_vs_read_bsa,
                                                            i_value                   => to_number(l_bsa, '999.999'),
                                                            i_id_unit_measure         => l_id_unit_measure_bsa,
                                                            i_dt_vital_sign_read_tstz => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                     l_dt_vs_read,
                                                                                                                     i_prof),
                                                            i_flg_edit_type           => c_edit_type_edit,
                                                            o_id_vital_sign_read_hist => l_id_vital_sign_read_hist,
                                                            o_error                   => o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            l_dbg_msg := 'update record with edited values. id_vital_sign_read = ' || l_id_vs_read_bsa;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => g_package_name,
                                                 sub_object_name => c_function_name);
                        
                            -- update new BSA
                            ts_vital_sign_read.upd(id_vital_sign_read_in => l_id_vs_read_bsa,
                                                   value_in              => to_number(l_bsa, '999.999'),
                                                   id_unit_measure_in    => l_id_unit_measure_bsa,
                                                   dt_registry_in        => c_sysdate_tstz,
                                                   id_prof_read_in       => i_prof.id,
                                                   id_edit_reason_in     => i_id_edit_reason,
                                                   id_edit_reason_nin    => FALSE,
                                                   rows_out              => rows_vsr_out);
                            --notify pdms that a vital sign was updated
                            IF i_update_pdms
                            THEN
                                l_dbg_msg := 'call pk_api_pdms_core_in.update_vs_pdms';
                                IF NOT pk_api_pdms_core_in.update_vs_pdms(i_lang       => i_lang,
                                                                          i_prof       => i_prof,
                                                                          i_id_vs      => table_number(g_vs_bsa),
                                                                          i_id_vs_read => table_number(l_id_vs_read_bsa),
                                                                          i_value_vs   => table_number(to_number(l_bsa,
                                                                                                                 '999.999')),
                                                                          o_error      => o_error)
                                THEN
                                
                                    RAISE l_exception;
                                END IF;
                            END IF;
                            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                                  i_code   => pk_vital_sign.g_trs_notes_edit ||
                                                                              l_id_vs_read_bsa,
                                                                  i_desc   => i_notes_edit,
                                                                  i_module => 'VITAL_SIGN');
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'VITAL_SIGN_READ',
                                                          i_rowids     => rows_vsr_out,
                                                          o_error      => o_error);
                        END IF;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            ELSIF l_id_vital_sign IN (g_vs_height)
            THEN
                BEGIN
                    -- retrieve WEIGHT info
                    BEGIN
                    
                        SELECT aux.id_vital_sign_read, aux.value, aux.id_unit_measure
                          INTO l_id_vs_read_weight, l_weight, l_weight_um
                          FROM (SELECT vsr.id_vital_sign_read,
                                       vsr.value,
                                       vsr.id_unit_measure,
                                       row_number() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.dt_registry DESC NULLS LAST) rn
                                  FROM vital_sign_read vsr
                                 WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                                   AND vsr.id_vital_sign = g_vs_weight
                                   AND vsr.id_episode = l_id_episode) aux
                         WHERE aux.rn = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            -- NOTE:
                            -- If there is no previus data it will not be possible to register BMI or BSA
                            l_id_vs_read_weight := NULL;
                            l_weight            := NULL;
                            l_weight_um         := NULL;
                    END;
                
                    IF l_id_vs_read_weight IS NOT NULL
                    THEN
                    
                        l_id_vs_read_height_weight := l_id_vs_read_weight;
                    
                        -- -- --
                        -- BMI
                        -- -- --
                        -- retrieve BMI info       
                        BEGIN
                        
                            SELECT aux.id_vital_sign_read, aux.id_unit_measure
                              INTO l_id_vs_read_bmi, l_id_unit_measure_bmi
                              FROM (SELECT vsr.id_vital_sign_read,
                                           vsr.id_unit_measure,
                                           row_number() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.dt_registry DESC NULLS LAST) rn
                                      FROM vital_sign_read vsr
                                     WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                                       AND vsr.id_vital_sign = g_vs_bmi
                                       AND vsr.id_episode = l_id_episode) aux
                             WHERE aux.rn = 1;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_vs_read_bmi      := NULL;
                                l_id_unit_measure_bmi := NULL;
                        END;
                    
                        IF l_id_vs_read_bmi IS NOT NULL
                        THEN
                            -- calculation of the new BMI
                            l_bmi := pk_calc.get_bmi(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_weight    => l_weight,
                                                     i_weight_um => l_weight_um,
                                                     i_height    => l_value,
                                                     i_height_um => i_id_unit_measure);
                        
                            l_bmi := REPLACE(l_bmi, ',', '.');
                        
                            l_dbg_msg := 'call function to insert into history table. id_vital_sign_read = ' ||
                                         l_id_vs_read_bmi;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => g_package_name,
                                                 sub_object_name => c_function_name);
                            IF NOT set_vital_sign_read_hist(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_id_vital_sign_read      => l_id_vs_read_bmi,
                                                            i_value                   => to_number(l_bmi, '999.999'),
                                                            i_id_unit_measure         => l_id_unit_measure_bmi,
                                                            i_dt_vital_sign_read_tstz => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                     l_dt_vs_read,
                                                                                                                     i_prof),
                                                            i_flg_edit_type           => c_edit_type_edit,
                                                            o_id_vital_sign_read_hist => l_id_vital_sign_read_hist,
                                                            o_error                   => o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            l_dbg_msg := l_bmi || 'update record with edited values. id_vital_sign_read = ' ||
                                         l_id_vs_read_bmi;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => g_package_name,
                                                 sub_object_name => c_function_name);
                        
                            -- update new BMI
                            ts_vital_sign_read.upd(id_vital_sign_read_in => l_id_vs_read_bmi,
                                                   value_in              => to_number(l_bmi, '999.999'),
                                                   id_unit_measure_in    => l_id_unit_measure_bmi,
                                                   dt_registry_in        => c_sysdate_tstz,
                                                   id_prof_read_in       => i_prof.id,
                                                   id_edit_reason_in     => i_id_edit_reason,
                                                   id_edit_reason_nin    => FALSE,
                                                   rows_out              => rows_vsr_out);
                            --notify pdms that a vital sign was updated
                            IF i_update_pdms
                            THEN
                                l_dbg_msg := 'call pk_api_pdms_core_in.update_vs_pdms';
                                IF NOT pk_api_pdms_core_in.update_vs_pdms(i_lang       => i_lang,
                                                                          i_prof       => i_prof,
                                                                          i_id_vs      => table_number(g_vs_bmi),
                                                                          i_id_vs_read => table_number(l_id_vs_read_bmi),
                                                                          i_value_vs   => table_number(to_number(l_bmi,
                                                                                                                 '999.999')),
                                                                          o_error      => o_error)
                                THEN
                                
                                    RAISE l_exception;
                                END IF;
                            END IF;
                            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                                  i_code   => pk_vital_sign.g_trs_notes_edit ||
                                                                              l_id_vs_read_bmi,
                                                                  i_desc   => i_notes_edit,
                                                                  i_module => 'VITAL_SIGN');
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'VITAL_SIGN_READ',
                                                          i_rowids     => rows_vsr_out,
                                                          o_error      => o_error);
                        END IF;
                    
                        -- -- --
                        -- BSA
                        -- -- --
                        -- retrieve BSA info
                        BEGIN
                        
                            SELECT aux.id_vital_sign_read, aux.id_unit_measure
                              INTO l_id_vs_read_bsa, l_id_unit_measure_bsa
                              FROM (SELECT vsr.id_vital_sign_read,
                                           vsr.id_unit_measure,
                                           row_number() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.dt_registry DESC NULLS LAST) rn
                                      FROM vital_sign_read vsr
                                     WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_read
                                       AND vsr.id_vital_sign = g_vs_bsa
                                       AND vsr.id_episode = l_id_episode) aux
                             WHERE aux.rn = 1;
                        
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_id_vs_read_bsa      := NULL;
                                l_id_unit_measure_bsa := NULL;
                        END;
                    
                        IF l_id_vs_read_bsa IS NOT NULL
                        THEN
                            l_bsa := pk_calc.get_bsa(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_weight    => l_weight,
                                                     i_weight_um => l_weight_um,
                                                     i_height    => l_value,
                                                     i_height_um => i_id_unit_measure);
                        
                            l_bsa := REPLACE(l_bsa, ',', '.');
                        
                            l_dbg_msg := 'call function to insert into history table. id_vital_sign_read = ' ||
                                         l_id_vs_read_bsa;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => g_package_name,
                                                 sub_object_name => c_function_name);
                            IF NOT set_vital_sign_read_hist(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_id_vital_sign_read      => l_id_vs_read_bsa,
                                                            i_value                   => to_number(l_bsa, '999.999'),
                                                            i_id_unit_measure         => l_id_unit_measure_bsa,
                                                            i_dt_vital_sign_read_tstz => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                     l_dt_vs_read,
                                                                                                                     i_prof),
                                                            i_flg_edit_type           => c_edit_type_edit,
                                                            o_id_vital_sign_read_hist => l_id_vital_sign_read_hist,
                                                            o_error                   => o_error)
                            THEN
                                RAISE l_exception;
                            END IF;
                        
                            l_dbg_msg := 'update record with edited values. id_vital_sign_read = ' || l_id_vs_read_bsa;
                            pk_alertlog.log_info(text            => l_dbg_msg,
                                                 object_name     => g_package_name,
                                                 sub_object_name => c_function_name);
                        
                            -- update new BSA
                            ts_vital_sign_read.upd(id_vital_sign_read_in => l_id_vs_read_bsa,
                                                   value_in              => to_number(l_bsa, '999.999'),
                                                   id_unit_measure_in    => l_id_unit_measure_bsa,
                                                   dt_registry_in        => c_sysdate_tstz,
                                                   id_prof_read_in       => i_prof.id,
                                                   id_edit_reason_in     => i_id_edit_reason,
                                                   id_edit_reason_nin    => FALSE,
                                                   rows_out              => rows_vsr_out);
                            --notify pdms that a vital sign was updated
                            IF i_update_pdms
                            THEN
                                l_dbg_msg := 'call pk_api_pdms_core_in.update_vs_pdms';
                                IF NOT pk_api_pdms_core_in.update_vs_pdms(i_lang       => i_lang,
                                                                          i_prof       => i_prof,
                                                                          i_id_vs      => table_number(g_vs_bsa),
                                                                          i_id_vs_read => table_number(l_id_vs_read_bsa),
                                                                          i_value_vs   => table_number(to_number(l_bsa,
                                                                                                                 '999.999')),
                                                                          o_error      => o_error)
                                THEN
                                
                                    RAISE l_exception;
                                END IF;
                            END IF;
                            pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                                  i_code   => pk_vital_sign.g_trs_notes_edit ||
                                                                              l_id_vs_read_bsa,
                                                                  i_desc   => i_notes_edit,
                                                                  i_module => 'VITAL_SIGN');
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'VITAL_SIGN_READ',
                                                          i_rowids     => rows_vsr_out,
                                                          o_error      => o_error);
                        END IF;
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END edit_vital_sign;

    /************************************************************************************************************
    * This function is called when editing a vital sign
    *
    * @param        i_lang                    Language id
    * @param        i_prof                    Professional, software and institution ids
    * @param        id_vital_sign_read        Vital Sign reading ID
    * @param        i_value                   Vital sign value
    * @param        id_unit_measure           Measure unit ID
    * @param        dt_vital_sign_read_tstz   Date when vital sign was read
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/
    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN table_number,
        i_tbtb_attribute          IN table_table_number,
        i_tbtb_free_text          IN table_table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        i_value_high              IN table_number DEFAULT table_number(),
        i_value_low               IN table_number DEFAULT table_number(),
        i_fetus_vs                IN NUMBER DEFAULT NULL,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'edit_vital_sign';
        l_message   debug_msg;
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_vital_sign.edit_vital_sign(i_lang                    => i_lang,
                                             i_prof                    => i_prof,
                                             i_id_vital_sign_read      => i_id_vital_sign_read,
                                             i_value                   => i_value,
                                             i_id_unit_measure         => i_id_unit_measure,
                                             i_dt_vital_sign_read_tstz => i_dt_vital_sign_read_tstz,
                                             i_dt_registry             => i_dt_registry,
                                             i_id_unit_measure_sel     => i_id_unit_measure_sel,
                                             i_tbtb_attribute          => i_tbtb_attribute,
                                             i_tbtb_free_text          => i_tbtb_free_text,
                                             i_id_edit_reason          => i_id_edit_reason,
                                             i_notes_edit              => i_notes_edit,
                                             i_value_high              => i_value_high,
                                             i_value_low               => i_value_low,
                                             i_fetus_vs                => i_fetus_vs,
                                             i_update_pdms             => TRUE,
                                             o_error                   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END edit_vital_sign;

    FUNCTION edit_vital_sign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN table_number,
        i_value                   IN table_number,
        i_id_unit_measure         IN table_number,
        i_dt_vital_sign_read_tstz IN VARCHAR2,
        i_dt_registry             IN VARCHAR2 DEFAULT NULL,
        i_id_unit_measure_sel     IN table_number,
        i_tbtb_attribute          IN table_table_number,
        i_tbtb_free_text          IN table_table_clob,
        i_id_edit_reason          IN vital_sign_read.id_edit_reason%TYPE,
        i_notes_edit              IN CLOB,
        i_value_high              IN table_number DEFAULT table_number(),
        i_value_low               IN table_number DEFAULT table_number(),
        i_fetus_vs                IN NUMBER DEFAULT NULL,
        i_update_pdms             IN BOOLEAN,
        i_id_epis_documentation   IN epis_documentation.id_epis_documentation%TYPE DEFAULT NULL,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'edit_vital_sign';
        l_message   debug_msg;
        l_exception EXCEPTION;
        c_sysdate_tstz CONSTANT vital_sign_read.dt_vital_sign_read_tstz%TYPE := current_timestamp();
        l_tb_attribute        table_number;
        l_tb_free_text        table_clob;
        l_id_unit_measure_sel vital_sign_read.id_unit_measure_sel%TYPE;
        l_value_high          vital_sign_read.value_high%TYPE;
        l_value_low           vital_sign_read.value_high%TYPE;
    BEGIN
        FOR i IN 1 .. i_id_vital_sign_read.count
        LOOP
            IF i_tbtb_attribute.exists(i)
            THEN
                l_tb_attribute := i_tbtb_attribute(i);
            ELSE
                l_tb_attribute := table_number();
            END IF;
        
            IF i_tbtb_free_text.exists(i)
            THEN
                l_tb_free_text := i_tbtb_free_text(i);
            ELSE
                l_tb_free_text := table_clob();
            END IF;
        
            IF i_id_unit_measure_sel.exists(i)
            THEN
                l_id_unit_measure_sel := i_id_unit_measure_sel(i);
            ELSE
                l_id_unit_measure_sel := i_id_unit_measure(i);
            END IF;
        
            IF i_value_high.exists(i)
            THEN
                l_value_high := i_value_high(i);
            ELSE
                l_value_high := NULL;
            END IF;
        
            IF i_value_low.exists(i)
            THEN
                l_value_low := i_value_low(i);
            ELSE
                l_value_low := NULL;
            END IF;
        
            l_message := 'CALL SINGLE EDIT FUNCTION';
            IF NOT
                edit_vital_sign(i_lang                    => i_lang,
                                i_prof                    => i_prof,
                                i_id_vital_sign_read      => i_id_vital_sign_read(i),
                                i_value                   => i_value(i),
                                i_id_unit_measure         => i_id_unit_measure(i),
                                i_dt_vital_sign_read_tstz => i_dt_vital_sign_read_tstz,
                                i_dt_registry             => nvl(i_dt_registry,
                                                                 pk_date_utils.date_send_tsz(i_lang, c_sysdate_tstz, i_prof)),
                                i_id_unit_measure_sel     => l_id_unit_measure_sel,
                                i_tb_attribute            => l_tb_attribute,
                                i_tb_free_text            => l_tb_free_text,
                                i_id_edit_reason          => i_id_edit_reason,
                                i_notes_edit              => i_notes_edit,
                                i_value_high              => l_value_high,
                                i_value_low               => l_value_low,
                                i_fetus_vs                => i_fetus_vs,
                                i_update_pdms             => i_update_pdms,
                                o_error                   => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END edit_vital_sign;

    /************************************************************************************************************
    * This function is returns history for a vital sign
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign_read     Vital Sign read ID
    * @param        o_vsr_history            History information
    * @param        o_error                  List of changed columns 
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/

    FUNCTION get_vital_sign_read_hist
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vsr_history        OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'get_vital_sign_read_hist';
        l_dbg_msg debug_msg;
    BEGIN
    
        l_dbg_msg := 'get history records for a vital sign. id_vital_sign_read = ' || i_id_vital_sign_read;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        OPEN o_vsr_history FOR
            SELECT vsrh.id_vital_sign_read,
                   vsrh.value VALUE,
                   pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsrh.id_unit_measure, vsr.id_vs_scales_element) AS desc_unit_measure,
                   pk_date_utils.date_char_tsz(i_lang,
                                               vsrh.dt_vital_sign_read_tstz,
                                               i_prof.institution,
                                               i_prof.software) AS date_read,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, vsrh.id_prof_read) AS prof_name,
                   pk_date_utils.date_char_tsz(i_lang, vsrh.dt_registry, i_prof.institution, i_prof.software) AS dt_registry,
                   vsrh.flg_value_changed,
                   vsrh.flg_dt_vs_read_changed,
                   vsrh.flg_id_prof_changed,
                   vsrh.flg_id_unit_changed
              FROM vital_sign_read_hist vsrh
              LEFT JOIN vital_sign_read vsr
                ON vsr.id_vital_sign_read = vsrh.id_vital_sign_read
             WHERE vsrh.id_vital_sign_read = i_id_vital_sign_read;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vital_sign_read_hist;

    /************************************************************************************************************
    * This function is returns details for a vital sign
    * @param        i_lang                  Language id
    * @param        i_prof                  Professional, software and institution ids
    * @param        i_id_vital_sign_read    Vital Sign reading ID
    * @param        i_id_vital_sign         Vital Sign ID
    * @param        i_flg_view              View identifier
    * @param        o_vsr_detail            Vital sign limit
    * @param        o_vsr_ids               Vital sign Read IDs for editing
    * @param        o_is_monit_record       Indicates if the record comes from a monitorization
    * @param        o_dt_ini                Start date limit
    * @param        o_dt_end                End date limit
    * @param        o_error                 error
    *                
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/

    FUNCTION get_vsr_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_vital_sign      IN vital_sign_read.id_vital_sign%TYPE,
        i_flg_view           IN vs_soft_inst.flg_view%TYPE,
        i_id_episode         IN vital_sign_read.id_episode%TYPE,
        o_vsr_detail         OUT pk_types.cursor_type,
        o_vsr_ids            OUT pk_types.cursor_type,
        o_is_monit_record    OUT VARCHAR2,
        o_dt_ini             OUT VARCHAR2,
        o_dt_end             OUT VARCHAR2,
        o_vsr_attrib         OUT pk_types.cursor_type,
        o_edit_info          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_VSR_DETAIL';
        l_dbg_msg debug_msg;
        l_exception EXCEPTION;
        l_monitorization_record vital_sign_read.id_monitorization_vs_plan%TYPE;
        l_id_episode            episode.id_episode%TYPE;
        l_id_patient            patient.id_patient%TYPE;
    
        l_confs       PLS_INTEGER;
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
    
        l_parent_count NUMBER;
    
        l_id_current_vs  vital_sign_read.id_vital_sign%TYPE;
        l_dt_read_vs     vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_dt_registry_vs vital_sign_read.dt_registry%TYPE;
        l_decimal_symbol sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                          i_prof_inst => i_prof.institution,
                                                                          i_prof_soft => i_prof.software);
        l_age            vital_sign_unit_measure.age_min%TYPE;
    
        l_vs_attributes sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'VITAL_SIGN_ATTRIBUTES',
                                                                         i_prof_inst => i_prof.institution,
                                                                         i_prof_soft => i_prof.software);
    BEGIN
    
        l_dbg_msg := 'get data from vital sign record. id_vital_sign_read = ' || i_id_vital_sign_read;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        BEGIN
            SELECT vsr.id_monitorization_vs_plan, vsr.id_patient, vsr.id_episode
              INTO l_monitorization_record, l_id_patient, l_id_episode
              FROM vital_sign_read vsr
             WHERE vsr.id_vital_sign_read = i_id_vital_sign_read;
        EXCEPTION
            WHEN no_data_found THEN
                l_monitorization_record := NULL;
                BEGIN
                    SELECT e.id_patient
                      INTO l_id_patient
                      FROM episode e
                     WHERE e.id_episode = i_id_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_patient := NULL;
                END;
                l_id_episode := i_id_episode;
        END;
    
        IF l_monitorization_record IS NOT NULL
        THEN
            o_is_monit_record := 'Y';
        ELSE
            o_is_monit_record := 'N';
        
            l_dbg_msg := 'calculate date limits. id_vital_sign_read = ' || i_id_vital_sign_read;
            pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        
            IF NOT get_vs_date_limits(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_patient           => l_id_patient,
                                      i_episode           => l_id_episode,
                                      i_id_monitorization => NULL,
                                      o_dt_ini            => o_dt_ini,
                                      o_dt_end            => o_dt_end,
                                      o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        l_dbg_msg := 'test configs for vital signs'' limits parametrizations. id_vital_sign_read = ' ||
                     i_id_vital_sign_read;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT COUNT(1)
          INTO l_confs
          FROM vs_soft_inst vsi
         INNER JOIN vital_sign vs
            ON vsi.id_vital_sign = vs.id_vital_sign
           AND vs.flg_available = pk_alert_constant.g_yes
         WHERE vsi.id_software = i_prof.software
           AND vsi.id_institution = i_prof.institution
           AND vsi.flg_view = nvl(i_flg_view, vsi.flg_view);
    
        IF l_confs > 0
        THEN
            l_software    := i_prof.software;
            l_institution := i_prof.institution;
        END IF;
    
        l_age := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', l_id_patient);
    
        l_dbg_msg := 'get limits for a vital sign. id_vital_sign = ' || i_id_vital_sign;
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        OPEN o_vsr_detail FOR
            SELECT DISTINCT vsi.id_vital_sign,
                            (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsi.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_min,
                            (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_id_vital_sign   => vsi.id_vital_sign,
                                                                        i_id_unit_measure => vsi.id_unit_measure,
                                                                        i_id_institution  => i_prof.institution,
                                                                        i_id_software     => i_prof.software,
                                                                        i_age             => l_age)
                               FROM dual) val_max,
                            vsi.rank,
                            vsi.rank_conc,
                            vsi.id_vital_sign_parent,
                            vsi.relation_type,
                            (SELECT pk_vital_sign_core.get_vsum_format_num(i_lang            => i_lang,
                                                                           i_prof            => i_prof,
                                                                           i_id_vital_sign   => vsi.id_vital_sign,
                                                                           i_id_unit_measure => vsi.id_unit_measure,
                                                                           i_id_institution  => i_prof.institution,
                                                                           i_id_software     => i_prof.software,
                                                                           i_age             => l_age)
                               FROM dual) format_num,
                            vsi.flg_fill_type,
                            vsi.flg_sum,
                            vsi.name_vs,
                            vsi.desc_unit_measure,
                            vsi.id_unit_measure,
                            o_dt_end AS dt_server
            
              FROM (SELECT vsi.id_vital_sign,
                           vsi.rank,
                           NULL AS rank_conc,
                           CASE
                                WHEN vsrel.relation_domain = pk_alert_constant.g_vs_rel_sum THEN
                                 NULL
                                ELSE
                                 vsrel.id_vital_sign_parent
                            END id_vital_sign_parent,
                           vsrel.relation_domain AS relation_type,
                           CASE (SELECT COUNT(1)
                               FROM vital_sign_relation vrpar
                              WHERE vsi.id_vital_sign = vrpar.id_vital_sign_parent
                                AND vrpar.relation_domain = pk_alert_constant.g_vs_rel_sum
                                AND vrpar.flg_available = pk_alert_constant.g_yes)
                               WHEN 0 THEN
                                vs.flg_fill_type
                               ELSE
                                'X'
                           END AS flg_fill_type,
                           CASE vsrel.relation_domain
                               WHEN pk_alert_constant.g_vs_rel_sum THEN
                                pk_alert_constant.g_yes
                               ELSE
                                pk_alert_constant.g_no
                           END AS flg_sum,
                           pk_translation.get_translation(i_lang, vs.code_vital_sign) AS name_vs,
                           pk_translation.get_translation(i_lang, um.code_unit_measure) AS desc_unit_measure,
                           vsi.id_unit_measure
                      FROM vs_soft_inst vsi
                     INNER JOIN vital_sign vs
                        ON vsi.id_vital_sign = vs.id_vital_sign
                       AND vs.flg_available = pk_alert_constant.g_yes
                      LEFT OUTER JOIN unit_measure um
                        ON vsi.id_unit_measure = um.id_unit_measure
                       AND um.flg_available = pk_alert_constant.g_yes
                    
                      LEFT OUTER JOIN vital_sign_relation vsrel
                        ON vsi.id_vital_sign = vsrel.id_vital_sign_detail
                       AND vsrel.flg_available = pk_alert_constant.g_yes
                       AND vsrel.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                     WHERE vsi.id_software = l_software
                       AND vsi.id_institution = l_institution
                       AND vsi.flg_view = nvl(i_flg_view, vsi.flg_view)
                       AND vsi.id_vital_sign = i_id_vital_sign
                    
                    UNION ALL
                    
                    -- Details (vital signs chidren) of vital signs (blood pressures) configured for a view
                    SELECT vsrel.id_vital_sign_detail AS id_vital_sign,
                           vsi.rank,
                           vsrel.rank AS rank_conc,
                           CASE
                               WHEN vsrel.relation_domain = pk_alert_constant.g_vs_rel_sum THEN
                                NULL
                               ELSE
                                vsrel.id_vital_sign_parent
                           END id_vital_sign_parent,
                           vsrel.relation_domain AS relation_type,
                           vs.flg_fill_type,
                           CASE vsrel.relation_domain
                               WHEN pk_alert_constant.g_vs_rel_sum THEN
                                pk_alert_constant.g_yes
                               ELSE
                                pk_alert_constant.g_no
                           END AS flg_sum,
                           pk_translation.get_translation(i_lang, vs.code_vital_sign) AS name_vs,
                           pk_translation.get_translation(i_lang, um.code_unit_measure) AS desc_unit_measure,
                           vsi.id_unit_measure
                      FROM (SELECT vsi.id_vital_sign, vsi.rank, vsi.id_unit_measure, vsi.id_institution, vsi.id_software
                              FROM vs_soft_inst vsi
                             INNER JOIN vital_sign vs
                                ON vsi.id_vital_sign = vs.id_vital_sign
                               AND vs.flg_available = pk_alert_constant.g_yes
                             WHERE vsi.id_software = l_software
                               AND vsi.id_institution = l_institution
                               AND vsi.flg_view = nvl(i_flg_view, vsi.flg_view)) vsi
                     INNER JOIN vital_sign_relation vsrel
                        ON vsi.id_vital_sign = vsrel.id_vital_sign_parent
                       AND vsrel.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc)
                       AND vsrel.flg_available = pk_alert_constant.g_yes
                     INNER JOIN vital_sign vs
                        ON vsrel.id_vital_sign_detail = vs.id_vital_sign
                       AND vs.flg_available = pk_alert_constant.g_yes
                      LEFT OUTER JOIN unit_measure um
                        ON vsi.id_unit_measure = um.id_unit_measure
                       AND um.flg_available = pk_alert_constant.g_yes
                    
                     WHERE vsi.id_vital_sign = i_id_vital_sign) vsi
             ORDER BY vsi.rank ASC, rank_conc ASC NULLS FIRST;
    
        SELECT COUNT(1)
          INTO l_parent_count
          FROM vital_sign_relation vsrl
         WHERE vsrl.id_vital_sign_parent = i_id_vital_sign
           AND vsrl.flg_available = pk_alert_constant.g_yes
           AND vsrl.relation_domain != pk_alert_constant.g_vs_rel_percentile;
    
        IF i_id_vital_sign_read IS NOT NULL
        THEN
            IF l_parent_count > 0
            THEN
                SELECT vsr.id_vital_sign, vsr.dt_vital_sign_read_tstz, vsr.dt_registry
                  INTO l_id_current_vs, l_dt_read_vs, l_dt_registry_vs
                  FROM vital_sign_read vsr
                 WHERE vsr.id_vital_sign_read = i_id_vital_sign_read;
            
                OPEN o_vsr_ids FOR
                    SELECT vsrl.id_vital_sign_parent,
                           vsrl.id_vital_sign_detail id_vital_sign,
                           vsr.id_vital_sign_read,
                           nvl(vsr.value, vsr.id_vital_sign_desc) VALUE,
                           CASE vsrl.relation_domain
                               WHEN pk_alert_constant.g_vs_rel_conc THEN
                                pk_vital_sign.get_bloodpressure_value(i_vital_sign         => vsrl.id_vital_sign_parent,
                                                                      i_patient            => vsr.id_patient,
                                                                      i_episode            => vsr.id_episode,
                                                                      i_dt_vital_sign_read => vsr.dt_vital_sign_read_tstz,
                                                                      i_decimal_symbol     => l_decimal_symbol,
                                                                      i_dt_registry        => vsr.dt_registry)
                               WHEN pk_alert_constant.g_vs_rel_sum THEN
                                nvl2(vsr.id_vital_sign_desc,
                                     pk_vital_sign.get_vsd_desc(i_lang, vsr.id_vital_sign_desc, vsr.id_patient),
                                     pk_utils.to_str(vsr.value, l_decimal_symbol))
                               ELSE
                                NULL
                           END AS desc_value,
                           vsr.id_unit_measure,
                           pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                       i_date => vsr.dt_vital_sign_read_tstz,
                                                       i_prof => i_prof) dt_vital_sign_read_tstz,
                           
                           vsse.id_vital_sign_scales,
                           vsd.value                 id_vital_sign_glasgow
                      FROM vital_sign_relation vsrl
                     INNER JOIN vital_sign_read vsr
                        ON vsr.id_vital_sign = vsrl.id_vital_sign_detail
                      LEFT JOIN vital_sign_desc vsd
                        ON vsd.id_vital_sign_desc = vsr.id_vital_sign_desc
                      LEFT JOIN vital_sign_scales_element vsse
                        ON vsse.id_vs_scales_element = vsr.id_vs_scales_element
                     WHERE vsrl.id_vital_sign_parent = i_id_vital_sign
                       AND vsr.id_episode = l_id_episode
                       AND vsr.dt_vital_sign_read_tstz = l_dt_read_vs
                       AND vsr.dt_registry = l_dt_registry_vs
                       AND vsrl.flg_available = pk_alert_constant.g_yes
                       AND vsrl.relation_domain != pk_alert_constant.g_vs_rel_percentile
                     ORDER BY vsrl.rank ASC;
            ELSE
                OPEN o_vsr_ids FOR
                    SELECT NULL id_vital_sign_parent,
                           vsr.id_vital_sign_read,
                           vsr.id_vital_sign,
                           nvl(vsr.value, vsd.id_vital_sign_desc) VALUE,
                           nvl2(vsr.id_vital_sign_desc,
                                pk_vital_sign.get_vsd_desc(i_lang, vsr.id_vital_sign_desc, vsr.id_patient),
                                pk_utils.to_str(vsr.value, l_decimal_symbol)) AS desc_value,
                           vsr.id_unit_measure,
                           pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                       i_date => vsr.dt_vital_sign_read_tstz,
                                                       i_prof => i_prof) dt_vital_sign_read_tstz,
                           vsse.id_vital_sign_scales,
                           vsd.value id_vital_sign_glasgow
                      FROM vital_sign_read vsr
                      LEFT JOIN vital_sign_desc vsd
                        ON vsd.id_vital_sign_desc = vsr.id_vital_sign_desc
                      LEFT JOIN vital_sign_scales_element vsse
                        ON vsse.id_vs_scales_element = vsr.id_vs_scales_element
                     WHERE vsr.id_vital_sign_read = i_id_vital_sign_read;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_vsr_ids);
        END IF;
    
        IF l_vs_attributes = pk_alert_constant.g_yes
        THEN
            IF NOT pk_vital_sign_core.get_vs_read_attributes(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_id_vital_sign      => i_id_vital_sign,
                                                             i_id_vital_sign_read => i_id_vital_sign_read,
                                                             o_cursor             => o_vsr_attrib,
                                                             o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_vsr_attrib);
        END IF;
    
        IF NOT pk_vital_sign_core.get_edit_info(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_vital_sign_read => i_id_vital_sign_read,
                                                i_screen             => 'E',
                                                i_flg_view           => i_flg_view,
                                                o_info               => o_edit_info,
                                                o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_vsr_detail);
            pk_types.open_my_cursor(o_vsr_ids);
            pk_types.open_my_cursor(o_vsr_attrib);
            pk_types.open_my_cursor(o_edit_info);
        
            RETURN FALSE;
    END get_vsr_detail;

    /************************************************************************************************************
    * This function calculates date limits when editing a vital sign
    * @param        i_lang                  Language id
    * @param        i_prof                  Professional, software and institution ids
    * @param        i_patient               Patient ID
    * @param        i_episode               Episode ID
    * @param        i_monitorization        Monitorization ID
    * @param        o_dt_ini                Start date limit
    * @param        o_dt_end                End date limit
    * @param        o_error                 error
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      18-Feb-2011
    ************************************************************************************************************/

    FUNCTION get_vs_date_limits
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_id_monitorization IN monitorization.id_monitorization%TYPE,
        o_dt_ini            OUT VARCHAR2,
        o_dt_end            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'GET_VS_DATE_LIMITS';
        l_dbg_msg debug_msg;
        l_dt_ini  episode.dt_begin_tstz%TYPE;
        l_dt_end  episode.dt_end_tstz%TYPE;
    BEGIN
        l_dbg_msg := 'get date from which it is possible to register vital signs';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        SELECT MAX(dt_ini)
          INTO l_dt_ini
          FROM (SELECT e.dt_begin_tstz AS dt_ini
                  FROM episode e
                 WHERE e.id_episode = i_episode
                /*UNION ALL
                SELECT p.dt_birth AS dt_ini
                  FROM patient p
                 WHERE p.id_patient = i_patient*/
                UNION ALL
                SELECT m.dt_monitorization_tstz AS dt_ini
                  FROM monitorization m
                 WHERE m.id_monitorization = i_id_monitorization);
    
        o_dt_ini := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt_ini, i_prof => i_prof);
    
        l_dbg_msg := 'get date as far it is possible to register vital signs';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
    
        SELECT MIN(dt_end)
          INTO l_dt_end
          FROM (SELECT e.dt_end_tstz AS dt_end
                  FROM episode e
                 WHERE e.id_episode = i_episode
                /*UNION ALL
                SELECT p.dt_deceased AS dt_end
                  FROM patient p
                 WHERE p.id_patient = i_patient*/
                );
    
        o_dt_end := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt_end, i_prof => i_prof);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            o_dt_ini := NULL;
            o_dt_end := NULL;
            RETURN FALSE;
    END get_vs_date_limits;

    /**********************************************************************************************
    * Get vital signs 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_scope                     Scope ID (Patient ID, Visit ID)
    * @param    i_scope_type                Scope type (by patient {P}, by visit {V})
    * @param    i_begin_date                Begin date
    * @param    i_end_date                  End date
    * @param    i_flg_view                  Vital signs view to be used to get the vital sign rank
    * @param    i_flg_mode                  0-get last 3 recods, 1- get last 2 records and the 1st one
    *
    * @param    o_list                      Cursor with vital signs
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.0.5
    * @since   2011/02/02
    **********************************************************************************************/
    /**********************************************************************************************
    * Get vital signs 
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_scope                     Scope ID (Patient ID, Visit ID)
    * @param    i_scope_type                Scope type (by patient {P}, by visit {V})
    * @param    i_begin_date                Begin date
    * @param    i_end_date                  End date
    * @param    i_flg_view                  Vital signs view to be used to get the vital sign rank
    * 
    * @param    o_list                      Cursor with vital signs
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @author  Filipe Silva
    * @version 2.6.2
    * @since   2011/02/02
    **********************************************************************************************/
    FUNCTION get_vital_signs_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_scope          IN NUMBER,
        i_scope_type     IN VARCHAR2,
        i_begin_date     IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_outside_period IN VARCHAR2,
        i_flg_view       IN VARCHAR2,
        o_list           OUT t_cur_vital_signs,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_id_patient     patient.id_patient%TYPE;
        l_id_visit       visit.id_visit%TYPE;
        l_id_episode     episode.id_episode%TYPE;
        l_decimal_symbol sys_config.value%TYPE;
        l_func_name      VARCHAR2(30 CHAR) := 'GET_VITAL_SIGNS_LIST';
        l_dbg_msg        debug_msg;
    
    BEGIN
    
        l_dbg_msg := 'GET DECIMAL SYMBOL';
        pk_alertlog.log_debug(l_dbg_msg);
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                    i_prof_inst => i_prof.institution,
                                                    i_prof_soft => i_prof.software);
    
        l_dbg_msg := 'GET SCOPE ID: ' || i_scope || ' AND SCOPE TYPE: ' || i_scope_type;
        pk_alertlog.log_debug(l_dbg_msg);
    
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_dbg_msg := 'OPEN O_LIST CURSOR';
        pk_alertlog.log_debug(l_dbg_msg);
        OPEN o_list FOR
            SELECT pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_patient            => t.id_patient_1,
                                               i_episode            => t.id_episode_1,
                                               i_vital_sign         => t.id_vital_sign,
                                               i_value              => t.value_1,
                                               i_vs_unit_measure    => t.id_unit_measure_1,
                                               i_vital_sign_desc    => t.id_vital_sign_desc_1,
                                               i_vs_scales_element  => t.id_vs_scales_element_1,
                                               i_dt_vital_sign_read => t.dt_vital_sign_read_tstz_1,
                                               i_ea_unit_measure    => t.id_unit_measure_1,
                                               i_short_desc         => pk_alert_constant.g_no,
                                               i_decimal_symbol     => l_decimal_symbol,
                                               i_dt_registry        => t.dt_registry_1) || CASE
                        WHEN t.id_unit_measure_1 <> pk_vital_sign.c_without_um THEN
                         ' ' || (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                                  t.id_unit_measure_1,
                                                                                  t.id_vs_scales_element_1)
                                   FROM dual)
                    
                        ELSE
                         NULL
                    END || ' ' ||
                   --
                    (SELECT pk_vital_sign.get_vs_scale_short_desc(i_lang, i_prof, t.id_vs_scales_element_1)
                       FROM dual)
                   
                    AS vs_description_1,
                   t.dt_vital_sign_read_tstz_1 AS dt_reg_1,
                   t.id_prof_read_1,
                   t.id_vital_sign_read_1,
                   t.id_episode_1,
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_patient            => t.id_patient_2,
                                               i_episode            => t.id_episode_2,
                                               i_vital_sign         => t.id_vital_sign,
                                               i_value              => t.value_2,
                                               i_vs_unit_measure    => t.id_unit_measure_2,
                                               i_vital_sign_desc    => t.id_vital_sign_desc_2,
                                               i_vs_scales_element  => t.id_vs_scales_element_2,
                                               i_dt_vital_sign_read => t.dt_vital_sign_read_tstz_2,
                                               i_ea_unit_measure    => t.id_unit_measure_2,
                                               i_short_desc         => pk_alert_constant.g_no,
                                               i_decimal_symbol     => l_decimal_symbol,
                                               i_dt_registry        => t.dt_registry_2) || CASE
                        WHEN t.id_unit_measure_2 <> pk_vital_sign.c_without_um THEN
                         ' ' || (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                                  t.id_unit_measure_2,
                                                                                  t.id_vs_scales_element_2)
                                   FROM dual)
                        ELSE
                         NULL
                    END || ' ' ||
                   --
                    (SELECT pk_vital_sign.get_vs_scale_short_desc(i_lang, i_prof, t.id_vs_scales_element_2)
                       FROM dual) AS vs_description_2,
                   t.dt_vital_sign_read_tstz_2 AS dt_reg_2,
                   t.id_prof_read_2,
                   t.id_vital_sign_read_2,
                   t.id_episode_2,
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_patient            => t.id_patient_3,
                                               i_episode            => t.id_episode_3,
                                               i_vital_sign         => t.id_vital_sign,
                                               i_value              => t.value_3,
                                               i_vs_unit_measure    => t.id_unit_measure_3,
                                               i_vital_sign_desc    => t.id_vital_sign_desc_3,
                                               i_vs_scales_element  => t.id_vs_scales_element_3,
                                               i_dt_vital_sign_read => t.dt_vital_sign_read_tstz_3,
                                               i_ea_unit_measure    => t.id_unit_measure_3,
                                               i_short_desc         => pk_alert_constant.g_no,
                                               i_decimal_symbol     => l_decimal_symbol,
                                               i_dt_registry        => t.dt_registry_3) || CASE
                        WHEN t.id_unit_measure_3 <> pk_vital_sign.c_without_um THEN
                         ' ' || (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                                  t.id_unit_measure_3,
                                                                                  t.id_vs_scales_element_3)
                                   FROM dual)
                        ELSE
                         NULL
                    END || ' ' ||
                   --
                    (SELECT pk_vital_sign.get_vs_scale_short_desc(i_lang, i_prof, t.id_vs_scales_element_3)
                       FROM dual) AS vs_description_3,
                   t.dt_vital_sign_read_tstz_3 AS dt_reg_3,
                   t.id_prof_read_3,
                   t.id_vital_sign_read_3,
                   t.id_episode_3,
                   t.id_vital_sign,
                   t.dt_registry_1,
                   t.dt_registry_2,
                   t.dt_registry_3,
                   pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                               i_prof               => i_prof,
                                               i_patient            => t.id_patient_4,
                                               i_episode            => t.id_episode_4,
                                               i_vital_sign         => t.id_vital_sign,
                                               i_value              => t.value_4,
                                               i_vs_unit_measure    => t.id_unit_measure_4,
                                               i_vital_sign_desc    => t.id_vital_sign_desc_4,
                                               i_vs_scales_element  => t.id_vs_scales_element_4,
                                               i_dt_vital_sign_read => t.dt_vital_sign_read_tstz_4,
                                               i_ea_unit_measure    => t.id_unit_measure_4,
                                               i_short_desc         => pk_alert_constant.g_no,
                                               i_decimal_symbol     => l_decimal_symbol,
                                               i_dt_registry        => t.dt_registry_4) || CASE
                        WHEN t.id_unit_measure_4 <> pk_vital_sign.c_without_um THEN
                         ' ' || (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                                  t.id_unit_measure_4,
                                                                                  t.id_vs_scales_element_4)
                                   FROM dual)
                        ELSE
                         NULL
                    END || ' ' ||
                   --
                    (SELECT pk_vital_sign.get_vs_scale_short_desc(i_lang, i_prof, t.id_vs_scales_element_4)
                       FROM dual) AS vs_description_4,
                   t.dt_vital_sign_read_tstz_4 AS dt_reg_4,
                   t.id_prof_read_4,
                   t.id_vital_sign_read_4,
                   t.id_episode_4,
                   t.dt_registry_4,
                   t.vs_desc
              FROM (SELECT ea.id_vital_sign,
                           lst1.id_vital_sign_read id_vital_sign_read_1,
                           lst1.id_prof_read id_prof_read_1,
                           lst1.value value_1,
                           lst1.id_patient id_patient_1,
                           lst1.id_episode id_episode_1,
                           lst1.id_unit_measure id_unit_measure_1,
                           lst1.id_vital_sign_desc id_vital_sign_desc_1,
                           lst1.id_vs_scales_element id_vs_scales_element_1,
                           lst1.dt_vital_sign_read_tstz dt_vital_sign_read_tstz_1,
                           lst2.id_vital_sign_read id_vital_sign_read_2,
                           lst2.id_prof_read id_prof_read_2,
                           lst2.value value_2,
                           lst2.id_vs_scales_element id_vs_scales_element_2,
                           lst2.id_patient id_patient_2,
                           lst2.id_episode id_episode_2,
                           lst2.id_unit_measure id_unit_measure_2,
                           lst2.id_vital_sign_desc id_vital_sign_desc_2,
                           lst2.dt_vital_sign_read_tstz dt_vital_sign_read_tstz_2,
                           lst3.id_vital_sign_read id_vital_sign_read_3,
                           lst3.id_prof_read id_prof_read_3,
                           lst3.value value_3,
                           lst3.id_patient id_patient_3,
                           lst3.id_episode id_episode_3,
                           lst3.id_unit_measure id_unit_measure_3,
                           lst3.id_vital_sign_desc id_vital_sign_desc_3,
                           lst3.id_vs_scales_element id_vs_scales_element_3,
                           lst3.dt_vital_sign_read_tstz dt_vital_sign_read_tstz_3,
                           pk_vital_sign.get_vs_desc(i_lang, ea.id_vital_sign, pk_alert_constant.g_no) vs_desc,
                           lst1.dt_registry dt_registry_1,
                           lst2.dt_registry dt_registry_2,
                           lst3.dt_registry dt_registry_3,
                           lst4.id_vital_sign_read id_vital_sign_read_4,
                           lst4.id_prof_read id_prof_read_4,
                           lst4.value value_4,
                           lst4.id_patient id_patient_4,
                           lst4.id_episode id_episode_4,
                           lst4.id_unit_measure id_unit_measure_4,
                           lst4.id_vital_sign_desc id_vital_sign_desc_4,
                           lst4.id_vs_scales_element id_vs_scales_element_4,
                           lst4.dt_vital_sign_read_tstz dt_vital_sign_read_tstz_4,
                           lst4.dt_registry dt_registry_4
                      FROM (SELECT vvea.id_vital_sign,
                                   vvea.id_unit_measure,
                                   vvea.n_records,
                                   vvea.id_first_vsr,
                                   vvea.id_min_vsr,
                                   vvea.id_max_vsr,
                                   vvea.id_last_3_vsr,
                                   vvea.id_last_2_vsr,
                                   vvea.id_last_1_vsr
                              FROM vs_visit_ea vvea
                             WHERE l_id_visit IS NOT NULL
                               AND vvea.id_visit = l_id_visit
                            UNION ALL
                            SELECT vpea.id_vital_sign,
                                   vpea.id_unit_measure,
                                   vpea.n_records,
                                   vpea.id_first_vsr,
                                   vpea.id_min_vsr,
                                   vpea.id_max_vsr,
                                   vpea.id_last_3_vsr,
                                   vpea.id_last_2_vsr,
                                   vpea.id_last_1_vsr
                              FROM vs_patient_ea vpea
                             WHERE l_id_visit IS NULL
                               AND vpea.id_patient = l_id_patient) ea
                      LEFT OUTER JOIN vital_sign_read lst1
                        ON ea.id_last_1_vsr = lst1.id_vital_sign_read
                       AND lst1.dt_vital_sign_read_tstz >= nvl(i_begin_date, lst1.dt_vital_sign_read_tstz)
                       AND lst1.dt_vital_sign_read_tstz <= nvl(i_end_date, lst1.dt_vital_sign_read_tstz)
                       AND lst1.flg_state != pk_alert_constant.g_cancelled
                      LEFT OUTER JOIN vital_sign_read lst2
                        ON ea.id_last_2_vsr = lst2.id_vital_sign_read
                       AND lst2.dt_vital_sign_read_tstz >= nvl(i_begin_date, lst2.dt_vital_sign_read_tstz)
                       AND lst2.dt_vital_sign_read_tstz <= nvl(i_end_date, lst2.dt_vital_sign_read_tstz)
                       AND lst2.flg_state != pk_alert_constant.g_cancelled
                      LEFT OUTER JOIN vital_sign_read lst3
                        ON ea.id_last_3_vsr = lst3.id_vital_sign_read
                       AND lst3.dt_vital_sign_read_tstz >= nvl(i_begin_date, lst3.dt_vital_sign_read_tstz)
                       AND lst3.dt_vital_sign_read_tstz <= nvl(i_end_date, lst3.dt_vital_sign_read_tstz)
                       AND lst3.flg_state != pk_alert_constant.g_cancelled
                      LEFT OUTER JOIN vital_sign_read lst4
                        ON ea.id_first_vsr = lst4.id_vital_sign_read
                       AND lst4.dt_vital_sign_read_tstz >= nvl(i_begin_date, lst4.dt_vital_sign_read_tstz)
                       AND lst4.dt_vital_sign_read_tstz <= nvl(i_end_date, lst4.dt_vital_sign_read_tstz)
                       AND lst4.flg_state != pk_alert_constant.g_cancelled) t
             WHERE id_vital_sign_read_1 IS NOT NULL
                OR id_vital_sign_read_2 IS NOT NULL
                OR id_vital_sign_read_3 IS NOT NULL;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_dbg_msg,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            open_cur_vital_signs(o_list);
            RETURN FALSE;
    END get_vital_signs_list;

    /**********************************************************************************************
    * Opens the  t_cur_vital_signs strong cursor
    * 
    * @param    i_cursor                    Cursor
    * 
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   06-Oct-2011
    **********************************************************************************************/
    PROCEDURE open_cur_vital_signs(i_cursor IN OUT t_cur_vital_signs) IS
    
    BEGIN
    
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL vs_description_1,
                   NULL dt_reg_1,
                   NULL id_professional_1,
                   NULL id_vital_sign_read_1,
                   NULL id_episode_1,
                   NULL vs_description_2,
                   NULL dt_reg_2,
                   NULL id_professional_2,
                   NULL id_vital_sign_read_2,
                   NULL id_episode_2,
                   NULL vs_description_3,
                   NULL dt_reg_3,
                   NULL id_professional_3,
                   NULL id_vital_sign_read_3,
                   NULL id_episode_3,
                   NULL id_vital_sign,
                   NULL dt_last_upd_1,
                   NULL dt_last_upd_2,
                   NULL dt_last_upd_3,
                   NULL vs_description_4,
                   NULL dt_reg_4,
                   NULL id_professional_4,
                   NULL id_vital_sign_read_4,
                   NULL id_episode_4,
                   NULL dt_last_upd_4,
                   NULL vs_desc
              FROM dual
             WHERE 1 = 0;
    
    END open_cur_vital_signs;

    /**********************************************************************************************
    * This functions sets a vital sign as "reviewed"
    * 
    * @param IN   i_lang                  Language ID
    * @param IN   i_prof                  Professional information
    * @param IN   i_episode               Episode ID
    * @param IN   i_id_vital_sign_read    Vital Sign reading ID
    * @param IN   i_review_notes          Review notes
    * @param OUT  o_error                 Error structure
    * 
    * @return                             True on success, false on error
    * 
    * @author  Sergio Dias
    * @version 2.6.1
    * @since   2011/03/10
    **********************************************************************************************/
    FUNCTION set_vital_sign_review
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_review_notes       IN review_detail.review_notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'set_vital_sign_review';
        l_message   debug_msg;
        l_exception EXCEPTION;
    
    BEGIN
    
        l_message := 'SET_ALLERGY_AS_REVIEW';
        IF (NOT pk_review.set_review(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_record_area => i_id_vital_sign_read,
                                     i_flg_context    => pk_review.get_vital_signs_context(),
                                     i_dt_review      => current_timestamp,
                                     i_review_notes   => i_review_notes,
                                     i_episode        => i_episode,
                                     i_flg_auto       => pk_alert_constant.g_no,
                                     i_revision       => NULL,
                                     o_error          => o_error))
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_vital_sign_review;

    /**********************************************************************************************
    * This function sets one or several vital signs as "reviewed"
    * 
    * @param IN   i_lang                  Language ID
    * @param IN   i_prof                  Professional information
    * @param IN   i_episode               Episode ID
    * @param IN   i_id_vital_sign_read    Vital Sign reading ID (multiple)
    * @param IN   i_review_notes          Review notes
    * @param OUT  o_error                 Error structure
    * 
    * @return                             True on success, false on error
    * 
    * @author  Sergio Dias
    * @version 2.6.1
    * @since   2011/03/10
    **********************************************************************************************/
    FUNCTION set_vital_sign_review
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_vital_sign_read IN table_number,
        i_review_notes       IN review_detail.review_notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'set_vital_sign_review';
        l_message   debug_msg;
        l_exception EXCEPTION;
    
    BEGIN
    
        FOR i IN 1 .. i_id_vital_sign_read.count
        LOOP
            l_message := 'SET_ALLERGY_REVIEW';
            IF (NOT set_vital_sign_review(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_episode            => i_episode,
                                          i_id_vital_sign_read => i_id_vital_sign_read(i),
                                          i_review_notes       => i_review_notes,
                                          o_error              => o_error))
            THEN
                RAISE l_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_vital_sign_review;

    /************************************************************************************************************
    * This function returns the new detail screen for a vital sign reading
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_id_vital_sign_read     Vital sign read ID
    * @param        i_flg_screen             Screen modifier
    * @param        o_hist                   History Info
    * @param        o_error                  Error
    *
    * @author     Sergio Dias
    * @version    2.6.1
    * @since      19-Apr-2011
    ************************************************************************************************************/
    FUNCTION get_vs_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_flg_screen         IN VARCHAR2,
        o_hist               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_VS_DETAIL';
        l_dbg_msg   debug_msg;
        --
        l_id_market   market.id_market%TYPE := pk_utils.get_institution_market(i_lang, i_prof.institution);
        l_tab_vs_hist t_vs_detail_coll;
    
        l_tab_hist      t_table_epis_hist := t_table_epis_hist();
        l_is_first_line BOOLEAN := TRUE;
    
        l_tbl_lables table_varchar := table_varchar();
        l_tbl_values table_varchar := table_varchar();
        l_tbl_types  table_varchar := table_varchar();
    
        l_value              sys_message.desc_message%TYPE;
        l_new_value          sys_message.desc_message%TYPE;
        l_date               sys_message.desc_message%TYPE;
        l_new_date           sys_message.desc_message%TYPE;
        l_result             sys_message.desc_message%TYPE;
        l_editing_result     sys_message.desc_message%TYPE;
        l_status             sys_message.desc_message%TYPE;
        l_cancelled          sys_message.desc_message%TYPE;
        l_cancel_reason      sys_message.desc_message%TYPE;
        l_cancel_notes       sys_message.desc_message%TYPE;
        l_review             sys_message.desc_message%TYPE;
        l_reviewed_by        sys_message.desc_message%TYPE;
        l_weight             sys_message.desc_message%TYPE;
        l_height             sys_message.desc_message%TYPE;
        l_cancel_reason_desc translation.desc_lang_1%TYPE;
        l_prof_cancel        vital_sign_read.id_prof_cancel%TYPE;
        l_notes_cancel       vital_sign_read.notes_cancel%TYPE;
        l_dt_cancel          vital_sign_read.dt_cancel_tstz%TYPE;
        l_notes              sys_message.desc_message%TYPE;
        l_partial_value      vital_sign_read.value%TYPE;
        l_partial_unit       vital_sign_read.id_unit_measure%TYPE;
        l_vital_sign         vital_sign_read.id_vital_sign%TYPE;
        l_patient            vital_sign_read.id_patient%TYPE;
        l_partial_date       vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
        l_edit_reason     sys_message.desc_message%TYPE;
        l_new_record      sys_message.desc_message%TYPE;
        l_triage          sys_message.desc_message%TYPE;
        l_vital_sign_desc translation.desc_lang_1%TYPE;
    
        CURSOR c_reviews(i_vsr IN vital_sign_read.id_vital_sign_read%TYPE) IS
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, rv.id_professional) desc_prof,
                   pk_date_utils.date_char_tsz(i_lang, rv.dt_review, i_prof.institution, i_prof.software) review_date,
                   rv.id_professional
              FROM review_detail rv
              LEFT JOIN vital_sign_read vsr
                ON rv.id_record_area = vsr.id_vital_sign_read
               AND vsr.id_episode = rv.id_episode
             WHERE rv.flg_context = pk_review.get_vital_signs_context
               AND rv.id_record_area = i_vsr
             ORDER BY rv.dt_review DESC;
    
        CURSOR vs_read_attrib(i_id IN vital_sign_read.id_vital_sign_read%TYPE) IS
            SELECT l_vsa_label, l_vsa_value
              FROM (SELECT pk_translation.get_translation(i_lang, vsap.code_vs_attribute) l_vsa_label,
                           to_char(decode(to_char(vsra.free_text),
                                          '',
                                          pk_translation.get_translation(i_lang, vsa.code_vs_attribute),
                                          vsra.free_text)) l_vsa_value,
                           (SELECT pk_vital_sign_core.get_vsa_rank(i_lang,
                                                                   i_prof,
                                                                   vsr.id_vital_sign,
                                                                   vsap.id_vs_attribute,
                                                                   l_id_market)
                              FROM dual) rank
                      FROM vs_read_attribute vsra
                      JOIN vs_attribute vsa
                        ON vsa.id_vs_attribute = vsra.id_vs_attribute
                      JOIN vs_attribute vsap
                        ON vsap.id_vs_attribute = vsa.id_parent
                      JOIN vital_sign_read vsr
                        ON vsr.id_vital_sign_read = vsra.id_vital_sign_read
                     WHERE vsra.id_vital_sign_read = i_id) aux
             ORDER BY aux.rank ASC NULLS LAST;
    
        CURSOR vs_read_attrib_hist(i_id IN vital_sign_read_hist.id_vital_sign_read_hist%TYPE) IS
            SELECT l_vsa_label, l_vsa_value
              FROM (SELECT pk_translation.get_translation(i_lang, vsap.code_vs_attribute) l_vsa_label,
                           to_char(decode(to_char(vsrha.free_text),
                                          '',
                                          pk_translation.get_translation(i_lang, vsa.code_vs_attribute),
                                          vsrha.free_text)) l_vsa_value,
                           (SELECT pk_vital_sign_core.get_vsa_rank(i_lang,
                                                                   i_prof,
                                                                   vsr.id_vital_sign,
                                                                   vsap.id_vs_attribute,
                                                                   l_id_market)
                              FROM dual) rank
                      FROM vital_sign_read_hist vsrh
                      JOIN vs_read_hist_attribute vsrha
                        ON vsrha.id_vital_sign_read_hist = vsrh.id_vital_sign_read_hist
                      JOIN vs_attribute vsa
                        ON vsa.id_vs_attribute = vsrha.id_vs_attribute
                      JOIN vs_attribute vsap
                        ON vsap.id_vs_attribute = vsa.id_parent
                      JOIN vital_sign_read vsr
                        ON vsr.id_vital_sign_read = vsrh.id_vital_sign_read
                     WHERE vsrh.id_vital_sign_read_hist = i_id) aux
             ORDER BY aux.rank ASC NULLS LAST;
        ------------------------------------------------------
        FUNCTION get_values
        (
            i_actual_row   IN t_vs_detail,
            i_previous_row IN t_vs_detail,
            o_tbl_labels   OUT table_varchar,
            o_tbl_values   OUT table_varchar,
            o_tbl_types    OUT table_varchar
        ) RETURN BOOLEAN IS
            l_vsa_label_act  table_varchar;
            l_vsa_value_act  table_varchar;
            l_vsa_label_prev table_varchar;
            l_vsa_value_prev table_varchar;
            l_found          NUMBER(6);
            l_prev_gs_value  VARCHAR2(1000 CHAR);
            l_prev_vs_desc   VARCHAR2(1000 CHAR);
            l_act_gs_value   VARCHAR2(1000 CHAR);
            l_act_vs_desc    VARCHAR2(1000 CHAR);
            idx              NUMBER(12);
        BEGIN
            o_tbl_labels := table_varchar();
            o_tbl_values := table_varchar();
            o_tbl_types  := table_varchar();
            IF i_actual_row.flg_state <> pk_vital_sign.c_flg_status_cancelled
            THEN
                --title
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => l_editing_result,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => NULL,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_title_t);
            
                --value
                IF nvl(i_actual_row.value, '-1') <> nvl(i_previous_row.value, '-1')
                THEN
                    --new value
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_new_value,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => get_full_value(i_lang        => i_lang,
                                                                            i_prof        => i_prof,
                                                                            i_vsr         => i_actual_row.id_vital_sign_read,
                                                                            i_vital_sign  => i_actual_row.id_vital_sign,
                                                                            i_value       => nvl(i_actual_row.value,
                                                                                                 pk_vital_sign.get_vsd_desc(i_lang,
                                                                                                                            i_actual_row.id_vital_sign_desc,
                                                                                                                            NULL)),
                                                                            i_dt_read     => i_actual_row.dt_vital_sign_read_tstz,
                                                                            i_dt_registry => i_actual_row.dt_registry) || ' ' ||
                                                             pk_vital_sign_core.get_um_desc(i_lang, i_actual_row.id_unit_measure, NULL) ||
                                                             pk_vital_sign_core.get_vs_value_converted(i_lang,
                                                                                                       i_prof,
                                                                                                       CASE
                                                                                                           WHEN i_actual_row.is_hist = pk_alert_constant.g_yes THEN
                                                                                                            i_actual_row.id_vital_sign_read_hist
                                                                                                           ELSE
                                                                                                            i_actual_row.id_vital_sign_read
                                                                                                       END,
                                                                                                       pk_alert_constant.g_yes,
                                                                                                       i_actual_row.is_hist) || CASE
                                                                 WHEN i_actual_row.is_triage = pk_alert_constant.g_yes THEN
                                                                  ' ' || l_triage
                                                                 ELSE
                                                                  NULL
                                                             END,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_new_content_n);
                    --previous value           
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_value,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => get_full_value(i_lang        => i_lang,
                                                                            i_prof        => i_prof,
                                                                            i_vsr         => i_previous_row.id_vital_sign_read,
                                                                            i_vital_sign  => i_previous_row.id_vital_sign,
                                                                            i_value       => nvl(i_previous_row.value,
                                                                                                 pk_vital_sign.get_vsd_desc(i_lang,
                                                                                                                            i_previous_row.id_vital_sign_desc,
                                                                                                                            NULL)),
                                                                            i_dt_read     => i_previous_row.dt_vital_sign_read_tstz,
                                                                            i_dt_registry => i_previous_row.dt_registry) || ' ' ||
                                                             pk_vital_sign_core.get_um_desc(i_lang, i_previous_row.id_unit_measure, NULL) ||
                                                             pk_vital_sign_core.get_vs_value_converted(i_lang,
                                                                                                       i_prof,
                                                                                                       CASE
                                                                                                           WHEN i_previous_row.is_hist = pk_alert_constant.g_yes THEN
                                                                                                            i_previous_row.id_vital_sign_read_hist
                                                                                                           ELSE
                                                                                                            i_previous_row.id_vital_sign_read
                                                                                                       END,
                                                                                                       pk_alert_constant.g_yes,
                                                                                                       i_previous_row.is_hist) || CASE
                                                                 WHEN i_previous_row.is_triage = pk_alert_constant.g_yes THEN
                                                                  ' ' || l_triage
                                                                 ELSE
                                                                  NULL
                                                             END,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_content_c);
                END IF;
            
                -- PARCIAIS DE GLASGOW
                IF i_actual_row.value IS NOT NULL
                   AND i_actual_row.is_glasgow = pk_alert_constant.g_yes
                THEN
                    idx             := 0;
                    l_prev_gs_value := NULL;
                    l_prev_vs_desc  := NULL;
                    l_act_gs_value  := NULL;
                    l_act_vs_desc   := NULL;
                    FOR rec IN (SELECT a.gs_value, a.gs_vital_sign
                                  FROM (SELECT nvl2(vsr2.id_vital_sign_desc,
                                                    pk_vital_sign.get_vsd_desc(i_lang,
                                                                               vsr2.id_vital_sign_desc,
                                                                               vsr2.id_patient),
                                                    pk_utils.to_str(vsr2.value, l_decimal_symbol)) gs_value,
                                               vsr2.id_vital_sign gs_vital_sign,
                                               vr2.rank,
                                               'A' state
                                          FROM vital_sign_read vsr
                                          JOIN vital_sign_relation vr
                                            ON vr.relation_domain = pk_alert_constant.g_vs_rel_sum
                                           AND vr.id_vital_sign_detail = vsr.id_vital_sign
                                           AND vr.relation_domain != pk_alert_constant.g_vs_rel_percentile
                                          JOIN vital_sign_relation vr2
                                            ON vr2.id_vital_sign_parent = vr.id_vital_sign_parent
                                           AND vr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
                                          JOIN vital_sign_read vsr2
                                            ON vsr2.dt_vital_sign_read_tstz = vsr.dt_vital_sign_read_tstz
                                           AND vsr2.id_vital_sign = vr2.id_vital_sign_detail
                                         WHERE vsr.id_vital_sign_read = i_actual_row.id_vital_sign_read
                                           AND i_actual_row.is_hist = pk_alert_constant.g_no
                                           AND vr.relation_domain != pk_alert_constant.g_vs_rel_percentile
                                        UNION ALL
                                        SELECT nvl2(vsrh2.id_vital_sign_desc,
                                                    pk_vital_sign.get_vsd_desc(i_lang,
                                                                               vsrh2.id_vital_sign_desc,
                                                                               vsr2.id_patient),
                                                    pk_utils.to_str(vsrh2.value, l_decimal_symbol)) gs_value,
                                               vsr2.id_vital_sign gs_vital_sign,
                                               vr2.rank,
                                               'A' state
                                          FROM vital_sign_read_hist vsrh
                                          JOIN vital_sign_read vsr
                                            ON vsrh.id_vital_sign_read = vsr.id_vital_sign_read
                                          JOIN vital_sign_relation vr
                                            ON vr.relation_domain = pk_alert_constant.g_vs_rel_sum
                                           AND vr.id_vital_sign_detail = vsr.id_vital_sign
                                          JOIN vital_sign_relation vr2
                                            ON vr2.id_vital_sign_parent = vr.id_vital_sign_parent
                                           AND vr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
                                          JOIN vital_sign_read vsr2
                                            ON vsr2.dt_vital_sign_read_tstz = vsrh.dt_vital_sign_read_tstz
                                           AND vsr2.id_vital_sign = vr2.id_vital_sign_detail
                                          JOIN vital_sign_read_hist vsrh2
                                            ON vsrh2.id_vital_sign_read = vsr2.id_vital_sign_read
                                           AND vsrh2.dt_registry = vsrh.dt_registry
                                         WHERE vsrh.id_vital_sign_read_hist = i_actual_row.id_vital_sign_read_hist
                                           AND i_actual_row.is_hist = pk_alert_constant.g_yes
                                        UNION ALL
                                        SELECT nvl2(vsrh2.id_vital_sign_desc,
                                                    pk_vital_sign.get_vsd_desc(i_lang,
                                                                               vsrh2.id_vital_sign_desc,
                                                                               vsr2.id_patient),
                                                    pk_utils.to_str(vsrh2.value, l_decimal_symbol)) gs_value,
                                               vsr2.id_vital_sign gs_vital_sign,
                                               vr2.rank,
                                               'P' state
                                          FROM vital_sign_read_hist vsrh
                                          JOIN vital_sign_read vsr
                                            ON vsrh.id_vital_sign_read = vsr.id_vital_sign_read
                                          JOIN vital_sign_relation vr
                                            ON vr.relation_domain = pk_alert_constant.g_vs_rel_sum
                                           AND vr.id_vital_sign_detail = vsr.id_vital_sign
                                          JOIN vital_sign_relation vr2
                                            ON vr2.id_vital_sign_parent = vr.id_vital_sign_parent
                                           AND vr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
                                          JOIN vital_sign_read vsr2
                                            ON vsr2.dt_vital_sign_read_tstz = vsrh.dt_vital_sign_read_tstz
                                           AND vsr2.id_vital_sign = vr2.id_vital_sign_detail
                                          JOIN vital_sign_read_hist vsrh2
                                            ON vsrh2.id_vital_sign_read = vsr2.id_vital_sign_read
                                           AND vsrh2.dt_registry = vsrh.dt_registry
                                         WHERE vsrh.id_vital_sign_read_hist = i_previous_row.id_vital_sign_read_hist
                                           AND i_previous_row.is_hist = pk_alert_constant.g_yes) a
                                 ORDER BY a.rank, a.gs_vital_sign, a.state)
                    LOOP
                        BEGIN
                            SELECT pk_translation.get_translation(i_lang, vs.code_vital_sign)
                              INTO l_vital_sign_desc
                              FROM vital_sign vs
                             WHERE vs.id_vital_sign = rec.gs_vital_sign;
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_vital_sign_desc := NULL;
                        END;
                    
                        l_prev_gs_value := l_act_gs_value;
                        l_prev_vs_desc  := l_act_vs_desc;
                        l_act_gs_value  := rec.gs_value;
                        l_act_vs_desc   := l_vital_sign_desc;
                    
                        IF idx > 0
                        THEN
                        
                            IF l_act_gs_value <> l_prev_gs_value
                               AND l_act_vs_desc = l_prev_vs_desc
                            THEN
                                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                           i_value_1  => l_prev_vs_desc || ' ' || l_new_record,
                                                           io_table_2 => o_tbl_values,
                                                           i_value_2  => l_prev_gs_value,
                                                           io_table_3 => o_tbl_types,
                                                           i_value_3  => pk_vital_sign.g_new_content_n);
                            
                                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                           i_value_1  => l_act_vs_desc,
                                                           io_table_2 => o_tbl_values,
                                                           i_value_2  => l_act_gs_value,
                                                           io_table_3 => o_tbl_types,
                                                           i_value_3  => pk_vital_sign.g_content_c);
                            
                            END IF;
                        
                        END IF;
                        idx := idx + 1;
                    
                    END LOOP;
                END IF;
            
                --date
                IF pk_date_utils.compare_dates_tsz(i_prof,
                                                   i_actual_row.dt_vital_sign_read_tstz,
                                                   i_previous_row.dt_vital_sign_read_tstz) <> 'E'
                THEN
                    --new date           
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_new_date,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => nvl(pk_date_utils.date_char_tsz(i_lang,
                                                                                             i_actual_row.dt_vital_sign_read_tstz,
                                                                                             i_prof.institution,
                                                                                             i_prof.software),
                                                                 pk_vital_sign.g_detail_empty),
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_new_content_n);
                
                    --previous date
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_date,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => nvl(pk_date_utils.date_char_tsz(i_lang,
                                                                                             i_previous_row.dt_vital_sign_read_tstz,
                                                                                             i_prof.institution,
                                                                                             i_prof.software),
                                                                 pk_vital_sign.g_detail_empty),
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_content_c);
                
                END IF;
            
                l_vsa_label_act  := table_varchar();
                l_vsa_value_act  := table_varchar();
                l_vsa_label_prev := table_varchar();
                l_vsa_value_prev := table_varchar();
                --get attributes
                IF i_actual_row.is_hist = pk_alert_constant.g_no
                THEN
                    OPEN vs_read_attrib(i_actual_row.id_vital_sign_read);
                    FETCH vs_read_attrib BULK COLLECT
                        INTO l_vsa_label_act, l_vsa_value_act;
                    CLOSE vs_read_attrib;
                ELSE
                    OPEN vs_read_attrib_hist(i_actual_row.id_vital_sign_read_hist);
                    FETCH vs_read_attrib_hist BULK COLLECT
                        INTO l_vsa_label_act, l_vsa_value_act;
                    CLOSE vs_read_attrib_hist;
                END IF;
            
                IF i_previous_row.is_hist = pk_alert_constant.g_no
                THEN
                    OPEN vs_read_attrib(i_previous_row.id_vital_sign_read);
                    FETCH vs_read_attrib BULK COLLECT
                        INTO l_vsa_label_prev, l_vsa_value_prev;
                    CLOSE vs_read_attrib;
                ELSE
                    OPEN vs_read_attrib_hist(i_previous_row.id_vital_sign_read_hist);
                    FETCH vs_read_attrib_hist BULK COLLECT
                        INTO l_vsa_label_prev, l_vsa_value_prev;
                    CLOSE vs_read_attrib_hist;
                END IF;
            
                --compare attributes            
                FOR k IN 1 .. l_vsa_label_act.count
                LOOP
                    l_found := 0;
                    FOR j IN 1 .. l_vsa_label_prev.count
                    LOOP
                    
                        IF l_vsa_label_act(k) = l_vsa_label_prev(j)
                        THEN
                            IF nvl(l_vsa_value_act(k), '-1') <> nvl(l_vsa_value_prev(j), '-1')
                            THEN
                                --new attribute
                                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                           i_value_1  => l_vsa_label_act(k) || ' ' || l_new_record,
                                                           io_table_2 => o_tbl_values,
                                                           i_value_2  => nvl(l_vsa_value_act(k),
                                                                             pk_vital_sign.g_detail_empty),
                                                           io_table_3 => o_tbl_types,
                                                           i_value_3  => pk_vital_sign.g_new_content_n);
                            
                                --previous date
                                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                           i_value_1  => l_vsa_label_prev(j),
                                                           io_table_2 => o_tbl_values,
                                                           i_value_2  => nvl(l_vsa_value_prev(j),
                                                                             pk_vital_sign.g_detail_empty),
                                                           io_table_3 => o_tbl_types,
                                                           i_value_3  => pk_vital_sign.g_content_c);
                            
                            END IF;
                            l_found := 1;
                            EXIT;
                        
                        END IF;
                    
                    END LOOP;
                
                    IF l_found = 0
                    THEN
                        --new attribute
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_vsa_label_act(k) || ' ' || l_new_record,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => nvl(l_vsa_value_act(k), pk_vital_sign.g_detail_empty),
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_new_content_n);
                    
                        --previous date
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_vsa_label_act(k),
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => pk_vital_sign.g_detail_empty,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_content_c);
                    END IF;
                
                END LOOP;
            
                -- search for deleted attributes
                FOR j IN 1 .. l_vsa_label_prev.count
                LOOP
                    l_found := 0;
                    FOR k IN 1 .. l_vsa_label_act.count
                    LOOP
                        IF l_vsa_label_act(k) = l_vsa_label_prev(j)
                        THEN
                            l_found := 1;
                            EXIT;
                        END IF;
                    END LOOP;
                
                    IF l_found = 0
                    THEN
                        --new attribute
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_vsa_label_prev(j) || ' ' || l_new_record,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => pk_vital_sign.g_detail_empty,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_new_content_n);
                    
                        --previous date
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_vsa_label_prev(j),
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => nvl(l_vsa_value_prev(j), pk_vital_sign.g_detail_empty),
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_content_c);
                    END IF;
                
                END LOOP;
            
                --edit reason
                IF nvl(i_actual_row.edit_reason, '-1') <> nvl(i_previous_row.edit_reason, '-1')
                THEN
                    IF i_actual_row.edit_reason IS NOT NULL
                    THEN
                        -- new
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_edit_reason || ' ' || l_new_record,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => i_actual_row.edit_reason,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_new_content_n);
                        --previous date
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_edit_reason || ' ' || l_new_record,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => i_previous_row.edit_reason,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_content_c);
                    END IF;
                END IF;
            
                --signature
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => NULL,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => l_reviewed_by ||
                                                         pk_prof_utils.get_name_signature(i_lang, i_prof, i_actual_row.id_prof_read) || CASE
                                                             WHEN pk_prof_utils.get_spec_signature(i_lang,
                                                                                                   i_prof,
                                                                                                   i_actual_row.id_prof_read,
                                                                                                   NULL,
                                                                                                   NULL) IS NOT NULL THEN
                                                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                       i_prof,
                                                                                                       i_actual_row.id_prof_read,
                                                                                                       NULL,
                                                                                                       NULL) || ')'
                                                             ELSE
                                                              NULL
                                                         END || '; ' || pk_date_utils.date_char_tsz(i_lang,
                                                                                                    i_actual_row.dt_registry,
                                                                                                    i_prof.institution,
                                                                                                    i_prof.software),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_signature_s);
            
            ELSE
            
                -- if record is cancelled, inserts cancellation info in the detail screen
                IF i_actual_row.flg_state = pk_vital_sign.c_flg_status_cancelled
                THEN
                
                    SELECT pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_id_cancel_reason => vsr.id_cancel_reason),
                           vsr.id_prof_cancel,
                           vsr.notes_cancel,
                           vsr.dt_cancel_tstz
                      INTO l_cancel_reason_desc, l_prof_cancel, l_notes_cancel, l_dt_cancel
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign_read = i_actual_row.id_vital_sign_read;
                
                    --title
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => chr(10) || l_status,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => l_cancelled,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_content_c);
                
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_cancel_reason,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => l_cancel_reason_desc,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_content_c);
                
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_cancel_notes,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => l_notes_cancel,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_content_c);
                
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => NULL,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => l_reviewed_by ||
                                                             pk_prof_utils.get_name_signature(i_lang, i_prof, l_prof_cancel) || CASE
                                                                 WHEN pk_prof_utils.get_spec_signature(i_lang,
                                                                                                       i_prof,
                                                                                                       l_prof_cancel,
                                                                                                       NULL,
                                                                                                       NULL) IS NOT NULL THEN
                                                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                           i_prof,
                                                                                                           i_actual_row.id_prof_read,
                                                                                                           NULL,
                                                                                                           NULL) || ')'
                                                                 ELSE
                                                                  NULL
                                                             END || '; ' || pk_date_utils.date_char_tsz(i_lang,
                                                                                                        l_dt_cancel,
                                                                                                        i_prof.institution,
                                                                                                        i_prof.software),
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_signature_s);
                END IF;
            END IF;
            RETURN TRUE;
        END get_values;
    
        FUNCTION get_first_values
        (
            i_actual_row IN t_vs_detail,
            o_tbl_labels OUT table_varchar,
            o_tbl_values OUT table_varchar,
            o_tbl_types  OUT table_varchar
        ) RETURN BOOLEAN IS
            l_notes_desc vital_sign_notes.notes%TYPE;
            l_vsa_label  table_varchar;
            l_vsa_value  table_varchar;
        BEGIN
            o_tbl_labels := table_varchar();
            o_tbl_values := table_varchar();
            o_tbl_types  := table_varchar();
        
            -- if record is cancelled, inserts cancellation info in the detail screen
            IF i_actual_row.flg_state = pk_vital_sign.c_flg_status_cancelled
            THEN
            
                SELECT pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_id_cancel_reason => vsr.id_cancel_reason),
                       vsr.id_prof_cancel,
                       vsr.notes_cancel,
                       vsr.dt_cancel_tstz
                  INTO l_cancel_reason_desc, l_prof_cancel, l_notes_cancel, l_dt_cancel
                  FROM vital_sign_read vsr
                 WHERE vsr.id_vital_sign_read = i_actual_row.id_vital_sign_read;
            
                --title
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => chr(10) || l_status,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => l_cancelled,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_content_c);
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => l_cancel_reason,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => l_cancel_reason_desc,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_content_c);
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => l_cancel_notes,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => l_notes_cancel,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_content_c);
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => NULL,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => l_reviewed_by ||
                                                         pk_prof_utils.get_name_signature(i_lang, i_prof, l_prof_cancel) || CASE
                                                             WHEN pk_prof_utils.get_spec_signature(i_lang,
                                                                                                   i_prof,
                                                                                                   l_prof_cancel,
                                                                                                   NULL,
                                                                                                   NULL) IS NOT NULL THEN
                                                              ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                       i_prof,
                                                                                                       i_actual_row.id_prof_read,
                                                                                                       NULL,
                                                                                                       NULL) || ')'
                                                             ELSE
                                                              NULL
                                                         END || '; ' || pk_date_utils.date_char_tsz(i_lang,
                                                                                                    l_dt_cancel,
                                                                                                    i_prof.institution,
                                                                                                    i_prof.software),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_signature_s);
            END IF;
        
            --title
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => l_result,
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => NULL,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_vital_sign.g_title_t);
        
            --i_row.value               
            IF i_actual_row.value IS NOT NULL
            THEN
            
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => l_value,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => get_full_value(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_vsr         => i_actual_row.id_vital_sign_read,
                                                                        i_vital_sign  => i_actual_row.id_vital_sign,
                                                                        i_value       => nvl(i_actual_row.value,
                                                                                             pk_vital_sign.get_vsd_desc(i_lang,
                                                                                                                        i_actual_row.id_vital_sign_desc,
                                                                                                                        NULL)),
                                                                        i_dt_read     => i_actual_row.dt_vital_sign_read_tstz,
                                                                        i_dt_registry => i_actual_row.dt_registry) || ' ' ||
                                                         pk_vital_sign_core.get_um_desc(i_lang, i_actual_row.id_unit_measure, NULL) ||
                                                         pk_vital_sign_core.get_vs_value_converted(i_lang,
                                                                                                   i_prof,
                                                                                                   CASE
                                                                                                       WHEN i_actual_row.is_hist = pk_alert_constant.g_yes THEN
                                                                                                        i_actual_row.id_vital_sign_read_hist
                                                                                                       ELSE
                                                                                                        i_actual_row.id_vital_sign_read
                                                                                                   END,
                                                                                                   pk_alert_constant.g_yes,
                                                                                                   i_actual_row.is_hist) || CASE
                                                             WHEN i_actual_row.is_triage = pk_alert_constant.g_yes THEN
                                                              ' ' || l_triage
                                                             ELSE
                                                              NULL
                                                         END,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_content_c);
            END IF;
        
            -- PARCIAIS DE GLASGOW
            IF i_actual_row.value IS NOT NULL
               AND i_actual_row.is_glasgow = pk_alert_constant.g_yes
               AND i_actual_row.is_hist = pk_alert_constant.g_no
            THEN
                FOR rec IN (SELECT nvl2(vsr2.id_vital_sign_desc,
                                        pk_vital_sign.get_vsd_desc(i_lang, vsr2.id_vital_sign_desc, vsr2.id_patient),
                                        pk_utils.to_str(vsr2.value, l_decimal_symbol)) gs_value,
                                   vsr2.id_vital_sign gs_vital_sign
                              FROM vital_sign_read vsr
                              JOIN vital_sign_relation vr
                                ON vr.relation_domain = pk_alert_constant.g_vs_rel_sum
                               AND vr.id_vital_sign_detail = vsr.id_vital_sign
                              JOIN vital_sign_relation vr2
                                ON vr2.id_vital_sign_parent = vr.id_vital_sign_parent
                               AND vr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
                              JOIN vital_sign_read vsr2
                                ON vsr2.dt_vital_sign_read_tstz = vsr.dt_vital_sign_read_tstz
                               AND vsr2.id_vital_sign = vr2.id_vital_sign_detail
                             WHERE vsr.id_vital_sign_read = i_id_vital_sign_read
                             ORDER BY vr2.rank, vsr2.id_vital_sign)
                LOOP
                    BEGIN
                        SELECT pk_translation.get_translation(i_lang, vs.code_vital_sign)
                          INTO l_vital_sign_desc
                          FROM vital_sign vs
                         WHERE vs.id_vital_sign = rec.gs_vital_sign;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_vital_sign_desc := NULL;
                    END;
                
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_vital_sign_desc,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => rec.gs_value,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_content_c);
                END LOOP;
            END IF;
        
            IF i_actual_row.value IS NOT NULL
               AND i_actual_row.is_glasgow = pk_alert_constant.g_yes
               AND i_actual_row.is_hist = pk_alert_constant.g_yes
            THEN
                FOR rec IN (SELECT nvl2(vsrh2.id_vital_sign_desc,
                                        pk_vital_sign.get_vsd_desc(i_lang, vsrh2.id_vital_sign_desc, vsr2.id_patient),
                                        pk_utils.to_str(vsrh2.value, l_decimal_symbol)) gs_value,
                                   vsr2.id_vital_sign gs_vital_sign
                              FROM vital_sign_read_hist vsrh
                              JOIN vital_sign_read vsr
                                ON vsrh.id_vital_sign_read = vsr.id_vital_sign_read
                              JOIN vital_sign_relation vr
                                ON vr.relation_domain = pk_alert_constant.g_vs_rel_sum
                               AND vr.id_vital_sign_detail = vsr.id_vital_sign
                              JOIN vital_sign_relation vr2
                                ON vr2.id_vital_sign_parent = vr.id_vital_sign_parent
                               AND vr2.relation_domain != pk_alert_constant.g_vs_rel_percentile
                              JOIN vital_sign_read vsr2
                                ON vsr2.dt_vital_sign_read_tstz = vsrh.dt_vital_sign_read_tstz
                               AND vsr2.id_vital_sign = vr2.id_vital_sign_detail
                              JOIN vital_sign_read_hist vsrh2
                                ON vsrh2.id_vital_sign_read = vsr2.id_vital_sign_read
                               AND vsrh2.dt_registry = vsrh.dt_registry
                             WHERE vsrh.id_vital_sign_read_hist = i_actual_row.id_vital_sign_read_hist
                             ORDER BY vr2.rank, vsr2.id_vital_sign)
                LOOP
                    BEGIN
                        SELECT pk_translation.get_translation(i_lang, vs.code_vital_sign)
                          INTO l_vital_sign_desc
                          FROM vital_sign vs
                         WHERE vs.id_vital_sign = rec.gs_vital_sign;
                    EXCEPTION
                        WHEN OTHERS THEN
                            l_vital_sign_desc := NULL;
                    END;
                
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_vital_sign_desc,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => rec.gs_value,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_content_c);
                END LOOP;
            END IF;
        
            --i_row.date               
            IF i_actual_row.dt_vital_sign_read_tstz IS NOT NULL
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => l_date,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                     i_actual_row.dt_vital_sign_read_tstz,
                                                                                     i_prof.institution,
                                                                                     i_prof.software),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_content_c);
            END IF;
            -- attributes
        
            IF i_actual_row.is_hist = pk_alert_constant.g_no
            THEN
                OPEN vs_read_attrib(i_actual_row.id_vital_sign_read);
                FETCH vs_read_attrib BULK COLLECT
                    INTO l_vsa_label, l_vsa_value;
                CLOSE vs_read_attrib;
            ELSE
                OPEN vs_read_attrib_hist(i_actual_row.id_vital_sign_read_hist);
                FETCH vs_read_attrib_hist BULK COLLECT
                    INTO l_vsa_label, l_vsa_value;
                CLOSE vs_read_attrib_hist;
            END IF;
        
            FOR k IN 1 .. l_vsa_label.count
            LOOP
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => l_vsa_label(k),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => l_vsa_value(k),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_content_c);
            END LOOP;
        
            --
            IF i_flg_screen = g_detail_screen_d
            THEN
            
                SELECT vsr.id_vital_sign, vsr.id_patient
                  INTO l_vital_sign, l_patient
                  FROM vital_sign_read vsr
                 WHERE vsr.id_vital_sign_read = i_actual_row.id_vital_sign_read;
            
                -- if record is a BMI record, displays associated values
                IF l_vital_sign = 1188 --BMI TO DO: replace by constant
                THEN
                    BEGIN
                        -- associated weight value
                        SELECT vsr.value, vsr.id_unit_measure, vsr.dt_vital_sign_read_tstz
                          INTO l_partial_value, l_partial_unit, l_partial_date
                          FROM vital_sign_read vsr
                         WHERE vsr.id_patient = l_patient
                           AND vsr.id_vital_sign = 29 --WEIGHT TO DO: replace by constant
                           AND vsr.dt_registry = i_actual_row.dt_registry;
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => NULL,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => NULL,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_signature_s);
                    
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_weight,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => get_full_value(i_lang        => i_lang,
                                                                                i_prof        => i_prof,
                                                                                i_vsr         => i_actual_row.id_vital_sign_read,
                                                                                i_vital_sign  => i_actual_row.id_vital_sign,
                                                                                i_value       => l_partial_value,
                                                                                i_dt_read     => i_actual_row.dt_vital_sign_read_tstz,
                                                                                i_dt_registry => i_actual_row.dt_registry) || ' ' ||
                                                                 pk_vital_sign_core.get_um_desc(i_lang, l_partial_unit, NULL) ||
                                                                 pk_vital_sign_core.get_vs_value_converted(i_lang,
                                                                                                           i_prof,
                                                                                                           CASE
                                                                                                               WHEN i_actual_row.is_hist = pk_alert_constant.g_yes THEN
                                                                                                                i_actual_row.id_vital_sign_read_hist
                                                                                                               ELSE
                                                                                                                i_actual_row.id_vital_sign_read
                                                                                                           END,
                                                                                                           pk_alert_constant.g_yes,
                                                                                                           i_actual_row.is_hist) || CASE
                                                                     WHEN i_actual_row.is_triage = pk_alert_constant.g_yes THEN
                                                                      ' ' || l_triage
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_content_c);
                    
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_date,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                             l_partial_date,
                                                                                             i_prof.institution,
                                                                                             i_prof.software),
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_content_c);
                    
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => NULL,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => NULL,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_signature_s);
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                
                    BEGIN
                        -- associated height value
                        SELECT vsr.value, vsr.id_unit_measure, vsr.dt_vital_sign_read_tstz
                          INTO l_partial_value, l_partial_unit, l_partial_date
                          FROM vital_sign_read vsr
                         WHERE vsr.id_patient = l_patient
                           AND vsr.id_vital_sign = 30 --HEIGHT TO DO: replace by constant
                           AND vsr.dt_registry = i_actual_row.dt_registry;
                    
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_height,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => get_full_value(i_lang        => i_lang,
                                                                                i_prof        => i_prof,
                                                                                i_vsr         => i_actual_row.id_vital_sign_read,
                                                                                i_vital_sign  => i_actual_row.id_vital_sign,
                                                                                i_value       => l_partial_value,
                                                                                i_dt_read     => i_actual_row.dt_vital_sign_read_tstz,
                                                                                i_dt_registry => i_actual_row.dt_registry) || ' ' ||
                                                                 pk_vital_sign_core.get_um_desc(i_lang, l_partial_unit, NULL) ||
                                                                 pk_vital_sign_core.get_vs_value_converted(i_lang,
                                                                                                           i_prof,
                                                                                                           CASE
                                                                                                               WHEN i_actual_row.is_hist = pk_alert_constant.g_yes THEN
                                                                                                                i_actual_row.id_vital_sign_read_hist
                                                                                                               ELSE
                                                                                                                i_actual_row.id_vital_sign_read
                                                                                                           END,
                                                                                                           pk_alert_constant.g_yes,
                                                                                                           i_actual_row.is_hist) || CASE
                                                                     WHEN i_actual_row.is_triage = pk_alert_constant.g_yes THEN
                                                                      ' ' || l_triage
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_content_c);
                    
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_date,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                             l_partial_date,
                                                                                             i_prof.institution,
                                                                                             i_prof.software),
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_content_c);
                    
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => NULL,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => NULL,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_signature_s);
                    
                    EXCEPTION
                        WHEN OTHERS THEN
                            NULL;
                    END;
                END IF;
            
            END IF;
        
            --i_row.id_vital_sign_notes               
            IF i_actual_row.id_vital_sign_notes IS NOT NULL
            THEN
            
                BEGIN
                    SELECT vsn.notes
                      INTO l_notes_desc
                      FROM vital_sign_notes vsn
                     WHERE vsn.id_vital_sign_notes = i_actual_row.id_vital_sign_notes;
                
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => l_notes,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => l_notes_desc,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_content_c);
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            --edit reason
            IF i_actual_row.edit_reason IS NOT NULL
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => l_edit_reason,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => i_actual_row.edit_reason,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_vital_sign.g_content_c);
            END IF;
        
            --signature
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => NULL,
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_reviewed_by ||
                                                     pk_prof_utils.get_name_signature(i_lang, i_prof, i_actual_row.id_prof_read) || CASE
                                                         WHEN pk_prof_utils.get_spec_signature(i_lang,
                                                                                               i_prof,
                                                                                               i_actual_row.id_prof_read,
                                                                                               NULL,
                                                                                               NULL) IS NOT NULL THEN
                                                          ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                   i_prof,
                                                                                                   i_actual_row.id_prof_read,
                                                                                                   NULL,
                                                                                                   NULL) || ')'
                                                         ELSE
                                                          NULL
                                                     END || '; ' || pk_date_utils.date_char_tsz(i_lang,
                                                                                                i_actual_row.dt_registry,
                                                                                                i_prof.institution,
                                                                                                i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_vital_sign.g_signature_s);
        
            RETURN TRUE;
        END get_first_values;
    
        FUNCTION get_info_labels RETURN table_varchar IS
            l_table table_varchar := table_varchar();
        BEGIN
            --RECORD_STATE            
            pk_inp_detail.add_value(io_table => l_table, i_value => 'RECORD_STATE_TO_FORMAT');
            --RECORD ACTION
            pk_inp_detail.add_value(io_table => l_table, i_value => 'RECORD_ACTION');
        
            RETURN l_table;
        END get_info_labels;
    
        FUNCTION get_info_values(i_row IN t_vs_detail) RETURN table_varchar IS
            l_table table_varchar := table_varchar();
        BEGIN
            --RECORD_STATE                        
            pk_inp_detail.add_value(io_table => l_table,
                                    i_value  => CASE
                                                    WHEN i_row.flg_state = pk_vital_sign.c_flg_status_cancelled THEN
                                                     pk_vital_sign.c_flg_status_cancelled
                                                    ELSE
                                                     pk_vital_sign.c_flg_status_active
                                                END);
            --RECORD ACTION
            pk_inp_detail.add_value(io_table => l_table, i_value => pk_vital_sign.c_flg_status_active);
        
            RETURN l_table;
        END get_info_values;
    
        FUNCTION get_revisions
        (
            i_actual_row IN t_vs_detail,
            o_tbl_labels OUT table_varchar,
            o_tbl_values OUT table_varchar,
            o_tbl_types  OUT table_varchar
        ) RETURN BOOLEAN IS
            l_show_header BOOLEAN := TRUE;
        BEGIN
            o_tbl_labels := table_varchar();
            o_tbl_values := table_varchar();
            o_tbl_types  := table_varchar();
            IF i_flg_screen = pk_vital_sign.g_hist_screen_h
            THEN
                --loads review data
                --title
            
                FOR vc IN c_reviews(i_vsr => i_actual_row.id_vital_sign_read)
                LOOP
                    IF l_show_header
                    THEN
                        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                                   i_value_1  => l_review,
                                                   io_table_2 => o_tbl_values,
                                                   i_value_2  => NULL,
                                                   io_table_3 => o_tbl_types,
                                                   i_value_3  => pk_vital_sign.g_title_t);
                        l_show_header := FALSE;
                    END IF;
                    --signature
                    pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                               i_value_1  => NULL,
                                               io_table_2 => o_tbl_values,
                                               i_value_2  => l_reviewed_by || vc.desc_prof || CASE
                                                                 WHEN pk_prof_utils.get_spec_signature(i_lang,
                                                                                                       i_prof,
                                                                                                       vc.id_professional,
                                                                                                       NULL,
                                                                                                       NULL) IS NOT NULL THEN
                                                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                           i_prof,
                                                                                                           vc.id_professional,
                                                                                                           NULL,
                                                                                                           NULL) || ')'
                                                                 ELSE
                                                                  NULL
                                                             END || '; ' || vc.review_date,
                                               io_table_3 => o_tbl_types,
                                               i_value_3  => pk_vital_sign.g_signature_s);
                END LOOP;
            
            END IF;
            RETURN TRUE;
        END get_revisions;
        ------------------------------------------------------
    
    BEGIN
        l_value          := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M013');
        l_new_value      := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M003');
        l_date           := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M014');
        l_new_date       := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M004');
        l_result         := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M001');
        l_editing_result := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M002');
        l_status         := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGNS_READ_T003');
        l_cancelled      := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M009');
        l_cancel_reason  := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M010');
        l_cancel_notes   := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M011');
        l_review         := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M015');
        l_reviewed_by    := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M017');
        l_weight         := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M018');
        l_height         := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_DETAIL_M019');
        l_notes          := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGNS_READ_T008');
        l_edit_reason    := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_M014');
        l_new_record     := pk_message.get_message(i_lang, i_prof, 'COMMON_T031');
        l_triage         := pk_message.get_message(i_lang, i_prof, 'VITAL_SIGN_M017');
    
        l_dbg_msg := 'GET HIST VITAL_SIGN_READ_HIST_LINE: ' || i_id_vital_sign_read;
        alertlog.pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
    
        SELECT t1.*
          BULK COLLECT
          INTO l_tab_vs_hist
          FROM (SELECT *
                  FROM (SELECT vsrh.id_vital_sign_read_hist,
                               vsrh.id_vital_sign_read,
                               vsr.id_vital_sign,
                               get_full_value(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_vsr         => vsrh.id_vital_sign_read,
                                              i_vital_sign  => vsr.id_vital_sign,
                                              i_value       => nvl(pk_utils.number_to_char(i_prof, vsrh.value),
                                                                   get_vsd_desc(i_lang,
                                                                                vsrh.id_vital_sign_desc,
                                                                                vsr.id_patient)),
                                              i_dt_read     => vsrh.dt_vital_sign_read_tstz,
                                              i_dt_registry => vsrh.dt_registry) get_full_value,
                               vsrh.flg_status,
                               decode(vsr.id_vs_scales_element,
                                      NULL,
                                      vsrh.id_unit_measure,
                                      (SELECT vsse.id_unit_measure
                                         FROM vital_sign_scales_element vsse
                                        WHERE vsse.id_vital_sign_scales =
                                              pk_vital_sign.get_vs_scale(vsr.id_vs_scales_element)
                                          AND rownum = 1)) id_unit_measure,
                               vsrh.id_prof_read,
                               vsrh.dt_vital_sign_read_tstz,
                               vsrh.dt_registry,
                               vsrh.id_vital_sign_desc,
                               vsr.id_vital_sign_notes,
                               CASE
                                    WHEN vrel.id_vital_sign_relation IS NULL THEN
                                     pk_alert_constant.g_no
                                    ELSE
                                     pk_alert_constant.g_yes
                                END is_glasgow,
                               pk_alert_constant.g_yes is_hist,
                               nvl(vsrh.notes_edit,
                                   to_clob(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, vsrh.id_edit_reason))) edit_reason,
                               pk_alert_constant.g_no is_triage
                          FROM vital_sign_read_hist vsrh
                          JOIN vital_sign_read vsr
                            ON vsr.id_vital_sign_read = vsrh.id_vital_sign_read
                          LEFT JOIN vital_sign_relation vrel
                            ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                           AND vrel.relation_domain = pk_alert_constant.g_vs_rel_sum
                           AND vrel.flg_available = pk_alert_constant.g_yes
                         WHERE vsrh.id_vital_sign_read = i_id_vital_sign_read
                           AND (i_flg_screen = pk_vital_sign.g_hist_screen_h)
                        UNION ALL
                        SELECT 999999999999999999999 id_vital_sign_read_hist,
                               vsr.id_vital_sign_read,
                               vsr.id_vital_sign,
                               get_full_value(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_vsr         => vsr.id_vital_sign_read,
                                              i_vital_sign  => vsr.id_vital_sign,
                                              i_value       => nvl(pk_utils.number_to_char(i_prof, vsr.value),
                                                                   get_vsd_desc(i_lang,
                                                                                vsr.id_vital_sign_desc,
                                                                                vsr.id_patient)),
                                              i_dt_read     => vsr.dt_vital_sign_read_tstz,
                                              i_dt_registry => vsr.dt_registry) get_full_value,
                               vsr.flg_state,
                               decode(vsr.id_vs_scales_element,
                                      NULL,
                                      vsr.id_unit_measure,
                                      (SELECT vsse.id_unit_measure
                                         FROM vital_sign_scales_element vsse
                                        WHERE vsse.id_vital_sign_scales =
                                              pk_vital_sign.get_vs_scale(vsr.id_vs_scales_element)
                                          AND rownum = 1)) id_unit_measure,
                               vsr.id_prof_read,
                               vsr.dt_vital_sign_read_tstz,
                               vsr.dt_registry,
                               vsr.id_vital_sign_desc,
                               vsr.id_vital_sign_notes,
                               CASE
                                   WHEN vrel.id_vital_sign_relation IS NULL THEN
                                    pk_alert_constant.g_no
                                   ELSE
                                    pk_alert_constant.g_yes
                               END is_glasgow,
                               pk_alert_constant.g_no is_hist,
                               nvl(pk_translation.get_translation_trs(vsr.code_notes_edit),
                                   to_clob(pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, vsr.id_edit_reason))) edit_reason,
                               CASE
                                   WHEN vsr.id_epis_triage IS NULL THEN
                                    pk_alert_constant.g_no
                                   ELSE
                                    pk_alert_constant.g_yes
                               END is_triage
                          FROM vital_sign_read vsr
                          LEFT JOIN vital_sign_relation vrel
                            ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                           AND vrel.relation_domain = pk_alert_constant.g_vs_rel_sum
                           AND vrel.flg_available = pk_alert_constant.g_yes
                         WHERE vsr.id_vital_sign_read = i_id_vital_sign_read) t
                 ORDER BY t.id_vital_sign_read_hist DESC) t1;
    
        l_dbg_msg := 'tab_epis_hidrics_hist ' || l_tab_vs_hist.count;
        alertlog.pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF l_tab_vs_hist.count != 0
        THEN
            FOR i IN l_tab_vs_hist.first .. l_tab_vs_hist.last
            LOOP
                IF (i = l_tab_vs_hist.count)
                THEN
                    IF NOT get_first_values(i_actual_row => l_tab_vs_hist(i),
                                            o_tbl_labels => l_tbl_lables,
                                            o_tbl_values => l_tbl_values,
                                            o_tbl_types  => l_tbl_types)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSE
                    IF NOT get_values(i_actual_row   => l_tab_vs_hist(i),
                                      i_previous_row => l_tab_vs_hist(i + 1),
                                      o_tbl_labels   => l_tbl_lables,
                                      o_tbl_values   => l_tbl_values,
                                      o_tbl_types    => l_tbl_types)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
                l_tab_hist.extend;
                l_tab_hist(l_tab_hist.count) := t_rec_epis_hist(id_history      => l_tab_vs_hist(i).id_vital_sign_read_hist,
                                                                dt_history      => l_tab_vs_hist(i).dt_registry,
                                                                tbl_labels      => l_tbl_lables,
                                                                tbl_values      => l_tbl_values,
                                                                tbl_types       => l_tbl_types,
                                                                tbl_info_labels => get_info_labels(),
                                                                tbl_info_values => get_info_values(l_tab_vs_hist(i)));
            
                l_is_first_line := FALSE;
            END LOOP;
        
            -- review data added to screen
            IF NOT get_revisions(i_actual_row => l_tab_vs_hist(l_tab_vs_hist.count),
                                 o_tbl_labels => l_tbl_lables,
                                 o_tbl_values => l_tbl_values,
                                 o_tbl_types  => l_tbl_types)
            THEN
                RETURN FALSE;
            ELSE
                l_tab_hist.extend;
            
                l_tab_hist(l_tab_hist.count) := t_rec_epis_hist(id_history      => NULL,
                                                                dt_history      => NULL,
                                                                tbl_labels      => l_tbl_lables,
                                                                tbl_values      => l_tbl_values,
                                                                tbl_types       => l_tbl_types,
                                                                tbl_info_labels => get_info_labels(),
                                                                tbl_info_values => NULL);
            END IF;
        
        END IF;
    
        l_dbg_msg := 'OPEN O_HIST';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_hist FOR
            SELECT t.id_history id_hist,
                   --t.dt_history      dt_hist,
                   t.tbl_labels      right_labels,
                   t.tbl_values      right_values,
                   t.tbl_types       types,
                   t.tbl_info_labels info_labels,
                   t.tbl_info_values info_values
              FROM TABLE(l_tab_hist) t;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_vs_detail;

    /************************************************************************************************************
    * This function returns the blood pressure value concatenating the sistolic and diastolic pressure values
    *
    * @param      i_lang                      Language id
    * @param      i_prof                      Professional, software and institution ids
    * @param      i_id_vital_sign             Vital sign id (blood pressure id)
    * @param      i_id_vital_sign_read        Vital sign read id
    * @param      i_dt_vital_sign_read        Vital sign read date
    * @param      i_dt_registry               Registry date
    * @param      i_decimal_symbol            Decimal symbol
    *
    * @return     Blood pressure value
    *
    * @author     Sergio Dias
    * @version    2.6.1.0.1
    * @since      2011-04-30
    ************************************************************************************************************/
    FUNCTION get_bloodpressure_value_hist
    (
        i_vital_sign         IN vital_sign_read.id_vital_sign%TYPE,
        i_vital_sign_read    IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_dt_vital_sign_read IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE,
        i_decimal_symbol     IN sys_config.value%TYPE
    ) RETURN VARCHAR2 IS
        l_sistolicpressure   vital_sign_read.value%TYPE;
        l_diastolicpressure  vital_sign_read.value%TYPE;
        l_value              vital_sign_read.value%TYPE;
        l_id_vital_sign      vital_sign.id_vital_sign%TYPE;
        l_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE;
    
        CURSOR vsr_cur(id_vs IN vital_sign.id_vital_sign%TYPE) IS
            SELECT aux.id_vital_sign_read
              FROM (SELECT vsr.id_vital_sign_read,
                           vsrel.rank,
                           row_number() over(PARTITION BY vsrel.id_vital_sign_detail ORDER BY vsr.dt_registry DESC) rn
                      FROM vital_sign_read vsr
                      JOIN vital_sign_relation vsrel
                        ON vsr.id_vital_sign = vsrel.id_vital_sign_detail
                       AND vsrel.id_vital_sign_parent = (SELECT pk_vital_sign.get_vs_parent(id_vs)
                                                           FROM dual)
                       AND vsrel.relation_domain = pk_alert_constant.g_vs_rel_conc
                       AND vsrel.flg_available = pk_alert_constant.g_yes
                     WHERE vsr.dt_vital_sign_read_tstz = l_dt_vital_sign_read
                       AND vsr.id_episode = i_id_episode) aux
             WHERE aux.rn = 1
             ORDER BY aux.rank ASC;
    
    BEGIN
        IF i_vital_sign IS NULL
        THEN
            SELECT vsr.id_vital_sign
              INTO l_id_vital_sign
              FROM vital_sign_read vsr
             WHERE vsr.id_vital_sign_read = i_vital_sign_read;
        ELSE
            l_id_vital_sign := i_vital_sign;
        END IF;
    
        IF i_dt_vital_sign_read IS NULL
        THEN
            SELECT vsr.dt_vital_sign_read_tstz
              INTO l_dt_vital_sign_read
              FROM vital_sign_read vsr
             WHERE vsr.id_vital_sign_read = i_vital_sign_read;
        ELSE
            l_dt_vital_sign_read := i_dt_vital_sign_read;
        END IF;
    
        FOR vc IN vsr_cur(l_id_vital_sign)
        LOOP
        
            BEGIN
                SELECT VALUE
                  INTO l_value
                  FROM (SELECT vsrh.value
                          FROM vital_sign_read_hist vsrh
                          LEFT JOIN vital_sign_read vsr
                            ON vsr.id_vital_sign_read = vsrh.id_vital_sign_read
                         WHERE vsrh.id_vital_sign_read = vc.id_vital_sign_read
                              --AND vsrh.dt_vital_sign_read_tstz = l_dt_vital_sign_read
                           AND vsrh.dt_registry = i_dt_registry
                        UNION ALL
                        SELECT vsr.value
                          FROM vital_sign_read vsr
                         WHERE vsr.id_vital_sign_read = vc.id_vital_sign_read
                              --AND vsr.dt_vital_sign_read_tstz = l_dt_vital_sign_read
                           AND vsr.dt_registry = i_dt_registry
                           AND vsr.flg_state = pk_alert_constant.g_active);
            
                IF l_sistolicpressure IS NULL
                THEN
                    l_sistolicpressure := pk_utils.to_str(i_number => l_value, i_decimal_symbol => i_decimal_symbol);
                ELSE
                    l_diastolicpressure := pk_utils.to_str(i_number => l_value, i_decimal_symbol => i_decimal_symbol);
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_value := NULL;
            END;
        
        END LOOP;
    
        RETURN nvl(s1 => l_sistolicpressure, s2 => '---') || '/' || nvl(s1 => l_diastolicpressure, s2 => '---');
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN nvl(s1 => l_sistolicpressure, s2 => '---') || '/' || nvl(s1 => l_diastolicpressure, s2 => '---');
    END get_bloodpressure_value_hist;

    /********************************************************************************************
    * Gets a summary of Vital Signs and Indicators for a Patient
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_SCOPE                 Scope ID
    *                                     E-Episode ID
    *                                     V-Visit ID
    *                                     P-Patient ID
    * @param I_SCOPE_TYPE            Scope type
    *                                     E-Episode
    *                                     V-Visit
    *                                     P-Patient
    * @param I_FLG_SCOPE             Flag to filter the scope
    *                                     S-Summary 1.st level (last Note)
    *                                     D-Detailed 2.nd level (Last Note by each Area) 
    * @param I_INTERVAL              Interval to filter
    *                                     D-Last 24H
    *                                     W-Week
    *                                     M-Month
    *                                     A-All
    * @param O_DATA                  Cursor with VS and Indicators Data to show
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Ant�nio Neto
    * @since                         09-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_viewer_vs_indicators
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2,
        i_flg_scope  IN VARCHAR2,
        i_interval   IN VARCHAR2,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_scope_not_valid  EXCEPTION;
        e_invalid_argument EXCEPTION;
        l_flg_view CONSTANT VARCHAR2(2 CHAR) := 'V2';
        l_dt_begin   VARCHAR2(200 CHAR);
        l_dt_end     VARCHAR2(200 CHAR);
        l_nr_records NUMBER;
    BEGIN
    
        IF (i_scope IS NOT NULL AND i_scope_type IS NOT NULL)
        THEN
            --Detailed 2.nd level (Last result by each vital sign)
            IF i_flg_scope = pk_prog_notes_constants.g_flg_scope_detail_d
            THEN
                CASE i_interval
                -- last X records 
                    WHEN pk_alert_constant.g_last_x_records THEN
                        l_nr_records := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'VS_LAST_X_RECORDS');
                        IF NOT pk_vital_sign_core.get_dates_x_records(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_scope      => i_scope,
                                                                      i_scope_type => i_scope_type,
                                                                      i_nr_records => l_nr_records,
                                                                      o_dt_begin   => l_dt_begin,
                                                                      o_dt_end     => l_dt_end,
                                                                      o_error      => o_error)
                        THEN
                            NULL;
                        END IF;
                    WHEN pk_alert_constant.g_my_last_x_recods THEN
                        l_nr_records := pk_sysconfig.get_config(i_prof => i_prof, i_code_cf => 'VS_MY_LAST_X_RECORDS');
                        IF NOT pk_vital_sign_core.get_dates_x_records(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_scope      => i_scope,
                                                                      i_scope_type => i_scope_type,
                                                                      i_nr_records => l_nr_records,
                                                                      o_dt_begin   => l_dt_begin,
                                                                      o_dt_end     => l_dt_end,
                                                                      o_error      => o_error)
                        THEN
                            NULL;
                        END IF;
                    ELSE
                        l_dt_begin := NULL;
                        l_dt_end   := NULL;
                END CASE;
                g_error := 'Get Data for Detailed screen - last result by vital sign';
                OPEN o_data FOR
                    SELECT pk_translation.get_translation(i_lang, vs.code_vital_sign) || CASE
                                WHEN pk_translation.get_translation(i_lang, vss.code_vital_sign_scales) IS NOT NULL THEN
                                 ' - ' || pk_translation.get_translation(i_lang, vss.code_vital_sign_scales)
                                ELSE
                                 NULL
                            END note_desc,
                           t1.dt_vs_read_str dt_read_str,
                           t1.value_desc || ' ' || t1.desc_unit_measure val_desc,
                           t1.dt_vital_sign_read read_str
                      FROM (SELECT /*+opt_estimate (table t rows=1)*/
                             t.id_vital_sign_read,
                             t.dt_vital_sign_read,
                             t.l_rank,
                             t.id_vital_sign,
                             t.dt_vs_read_str,
                             t.value_desc,
                             t.desc_unit_measure,
                             t.vital_sign_scale,
                             row_number() over(PARTITION BY t.id_vital_sign, t.vital_sign_scale ORDER BY t.dt_vital_sign_read DESC) rn
                              FROM TABLE(pk_vital_sign_core.tf_vital_sign_grid(i_lang              => i_lang,
                                                                               i_prof              => i_prof,
                                                                               i_flg_view          => l_flg_view,
                                                                               i_flg_screen        => pk_vital_sign_core.g_flg_screen_d,
                                                                               i_all_details       => pk_alert_constant.g_yes,
                                                                               i_scope             => i_scope,
                                                                               i_scope_type        => i_scope_type,
                                                                               i_interval          => i_interval,
                                                                               i_dt_begin          => l_dt_begin,
                                                                               i_dt_end            => l_dt_end,
                                                                               i_flg_use_soft_inst => 'N')) t) t1
                      JOIN vital_sign vs
                        ON t1.id_vital_sign = vs.id_vital_sign
                      LEFT JOIN vital_sign_scales vss
                        ON t1.vital_sign_scale = vss.id_vital_sign_scales
                     WHERE t1.rn = 1
                     ORDER BY t1.dt_vital_sign_read DESC,
                              t1.l_rank             ASC NULLS LAST,
                              t1.vital_sign_scale   ASC NULLS LAST,
                              t1.id_vital_sign      ASC;
            
                --Not in scope raise error
            ELSE
                g_error := 'Not a valid i_flg_scope (parameters accepted in (''D''))';
                RAISE l_scope_not_valid;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_data);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_VIEWER_VS_INDICATORS',
                                              o_error);
            RETURN FALSE;
    END get_viewer_vs_indicators;

    PROCEDURE open_my_cursor(i_cursor IN OUT t_cur_vs_header) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_vital_sign,
                   NULL val_min,
                   NULL val_max,
                   NULL rank,
                   NULL rank_conc,
                   NULL id_vital_sign_parent,
                   NULL relation_type,
                   NULL format_num,
                   NULL flg_fill_type,
                   NULL flg_sum,
                   NULL name_vs,
                   NULL desc_unit_measure,
                   NULL id_unit_measure,
                   NULL dt_server,
                   NULL flg_view,
                   NULL id_institution,
                   NULL id_software
              FROM dual
             WHERE 1 = 0;
    END open_my_cursor;

    --

    /************************************************************************************************************
    * Get VS_DESC market id to be used by the given id_vs
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vs                     Vital sign id
    *
    * @return     Market id
    *
    * @author     Alexandre Santos
    * @version    2.5.1.2.1
    * @since      2011/08/25
    ***********************************************************************************************************/
    FUNCTION get_vs_desc_cfg_var
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_id_vs IN vital_sign_desc.id_vital_sign%TYPE
    ) RETURN market.id_market%TYPE IS
        c_function_name CONSTANT VARCHAR2(30) := 'GET_VS_DESC_CFG_VAR';
        --
        l_one CONSTANT PLS_INTEGER := 1;
        l_two CONSTANT PLS_INTEGER := 2;
        --
        l_message     debug_msg;
        l_inst_market market.id_market%TYPE;
        l_market      market.id_market%TYPE := 0;
    BEGIN
        l_message := 'Init';
        alertlog.pk_alertlog.log_info(text            => l_message,
                                      object_name     => g_package_name,
                                      sub_object_name => c_function_name);
    
        l_message := 'CALL PK_UTILS.GET_INSTITUTION_MARKET';
        alertlog.pk_alertlog.log_debug(text            => l_message,
                                       object_name     => g_package_name,
                                       sub_object_name => c_function_name);
        l_inst_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        l_message := 'GET ID_MARKET TO USE';
        alertlog.pk_alertlog.log_debug(text            => l_message,
                                       object_name     => g_package_name,
                                       sub_object_name => c_function_name);
        SELECT t.id_market
          INTO l_market
          FROM (SELECT vsd.id_market,
                       row_number() over(ORDER BY decode(vsd.id_market, l_inst_market, l_one, l_two)) line_number
                  FROM vital_sign_desc vsd
                 WHERE id_vital_sign = i_id_vs
                   AND flg_available = pk_alert_constant.g_yes
                   AND id_market IN (0, l_inst_market)) t
         WHERE t.line_number = l_one;
    
        RETURN l_market;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_market; --Is initialized with 0
        WHEN OTHERS THEN
            RETURN NULL;
    END get_vs_desc_cfg_var;

    /************************************************************************************************************
    * Obter lista de descritivos de um SV cuja leitura n�o ?num�rica
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_gender                    patient gender
    * @param      i_age                       patient age
    * @param      i_id_vs                     Vital sign alias or translation
    * @param      o_vs                        descritivos
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Alexandre Santos
    * @version    2.5
    * @since      2009/06/30
    ***********************************************************************************************************/
    FUNCTION get_vs_desc_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_gender IN patient.gender%TYPE,
        i_age    IN patient.age%TYPE,
        i_id_vs  IN vital_sign_desc.id_vital_sign%TYPE,
        o_vs     OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30) := 'GET_VS_DESC_LIST';
        --    
        l_message debug_msg;
        l_market  market.id_market%TYPE;
    BEGIN
        l_message := 'CALL GET_VS_DESC_CFG_VAR';
        alertlog.pk_alertlog.log_debug(text            => l_message,
                                       object_name     => g_package_name,
                                       sub_object_name => c_function_name);
        l_market := get_vs_desc_cfg_var(i_lang => i_lang, i_prof => i_prof, i_id_vs => i_id_vs);
    
        l_message := 'GET CURSOR';
        alertlog.pk_alertlog.log_debug(text            => l_message,
                                       object_name     => g_package_name,
                                       sub_object_name => c_function_name);
        OPEN o_vs FOR
            SELECT id_vital_sign_desc, rank, aux.value, vs_desc, vs_abbreviation, icon
              FROM (SELECT id_vital_sign_desc,
                           rank,
                           to_number(VALUE) VALUE,
                           pk_vital_sign.get_vs_alias(i_lang, i_gender, i_age, vsd.code_vital_sign_desc) vs_desc,
                           pk_translation.get_translation(i_lang, code_abbreviation) vs_abbreviation,
                           icon
                      FROM vital_sign_desc vsd
                     WHERE id_vital_sign = i_id_vs
                       AND flg_available = pk_alert_constant.g_yes
                       AND id_market = l_market) aux
             WHERE vs_desc IS NOT NULL
             ORDER BY rank, vs_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_vs);
            RETURN FALSE;
    END get_vs_desc_list;

    /************************************************************************************************************
    * Obter lista de descritivos de um SV cuja leitura n�o ?num�rica
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_patient                   patient id
    * @param      i_id_vs                     Vital sign alias or translation
    * @param      o_vs                        descritivos
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Lu�s Maia
    * @version    2.5
    * @since      2011/11/15
    ***********************************************************************************************************/
    FUNCTION get_vs_desc_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vs   IN vital_sign_desc.id_vital_sign%TYPE,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30) := 'GET_VS_DESC_LIST';
        --    
        l_message debug_msg;
        error_getting_values EXCEPTION;
        --
        l_gender patient.gender%TYPE;
        l_age    patient.age%TYPE;
    BEGIN
        g_error := 'CALL FUNCTION GET_PAT_INFO';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => c_function_name);
        IF NOT get_pat_info(i_lang => i_lang, i_patient => i_patient, o_gender => l_gender, o_age => l_age)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL GET_VS_DESC_LIST';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => g_package_name,
                                       sub_object_name => c_function_name);
        IF NOT get_vs_desc_list(i_lang   => i_lang,
                                i_prof   => i_prof,
                                i_gender => l_gender,
                                i_age    => l_age,
                                i_id_vs  => i_id_vs,
                                o_vs     => o_vs,
                                o_error  => o_error)
        THEN
            RAISE error_getting_values;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_vs);
            RETURN FALSE;
    END get_vs_desc_list;

    /************************************************************************************************************
    * Merges the registries in the vs_visit table when merging 2 visits that have the same vital sign registered in the both visits
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_patient                   patient id
    * @param      i_id_vs                     Vital sign alias or translation
    * @param      o_vs                        descritivos
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Sofia Mendes
    * @version    2.6
    * @since      2011/11/15
    ***********************************************************************************************************/
    FUNCTION merge_vs_visit_ea_dup
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_id_visit       IN visit.id_visit%TYPE,
        i_other_id_visit IN visit.id_visit%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(30) := 'MERGE_VS_VISIT_EA_DUP';
    
        --            
        l_min_vsr   vs_visit_ea.id_min_vsr%TYPE;
        l_max_vsr   vs_visit_ea.id_max_vsr%TYPE;
        l_lst3_vsr  vs_visit_ea.id_last_3_vsr%TYPE;
        l_lst2_vsr  vs_visit_ea.id_last_2_vsr%TYPE;
        l_lst1_vsr  vs_visit_ea.id_last_1_vsr%TYPE;
        l_n_records vs_visit_ea.n_records%TYPE;
    
        --l_vs_vis_ea vs_visit_ea%ROWTYPE;
    BEGIN
        g_error := 'merge_vs_visit_ea_dup. i_patient: ' || i_patient || ' i_id_visit: ' || i_id_visit ||
                   ' i_other_id_visit: ' || i_other_id_visit;
        pk_alertlog.log_debug(g_error);
    
        FOR rec IN (SELECT *
                      FROM vs_visit_ea v
                     WHERE v.id_visit = i_other_id_visit
                       AND EXISTS (SELECT 1
                              FROM vs_visit_ea vvea
                             WHERE vvea.id_visit = i_id_visit
                               AND vvea.id_vital_sign = v.id_vital_sign
                               AND vvea.id_unit_measure = v.id_unit_measure))
        LOOP
            g_error := 'CALL ts_vs_visit_ea.del_by';
            pk_alertlog.log_debug(g_error);
            ts_vs_visit_ea.del_by(where_clause_in => ' id_visit = ' || i_other_id_visit || ' AND id_vital_sign = ' ||
                                                     rec.id_vital_sign || ' AND id_unit_measure = ' ||
                                                     rec.id_unit_measure);
        
            --
            g_error := 'CALL pk_vital_sign_pbl.get_vs_n_records. id_vital_sign: ' || rec.id_vital_sign;
            pk_alertlog.log_debug(g_error);
            l_n_records := pk_vital_sign_pbl.get_vs_n_records(i_vital_sign => rec.id_vital_sign,
                                                              i_patient    => i_patient,
                                                              i_visit      => i_id_visit);
        
            g_error := 'CALL pk_vital_sign.get_min_max_vsr. id_vital_sign: ' || rec.id_vital_sign ||
                       ' id_unit_measure: ' || rec.id_unit_measure;
            pk_alertlog.log_debug(g_error);
            pk_vital_sign.get_min_max_vsr(i_vital_sign   => rec.id_vital_sign,
                                          i_unit_measure => rec.id_unit_measure,
                                          i_patient      => i_patient,
                                          i_visit        => i_id_visit,
                                          o_min_vsr      => l_min_vsr,
                                          o_max_vsr      => l_max_vsr);
        
            g_error := 'CALL pk_vital_sign.get_min_max_vsr. id_vital_sign: ' || rec.id_vital_sign ||
                       ' id_unit_measure: ' || rec.id_unit_measure;
            pk_alertlog.log_debug(g_error);
            pk_vital_sign.get_lst_vsr(i_vital_sign   => rec.id_vital_sign,
                                      i_unit_measure => rec.id_unit_measure,
                                      i_patient      => i_patient,
                                      i_visit        => i_id_visit,
                                      o_lst3_vsr     => l_lst3_vsr,
                                      o_lst2_vsr     => l_lst2_vsr,
                                      o_lst1_vsr     => l_lst1_vsr);
        
            g_error := 'CALL ts_vs_visit_ea.upd: n_records_in' || l_n_records || ' id_min_vsr_in: ' || l_min_vsr ||
                       ' id_max_vsr_in: ' || l_max_vsr || ' id_last_1_vsr_in: ' || l_lst1_vsr || ' id_last_2_vsr_in: ' ||
                       l_lst2_vsr || ' id_last_3_vsr_in: ' || l_lst3_vsr;
            pk_alertlog.log_debug(g_error);
            ts_vs_visit_ea.upd(id_visit_in        => i_id_visit,
                               id_vital_sign_in   => rec.id_vital_sign,
                               id_unit_measure_in => rec.id_unit_measure,
                               n_records_in       => l_n_records,
                               id_min_vsr_in      => l_min_vsr,
                               id_max_vsr_in      => l_max_vsr,
                               id_last_1_vsr_in   => l_lst1_vsr,
                               id_last_1_vsr_nin  => FALSE,
                               id_last_2_vsr_in   => l_lst2_vsr,
                               id_last_2_vsr_nin  => FALSE,
                               id_last_3_vsr_in   => l_lst3_vsr,
                               id_last_3_vsr_nin  => FALSE);
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            RETURN FALSE;
    END merge_vs_visit_ea_dup;

    /************************************************************************************************************
    * Get the vital sign date from the vital_sign_read record
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        Vital sign read ID
    * @param      o_dt_vital_sign_read_tstz   Vital sign clinical date
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Sofia Mendes
    * @version    2.6.2
    * @since      24-08-2012
    ***********************************************************************************************************/
    FUNCTION get_vital_sign_date
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        o_dt_vital_sign_read_tstz OUT NOCOPY vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(19 CHAR) := 'GET_VITAL_SIGN_DATE';
        --    
        l_message debug_msg;
        error_getting_values EXCEPTION;
    BEGIN
    
        g_error := 'get_id_vital_sign. i_id_vital_sign_read: ' || i_id_vital_sign_read;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT v.dt_vital_sign_read_tstz
          INTO o_dt_vital_sign_read_tstz
          FROM vital_sign_read v
         WHERE v.id_vital_sign_read = i_id_vital_sign_read;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            RETURN FALSE;
    END get_vital_sign_date;

    /************************************************************************************************************
    * Get the vital sign ranks to be used on single page. 
    * Rank 1: 1st value
    * Rank 2: penultimate value
    * Rank 3: last value
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        Vital sign read ID
    * @param      i_scope                     Scope ID (Episode ID; Visit ID; Patient ID)
    * @param      i_flg_scope                 Scope (E- Episode, V- Visit, P- Patient)
    * @param      o_id_vital_sign_read        Vital sign read ID
    * @param      o_rank                      Rank
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Sofia Mendes
    * @version    2.6.2
    * @since      24-08-2012
    ***********************************************************************************************************/
    FUNCTION get_vital_signs_ranks
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_scope          IN VARCHAR2,
        i_scope              IN NUMBER,
        i_id_vital_sign_read IN table_number,
        o_id_vital_sign_read OUT NOCOPY table_number,
        o_rank               OUT NOCOPY table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(17 CHAR) := 'GET_ID_VITAL_SIGN';
        --    
        l_message debug_msg;
        error_getting_values EXCEPTION;
    BEGIN
        IF (i_flg_scope = pk_alert_constant.g_scope_type_visit)
        THEN
            SELECT t.id_vital_sign_read, decode(rn_asc, 1, 1, decode(rn_desc, 2, 2, 3)) rank
              BULK COLLECT
              INTO o_id_vital_sign_read, o_rank
              FROM (SELECT row_number() over(PARTITION BY epi.id_visit, nvl(vsr.id_vital_sign_parent, v.id_vital_sign) ORDER BY v.dt_vital_sign_read_tstz ASC) rn_asc,
                           row_number() over(PARTITION BY epi.id_visit, nvl(vsr.id_vital_sign_parent, v.id_vital_sign) ORDER BY v.dt_vital_sign_read_tstz DESC) rn_desc,
                           v.*
                      FROM vital_sign_read v
                      JOIN episode epi
                        ON epi.id_episode = v.id_episode
                      LEFT JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_detail = v.id_vital_sign
                       AND vsr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                     WHERE epi.id_visit = i_scope
                       AND v.id_vital_sign_read IN (SELECT column_value
                                                      FROM TABLE(i_id_vital_sign_read))) t
             WHERE t.rn_asc = 1 --1st records
                OR t.rn_desc IN (1, 2) --last 2 records
            ;
        ELSIF (i_flg_scope = pk_alert_constant.g_scope_type_patient)
        THEN
            SELECT t.id_vital_sign_read, decode(rn_asc, 1, 1, decode(rn_desc, 2, 2, 3)) rank
              BULK COLLECT
              INTO o_id_vital_sign_read, o_rank
              FROM (SELECT row_number() over(PARTITION BY v.id_patient, nvl(vsr.id_vital_sign_parent, v.id_vital_sign) ORDER BY v.dt_vital_sign_read_tstz ASC) rn_asc,
                           row_number() over(PARTITION BY v.id_patient, nvl(vsr.id_vital_sign_parent, v.id_vital_sign) ORDER BY v.dt_vital_sign_read_tstz DESC) rn_desc,
                           v.*
                      FROM vital_sign_read v
                      LEFT JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_detail = v.id_vital_sign
                       AND vsr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                     WHERE v.id_patient = i_scope
                       AND v.id_vital_sign_read IN (SELECT column_value
                                                      FROM TABLE(i_id_vital_sign_read))) t
             WHERE t.rn_asc = 1 --1st records
                OR t.rn_desc IN (1, 2) --last 2 records
            ;
        ELSIF (i_flg_scope = pk_alert_constant.g_scope_type_episode)
        THEN
        
            SELECT t.id_vital_sign_read, decode(rn_asc, 1, 1, decode(rn_desc, 2, 2, 3)) rank
              BULK COLLECT
              INTO o_id_vital_sign_read, o_rank
              FROM (SELECT row_number() over(PARTITION BY v.id_episode, nvl(vsr.id_vital_sign_parent, v.id_vital_sign) ORDER BY v.dt_vital_sign_read_tstz ASC) rn_asc,
                           row_number() over(PARTITION BY v.id_episode, nvl(vsr.id_vital_sign_parent, v.id_vital_sign) ORDER BY v.dt_vital_sign_read_tstz DESC) rn_desc,
                           v.*
                      FROM vital_sign_read v
                      LEFT JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_detail = v.id_vital_sign
                       AND vsr.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
                     WHERE v.id_episode = i_scope
                       AND v.id_vital_sign_read IN (SELECT column_value
                                                      FROM TABLE(i_id_vital_sign_read))) t
             WHERE t.rn_asc = 1 --1st records
                OR t.rn_desc IN (1, 2) --last 2 records
            ;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            RETURN FALSE;
    END get_vital_signs_ranks;

    /************************************************************************************************************
    * Get the vital sign rank define for the given view
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign             Vital sign ID
    * @param      i_flg_view                  Vital Signs View
    *
    * @return     Rank
    *
    * @author     Sofia Mendes
    * @version    2.6.2
    * @since      24-08-2012
    ***********************************************************************************************************/
    FUNCTION get_vital_sign_view_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_flg_view      IN VARCHAR2
    ) RETURN vs_soft_inst.rank%TYPE IS
        c_function_name CONSTANT VARCHAR2(24 CHAR) := 'GET_VITAL_SIGN_VIEW_RANK';
        --            
        error_getting_values EXCEPTION;
        l_rank vs_soft_inst.rank%TYPE;
    BEGIN
        g_error := 'GET vital sign rank. id_vital_sign: ' || i_id_vital_sign || ' i_flg_view: ' || i_flg_view;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT v.rank
          INTO l_rank
          FROM vs_soft_inst v
         WHERE v.id_institution = i_prof.institution
           AND v.id_software = i_prof.software
           AND v.id_vital_sign = i_id_vital_sign
           AND v.flg_view = i_flg_view
           AND rownum = 1;
    
        RETURN l_rank;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'NO vital sign rank found id_vital_sign: ' || i_id_vital_sign || ' i_flg_view: ' || i_flg_view;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => c_function_name);
            RETURN NULL;
    END get_vital_sign_view_rank;
    ----------------------------------------
    FUNCTION get_full_value
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_vsr         IN vital_sign_read.id_vital_sign_read%TYPE,
        i_vital_sign  IN vital_sign_read.id_vital_sign%TYPE,
        i_value       IN VARCHAR2,
        i_dt_read     IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry IN vital_sign_read.dt_registry%TYPE
    ) RETURN VARCHAR2 IS
        l_current_vital_sign vital_sign.id_vital_sign%TYPE;
        l_episode            episode.id_episode%TYPE;
        l_relation_domain    vital_sign_relation.relation_domain%TYPE;
        l_vs_parent          vital_sign_relation.id_vital_sign_parent%TYPE;
        l_result             VARCHAR2(200 CHAR);
        l_id_patient         patient.id_patient%TYPE;
        l_dt_read            vital_sign_read.dt_vital_sign_read_tstz%TYPE;
    BEGIN
        l_result := i_value;
    
        BEGIN
            SELECT vsrel.relation_domain, vsrel.id_vital_sign_parent
              INTO l_relation_domain, l_vs_parent
              FROM vital_sign_relation vsrel
             WHERE vsrel.id_vital_sign_detail = i_vital_sign
               AND vsrel.relation_domain IN (pk_alert_constant.g_vs_rel_conc, pk_alert_constant.g_vs_rel_sum)
               AND vsrel.flg_available = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_vs_parent IS NOT NULL
        THEN
            IF l_relation_domain = pk_alert_constant.g_vs_rel_sum
            THEN
                SELECT vsr.id_patient, vsr.id_episode
                  INTO l_id_patient, l_episode
                  FROM vital_sign_read vsr
                 WHERE vsr.id_vital_sign_read = i_vsr;
            
                SELECT to_char(get_glasgowtotal_value_hist(l_vs_parent,
                                                           l_id_patient,
                                                           l_episode,
                                                           i_dt_read,
                                                           i_dt_registry))
                  INTO l_result
                  FROM dual;
            
            END IF;
            IF l_relation_domain = pk_alert_constant.g_vs_rel_conc
            THEN
                SELECT DISTINCT vsr.id_vital_sign, vsr.id_episode, vsr.dt_vital_sign_read_tstz
                  INTO l_current_vital_sign, l_episode, l_dt_read
                  FROM vital_sign_read vsr
                 WHERE vsr.id_vital_sign_read = i_vsr;
            
                SELECT get_bloodpressure_value_hist(l_current_vital_sign,
                                                    i_vsr,
                                                    l_episode,
                                                    l_dt_read,
                                                    i_dt_registry,
                                                    pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                            i_prof_inst => i_prof.institution,
                                                                            i_prof_soft => i_prof.software))
                  INTO l_result
                  FROM dual;
            END IF;
        END IF;
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            l_result := '---';
            RETURN l_result;
    END;
    --
    /************************************************************************************************************
    * Get the vital sign type
    *
    * @param      i_vital_sign             Vital sign ID
    *
    * @return     Vital sign type
    *
    * @author     Alexandre Santos
    * @version    2.6.3
    * @since      08-03-2013
    ***********************************************************************************************************/
    FUNCTION get_vital_sign_type(i_vital_sign IN vital_sign.id_vital_sign%TYPE) RETURN VARCHAR2 IS
        l_ret VARCHAR2(1 CHAR) := pk_vital_sign.g_vs_type_normal;
    BEGIN
        SELECT CASE a.has_childs
                   WHEN pk_alert_constant.g_yes THEN
                    pk_vital_sign.g_vs_type_parent
                   ELSE
                    CASE a.has_parent
                        WHEN pk_alert_constant.g_yes THEN
                         pk_vital_sign.g_vs_type_child
                        ELSE
                         pk_vital_sign.g_vs_type_normal
                    END
               END vs_type
          INTO l_ret
          FROM (SELECT decode((SELECT COUNT(*)
                                FROM vital_sign_relation vsr
                               WHERE vsr.id_vital_sign_parent = i_vital_sign
                                 AND vsr.relation_domain != pk_alert_constant.g_vs_rel_percentile),
                              0,
                              pk_alert_constant.g_no,
                              pk_alert_constant.g_yes) has_childs,
                       decode((SELECT COUNT(*)
                                FROM vital_sign_relation vsr
                               WHERE vsr.id_vital_sign_detail = i_vital_sign
                                 AND vsr.relation_domain != pk_alert_constant.g_vs_rel_percentile),
                              0,
                              pk_alert_constant.g_no,
                              pk_alert_constant.g_yes) has_parent
                  FROM dual) a;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_vital_sign.g_vs_type_normal;
    END get_vital_sign_type;
    --

    /**************************************************************************
    * Returns the data about a given vital sign, considering the unit measure
    * in use by the institution.
    *   
    * @param i_value                  Value to convert
    * @param i_vital_sign             Vital sign id
    * @param i_um_origin              Origin unit measure (u.m. of i_value)
    * @param i_um_dest                Destination unit measure (i_value will be converted to this u.m.)
    *
    * @return                         Converted value
    *                        
    * @author                         Jos?Brito
    * @version                        2.6
    * @since                          19/01/2010
    **************************************************************************/
    FUNCTION get_unit_mea_conversion
    (
        i_value      IN vital_sign_read.value%TYPE,
        i_vital_sign IN vital_sign.id_vital_sign%TYPE,
        i_um_origin  IN triage_unit_mea_conversion.id_unit_measure_orig%TYPE,
        i_um_dest    IN triage_unit_mea_conversion.id_unit_measure_dest%TYPE
    ) RETURN NUMBER IS
    
        l_formula      unit_measure_convert.formula%TYPE;
        l_decimals     unit_measure_convert.decimals%TYPE;
        l_for_result   vital_sign_read.value%TYPE;
        l_result_final vital_sign_read.value%TYPE;
    
        CURSOR c_conversion_form IS
            SELECT tuc.formula, tuc.decimals
              FROM triage_unit_mea_conversion tuc
             WHERE tuc.id_unit_measure_orig = i_um_origin
               AND tuc.id_unit_measure_dest = i_um_dest
               AND tuc.id_vital_sign = i_vital_sign;
    BEGIN
        IF i_um_origin != i_um_dest
        THEN
            OPEN c_conversion_form;
            FETCH c_conversion_form
                INTO l_formula, l_decimals;
            CLOSE c_conversion_form;
        
            IF l_formula IS NULL
            THEN
                l_result_final := i_value;
            ELSE
                EXECUTE IMMEDIATE l_formula
                    INTO l_for_result
                    USING i_value;
            
                l_result_final := round(l_for_result, l_decimals);
            END IF;
        ELSIF i_um_origin = i_um_dest
        THEN
            l_result_final := i_value;
        ELSE
            l_result_final := i_value;
        END IF;
    
        RETURN l_result_final;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_unit_mea_conversion;
    --
    /************************************************************************************************************
    * Get the normal peak flow value for the given patient age, gender and height
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_pat_age                   patient age in years
    * @param      i_pat_gender                patient gender
    * @param      i_pat_height                patient height
    *
    * @return     Peak flow normal value 
    *
    * @author     Alexandre Santos
    * @version    2.6.3.6
    * @since      09-07-2013
    ***********************************************************************************************************/
    FUNCTION get_peak_flow_predict
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pat_age    IN patient.age%TYPE,
        i_pat_gender IN patient.gender%TYPE,
        i_pat_height IN vital_sign_read.value%TYPE
    ) RETURN vital_sign_read.value%TYPE IS
        --
        l_peak_flow_predict vital_sign_read.value%TYPE;
        --
        l_ret vital_sign_read.value%TYPE;
    BEGIN
        IF i_pat_age IS NULL
           OR i_pat_gender IS NULL
           OR i_pat_height IS NULL
        THEN
            l_peak_flow_predict := NULL;
        ELSIF i_pat_age >= 15
        THEN
            IF i_pat_gender = pk_patient.g_pat_gender_male
            THEN
                l_peak_flow_predict := exp((0.544 * ln(i_pat_age)) - (0.0151 * i_pat_age) - (74.7 / i_pat_height) + 5.48);
            ELSIF i_pat_gender = pk_patient.g_pat_gender_female
            THEN
                l_peak_flow_predict := exp((0.376 * ln(i_pat_age)) - (0.0120 * i_pat_age) - (58.8 / i_pat_height) + 5.63);
            ELSE
                l_peak_flow_predict := NULL;
            END IF;
        ELSE
            l_peak_flow_predict := 455 * (i_pat_height / 100) - 332;
        END IF;
    
        IF l_peak_flow_predict IS NOT NULL
        THEN
            l_ret := round(50.356 + (0.4 * l_peak_flow_predict) + (0.0008814 * power(l_peak_flow_predict, 2)) -
                           (0.0000001116 * power(l_peak_flow_predict, 3)));
        END IF;
    
        RETURN l_ret;
    END get_peak_flow_predict;
    --
    /************************************************************************************************************
    * Get the last read value for the given vital sign
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_episode                   episode id
    * @param      i_vital_sign                vital signid
    *
    * @return     Vital sign value if exists; Otherwise NULL
    *
    * @author     Alexandre Santos
    * @version    2.6.3.6
    * @since      15-07-2013
    ***********************************************************************************************************/
    FUNCTION get_vs_read_value
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_vital_sign IN vital_sign.id_vital_sign%TYPE
    ) RETURN vital_sign_read.value%TYPE IS
        l_vsr_value vital_sign_read.value%TYPE;
    BEGIN
        BEGIN
            SELECT t.value
              INTO l_vsr_value
              FROM (SELECT v.value
                      FROM vital_signs_ea v
                     WHERE v.id_institution_read = i_prof.institution
                       AND v.id_vital_sign = i_vital_sign
                       AND v.id_patient = i_patient
                       AND v.flg_state = c_flg_status_active
                     ORDER BY dt_vital_sign_read DESC NULLS LAST) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_vsr_value := NULL;
        END;
    
        RETURN l_vsr_value;
    END get_vs_read_value;

    /**************************************************************************
    * Checks if it is possible to edit the vital sign value
    *
    * @param i_lang                    Language ID
    * @param i_prof                   Professional info
    * @param i_id_triage              Triage Identifier
    * @param i_flg_fill_type          Vital sign fill type
    * 
    * @return                         Flag read only two values available(Y/N) 
    * @author                         Sofia Mendes
    * @version                        2.6.3.7.1
    * @since                         14-8-2013
    **************************************************************************/
    FUNCTION is_vital_sign_read_only
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_triage  IN epis_triage.id_epis_triage%TYPE,
        i_flg_fill_type   IN vital_sign.flg_fill_type%TYPE,
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE DEFAULT NULL
        --   i_id_patient      IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_read_only         VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_count             NUMBER;
        l_view_only_profile VARCHAR2(1 CHAR) := pk_prof_utils.check_has_functionality(i_lang,
                                                                                      i_prof,
                                                                                      'READ ONLY PROFILE');
    
    BEGIN
        g_error := 'CHECK IF THE VITAL SIGN SHOULD BE EDITABLE';
        pk_alertlog.log_debug(g_error);
        IF (i_id_epis_triage IS NOT NULL)
        THEN
            l_read_only := pk_alert_constant.g_yes;
        END IF;
    
        IF (i_flg_fill_type = pk_vital_sign.g_fill_type_read_only)
        THEN
            l_read_only := pk_alert_constant.g_yes;
        END IF;
        IF l_view_only_profile = pk_alert_constant.g_yes
        THEN
            l_read_only := pk_alert_constant.g_yes;
        END IF;
        IF i_vital_sign_read IS NOT NULL
        THEN
            SELECT COUNT(1)
              INTO l_count
              FROM epis_scales_score es
             WHERE es.id_vital_sign_read = i_vital_sign_read;
            IF l_count > 0
            THEN
                l_read_only := pk_alert_constant.g_yes;
            END IF;
        END IF;
        RETURN l_read_only;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_read_only;
        
    END is_vital_sign_read_only;

    /************************************************************************************************************
    * This function creates a record in the history table for vital signs read attributes
    *
    * @param        i_lang                       Language id
    * @param        i_prof                       Professional, software and institution ids
    * @param        i_id_vital_sign_read         Vital Sign Read ID
    * @param        i_id_vital_sign_read_hist    Vital sign Read hist ID
    *
    * @author     Paulo Teixeira
    * @version    2.6.3
    * @since      2013-11-19
    ************************************************************************************************************/
    FUNCTION set_vs_read_hist_atttrib
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_vital_sign_read      IN vital_sign_read.id_vital_sign_read%TYPE,
        i_id_vital_sign_read_hist IN vital_sign_read_hist.id_vital_sign_read_hist%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'set_vs_read_hist_atttrib';
        l_dbg_msg           debug_msg;
        v_vs_read_attribute vs_read_attribute%ROWTYPE;
        rows_out            table_varchar;
    
        CURSOR c_vs_read_attribute(l_id vs_read_attribute.id_vital_sign_read%TYPE) IS
            SELECT vsra.id_vs_attribute, vsra.free_text
              FROM vs_read_attribute vsra
             WHERE vsra.id_vital_sign_read = l_id;
    BEGIN
    
        l_dbg_msg := 'open c_vs_read_attribute(i_id_vital_sign_read)';
        OPEN c_vs_read_attribute(i_id_vital_sign_read);
        LOOP
            FETCH c_vs_read_attribute
                INTO v_vs_read_attribute.id_vs_attribute, v_vs_read_attribute.free_text;
            EXIT WHEN c_vs_read_attribute%NOTFOUND;
        
            l_dbg_msg := 'call ts_vs_read_hist_attribute.ins';
            ts_vs_read_hist_attribute.ins(id_vital_sign_read_hist_in => i_id_vital_sign_read_hist,
                                          id_vs_attribute_in         => v_vs_read_attribute.id_vs_attribute,
                                          free_text_in               => v_vs_read_attribute.free_text,
                                          rows_out                   => rows_out);
        
            l_dbg_msg := 'call t_data_gov_mnt.process_insert for vs_read_hist_attribute';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'VS_READ_HIST_ATTRIBUTE',
                                          i_rowids     => rows_out,
                                          o_error      => o_error);
        
        END LOOP;
        CLOSE c_vs_read_attribute;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_vs_read_hist_atttrib;

    /************************************************************************************************************
    * This function returns the short description of the scale associated with the given vital sign scale element 
    *
    * @param      i_vs_scales_element      Vital sign scale element id
    *
    * @return     Vital sign scale id
    *
    * @author     Sofia Mendes
    * @version    2.6.3.9
    * @since      04/12/2013
    ************************************************************************************************************/
    FUNCTION get_vs_scale_short_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_vs_scales_element IN vital_sign_scales_element.id_vs_scales_element%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        c_function_name CONSTANT obj_name := 'GET_VS_SCALE_SHORT_DESC';
        l_dbg_msg debug_msg;
    
        l_desc_scale pk_translation.t_desc_translation;
    
    BEGIN
        IF i_vs_scales_element IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_dbg_msg := 'get vital sign scale id';
        pk_alertlog.log_info(text => l_dbg_msg, object_name => g_package_name, sub_object_name => c_function_name);
        SELECT pk_translation.get_translation(i_lang, vss.code_vital_sign_scales_short)
          INTO l_desc_scale
          FROM vital_sign_scales_element vsse
          JOIN vital_sign_scales vss
            ON vss.id_vital_sign_scales = vsse.id_vital_sign_scales
         WHERE vsse.id_vs_scales_element = i_vs_scales_element;
    
        RETURN l_desc_scale;
    
    END get_vs_scale_short_desc;
    /************************************************************************************************************
    * get_vs_value_dt_reg
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign_read        vital sign read identifier
    * @param      i_dt_vs_read                clinical date
    * @param      i_dt_registry               registered date
    *
    * @return     vital sign value
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/11/25
    ***********************************************************************************************************/

    FUNCTION get_vs_value_dt_reg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_dt_vs_read         IN vital_sign_read.dt_vital_sign_read_tstz%TYPE,
        i_dt_registry        IN vital_sign_read.dt_registry%TYPE,
        o_info               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        c_function_name CONSTANT VARCHAR2(30) := 'get_vs_value_dt_reg';
    BEGIN
        g_error := 'call pk_vital_sign_core.get_vs_value_dt_reg';
        IF NOT pk_vital_sign_core.get_vs_value_dt_reg(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_vital_sign_read => i_id_vital_sign_read,
                                                      i_dt_vs_read         => i_dt_vs_read,
                                                      i_dt_registry        => i_dt_registry,
                                                      o_info               => o_info,
                                                      o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_vs_value_dt_reg;
    /************************************************************************************************************
    * get_vs_most_recent_value
    *
    * @param      i_lang                      Prefered language from profissional
    * @param      i_prof                      professional (id, inst, softw)
    * @param      i_id_vital_sign             vital_sign identifier
    * @param      i_scope                     Scope ID
    *                                               E-Episode ID
    *                                               V-Visit ID
    *                                               P-Patient ID
    * @param      i_scope_type                Scope type
    *                                               E-Episode
    *                                               V-Visit
    *                                               P-Patient
    * @param      i_dt_begin               Begin date   
    * @param      i_dt_end                 end date                             
    * @param      o_info                      cursor out
    * @param      o_error                     error message
    *
    * @return     True on sucess otherwise false
    *
    * @author     Paulo Teixeira
    * @version    2.6
    * @since      2014/09/30
    ***********************************************************************************************************/
    FUNCTION get_vs_most_recent_value
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_dt_begin      IN VARCHAR2 DEFAULT NULL,
        i_dt_end        IN VARCHAR2 DEFAULT NULL,
        o_info          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        c_function_name CONSTANT VARCHAR2(30) := 'GET_VS_MOST_RECENT_VALUE';
    BEGIN
        g_error := 'pk_vital_sign_core..get_vs_most_recent_value';
        IF NOT pk_vital_sign_core.get_vs_most_recent_value(i_lang          => i_lang,
                                                           i_prof          => i_prof,
                                                           i_id_vital_sign => i_id_vital_sign,
                                                           i_scope         => i_scope,
                                                           i_scope_type    => i_scope_type,
                                                           i_dt_begin      => i_dt_begin,
                                                           i_dt_end        => i_dt_end,
                                                           o_info          => o_info,
                                                           o_error         => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_vs_most_recent_value;

    FUNCTION get_vs_sum_result(l_id_vital_sign_desc IN table_number) RETURN NUMBER IS
    
        l_sum NUMBER := 0;
    
    BEGIN
        SELECT SUM(vsd.value)
          INTO l_sum
          FROM vital_sign_desc vsd
         WHERE vsd.id_vital_sign_desc IN (SELECT *
                                            FROM TABLE(l_id_vital_sign_desc))
           AND vsd.flg_available = 'Y';
        RETURN l_sum;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_vs_desc_result
    (
        i_episode       IN episode.id_episode%TYPE,
        l_id_vs         IN table_number,
        l_id_vs_parent  IN vital_sign_relation.id_vital_sign_parent%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_vital_sign_desc    table_number := table_number();
        l_child_num          NUMBER := 0;
        l_dt_vital_sign_read vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_sum_final          NUMBER := NULL;
        l_sum_aux            NUMBER := 0;
    
        CURSOR c_vital_sign_read(child_num IN NUMBER) IS
            SELECT dt_vital_sign_read_tstz
              FROM (SELECT r.dt_vital_sign_read_tstz, vsr.id_vital_sign_parent, COUNT(1) AS COUNT
                      FROM vital_sign_read r
                      JOIN vital_sign_relation vsr
                        ON vsr.id_vital_sign_detail = r.id_vital_sign
                       AND vsr.relation_domain = 'S'
                     WHERE r.id_episode = i_episode
                       AND r.flg_state = pk_alert_constant.g_active
                       AND r.id_vital_sign IN (SELECT *
                                                 FROM TABLE(l_id_vs))
                       AND r.dt_vital_sign_read_tstz >= i_dt_min
                       AND r.dt_vital_sign_read_tstz <= i_dt_max
                     GROUP BY vsr.id_vital_sign_parent, r.dt_vital_sign_read_tstz
                    HAVING COUNT(1) = child_num
                     ORDER BY r.dt_vital_sign_read_tstz DESC);
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_child_num
          FROM vital_sign_relation vsr
         WHERE vsr.id_vital_sign_parent = l_id_vs_parent
           AND vsr.flg_available = pk_alert_constant.g_yes;
    
        OPEN c_vital_sign_read(l_child_num);
    
        LOOP
            FETCH c_vital_sign_read
                INTO l_dt_vital_sign_read;
            EXIT WHEN c_vital_sign_read%NOTFOUND;
        
            SELECT vsr.id_vital_sign_desc
              BULK COLLECT
              INTO l_vital_sign_desc
              FROM vital_sign_read vsr
             WHERE vsr.dt_vital_sign_read_tstz = l_dt_vital_sign_read
               AND vsr.id_vital_sign IN (SELECT *
                                           FROM TABLE(l_id_vs))
               AND vsr.id_episode = i_episode
               AND vsr.flg_state = pk_alert_constant.g_active;
        
            l_sum_aux := get_vs_sum_result(l_vital_sign_desc);
        
            IF i_flg_parameter = 'MAX'
            THEN
                IF l_sum_final < l_sum_aux
                   OR l_sum_final IS NULL
                THEN
                    l_sum_final := l_sum_aux;
                END IF;
            ELSIF i_flg_parameter = 'MIN'
            THEN
                IF l_sum_final > l_sum_aux
                   OR l_sum_final IS NULL
                THEN
                    l_sum_final := l_sum_aux;
                END IF;
            END IF;
        END LOOP;
    
        RETURN l_sum_final;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_vs_desc_result;

    FUNCTION get_vs_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_vs         IN table_number,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_result_value  OUT NUMBER,
        o_result_um     OUT unit_measure.id_unit_measure%TYPE
    ) RETURN BOOLEAN IS
        l_result_value    NUMBER(24, 3);
        l_result_um       unit_measure.id_unit_measure%TYPE;
        l_relation_domain vital_sign_relation.relation_domain%TYPE := NULL;
        l_id_vs_sum       table_number := table_number();
        l_id_vs_parent    vital_sign_relation.id_vital_sign_parent%TYPE := NULL;
        l_vs_sum          NUMBER := 0;
    BEGIN
    
        BEGIN
            SELECT DISTINCT vsr.relation_domain, vsr.id_vital_sign_parent
              INTO l_relation_domain, l_id_vs_parent
              FROM vital_sign_relation vsr
             WHERE vsr.id_vital_sign_parent IN (SELECT *
                                                  FROM TABLE(i_id_vs));
        EXCEPTION
            WHEN no_data_found THEN
                l_relation_domain := NULL;
                l_id_vs_parent    := NULL;
        END;
    
        IF l_relation_domain IS NULL
           OR l_relation_domain <> 'S'
        THEN
            IF i_flg_parameter = 'MAX'
            THEN
                SELECT *
                  INTO l_result_value, l_result_um
                  FROM (SELECT vsr.value, vsr.id_unit_measure
                          FROM vital_sign_read vsr
                         WHERE vsr.id_episode = i_episode
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                           AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                           AND vsr.id_vital_sign IN (SELECT *
                                                       FROM TABLE(i_id_vs))
                         ORDER BY 1 DESC)
                 WHERE rownum = 1;
            ELSIF i_flg_parameter = pk_sev_scores_constant.g_condition_most_recent
            THEN
                --MOST RECENT RECORD
                SELECT *
                  INTO l_result_value, l_result_um
                  FROM (SELECT vsr.value, vsr.id_unit_measure
                          FROM vital_sign_read vsr
                         WHERE vsr.id_episode = i_episode
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                           AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                           AND vsr.id_vital_sign IN (SELECT *
                                                       FROM TABLE(i_id_vs))
                         ORDER BY vsr.dt_vital_sign_read_tstz DESC)
                 WHERE rownum = 1;
            ELSE
                SELECT *
                  INTO l_result_value, l_result_um
                  FROM (SELECT vsr.value, vsr.id_unit_measure
                          FROM vital_sign_read vsr
                         WHERE vsr.id_episode = i_episode
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                           AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                           AND vsr.id_vital_sign IN (SELECT *
                                                       FROM TABLE(i_id_vs))
                         ORDER BY 1 ASC)
                 WHERE rownum = 1;
            END IF;
        ELSIF l_relation_domain = 'S'
        THEN
            SELECT vsr.id_vital_sign_detail
              BULK COLLECT
              INTO l_id_vs_sum
              FROM vital_sign_relation vsr
             WHERE vsr.id_vital_sign_parent IN (SELECT *
                                                  FROM TABLE(i_id_vs));
        
            IF i_flg_parameter = 'MAX'
            THEN
            
                l_vs_sum := get_vs_desc_result(i_episode       => i_episode,
                                               l_id_vs         => l_id_vs_sum,
                                               l_id_vs_parent  => l_id_vs_parent,
                                               i_flg_parameter => i_flg_parameter,
                                               i_dt_min        => i_dt_min,
                                               i_dt_max        => i_dt_max);
            
                BEGIN
                    SELECT *
                      INTO l_result_value, l_result_um
                      FROM (SELECT vsr.value, vsr.id_unit_measure
                              FROM vital_sign_read vsr
                             WHERE vsr.id_episode = i_episode
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                               AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                               AND vsr.id_vital_sign IN (SELECT *
                                                           FROM TABLE(i_id_vs))
                             ORDER BY 1 DESC)
                     WHERE rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_result_value := NULL;
                        l_result_um    := NULL;
                END;
            
                IF l_result_value < l_vs_sum
                   OR l_result_value IS NULL
                THEN
                    l_result_value := l_vs_sum;
                END IF;
            
            ELSIF i_flg_parameter = 'MIN'
            THEN
            
                l_vs_sum := get_vs_desc_result(i_episode       => i_episode,
                                               l_id_vs         => l_id_vs_sum,
                                               l_id_vs_parent  => l_id_vs_parent,
                                               i_flg_parameter => i_flg_parameter,
                                               i_dt_min        => i_dt_min,
                                               i_dt_max        => i_dt_max);
            
                BEGIN
                    SELECT *
                      INTO l_result_value, l_result_um
                      FROM (SELECT vsr.value, vsr.id_unit_measure
                              FROM vital_sign_read vsr
                             WHERE vsr.id_episode = i_episode
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                               AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                               AND vsr.id_vital_sign IN (SELECT *
                                                           FROM TABLE(i_id_vs))
                             ORDER BY 1 ASC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_result_value := NULL;
                        l_result_um    := NULL;
                END;
            
                IF l_result_value > l_vs_sum
                   OR l_result_value IS NULL
                THEN
                    l_result_value := l_vs_sum;
                END IF;
            
            END IF;
        END IF;
    
        o_result_value := l_result_value;
        o_result_um    := l_result_um;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_result_value := NULL;
            o_result_um    := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            o_result_value := NULL;
            o_result_um    := NULL;
            RETURN FALSE;
        
    END get_vs_result;

    FUNCTION get_vs_result
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_result_value    NUMBER(24, 3);
        l_id_vs           table_number := table_number();
        l_index           INTEGER := NULL;
        l_result          VARCHAR2(100) := NULL;
        l_relation_domain vital_sign_relation.relation_domain%TYPE := NULL;
        l_id_vs_sum       table_number := table_number();
        l_id_vs_parent    vital_sign_relation.id_vital_sign_parent%TYPE := NULL;
        l_vs_sum          NUMBER := 0;
    BEGIN
    
        SELECT mpt.id_param_task
          BULK COLLECT
          INTO l_id_vs
          FROM mtos_param_task mpt
         WHERE mpt.id_mtos_param = i_id_mtos_param
           AND mpt.flg_param_task_type = pk_sev_scores_constant.g_flg_param_task_vital_sign;
    
        BEGIN
            SELECT DISTINCT vsr.relation_domain, vsr.id_vital_sign_parent
              INTO l_relation_domain, l_id_vs_parent
              FROM vital_sign_relation vsr
             WHERE vsr.id_vital_sign_parent IN (SELECT *
                                                  FROM TABLE(l_id_vs));
        EXCEPTION
            WHEN no_data_found THEN
                l_relation_domain := NULL;
                l_id_vs_parent    := NULL;
        END;
    
        IF l_relation_domain IS NULL
           OR l_relation_domain <> 'S'
        THEN
            IF i_flg_parameter = 'MAX'
            THEN
                SELECT *
                  INTO l_result_value
                  FROM (SELECT vsr.value
                          FROM vital_sign_read vsr
                         WHERE vsr.id_episode = i_episode
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                           AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                           AND vsr.id_vital_sign IN (SELECT *
                                                       FROM TABLE(l_id_vs))
                         ORDER BY 1 DESC)
                 WHERE rownum = 1;
            ELSIF i_flg_parameter = 'MIN'
            THEN
                SELECT *
                  INTO l_result_value
                  FROM (SELECT vsr.value
                          FROM vital_sign_read vsr
                         WHERE vsr.id_episode = i_episode
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                           AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                           AND vsr.id_vital_sign IN (SELECT *
                                                       FROM TABLE(l_id_vs))
                         ORDER BY 1 ASC)
                 WHERE rownum = 1;
            
            ELSIF i_flg_parameter = 'L'
            THEN
            
                SELECT mm.multiplier_value
                  INTO l_index
                  FROM mtos_multiplier mm
                 WHERE mm.id_mtos_param = i_id_mtos_param
                   AND mm.flg_param_task_type = 'L';
            
                SELECT VALUE
                  INTO l_result_value
                  FROM (SELECT vsr.value,
                               row_number() over(PARTITION BY vsr.id_patient ORDER BY vsr.dt_vital_sign_read_tstz DESC) AS rn
                          FROM vital_sign_read vsr
                         WHERE vsr.id_episode = i_episode
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                           AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                           AND vsr.id_vital_sign IN (SELECT *
                                                       FROM TABLE(l_id_vs)))
                 WHERE rn = l_index;
            END IF;
        
        ELSIF l_relation_domain = 'S'
        THEN
        
            SELECT vsr.id_vital_sign_detail
              BULK COLLECT
              INTO l_id_vs_sum
              FROM vital_sign_relation vsr
             WHERE vsr.id_vital_sign_parent IN (SELECT *
                                                  FROM TABLE(l_id_vs));
        
            IF i_flg_parameter = 'MAX'
            THEN
            
                l_vs_sum := get_vs_desc_result(i_episode       => i_episode,
                                               l_id_vs         => l_id_vs_sum,
                                               l_id_vs_parent  => l_id_vs_parent,
                                               i_flg_parameter => i_flg_parameter,
                                               i_dt_min        => i_dt_min,
                                               i_dt_max        => i_dt_max);
                BEGIN
                    SELECT *
                      INTO l_result_value
                      FROM (SELECT vsr.value
                              FROM vital_sign_read vsr
                             WHERE vsr.id_episode = i_episode
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                               AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                               AND vsr.id_vital_sign IN (SELECT *
                                                           FROM TABLE(l_id_vs))
                             ORDER BY 1 DESC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_result_value := NULL;
                END;
            
                IF l_result_value < l_vs_sum
                   OR l_result_value IS NULL
                THEN
                    l_result_value := l_vs_sum;
                END IF;
            
            ELSIF i_flg_parameter = 'MIN'
            THEN
            
                l_vs_sum := get_vs_desc_result(i_episode       => i_episode,
                                               l_id_vs         => l_id_vs_sum,
                                               l_id_vs_parent  => l_id_vs_parent,
                                               i_flg_parameter => i_flg_parameter,
                                               i_dt_min        => i_dt_min,
                                               i_dt_max        => i_dt_max);
            
                BEGIN
                    SELECT *
                      INTO l_result_value
                      FROM (SELECT vsr.value
                              FROM vital_sign_read vsr
                             WHERE vsr.id_episode = i_episode
                               AND vsr.flg_state = pk_alert_constant.g_active
                               AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                               AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                               AND vsr.id_vital_sign IN (SELECT *
                                                           FROM TABLE(l_id_vs))
                             ORDER BY 1 ASC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_result_value := NULL;
                END;
            
                IF l_result_value > l_vs_sum
                   OR l_result_value IS NULL
                THEN
                    l_result_value := l_vs_sum;
                END IF;
            
            END IF;
        END IF;
    
        IF l_result_value < 1
           AND l_result_value > 0
        THEN
            l_result := to_char(l_result_value, 'FM9990d999');
        ELSE
            l_result := to_char(l_result_value);
        END IF;
    
        RETURN l_result;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_vs_result;

    FUNCTION get_vs_result_um
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_mtos_param IN mtos_param.id_mtos_param%TYPE,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_unit_measure INTEGER := NULL;
        l_id_vs        table_number := table_number();
        l_index        INTEGER := NULL;
    BEGIN
    
        SELECT mpt.id_param_task
          BULK COLLECT
          INTO l_id_vs
          FROM mtos_param_task mpt
         WHERE mpt.id_mtos_param = i_id_mtos_param
           AND mpt.flg_param_task_type = pk_sev_scores_constant.g_flg_param_task_vital_sign;
    
        IF i_flg_parameter = 'MAX'
        THEN
            SELECT *
              INTO l_unit_measure
              FROM (SELECT vsr.id_unit_measure
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = i_episode
                       AND vsr.flg_state = pk_alert_constant.g_active
                       AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                       AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                       AND vsr.id_vital_sign IN (SELECT *
                                                   FROM TABLE(l_id_vs))
                     ORDER BY 1 DESC)
             WHERE rownum = 1;
        ELSIF i_flg_parameter = 'MIN'
        THEN
            SELECT *
              INTO l_unit_measure
              FROM (SELECT vsr.id_unit_measure
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = i_episode
                       AND vsr.flg_state = pk_alert_constant.g_active
                       AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                       AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                       AND vsr.id_vital_sign IN (SELECT *
                                                   FROM TABLE(l_id_vs))
                     ORDER BY 1 ASC)
             WHERE rownum = 1;
        
        ELSIF i_flg_parameter = 'L'
        THEN
        
            SELECT mm.multiplier_value
              INTO l_index
              FROM mtos_multiplier mm
             WHERE mm.id_mtos_param = i_id_mtos_param
               AND mm.flg_param_task_type = 'L';
        
            SELECT id_unit_measure
              INTO l_unit_measure
              FROM (SELECT vsr.id_unit_measure,
                           row_number() over(PARTITION BY vsr.id_episode ORDER BY vsr.dt_vital_sign_read_tstz DESC) AS rn
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = i_episode
                       AND vsr.flg_state = pk_alert_constant.g_active
                       AND vsr.dt_vital_sign_read_tstz >= i_dt_min
                       AND vsr.dt_vital_sign_read_tstz <= i_dt_max
                       AND vsr.id_vital_sign IN (SELECT *
                                                   FROM TABLE(l_id_vs)))
             WHERE rn = l_index;
        END IF;
    
        RETURN l_unit_measure;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_vs_result_um;

    FUNCTION get_vs_result_count
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_vs         IN table_number,
        i_flg_parameter IN VARCHAR2,
        i_dt_min        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_max        IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN INTEGER IS
        l_count INTEGER := 0;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM vital_sign_read vsr
         WHERE vsr.id_episode = i_episode
           AND vsr.flg_state = pk_alert_constant.g_active
           AND vsr.dt_vital_sign_read_tstz >= i_dt_min
           AND vsr.dt_vital_sign_read_tstz <= i_dt_max
           AND vsr.id_vital_sign IN (SELECT *
                                       FROM TABLE(i_id_vs));
    
        RETURN l_count;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
        
    END get_vs_result_count;

    /**
    * Set BMI vital sign
    *
    * @param i_lang           Language identifier
    * @param i_prof           Logged professional structure
    * @param i_id_episode     Episode id
    * @param i_id_patient     Patient id
    * @param i_id_vital_sign_read     Vital sign read id
    * @param o_error          Error information 
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @raises                PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.5
    * @since                2018-06-18
    */
    FUNCTION set_vs_bmi_auto
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT obj_name := 'SET_VS_BMI_AUTO';
        l_dbg_msg debug_msg;
        l_exception EXCEPTION;
    
        l_vs_bmi_autocomplete sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'VS_BIOMETRIC_BMI_AUTOCOMPLETE',
                                                                               i_prof    => i_prof);
    
        l_vs_count            NUMBER(3, 0);
        l_id_vs_list          table_number;
        l_dt_registry         VARCHAR2(1000 CHAR);
        l_dt_vital_sign_read  vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_vs_value_list       table_number := table_number();
        l_id_um_list          table_number := table_number();
        l_vital_sign_read_out table_number;
        l_save_id_vs          vital_sign_read.id_vital_sign%TYPE;
        l_save_vs_value       vital_sign_read.value%TYPE;
        l_save_id_um          vital_sign_read.id_unit_measure%TYPE;
        l_save_dt_vs_read_str VARCHAR2(100 CHAR);
        l_dt_vs_last          vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        l_vs_bmi_value_ch     VARCHAR(100 CHAR);
    
        l_save_id_vsr        vital_sign_read.id_vital_sign_read%TYPE;
        l_new_id_vs          vital_sign_read.id_vital_sign%TYPE;
        l_id_vital_sign_read vital_sign_read.id_vital_sign_read%TYPE;
        l_vs_value           table_number := table_number();
        l_vs_um              table_number := table_number();
        FUNCTION get_last_vs_date
        (
            i_id_vital_sign IN vital_sign_read.id_vital_sign%TYPE,
            i_dt_max_date   vital_sign_read.dt_vital_sign_read_tstz%TYPE
        ) RETURN vital_sign_read.dt_vital_sign_read_tstz%TYPE IS
            l_value_desc VARCHAR2(200 CHAR);
            l_dt_vs_date vital_sign_read.dt_vital_sign_read_tstz%TYPE;
        BEGIN
            IF NOT get_pat_lst_vsr_value(i_lang               => i_lang,
                                         i_prof               => i_prof,
                                         i_id_vital_sign      => i_id_vital_sign,
                                         i_patient            => i_id_patient,
                                         i_dt_max_reg         => i_dt_max_date,
                                         o_value_desc         => l_value_desc,
                                         o_dt_vital_sign_read => l_dt_vs_date,
                                         o_error              => o_error)
            THEN
                RAISE l_exception;
            END IF;
            RETURN l_dt_vs_date;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END get_last_vs_date;
    BEGIN
        -- Get vital sign date time by specific vital sign record
        l_dbg_msg := 'Call get_vital_sign_date';
        IF NOT get_vital_sign_date(i_lang                    => i_lang,
                                   i_prof                    => i_prof,
                                   i_id_vital_sign_read      => i_id_vital_sign_read,
                                   o_dt_vital_sign_read_tstz => l_dt_vital_sign_read,
                                   o_error                   => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        l_save_dt_vs_read_str := pk_date_utils.date_send_tsz(i_lang, l_dt_vital_sign_read, i_prof);
    
        -- Check if there are weight and height records at the same vs read date time
        SELECT vsr.id_vital_sign, vsr.value, vsr.id_unit_measure
          BULK COLLECT
          INTO l_id_vs_list, l_vs_value, l_vs_um
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign IN (g_vs_weight, g_vs_height)
           AND vsr.flg_state = pk_alert_constant.g_active
           AND vsr.dt_vital_sign_read_tstz = l_dt_vital_sign_read
           AND vsr.id_episode = i_id_episode;
    
        -- Check if VS_BIOMETRIC_BMI_AUTOCOMPLETE = 'Y', it will automatically retrieve the last measurement of the complementary value to calculated BMI
        IF (l_vs_bmi_autocomplete = pk_alert_constant.g_yes AND (l_id_vs_list IS NOT NULL AND l_id_vs_list.count = 1))
        THEN
            IF l_id_vs_list(1) = g_vs_weight
            THEN
                l_save_id_vs := g_vs_height;
                l_new_id_vs  := g_vs_weight;
            ELSIF l_id_vs_list(1) = g_vs_height
            THEN
                l_save_id_vs := g_vs_weight;
                l_new_id_vs  := g_vs_height;
            END IF;
        
            l_dt_vs_last := get_last_vs_date(l_save_id_vs, l_dt_vital_sign_read);
        
            BEGIN
                SELECT aux.value, aux.id_unit_measure, aux.id_vital_sign_read
                  INTO l_save_vs_value, l_save_id_um, l_save_id_vsr
                  FROM (SELECT vsr.value,
                               vsr.id_unit_measure,
                               vsr.id_vital_sign_read,
                               row_number() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.dt_registry DESC NULLS LAST) rn
                          FROM vital_sign_read vsr
                         WHERE vsr.dt_vital_sign_read_tstz = l_dt_vs_last
                           AND vsr.id_vital_sign = l_save_id_vs
                           AND vsr.flg_state = pk_alert_constant.g_active
                           AND vsr.id_patient = i_id_patient) aux
                 WHERE aux.rn = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    RETURN TRUE;
            END;
        ELSIF (l_vs_bmi_autocomplete = pk_alert_constant.g_yes AND
              (l_id_vs_list IS NOT NULL AND l_id_vs_list.count = 2))
        THEN
        
            IF l_id_vs_list(1) = g_vs_weight
            THEN
                l_vs_value_list.extend;
                l_id_um_list.extend;
                l_vs_value_list(1) := l_vs_value(1);
                l_id_um_list(1) := l_vs_um(1);
                l_vs_value_list.extend;
                l_id_um_list.extend;
                l_vs_value_list(2) := l_vs_value(2);
                l_id_um_list(2) := l_vs_um(2);
            ELSIF l_id_vs_list(1) = g_vs_height
            THEN
            
                l_vs_value_list.extend;
                l_id_um_list.extend;
                l_vs_value_list(1) := l_vs_value(2);
                l_id_um_list(1) := l_vs_um(2);
                l_vs_value_list.extend;
                l_id_um_list.extend;
                l_vs_value_list(2) := l_vs_value(1);
                l_id_um_list(2) := l_vs_um(1);
            
            END IF;
        END IF;
    
        IF l_save_id_vs = g_vs_weight
           AND l_id_vs_list.count = 1
        THEN
            l_dbg_msg := 'Call vital_sign_value and id_unit_meature 1';
            SELECT t.value, t.id_unit_measure
              BULK COLLECT
              INTO l_vs_value_list, l_id_um_list
              FROM (SELECT 1 rn1, vsr.value, vsr.id_unit_measure
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign = l_save_id_vs --g_vs_weight
                       AND vsr.flg_state = pk_alert_constant.g_active
                       AND vsr.id_vital_sign_read = l_save_id_vsr
                    UNION ALL
                    SELECT 2 rn1, vsr.value, vsr.id_unit_measure
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign = l_new_id_vs -- g_vs_height
                       AND vsr.id_vital_sign_read = i_id_vital_sign_read
                       AND vsr.flg_state = pk_alert_constant.g_active) t
             ORDER BY t.rn1;
        ELSIF l_save_id_vs = g_vs_height
              AND l_id_vs_list.count = 1
        THEN
            l_dbg_msg := 'Call vital_sign_value and id_unit_meature 2';
        
            SELECT t.value, t.id_unit_measure
              BULK COLLECT
              INTO l_vs_value_list, l_id_um_list
              FROM (SELECT 1 rn1, vsr.value, vsr.id_unit_measure
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign = l_new_id_vs --g_vs_weight
                       AND vsr.flg_state = pk_alert_constant.g_active
                       AND vsr.id_vital_sign_read = i_id_vital_sign_read --l_save_id_vsr
                    UNION ALL
                    SELECT 2 rn1, vsr.value, vsr.id_unit_measure
                      FROM vital_sign_read vsr
                     WHERE vsr.id_vital_sign = l_save_id_vs -- g_vs_height
                       AND vsr.id_vital_sign_read = l_save_id_vsr --i_id_vital_sign_read
                       AND vsr.flg_state = pk_alert_constant.g_active) t
             ORDER BY t.rn1;
        
        END IF;
    
        -- Both weight and height exist, then bmi can be calculated and set into vital sign read table
        IF ((l_vs_value_list.count = 2 AND l_vs_value_list(1) IS NOT NULL AND l_vs_value_list(2) IS NOT NULL) OR
           l_id_vs_list.count = 2)
        THEN
            l_dbg_msg         := 'Call pk_calc.get_bmi';
            l_vs_bmi_value_ch := pk_calc.get_bmi(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_weight    => l_vs_value_list(1),
                                                 i_weight_um => l_id_um_list(1),
                                                 i_height    => l_vs_value_list(2),
                                                 i_height_um => l_id_um_list(2));
        
            IF (pk_utils.is_number(l_vs_bmi_value_ch) = pk_alert_constant.g_yes)
            THEN
                BEGIN
                    l_save_vs_value := l_vs_bmi_value_ch;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_save_vs_value := pk_utils.char_to_number(i_prof, l_vs_bmi_value_ch);
                END;
            ELSE
                l_save_vs_value := NULL;
            END IF;
        
            IF l_save_vs_value IS NOT NULL
            THEN
                l_dbg_msg    := 'Call get_vs_um_inst';
                l_save_id_um := get_vs_um_inst(i_vital_sign  => g_vs_bmi,
                                               i_institution => i_prof.institution,
                                               i_software    => i_prof.software);
            
                l_dbg_msg := 'Call set_epis_vital_sign';
                IF NOT set_epis_vital_sign(i_lang               => i_lang,
                                           i_episode            => i_id_episode,
                                           i_prof               => i_prof,
                                           i_pat                => i_id_patient,
                                           i_vs_id              => table_number(g_vs_bmi),
                                           i_vs_val             => table_number(l_save_vs_value),
                                           i_id_monit           => NULL,
                                           i_unit_meas          => table_number(l_save_id_um),
                                           i_vs_scales_elements => table_number(NULL),
                                           i_notes              => NULL,
                                           i_prof_cat_type      => NULL,
                                           i_dt_vs_read         => table_varchar(l_save_dt_vs_read_str),
                                           i_epis_triage        => NULL,
                                           i_unit_meas_convert  => table_number(NULL),
                                           i_vs_val_high        => table_number(NULL),
                                           i_vs_val_low         => table_number(NULL),
                                           o_vital_sign_read    => l_vital_sign_read_out,
                                           o_dt_registry        => l_dt_registry,
                                           o_error              => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_dbg_msg,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_vs_bmi_auto;

    PROCEDURE get_monit_init_parameters
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
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_procedure_type intervention.flg_type%TYPE;
        l_flg_type       interv_dep_clin_serv.flg_type%TYPE;
        l_flg_filter     VARCHAR2(10 CHAR);
        l_codification   codification.id_codification%TYPE;
        l_permission     VARCHAR2(1 CHAR);
        l_pat_gender     VARCHAR2(5 CHAR);
        l_pat_age        NUMBER;
    
        l_id_dept dept.id_dept%TYPE;
    
        l_confs       PLS_INTEGER;
        l_software    vs_soft_inst.id_software%TYPE := pk_alert_constant.g_soft_all;
        l_institution vs_soft_inst.id_institution%TYPE := pk_alert_constant.g_inst_all;
        l_dt_ini      VARCHAR2(300 CHAR);
        l_dt_end      VARCHAR2(300 CHAR);
        l_error       t_error_out;
    
    BEGIN
    
        IF NOT get_vs_date_limits(i_lang              => l_lang,
                                  i_prof              => l_prof,
                                  i_patient           => NULL,
                                  i_episode           => NULL,
                                  i_id_monitorization => NULL,
                                  o_dt_ini            => l_dt_ini,
                                  o_dt_end            => l_dt_end,
                                  o_error             => l_error)
        THEN
            NULL;
        END IF;
    
        SELECT COUNT(1)
          INTO l_confs
          FROM vs_soft_inst vsi
         INNER JOIN vital_sign vs
            ON vsi.id_vital_sign = vs.id_vital_sign
           AND vs.flg_available = pk_alert_constant.g_yes
         WHERE vsi.id_software = l_prof.software
           AND vsi.id_institution = l_prof.institution
           AND vsi.flg_view = 'V2';
    
        IF l_confs > 0
        THEN
            l_software    := l_prof.software;
            l_institution := l_prof.institution;
        END IF;
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        pk_context_api.set_parameter('l_flg_view', 'V2');
        pk_context_api.set_parameter('l_institution', l_institution);
        pk_context_api.set_parameter('l_software', l_software);
        pk_context_api.set_parameter('l_dt_end', l_dt_end);
        pk_context_api.set_parameter('l_patient', NULL);
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_id := l_lang;
            ELSE
                NULL;
        END CASE;
    
    END get_monit_init_parameters;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_vital_sign;
/
