/*-- Last Change Revision: $Rev: 2026786 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_backoffice_inst_mx IS

    FUNCTION cret_or_updt_inst_by_clues_cat
    (
        i_tbl_id_clues  IN table_number,
        i_override_name IN BOOLEAN DEFAULT FALSE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR cat_clues_cursor(in_id_clues IN alert_adtcod_cfg.clues_inst_mx.id_clues%TYPE) IS
            SELECT DISTINCT cimx.code_clues,
                            cimx.institution_name,
                            cimx.id_rb_reg_class_postal_code  rb_postal_code,
                            rbrc.id_rb_regional_classifier    localidade,
                            rbrcp.id_rb_regional_classifier   municipio,
                            rbrcp.id_rb_regional_class_parent entidade,
                            cimx.inside_number,
                            cimx.outside_number,
                            cimx.email,
                            cimx.phone,
                            cimx.residence
              FROM alert_adtcod_cfg.clues_inst_mx cimx
            /*LEFT JOIN alert_adtcod_cfg.rb_reg_classifier_postal_code rbcp
            ON rbcp.id_rb_regional_classifier = cimx.id_rb_reg_class_postal_code*/
              LEFT JOIN alert_adtcod_cfg.rb_regional_classifier rbrc
                ON rbrc.id_rb_regional_classifier = cimx.id_rb_regional_classifier
              LEFT JOIN alert_adtcod_cfg.rb_regional_classifier rbrcp
                ON rbrcp.id_rb_regional_classifier = rbrc.id_rb_regional_class_parent
              LEFT JOIN alert_adtcod_cfg.settlement_mx sm
                ON sm.id_rb_reg_class_postal_code = cimx.id_rb_reg_class_postal_code
             WHERE cimx.id_clues = in_id_clues;
    
        cat_clues_row      cat_clues_cursor%ROWTYPE;
        l_id_institution   alert_core_data.ab_institution.id_ab_institution%TYPE;
        l_institution_name VARCHAR2(200 CHAR);
    
        l_new_id_institution alert_core_data.ab_institution.id_ab_institution%TYPE;
        l_new_id_inst_attr   inst_attributes.id_inst_attributes%TYPE;
    
    BEGIN
    
        FOR i IN 1 .. i_tbl_id_clues.count
        LOOP
        
            OPEN cat_clues_cursor(i_tbl_id_clues(i));
            FETCH cat_clues_cursor
                INTO cat_clues_row;
            CLOSE cat_clues_cursor;
        
            IF cat_clues_row.code_clues IS NULL
            THEN
                GOTO end_loop;
            END IF;
        
            BEGIN
                SELECT abi.id_ab_institution, abi.description
                  INTO l_id_institution, l_institution_name
                  FROM alert_core_data.ab_institution abi
                 WHERE abi.id_clues = i_tbl_id_clues(i);
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_institution := NULL;
            END;
        
            IF l_id_institution IS NOT NULL
            THEN
            
                IF i_override_name
                THEN
                    l_institution_name := cat_clues_row.institution_name;
                
                    pk_translation.insert_into_translation(i_lang       => 17,
                                                           i_code_trans => 'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                           l_id_institution,
                                                           i_desc_trans => l_institution_name);
                
                END IF;
            
                UPDATE inst_attributes
                   SET outdoor_number = cat_clues_row.outside_number,
                       indoor_number  = cat_clues_row.inside_number,
                       id_entity      = cat_clues_row.entidade,
                       id_municip     = cat_clues_row.municipio,
                       id_localidad   = cat_clues_row.localidade,
                       id_postal_code = cat_clues_row.rb_postal_code,
                       email          = cat_clues_row.email,
                       clues          = cat_clues_row.code_clues
                 WHERE id_institution = l_id_institution;
            
                UPDATE alert_core_data.ab_institution
                   SET phone_number = cat_clues_row.phone,
                       address1     = cat_clues_row.residence,
                       description  = l_institution_name
                 WHERE id_ab_institution = l_id_institution;
            ELSE
            
                SELECT alert_core_data.seq_ab_institution.nextval
                  INTO l_new_id_institution
                  FROM dual;
            
                pk_translation.insert_into_translation(i_lang       => 17,
                                                       i_code_trans => 'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                       l_new_id_institution,
                                                       i_desc_trans => cat_clues_row.institution_name);
            
                INSERT INTO alert_core_data.ab_institution
                    (id_ab_institution,
                     record_status,
                     id_ab_market,
                     code,
                     description,
                     shortname,
                     rb_country_key,
                     /*flg_type,*/
                     code_institution,
                     flg_available,
                     id_timezone_region,
                     address1,
                     phone_number,
                     id_clues)
                VALUES
                    (l_new_id_institution,
                     'A',
                     16,
                     l_new_id_institution,
                     cat_clues_row.institution_name,
                     cat_clues_row.institution_name,
                     484,
                     /*'123',*/
                     'AB_INSTITUTION.CODE_INSTITUTION.' || l_new_id_institution,
                     'Y',
                     334,
                     cat_clues_row.residence,
                     cat_clues_row.phone,
                     i_tbl_id_clues(i));
            
                SELECT seq_inst_attributes.nextval
                  INTO l_new_id_inst_attr
                  FROM dual;
            
                INSERT INTO inst_attributes
                    (id_country,
                     id_institution,
                     id_inst_attributes,
                     outdoor_number,
                     indoor_number,
                     id_entity,
                     id_municip,
                     id_localidad,
                     id_postal_code,
                     email,
                     clues,
                     flg_available)
                VALUES
                    (484,
                     l_new_id_institution,
                     l_new_id_inst_attr,
                     cat_clues_row.outside_number,
                     cat_clues_row.inside_number,
                     cat_clues_row.entidade,
                     cat_clues_row.municipio,
                     cat_clues_row.localidade,
                     cat_clues_row.rb_postal_code,
                     cat_clues_row.email,
                     cat_clues_row.code_clues,
                     'Y');
            
            END IF;
            <<end_loop>>
            NULL;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error create or update institution by clues catalog');
            RETURN FALSE;
    END cret_or_updt_inst_by_clues_cat;

END pk_backoffice_inst_mx;
/
