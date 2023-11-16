/*-- Last Change Revision: $Rev: 2027353 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:58 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_medication_core IS

    ------------------------------ PRIVATE PACKAGE VARIABLES ---------------------------
    g_package_name  VARCHAR2(30);
    g_package_owner VARCHAR2(30);

    /********************************************************************************************
    *  Convert any other drip unit to ml/hr
    *
    * @param    I_VAL_DRIP            Drip value
    * @param    I_UNIT_MEASURE_DRIP   Drip unit measure ID
    *
    * @return   NUMBER: Value of drip converted to "gota" unit measure
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/10/26
    ********************************************************************************************/
    FUNCTION convert2mlhr
    (
        i_val_drip          drug_presc_det.value_drip%TYPE,
        i_unit_measure_drip drug_presc_det.id_unit_measure_drip%TYPE
    ) RETURN drug_presc_det.value_drip%TYPE IS
    BEGIN
        -- if drip unit measure is "gota" then convert
        IF i_unit_measure_drip = 76097
        THEN
            RETURN(i_val_drip / 20) * 60;
            -- if drip unit measure is "microgota" then convert
        ELSIF i_unit_measure_drip = 76098
        THEN
            RETURN(i_val_drip / 60) * 60;
        ELSE
            RETURN(i_val_drip);
        END IF;
    END convert2mlhr;

    FUNCTION get_version_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_type  VARCHAR2(255);
        g_error VARCHAR2(4000);
    
        l_version VARCHAR2(255) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        o_error   VARCHAR2(4000);
    
    BEGIN
    
        --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_VERSION_TYPE: VERSION_TYPE agrupa os mercados de acordo com a sua forma de prescrever. O grupo A contém mercados com 2 bases de dados distintas, sendo uma para a prescrição de medicação interna e outra para a prescrição de medicação externa. O grupo B apresenta apenas uma única base de dados.
        -- Groups were created to divide version according to it´s way of prescribing: 
        -- A, for versions in which prescription is similar to 'PT', such as 'PT', 'BR', etc.
        -- and B, for versions in which prescription is similar to 'USA'.
        g_error := 'Get version type for version: ' || l_version;
        SELECT val -- version_type
          INTO l_type
          FROM sys_domain
         WHERE code_domain = g_prescription_vers_typ
           AND domain_owner = pk_sysdomain.k_default_schema
           AND desc_val = l_version
           AND rownum <= 1;
    
        RETURN l_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20002,
                                    
                                    pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                    'PK_MEDICATION_CORE.GET_VERSION_TYPE / ' || g_error || ' / ' || SQLERRM);
        
            RETURN NULL;
        
    END get_version_type;

    /*******************************************************************************************************************************************
    * Descrição: get medication name descriptive
    * @param I_LANG                   LANGUAGE                                 
    * @param I_PROF                   PROFESSIONAL ARRAY                       
    * @param I_MED                    MEDICATION ID (ID_DRUG, MED_ID or EMB_ID)
    * @param I_SUBJECT                MEDICATION SUBJECT                       
    * @param I_TYPE                   MEDICATION SCREEN: GRID OR OTHER         
    *                                                                          
    *                                                                          
    * @return                         O_NAME                                   
    * @raises                                                                  
    *                                                                          
    * @author                         Patrícia Neto                            
    * @version                         1.0                                     
    * @since                          2008/07/30                               
    *******************************************************************************************************************************************/

    FUNCTION get_medication_name
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_med       IN VARCHAR2,
        i_subject   IN VARCHAR2,
        i_type      IN VARCHAR2, -- GRID_SCREEN, SEARCH_SCREEN, REPORT_SCREEN, SEARCH_REPORT_SCREEN
        i_presc     IN NUMBER DEFAULT NULL,
        i_vers      IN VARCHAR2 DEFAULT NULL,
        i_vers_type IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR IS
        o_name  VARCHAR2(2000);
        g_error VARCHAR2(4000);
    
        l_vers_type VARCHAR2(50);
        l_version   VARCHAR2(50);
    
        CURSOR c_drug IS
            SELECT mi.*, decode(mi.flg_type, 'M', g_local, g_soro) l_subject
              FROM mi_med mi
             WHERE mi.id_drug = i_med
               AND mi.vers = l_version;
    
        r_drug c_drug%ROWTYPE;
    
        CURSOR c_emb IS
            SELECT me.med_name, me.med_descr, me.med_descr_formated, me.dci_descr, me.dosagem
              FROM me_med me
             WHERE me.emb_id = i_med
               AND me.vers = l_version;
    
        r_emb c_emb%ROWTYPE;
    
        CURSOR c_med IS
            SELECT DISTINCT me.med_descr,
                            me.dci_descr,
                            me.short_med_descr,
                            me.form_farm_descr,
                            me.dosagem,
                            me.med_name,
                            nvl(me.generico, pk_alert_constant.g_no) AS generico
              FROM me_med me
             WHERE me.med_id = i_med
               AND me.vers = l_version;
    
        r_med c_med%ROWTYPE;
    
        CURSOR c_other_prod IS
            SELECT op.other_product_desc, op.vers
              FROM other_product op
             WHERE op.id_other_product = i_med
               AND op.vers = l_version;
    
        r_other_prod c_other_prod%ROWTYPE;
    
        CURSOR c_iv_mix_fluid IS
            SELECT dpd.id_drug_presc_det presc_id, mi2.dci_descr med_name
              FROM mi_med mi, drug_presc_det dpd, mi_med mi2, drug_prescription dp, fluids_presc_det fd
             WHERE fd.id_drug_presc_det = i_presc
               AND fd.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpd.id_drug_prescription = dp.id_drug_prescription
               AND dpd.id_drug = mi.id_drug
               AND mi.flg_type = g_flg_new_fluid
               AND mi2.id_drug = fd.id_drug
               AND dpd.vers = mi.vers
               AND mi.vers = mi2.vers
               AND mi.vers = l_version
               AND mi2.vers = l_version
               AND dpd.vers = l_version;
    
    BEGIN
    
        IF i_vers IS NULL
        THEN
        
            l_version := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        
        ELSE
        
            l_version := i_vers;
        
        END IF;
    
        IF i_vers_type IS NULL
        THEN
        
            l_vers_type := pk_medication_core.get_version_type(i_lang, i_prof);
        
        ELSE
        
            l_vers_type := i_vers_type;
        
        END IF;
    
        IF i_subject IN (g_local, g_relatos_int, g_hospital, g_soro)
        THEN
        
            g_error := 'INTERNAL SUBJECT FETCH C_DRUG';
            OPEN c_drug;
            FETCH c_drug
                INTO r_drug;
            CLOSE c_drug;
        
            CASE i_type
            
                WHEN g_grid_screen THEN
                
                    BEGIN
                    
                        IF i_subject = g_hospital
                           AND l_vers_type <> g_vers_type_a
                        THEN
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação os medicamentos internos prescritos pertencentes ao grupo B de base de dados devem ser apresentados da seguinte forma: principio activo/nome do medicamento + dosagem + forma farmacêutica.
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - OTHER THEN PT VERSION';
                            o_name  := r_drug.dci_descr || ' / ' || r_drug.med_descr;
                        
                        ELSIF r_drug.l_subject = g_soro
                              AND r_drug.flg_type = g_flg_new_freq
                        THEN
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação os soros mais frequentemente construidos prescritos devem ser apresentados da seguinte forma: nome do medicamento + dosagem + forma farmacêutica.
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - PT VERSION';
                            o_name  := r_drug.med_descr;
                        
                        ELSIF r_drug.l_subject = g_soro
                              AND r_drug.flg_type = g_flg_new_fluid -- N construidos
                        THEN
                        
                            g_error := 'INTERNAL SUBJECT GRID_ALERTS TYPE - IV FLUIDS  N';
                            FOR i IN c_iv_mix_fluid
                            LOOP
                                o_name := o_name || '+ ' || i.med_name;
                            
                            END LOOP;
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação especificas dos warnings os soros construídos prescritos devem ser apresentados como a soma dos princípios activos dos vários medicamentos.              
                            o_name := substr(o_name, instr(o_name, '+', 1) + 2);
                        
                        ELSE
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação os medicamentos prescritos devem ser apresentados da seguinte forma: princípio activo. 
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - PT VERSION';
                            o_name  := r_drug.med_descr;
                        
                        END IF;
                    
                    END;
                
                WHEN g_chnm_screen THEN
                
                    BEGIN
                    
                        IF i_subject = g_hospital
                           AND l_vers_type <> g_vers_type_a
                        --l_version NOT IN ('PT', 'BR', 'SG') --g_pt
                        THEN
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação especificas do mercado PT os medicamentos internos prescritos pertencentes ao grupo B de base de dados devem ser apresentados da seguinte forma: principio activo/nome do medicamento + dosagem + forma farmacêutica.
                            g_error := 'INTERNAL SUBJECT CHNM_SCREEN TYPE - OTHER THEN PT VERSION';
                            o_name  := r_drug.dci_descr || ' / ' || r_drug.med_descr;
                        
                        ELSE
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação especificas do mercado PT os medicamentos internos prescritos devem ser apresentados da seguinte forma: nome do medicamento + dosagem + forma farmacêutica.                        
                            g_error := 'INTERNAL SUBJECT CHNM_SCREEN TYPE - PT VERSION';
                            o_name  := r_drug.med_descr_formated;
                        
                        END IF;
                    
                    END;
                
                WHEN g_alerts_screen THEN
                    -- PARA OS ECRÃS DE ALERTA DE INTERACÇÕES E CONTRAINDICAÇÕES
                    BEGIN
                    
                        IF i_subject = g_hospital
                           OR (l_vers_type <> g_vers_type_a
                           --l_version NOT IN ('PT', 'BR', 'SG') --g_pt
                           AND r_drug.flg_type NOT IN (g_flg_new_fluid, g_flg_new_freq))
                        THEN
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação especificas dos warnings os medicamentos internos prescritos pertencentes ao grupo B de base de dados devem ser apresentados da seguinte forma: principio activo/nome do medicamento + dosagem + forma farmacêutica.                        
                            g_error := 'INTERNAL SUBJECT GRID_ALERTS TYPE - OTHER THEN PT VERSION AND IV FLUIDS C AND N';
                            o_name  := r_drug.dci_descr || ' / ' || r_drug.med_descr;
                        
                        ELSIF r_drug.l_subject = g_soro
                              AND r_drug.flg_type = g_flg_new_freq -- 'C'
                        THEN
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação especificas dos warnings os soros mais frequentemente construídos prescritos devem ser apresentados da seguinte forma: nome do medicamento + dosagem + forma farmacêutica.                        
                            g_error := 'INTERNAL SUBJECT GRID_ALERTS TYPE - IV FLUIDS  C';
                            pk_alertlog.log_debug(g_error);
                            o_name := r_drug.med_descr;
                        
                        ELSIF r_drug.flg_type = g_flg_new_fluid -- N construidos
                        THEN
                        
                            g_error := 'INTERNAL SUBJECT GRID_ALERTS TYPE - IV FLUIDS  N';
                            FOR i IN c_iv_mix_fluid
                            LOOP
                                o_name := o_name || '+ ' || i.med_name;
                            
                            END LOOP;
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação especificas dos warnings os soros construídos prescritos devem ser apresentados como a soma dos princípios activos dos vários medicamentos.              
                            o_name := substr(o_name, instr(o_name, '+', 1) + 2);
                        
                        ELSE
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas de medicação especificas dos warnings os medicamentos internos devem ser apresentados da seguinte forma: principio activo.            
                            o_name := r_drug.dci_descr;
                        
                        END IF;
                    
                    END;
                
                ELSE
                    -- 'SEARCH_SCREEN, REPORT_SCREEN, SEARCH_REPORT_SCREEN
                    BEGIN
                    
                        IF r_drug.flg_type = g_flg_new_freq
                        THEN
                        
                            g_error := 'INTERNAL SUBJECT SEARCH_SCREEN TYPE - PT VERSION';
                            o_name  := r_drug.med_descr;
                        
                        ELSE
                        
                            IF l_vers_type = g_vers_type_a
                            --l_version IN ('PT', 'BR', 'SG') --g_pt
                            THEN
                            
                                IF i_subject = g_relatos_int
                                THEN
                                
                                    --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Para todos os restantes ecrãs os relatos de medicação interna prescritos pertencentes devem ser apresentados da seguinte forma: nome do medicamento + dosagem + forma farmacêutica + via de administração.                        
                                    g_error := 'INTERNAL SUBJECT REPORT_SCREEN TYPE - PT VERSION';
                                    o_name  := r_drug.med_descr || ' (' || r_drug.route_descr || ')';
                                
                                ELSE
                                
                                    IF r_drug.l_subject = g_soro
                                       AND r_drug.flg_type = g_flg_new_fluid -- N construidos
                                    THEN
                                    
                                        g_error := 'INTERNAL SUBJECT GRID_ALERTS TYPE - IV FLUIDS  N';
                                        FOR i IN c_iv_mix_fluid
                                        LOOP
                                            o_name := o_name || '+ ' || i.med_name;
                                        
                                        END LOOP;
                                    
                                        o_name := substr(o_name, instr(o_name, '+', 1) + 2);
                                    ELSE
                                        g_error := 'INTERNAL SUBJECT SEARCH_SCREEN TYPE - PT VERSION';
                                        o_name  := r_drug.med_descr;
                                    END IF;
                                
                                END IF;
                            
                            ELSE
                            
                                IF i_subject = g_relatos_int --Include route in reported medication search
                                THEN
                                
                                    --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Para todos os restantes ecrãs os relatos de medicação interna prescritos pertencentes devem ser apresentados da seguinte forma: nome do medicamento + dosagem + forma farmacêutica + via de administração.                        
                                    g_error := 'INTERNAL SUBJECT SEARCH_SCREEN TYPE - PT VERSION';
                                    o_name  := r_drug.dci_descr || ' / ' || r_drug.med_descr || ' (' ||
                                               r_drug.route_descr || ')';
                                
                                ELSE
                                
                                    IF r_drug.l_subject = g_soro
                                       AND r_drug.flg_type = g_flg_new_fluid -- N construidos
                                    THEN
                                    
                                        g_error := 'INTERNAL SUBJECT SEARCH_SCREEN TYPE - IV FLUIDS  N';
                                        FOR i IN c_iv_mix_fluid
                                        LOOP
                                            o_name := o_name || '+ ' || i.med_name;
                                        
                                        END LOOP;
                                    
                                        o_name := substr(o_name, instr(o_name, '+', 1) + 2);
                                    ELSE
                                    
                                        g_error := 'INTERNAL SUBJECT SEARCH_SCREEN TYPE - OTHER THEN PT VERSION';
                                        o_name  := r_drug.dci_descr || ' / ' || r_drug.med_descr;
                                    
                                    END IF;
                                END IF;
                            END IF;
                        END IF;
                    END;
            END CASE;
        
        ELSIF i_subject IN (g_exterior, g_exterior_chronic, g_exterior_report)
        THEN
        
            g_error := 'EXTERNAL SUBJECT FETCH C_MED';
            OPEN c_emb;
            FETCH c_emb
                INTO r_emb;
            CLOSE c_emb;
        
            CASE i_type
            
                WHEN 'GRID_SCREEN' THEN
                
                    BEGIN
                    
                        IF l_vers_type = g_vers_type_a
                        --l_version IN ('PT', 'BR', 'SG') --g_pt
                        THEN
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Em todos os ecrãs os medicamentos externos pertencentes ao grupo A prescritos devem ser apresentados da seguinte forma: principio activo/nome de marca.                                   
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - PT VERSION';
                            IF r_emb.med_name IS NOT NULL
                            THEN
                                o_name := r_emb.dci_descr || ' / ' || r_emb.med_name;
                            ELSE
                                o_name := r_emb.dci_descr;
                            END IF;
                        
                        ELSE
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Em todos os restantes ecrãs os medicamentos externos prescritos devem ser apresentados da seguinte forma: principio activo/nome do medicamento + dosagem + forma farmacêutica.                           
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - OTHER THEN PT VERSION';
                            o_name  := r_emb.dci_descr || ' / ' || r_emb.med_descr;
                        
                        END IF;
                    
                    END;
                
                WHEN g_alerts_screen THEN
                    -- PARA OS ECRÃS DE ALERTA DE INTERACÇÕES E CONTRAINDICAÇÕES
                    BEGIN
                    
                        IF l_vers_type = g_vers_type_a
                        --l_version IN ('PT', 'BR', 'SG') --g_pt
                        THEN
                        
                            g_error := 'INTERNAL SUBJECT g_alerts_screen TYPE - PT VERSION';
                            o_name  := r_emb.dci_descr || ' / ' || r_emb.med_name;
                        
                        ELSE
                        
                            g_error := 'INTERNAL SUBJECT g_alerts_screen TYPE - OTHER THEN PT VERSION';
                            o_name  := r_emb.dci_descr || ' / ' || r_emb.med_descr;
                        
                        END IF;
                    
                    END;
                ELSE
                
                    BEGIN
                    
                        IF l_vers_type = g_vers_type_a
                        --l_version IN ('PT', 'BR', 'SG') --g_pt
                        THEN
                        
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - PT VERSION';
                            o_name  := r_emb.med_descr;
                        
                        ELSE
                        
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - OTHER THEN PT VERSION';
                            SELECT decode(r_emb.dci_descr,
                                          NULL,
                                          r_emb.med_descr,
                                          r_emb.dci_descr || ' / ' || r_emb.med_descr)
                              INTO o_name
                              FROM dual;
                        
                        END IF;
                    
                    END;
                
            END CASE;
        
        ELSIF i_subject = g_relatos_ext
        THEN
        
            g_error := 'EXTERNAL REPORTED SUBJECT FETCH C_MED';
            OPEN c_med;
            FETCH c_med
                INTO r_med;
            CLOSE c_med;
        
            CASE i_type
            
                WHEN 'GRID_SCREEN' THEN
                
                    BEGIN
                    
                        IF l_vers_type = g_vers_type_a
                        --l_version IN ('PT', 'BR', 'SG') --g_pt
                        THEN
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas da medicação os relatos de medicamentos externos pertencentes ao grupo A prescritos devem ser apresentados da seguinte forma: principio activo/nome de marca.                                   
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - PT VERSION';
                            o_name  := r_med.dci_descr || ' / ' || r_med.med_name;
                        
                        ELSE
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Nas grelhas da medicação os medicamentos externos prescritos devem ser apresentados da seguinte forma: principio activo/nome do medicamento + dosagem + forma farmacêutica.                           
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - OTHER THEN PT VERSION';
                            o_name  := r_med.dci_descr || ' / ' || r_med.med_descr;
                        
                        END IF;
                    
                    END;
                
                ELSE
                
                    BEGIN
                    
                        IF l_vers_type = g_vers_type_a
                        --l_version IN ('PT', 'BR', 'SG') --g_pt
                        THEN
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Em todos os ecrãs os relatos de medicamentos externos pertencentes ao grupo A prescritos devem ser apresentados da seguinte forma: principio activo + nome de marca + dosagem + forma farmacêutica.                                   
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - PT VERSION';
                        
                            IF r_med.generico = pk_alert_constant.get_no
                            THEN
                                o_name := TRIM(r_med.dci_descr) || ' / ' ||
                                          TRIM(r_med.med_name || ' ' || r_med.dosagem) || ' / ' ||
                                          TRIM(r_med.form_farm_descr);
                            ELSE
                                o_name := TRIM(r_med.dci_descr) || ' / ' || TRIM(r_med.dosagem) || ' / ' ||
                                          TRIM(r_med.form_farm_descr);
                            END IF;
                        ELSE
                        
                            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Em todos os restantes ecrãs os medicamentos externos prescritos devem ser apresentados da seguinte forma: principio activo/nome do medicamento + dosagem + forma farmacêutica.                           
                            g_error := 'INTERNAL SUBJECT GRID_SCREEN TYPE - OTHER THEN PT VERSION';
                            o_name  := r_med.dci_descr || ' / ' || r_med.med_descr;
                        
                        END IF;
                    
                    END;
                
            END CASE;
        
        ELSIF i_subject = g_other_prod
        THEN
        
            g_error := 'OTHER PRODUCTS SUBJECT FETCH c_other_prod';
            OPEN c_other_prod;
            FETCH c_other_prod
                INTO r_other_prod;
            CLOSE c_other_prod;
        
            --[MEDICATION_RULE] PK_MEDICATION_CORE.GET_MEDICATION_NAME: Em todos os ecrãs os outros produtos prescritos devem ser apresentados com o descritivo completo.                                  
            o_name := r_other_prod.other_product_desc;
        
        ELSE
        
            NULL;
        
        END IF; -- i_subject
        o_name := REPLACE(TRIM(o_name), '/  /', '/');
        IF substr(o_name, 1, 1) = '/'
        THEN
            o_name := substr(o_name, 2);
        END IF;
        IF substr(o_name, -1) = '/'
        THEN
            o_name := substr(o_name, 1, length(o_name) - 1);
        END IF;
        RETURN o_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20002,
                                    pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                    'PK_MEDICATION_CORE.GET_MEDICATION_NAME / ' || g_error || ' / ' || SQLERRM);
        
            RETURN NULL;
        
    END get_medication_name;
   --
    /*******************************************************************************************************************************************
    *  Create new drugs                                                                                                   
    *                                                                                                                     
    * @param I_LANG                   LANGUAGE                                                                            
    * @param I_PROF                   PROFESSIONAL ARRAY                                                                  
    * @param I_DRUG_DESCR             MEDICATION DESCR                                                                    
    * @param I_CHNM                   CHNM ID                                                                             
    * @param I_FLG_TYPE               'M' FOR MEDICATION, 'F' FOR IV-FLUIDS                                               
    * @param I_FLG_MIX_FLUID          Y, FOR DRUGS TO BE ADDED TO IV-FLUIDS                                               
    * @param I_FLG_JUSTIFY            FLAG MED JUSTIFICATION: 'Y' IF IT NEED JUSTIFICATION WHEN PRESCRIBED, 'N' OTHERWISE 
    * @param I_DCI_ID                 ACTIVE INGREDIENT(S) ID                                                             
    * @param I_DCI_DESCR              ACTIVE INGREDIENT(S) DESCRIPTIVE                                                    
    * @param I_DOSAGE                 MEDICATION DOSAGE                                                                   
    * @param I_FORM_FARM_ID           FORM ID                                                                             
    * @param I_FORM_FARM_DESCR        FORM DESCR                                                                          
    * @param I_FORM_FARM_ABRV         FORM ABBREVIATION                                                                   
    * @param I_ROUTE_ID               ROUTE ID                                                                            
    * @param I_ROUTE_DESCR            ROUTE DESCRIPTIVE                                                                   
    * @param I_ROUTE_ABRV             ROUTE ABBREVIATION                                                                  
    * @param I_QT_DOS_COMP            BASIS QUANTITY FOR PT AND PACKAGE SIZE FOR USA                                      
    * @param I_ID_UNIT_DOS_COMP       MEDICATION UNIT MEASURE ID                                                          
    * @param I_COMMIT                 Y, FOR COMMIT, N, OTHERWI SE                                                        
    *                                                                                                                     
    * @param  o_max_group_id          PHARMACOLOGICAL GROUP CREATED                                                       
    * @return                         BOOLEAN                                                                             
    *                                                                                                                     
    * @raises                                                                                                             
    *                                                                                                                     
    * @author                         Patrícia Neto                                                                       
    * @version                         1.0                                                                                
    * @since                          2008/05/28                                                                          
    *                                                                                                                     
    *                                                                                                                     
    * @modified                      PN, 2008/10/14
    *******************************************************************************************************************************************/
    FUNCTION create_medication
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_drug_descr       IN mi_med.med_descr%TYPE,
        i_chnm             IN mi_med.chnm_id%TYPE,
        i_flg_type         IN mi_med.flg_type%TYPE,
        i_flg_mix_fluid    IN mi_med.flg_mix_fluid%TYPE,
        i_flg_justify      IN mi_med.flg_justify%TYPE,
        i_dci_id           IN mi_med.dci_id%TYPE,
        i_dci_descr        IN mi_med.dci_descr%TYPE,
        i_dosage           IN mi_med.dosagem%TYPE,
        i_form_farm_id     IN mi_med.form_farm_id%TYPE,
        i_form_farm_descr  IN mi_med.form_farm_descr%TYPE,
        i_form_farm_abrv   IN mi_med.form_farm_abrv%TYPE,
        i_route_id         IN mi_med.route_id%TYPE,
        i_route_descr      IN mi_med.route_descr%TYPE,
        i_route_abrv       IN mi_med.route_abrv%TYPE,
        i_qt_dos_comp      IN mi_med.qt_dos_comp%TYPE,
        i_id_unit_dos_comp IN unit_measure.id_unit_measure%TYPE,
        i_commit           IN VARCHAR2 DEFAULT NULL,
        o_id_medication    OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_notfound BOOLEAN;
        l_version  mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_unit_measure(l_unit_measure unit_measure.id_unit_measure%TYPE) IS
            SELECT id_unit_measure
              FROM unit_measure
             WHERE id_unit_measure_type = 1015
               AND id_unit_measure = l_unit_measure;
    
        r_unit_measure c_unit_measure%ROWTYPE;
    
    BEGIN
    
        g_error := 'Fetch c_unit_measure(' || i_id_unit_dos_comp || ')';
        pk_alertlog.log_debug(g_error);
        OPEN c_unit_measure(i_id_unit_dos_comp);
        FETCH c_unit_measure
            INTO r_unit_measure;
        l_notfound := c_unit_measure%NOTFOUND;
        CLOSE c_unit_measure;
    
        IF l_notfound
        THEN
        
            g_error := 'Attention: ' || i_id_unit_dos_comp || ' does not exist';
            pk_alertlog.log_debug(g_error);
            RAISE unexpected_error;
            RETURN NULL;
        
        END IF;
    
        --[MEDICATION_RULE] (10-09-09) PK_MEDICATION_CORE.CREATE_MESICATION Um novo medicamento pode ser criado tendo como campos obrigatórios de preenchimento o principio activo, a dosagem, a forma farmacêutica, a via de administração e unidade de medida de prescrição.
        g_error := 'Validate input parameteres';
        pk_alertlog.log_debug(g_error);
        IF i_drug_descr IS NOT NULL
           AND i_dci_id IS NOT NULL
           AND i_dci_descr IS NOT NULL
           AND i_dosage IS NOT NULL
           AND i_form_farm_id IS NOT NULL
           AND i_form_farm_descr IS NOT NULL
           AND i_form_farm_abrv IS NOT NULL
           AND i_route_id IS NOT NULL
           AND i_route_descr IS NOT NULL
           AND i_route_abrv IS NOT NULL
           AND i_qt_dos_comp IS NOT NULL
           AND i_id_unit_dos_comp IS NOT NULL
        THEN
        
            IF NOT create_medication_ins(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_drug_descr       => i_drug_descr,
                                         i_chnm             => i_chnm,
                                         i_flg_type         => i_flg_type,
                                         i_flg_mix_fluid    => i_flg_mix_fluid,
                                         i_flg_justify      => i_flg_justify,
                                         i_dci_id           => i_dci_id,
                                         i_dci_descr        => i_dci_descr,
                                         i_dosage           => i_dosage,
                                         i_form_farm_id     => i_form_farm_id,
                                         i_form_farm_descr  => i_form_farm_descr,
                                         i_form_farm_abrv   => i_form_farm_abrv,
                                         i_route_id         => i_route_id,
                                         i_route_descr      => i_route_descr,
                                         i_route_abrv       => i_route_abrv,
                                         i_qt_dos_comp      => i_qt_dos_comp,
                                         i_id_unit_dos_comp => i_id_unit_dos_comp,
                                         i_commit           => i_commit,
                                         o_id_medication    => o_id_medication,
                                         o_error            => o_error)
            THEN
                raise_application_error(-20001, 'ERROR CREATING NEW MEDICATION');
            END IF;
        
        ELSE
        
            g_error := 'Please input obligatory parameters.';
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        
        END IF;
    
        IF i_commit IS NULL
           OR i_commit = g_yes
        THEN
            g_error := 'Commit transaction';
            pk_alertlog.log_debug(g_error);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'create_medication',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_medication;

    /*******************************************************************************************************************************************
    *  Update drugs                                                                                                                            *
    *                                                                                                                                          *
    * @param I_LANG                   LANGUAGE                                                                                                 *
    * @param I_PROF                   PROFESSIONAL ARRAY                                                                                       *
    * @param I_DRUG                   MEDICATION ID                                                                                       *
    * @param i_drug_descr             MEDICATION DESCR                                                                                         *
    * @param I_CHNM                   CHNM ID                                                                                                  *
    * @param i_flg_type               'M' FOR MEDICATION, 'F' FOR IV-FLUIDS                                                                    *
    * @param i_flg_mix_fluid          Y, FOR DRUGS TO BE ADDED TO IV-FLUIDS                                                                    *
    * @param i_med_flg_available      Y, FOR AVAILABLE MEDICATION, N, OTHERWISE                                                                *
    * @param i_flg_justify            FLAG MED JUSTIFICATION: 'Y' IF IT NEED JUSTIFICATION WHEN PRESCRIBED, 'N' OTHERWISE                      *
    * @param i_dci_id                 ACTIVE INGREDIENT(S) ID                                                                                  *
    * @param i_dci_descr              ACTIVE INGREDIENT(S) DESCRIPTIVE                                                                         *
    * @param I_DOSAGE                 MEDICATION DOSAGE                                                                                        *
    * @param i_form_farm_id           FORM ID                                                                                                  *
    * @param i_form_farm_descr        FORM DESCR                                                                                               *
    * @param i_form_farm_abrv         FORM ABBREVIATION                                                                                        *
    * @param i_route_id               ROUTE ID                                                                                                 *
    * @param i_route_descr            ROUTE DESCRIPTIVE                                                                                        *
    * @param i_route_abrv             ROUTE ABBREVIATION                                                                                       *
    * @param i_qt_dos_comp            BASIS QUANTITY FOR PT AND PACKAGE SIZE FOR USA                                                           *
    * @param i_id_unit_dos_comp       MEDICATION UNIT MEASURE ID                                                                               *
    * @param i_commit                 Y, FOR COMMIT, N, OTHERWISE                                                                              *
    *                                                                                                                                          *
    * @return                         BOOLEAN                                                                                                  *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Patrícia Neto                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/05/28                                                                                               *
    *                                                                                                                                          *
    ********************************************************************************************************************************************/
    FUNCTION upd_medication
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_drug              IN mi_med.id_drug%TYPE,
        i_drug_descr        IN mi_med.med_descr%TYPE DEFAULT NULL,
        i_chnm              IN mi_med.chnm_id%TYPE DEFAULT NULL,
        i_flg_type          IN mi_med.flg_type%TYPE DEFAULT NULL,
        i_flg_mix_fluid     IN mi_med.flg_mix_fluid%TYPE DEFAULT NULL,
        i_med_flg_available IN mi_med.flg_available%TYPE DEFAULT NULL,
        i_flg_justify       IN mi_med.flg_justify%TYPE DEFAULT NULL,
        i_dci_id            IN mi_med.dci_id%TYPE DEFAULT NULL,
        i_dci_descr         IN mi_med.dci_descr%TYPE DEFAULT NULL,
        i_dosage            IN mi_med.dosagem%TYPE DEFAULT NULL,
        i_form_farm_id      IN mi_med.form_farm_id%TYPE DEFAULT NULL,
        i_form_farm_descr   IN mi_med.form_farm_descr%TYPE DEFAULT NULL,
        i_form_farm_abrv    IN mi_med.form_farm_abrv%TYPE DEFAULT NULL,
        i_route_id          IN mi_med.route_id%TYPE DEFAULT NULL,
        i_route_descr       IN mi_med.route_descr%TYPE DEFAULT NULL,
        i_route_abrv        IN mi_med.route_abrv%TYPE DEFAULT NULL,
        i_qt_dos_comp       IN mi_med.qt_dos_comp%TYPE DEFAULT NULL,
        i_id_unit_dos_comp  IN unit_measure.id_unit_measure%TYPE DEFAULT NULL,
        i_commit            IN VARCHAR2 DEFAULT NULL,
        o_info_iv_fluid     OUT pk_types.cursor_type,
        o_info_thp_protocol OUT pk_types.cursor_type,
        o_id_medication     OUT mi_med.id_drug%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_max_drug_id NUMBER;
        l_unit_descr  VARCHAR2(255);
        l_found       BOOLEAN;
        l_version     mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        --added
        l_id_drug_master VARCHAR(255);
        l_flg_available  mi_med.flg_available%TYPE;
        l_found_mix      BOOLEAN;
    
        l_prof_ddcs profissional;
    
        l_mipg_group_id table_varchar;
    
        CURSOR c_iddrug(l_drug VARCHAR2) IS
            SELECT *
              FROM mi_med
             WHERE id_drug = l_drug
               AND vers = l_version;
    
        l_iddrug c_iddrug%ROWTYPE;
    
        CURSOR c_unit_measure(l_unit_measure unit_measure.id_unit_measure%TYPE) IS
            SELECT id_unit_measure
              FROM unit_measure
             WHERE id_unit_measure_type = 1015
               AND id_unit_measure = l_unit_measure;
    
        r_unit_measure c_unit_measure%ROWTYPE;
    
        CURSOR c_protocols IS
            SELECT dtp.id_drug, tp.flg_available
              FROM drug_therapeutic_protocols dtp, therapeutic_protocols tp
             WHERE dtp.id_drug = i_drug
               AND dtp.id_therapeutic_protocols = tp.id_therapeutic_protocols;
    
        r_protocols c_protocols%ROWTYPE;
    
        CURSOR c_drug_dep_clin_serv(l_drug VARCHAR2) IS
            SELECT *
              FROM drug_dep_clin_serv ddcs
             WHERE id_drug = l_drug
               AND vers = l_version;
    
        l_ddcs c_drug_dep_clin_serv%ROWTYPE;
    
    BEGIN
    
        IF i_id_unit_dos_comp IS NOT NULL
        THEN
        
            g_error := 'Fetch c_unit_measure(' || i_id_unit_dos_comp || ')';
            pk_alertlog.log_debug(g_error);
            OPEN c_unit_measure(i_id_unit_dos_comp);
            FETCH c_unit_measure
                INTO r_unit_measure;
            l_found := c_unit_measure%NOTFOUND;
            CLOSE c_unit_measure;
        
            IF l_found
            THEN
            
                g_error := 'Attention: ' || i_id_unit_dos_comp || ' does not exist';
                pk_alertlog.log_debug(g_error);
                RAISE unexpected_error;
                RETURN FALSE;
            
            END IF;
        
        END IF;
    
        g_error := 'Fetch c_iddrug(' || i_drug || ')';
        pk_alertlog.log_debug(g_error);
        OPEN c_iddrug(i_drug);
        FETCH c_iddrug
            INTO l_iddrug;
        l_found := c_iddrug%FOUND;
        CLOSE c_iddrug;
    
        IF l_found
        THEN
        
            g_error := 'UPDATE MI_MED for id_drug = ' || i_drug;
            pk_alertlog.log_error(g_error);
            --Only invalidate the drug - make it not available
            --create a new medication even if it's a deactivation. The update is to invalidate the previous            
            g_error := 'CREATE NEW MI_MED based on id_drug = ' || i_drug;
            pk_alertlog.log_error(g_error);
            IF NOT create_medication_ins(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_drug_descr        => nvl(i_drug_descr, l_iddrug.med_descr),
                                         i_chnm              => nvl(i_chnm, l_iddrug.chnm_id),
                                         i_flg_type          => nvl(i_flg_type, l_iddrug.flg_type),
                                         i_flg_mix_fluid     => nvl(i_flg_mix_fluid, l_iddrug.flg_mix_fluid),
                                         i_flg_justify       => nvl(i_flg_justify, l_iddrug.flg_justify),
                                         i_dci_id            => nvl(i_dci_id, l_iddrug.dci_id),
                                         i_dci_descr         => nvl(i_dci_descr, l_iddrug.dci_descr),
                                         i_dosage            => nvl(i_dosage, l_iddrug.dosagem),
                                         i_form_farm_id      => nvl(i_form_farm_id, l_iddrug.form_farm_id),
                                         i_form_farm_descr   => nvl(i_form_farm_descr, l_iddrug.form_farm_descr),
                                         i_form_farm_abrv    => nvl(i_form_farm_abrv, l_iddrug.form_farm_abrv),
                                         i_route_id          => nvl(i_route_id, l_iddrug.route_id),
                                         i_route_descr       => nvl(i_route_descr, l_iddrug.route_descr),
                                         i_route_abrv        => nvl(i_route_abrv, l_iddrug.route_abrv),
                                         i_qt_dos_comp       => nvl(i_qt_dos_comp, l_iddrug.qt_dos_comp),
                                         i_id_unit_dos_comp  => nvl(i_id_unit_dos_comp, r_unit_measure.id_unit_measure), -- l_iddrug.unit_dos_comp),
                                         i_commit            => i_commit,
                                         i_id_drug_replicat  => i_drug, --ID drug replication
                                         i_med_flg_available => i_med_flg_available, --If the change is for disabling medication
                                         o_id_medication     => o_id_medication,
                                         o_error             => o_error)
            THEN
                raise_application_error(-20001, 'ERROR CREATING NEW MEDICATION');
            END IF;
        
            --creation of alternative unit measures is made also in create_medication_inst based on i_id_drug_replicat parameter
        
            g_error := 'DEACTIVATE MI_MED for id_drug = ' || i_drug;
            pk_alertlog.log_error(g_error);
            UPDATE mi_med mi
               SET flg_available = g_no
             WHERE mi.id_drug = i_drug
               AND mi.vers = l_version;
        
            g_error := 'Create drug_dep_clin_serv records for newly created medication';
            FOR l_ddcs IN c_drug_dep_clin_serv(i_drug)
            LOOP
                --Fill professional structure of the ddcs - set_drug_dcs uses the i_prof IN param to insert data
                l_prof_ddcs := profissional(i_prof.id, l_ddcs.id_institution, l_ddcs.id_software);
                IF NOT set_drug_dcs(i_lang              => i_lang,
                                    i_prof              => l_prof_ddcs,
                                    i_id_drug           => o_id_medication,
                                    i_id_dep_clin_serv  => l_ddcs.id_dep_clin_serv,
                                    i_flg_type          => l_ddcs.flg_type,
                                    i_flg_take_type     => l_ddcs.flg_take_type,
                                    i_takes             => l_ddcs.takes,
                                    i_interval          => l_ddcs.interval,
                                    i_dosage            => l_ddcs.dosage,
                                    i_qty               => l_ddcs.qty_inst,
                                    i_duration          => l_ddcs.duration,
                                    i_unit_measure_inst => l_ddcs.unit_measure_inst,
                                    i_unit_measure_freq => l_ddcs.unit_measure_freq,
                                    i_unit_measure_dur  => l_ddcs.unit_measure_dur,
                                    i_commit            => pk_alert_constant.g_no,
                                    o_error             => o_error)
                THEN
                    raise_application_error(-20001, 'ERROR CREATING NEW DDCS');
                END IF;
            
            END LOOP;
        
            --Association is changed to the new product created
            --UPDATE drug_dep_clin_serv ddcs
            --   SET ddcs.id_drug = o_id_medication
            -- WHERE ddcs.id_drug = i_drug
            --   AND ddcs.vers = l_version;
        
            --Create pharm_group
            SELECT mipg.group_id
              BULK COLLECT
              INTO l_mipg_group_id
              FROM mi_med_pharm_group mipg
             WHERE mipg.id_drug = i_drug
               AND mipg.vers = l_version;
        
           /* IF NOT ins_id_drug_pharm_group(i_lang        => i_lang,
                                           i_prof        => i_prof,
                                           i_drug        => o_id_medication,
                                           i_pharm_group => l_mipg_group_id,
                                           i_commit      => pk_alert_constant.g_no,
                                           o_error       => o_error)
            THEN
                raise_application_error(-20001, 'ERROR INSERTING PHARM GROUP');
            END IF;*/
        
            --deactivate most frequent admixture iv fluids when drug is deactivated 
            --even if it's not a deactivation, the original one is deactivated, so this should be made
        
           
        
        ELSE
        
            g_error := 'Please input obligatory parameters.';
            pk_alertlog.log_debug(g_error);
            RAISE unexpected_error;
            RETURN FALSE;
        
        END IF;
    
        IF i_commit IS NULL
           OR i_commit = g_yes
        THEN
            g_error := 'Commit transaction';
            pk_alertlog.log_debug(g_error);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'upd_medication',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END upd_medication;

    /*******************************************************************************************************************************************
    *  Create prescribing alternative units for a medication                                                                                   *
    *                                                                                                                                          *
    * @param I_LANG                   LANGUAGE                                                                                                 *
    * @param I_PROF                   PROFESSIONAL ARRAY                                                                                       *
    * @param i_drug                   MEDICATION ID                                                                                            *
    * @param i_unit_measure           ALTERNATIVE UNIT MEASURE                                                                                 * 
    * @param i_flg_default            FLAG DEFAULT FOR EACH DRUG UNIT MEDURE                                                                   * 
    * @param i_commit                 Y, FOR COMMIT, N, OTHERWISE                                                                              *
    *                                                                                                                                          *
    * @return                         BOOLEAN                                                                                                  *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Patrícia Neto                                                                                            *
    * @version                         1.0                                                                                                     *
    * @since                          2008/10/14                                                                                               *
    *                                                                                                                                          * 
    *******************************************************************************************************************************************/
    FUNCTION create_alternative_units
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_drug         IN mi_med.id_drug%TYPE,
        i_unit_measure IN table_varchar,
        i_commit       IN VARCHAR2 DEFAULT NULL,
        i_chnm         IN mi_med.chnm_id%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version      mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_cursor_unit  mi_med.id_unit_measure%TYPE;
        l_drug_unit    drug_unit.id_drug_unit%TYPE;
        l_type         mi_med.flg_type%TYPE;
        l_notfound     BOOLEAN;
        l_default_unit drug_unit.id_unit_measure%TYPE;
        l_chnm_id      mi_med.chnm_id%TYPE;
    
        CURSOR c_unit_measure_exists(l_unit_measure VARCHAR2) IS
            SELECT id_unit_measure
              FROM drug_unit
             WHERE vers = l_version
               AND id_drug = i_drug
               AND chnm_id = i_chnm
               AND id_unit_measure = l_unit_measure;
    
        r_unit_measure_exists c_unit_measure_exists%ROWTYPE;
    
    BEGIN
    
        --check if chnm is null. if so, puts an identifier in that record as '-id_drug'.
        BEGIN
            SELECT decode(i_chnm, NULL, '-' || i_drug, i_chnm)
              INTO l_chnm_id
              FROM dual;
        EXCEPTION
            WHEN OTHERS THEN
                raise_application_error(-20001, 'Error converting CHNM_ID when I_CHNM is null');
        END;
    
        FOR i IN 1 .. i_unit_measure.count
        LOOP
        
            g_error := 'Get flg_type from MI_MED';
            pk_alertlog.log_debug(g_error);
            SELECT flg_type
              INTO l_type
              FROM mi_med
             WHERE vers = l_version
               AND id_drug = i_drug;
        
            g_error := 'Get maximum ID_DRUG_UNIT: ' || l_drug_unit;
            pk_alertlog.log_debug(g_error);
            SELECT MAX(id_drug_unit) + 1
              INTO l_drug_unit
              FROM drug_unit;
        
            l_default_unit := to_number(i_unit_measure(i), '999999999999999999999999');
        
            OPEN c_unit_measure_exists(i_unit_measure(i));
            FETCH c_unit_measure_exists
                INTO r_unit_measure_exists;
            l_notfound := c_unit_measure_exists%NOTFOUND;
            CLOSE c_unit_measure_exists;
        
            IF l_notfound
            THEN
            
                --[MEDICATION_RULE] (10-09-09) PK_MEDICATION_CORE.CREATE_ALTERNATIVE_UNITS  Exclusivamento no mercado PT, as unidades de prescição alternativas são definidas na tabela DRUG_UNIT.    
                g_error := 'Insert into drug_unit for id_drug:' || i_drug || ' and id_unit_measure: ' || l_default_unit;
                pk_alertlog.log_debug(g_error);
                INSERT INTO drug_unit
                    (id_drug,
                     chnm_id,
                     drug_flg_type,
                     flg_type,
                     flg_available,
                     vers,
                     id_unit_measure,
                     flg_default,
                     id_drug_unit)
                VALUES
                    (i_drug, l_chnm_id, l_type, 'I', 'Y', l_version, i_unit_measure(i), 'N', l_drug_unit);
            
            ELSE
            
                g_error := 'ID_UNIT_MEASURE already exists for this medication';
                pk_alertlog.log_debug(g_error);
                RAISE unexpected_error;
                RETURN FALSE;
            
            END IF;
        
        END LOOP;
    
        IF i_commit IS NULL
           OR i_commit = g_yes
        THEN
            g_error := 'Commit transaction';
            pk_alertlog.log_debug(g_error);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CORE',
                                              i_function => 'create_alternative_units',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_alternative_units;

    /*******************************************************************************************************************************************
    * Use the logging package to write log messages                                                                                            *
    *                                                                                                                                          * 
    * @ param i_log_msg         message to be sent to the log                                                                                  *                                                                     
    * @ param i_log_type        type of log: fatal - F, error - E, warn - W, info - I, debug -D                                                *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * @author                         Orlando Antunes                                                                                          *
    * @version                         1.0                                                                                                     *
    * @since                          2008/05/28                                                                                               *
    *                                                                                                                                          *         
    *******************************************************************************************************************************************/
    PROCEDURE print_medication_logs
    (
        i_log_msg  IN VARCHAR2,
        i_log_type IN VARCHAR2 DEFAULT 'E'
    ) IS
    
    BEGIN
    
        CASE i_log_type
            WHEN c_log_fatal THEN
                BEGIN
                    pk_alertlog.log_debug(i_log_msg);
                END;
            WHEN c_log_warn THEN
                BEGIN
                    pk_alertlog.log_debug(i_log_msg);
                END;
            WHEN c_log_info THEN
                BEGIN
                    pk_alertlog.log_debug(i_log_msg);
                END;
            WHEN c_log_debug THEN
                BEGIN
                    pk_alertlog.log_debug(i_log_msg);
                END;
            ELSE
                --o default é error
                BEGIN
                    pk_alertlog.log_debug(i_log_msg);
                END;
        END CASE;
    
    END print_medication_logs;
    --

    /*--------------------------------------------------
    |       Therapeutic_Protocols via interface         |
    ---------------------------------------------------*/

    /****************************************************************************************************************************************
    * Creates the parametrization for the specified drug, in the software and instituion.                                                   *   
    *                                                                                                                                       *
    * @ param i_lang                                  Language                                                                              *
    * @ param i_prof                                  Professional                                                                          *
    * @ param i_id_drug                               Id drug                                                                               *
    * @ param i_id_dep_clin_serv                      Id for dep_clin_serv (Clinical Service)                                               *
    * @ param i_flg_type                              Type of drug: (M - drug, F - IV Fluid)                                                *
    * @ param i_flg_take_type                         Type of take: (A - Ad Eternum; C - continuous, N - normal, S - SOS, U - single dose)  *
    * @ param i_takes                                 Number of takes                                                                       *
    * @ param i_interval                              Interval between takes                                                                *
    * @ param i_dosage                                Dose                                                                                  *
    * @ param i_qty                                   Quantity                                                                              *
    * @ param i_duration                              Duration                                                                              *
    * @ param i_unit_measure_inst                     Quantity's unit measure                                                               *
    * @ param i_unit_measure_freq                     Frequency's unit measure                                                              *
    * @ param i_unit_measure_dur                      Duration's unit measure                                                               *
    * @ param i_commit                                Commit in this function (Y/N)                                                         *
    * @ param o_error                                 Error message                                                                         *
    *                                                                                                                                       *
    * @return                         true or false on success or error                                                                     *
    *                                                                                                                                       *
    * @author                         Orlando Antunes                                                                                       *
    * @version                        0.1                                                                                                   *
    * @since                          2008/10/14                                                                                            *
    *****************************************************************************************************************************************/
    FUNCTION set_drug_dcs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_drug           IN mi_med.id_drug%TYPE,
        i_id_dep_clin_serv  IN drug_dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_flg_type          IN drug_dep_clin_serv.flg_type%TYPE,
        i_flg_take_type     IN drug_dep_clin_serv.flg_take_type%TYPE DEFAULT NULL,
        i_takes             IN drug_dep_clin_serv.takes%TYPE DEFAULT NULL,
        i_interval          IN drug_dep_clin_serv.interval%TYPE DEFAULT NULL,
        i_dosage            IN drug_dep_clin_serv.dosage%TYPE DEFAULT NULL,
        i_qty               IN drug_dep_clin_serv.qty_inst%TYPE DEFAULT NULL,
        i_duration          IN drug_dep_clin_serv.duration%TYPE DEFAULT NULL,
        i_unit_measure_inst IN drug_dep_clin_serv.unit_measure_inst%TYPE DEFAULT NULL,
        i_unit_measure_freq IN drug_dep_clin_serv.unit_measure_freq%TYPE DEFAULT NULL,
        i_unit_measure_dur  IN drug_dep_clin_serv.unit_measure_dur%TYPE DEFAULT NULL,
        i_commit            IN VARCHAR2 DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version VARCHAR2(255) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
    BEGIN
    
        --CREATE therapeutic_protocols
        INSERT INTO drug_dep_clin_serv
            (id_drug_dep_clin_serv,
             id_drug,
             id_dep_clin_serv,
             rank,
             flg_type,
             id_institution,
             id_professional,
             id_software,
             flg_take_type,
             takes,
             INTERVAL,
             dosage,
             qty_inst,
             duration,
             unit_measure_inst,
             unit_measure_freq,
             unit_measure_dur,
             vers)
        VALUES
            (seq_drug_dep_clin_serv.nextval,
             i_id_drug,
             i_id_dep_clin_serv,
             0,
             i_flg_type,
             i_prof.institution,
             NULL,
             i_prof.software,
             i_flg_take_type,
             i_takes,
             i_interval,
             i_dosage,
             i_qty,
             i_duration,
             i_unit_measure_inst,
             i_unit_measure_freq,
             i_unit_measure_dur,
             l_version);
    
        IF i_commit IS NULL
           OR i_commit = g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CORE',
                                              i_function => 'SET_DRUG_DCS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_drug_dcs;
    
    /* Get the list of softwares available in the specified instituition                                                                        *
    *                                                                                                                                          *
    * @param i_lang                   Language ID                                                                                              *
    * @param i_id_institution         Institution ID                                                                                           *
    * @param o_software_list          List of softwares                                                                                        *
    * @param o_error                  Error message
                                                                                                *                                                                                                                                          *
    * @author                         Orlando Antunes                                                                                          *
    * @version                        1.0                                                                                                      *
    * @since                          2009/12/05                                                                                               *
    *******************************************************************************************************************************************/
    FUNCTION get_software_by_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software_list  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET SOFTWARE LIST';
        OPEN o_software_list FOR
            SELECT si.id_software id, pk_translation.get_translation(i_lang, s.code_software) soft_descr
              FROM software_institution si, software s
             WHERE si.id_institution = i_id_institution
               AND si.id_software = s.id_software
             ORDER BY id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'GET_SOFTWARE_BY_INSTITUTION',
                                              i_function => 'PK_MEDICATION_CORE',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_software_by_institution;
    --

    /*******************************************************************************************************************************************
    * Creates alert events for Medication area in the sys_alert_event table.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_id_episode          Episode ID
    * 
    * @param i_id_record           ID of record that creates de new Alert (e.g. drug_presc_plan.id_drug_presc_plan)
    * @param i_dt_record           Date of record that creates de new Alert (e.g. drug_presc_plan.dt_plan_tstz)
    *
    * @ param i_dpd_flg_status     Drug_presc_det flg_status field
    * @ param i_drd_flg_status     Drug_req_det flg_status field
    * @ param i_dpp_flg_status     Drug_presc_plan flg_status field
    * @ param i_dr_flg_status      Drug_req flg_status field
    * @ param i_drs_flg_status     Drug_req_supply flg_status field
    * @ param i_med_type           Medication type: M -drugs, S - IV Fluids
    *   
    * @param i_replace1            Replace value for alert message (e.g. drug name)
    *
    * @param i_institution         Institution
    * @param i_software            Software
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Orlando Antunes
    * @since                       2009/01/08
    * @version                     1.0
    *
    *****************************************************************************************************************************************************/
    FUNCTION set_medication_alerts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        --new alert identification
        i_id_record IN sys_alert_event.id_record%TYPE,
        i_dt_record IN sys_alert_event.dt_record%TYPE,
        --conditions for new alerts
        i_dpd_flg_status IN VARCHAR2 DEFAULT NULL,
        i_drd_flg_status IN VARCHAR2 DEFAULT NULL,
        i_dpp_flg_status IN VARCHAR2 DEFAULT NULL,
        i_dr_flg_status  IN VARCHAR2 DEFAULT NULL,
        i_drs_flg_status IN VARCHAR2 DEFAULT NULL,
        i_med_type       IN VARCHAR2 DEFAULT NULL,
        --alert object description
        i_alert_message IN VARCHAR2,
        --
        i_institution IN sys_alert_event.id_institution%TYPE,
        i_software    IN sys_alert_event.id_software%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        --sys_alert_event row
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_error           t_error_out;
    
        --clinical_service
        l_id_clinical_service episode.id_clinical_service%TYPE;
    
        l_id_visit visit.id_visit%TYPE;
        l_dt_visit visit.dt_creation%TYPE;
    
        g_ex_dt_visit_gt_dt_alert EXCEPTION;
    
    BEGIN
    
        --new alert event - generic attributes:
        l_alert_event_row.id_software    := i_prof.software;
        l_alert_event_row.id_institution := i_prof.institution;
        l_alert_event_row.id_episode     := i_id_episode;
        --
        l_alert_event_row.id_record := i_id_record;
        l_alert_event_row.dt_record := i_dt_record;
        --
        l_alert_event_row.replace1   := i_alert_message;
        l_alert_event_row.id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
        --l_alert_event_row.id_visit   := pk_analysis.get_visit(i_episode => i_id_episode, o_error => l_error);
        l_alert_event_row.id_visit := pk_episode.get_id_visit(i_episode => i_id_episode);
    
        ---------------            
        -- Alerta 10 --           
        ---------------            
        --Alert Conditions:
        IF i_dpp_flg_status IN ('R', 'D')
           AND i_dpd_flg_status IN ('R', 'E', 'D')
           AND i_dr_flg_status IS NULL
           AND i_drd_flg_status IS NULL
          --drugs
           AND i_med_type = 'M'
        THEN
            g_error := 'ALERT 10 - BEGIN:';
            --
        
            --get_clinical_service and id_visit
            BEGIN
                SELECT e.id_clinical_service, e.id_visit
                  INTO l_id_clinical_service, l_id_visit
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_medication_core.print_medication_logs('Clinical Service not found for episode ' || i_id_episode,
                                                             pk_medication_core.c_log_error);
                    l_id_clinical_service := NULL;
            END;
        
            --get visit date with id_visit
            BEGIN
                SELECT v.dt_creation
                  INTO l_dt_visit
                  FROM visit v
                 WHERE v.id_visit = l_id_visit;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_medication_core.print_medication_logs('Clinical visit not found for episode' || i_id_episode,
                                                             pk_medication_core.c_log_error);
                    l_id_clinical_service := NULL;
            END;
            --
        
            --  verify if visit.dt_create is lower than sys_alert_event.dt_record
            BEGIN
                IF l_dt_visit > i_dt_record
                THEN
                    --RAISE g_ex_dt_visit_gt_dt_alert;
                    pk_medication_core.print_medication_logs('INVARIANT! visit' || l_id_visit || ' l_dt_visit(' ||
                                                             l_dt_visit || ') > i_dt_record(' || i_dt_record || ')',
                                                             pk_medication_core.c_log_error);
                END IF;
            END;
            --
        
            l_alert_event_row.id_sys_alert := 10;
            --
            l_alert_event_row.id_professional     := i_prof.id;
            l_alert_event_row.id_room             := NULL;
            l_alert_event_row.id_clinical_service := l_id_clinical_service;
            --
            l_alert_event_row.replace2 := pk_sysconfig.get_config('ALERT_TAKE_TIMEOUT1', i_prof);
            --Insere evento na tabela de alertas
            g_error := 'INSERT INTO SYS_ALERT_EVENT ALERT 10';
            pk_alertlog.log_warn('Parameters for Alert id :' || 10 || '.' || ' i_id_episode: ' || i_id_episode ||
                                 ' i_id_record: ' || i_id_record || ' i_dt_record: ' || i_dt_record);
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    --i_flg_type_dest   => i_flg_type,
                                                    o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
        ------------------            
        -- End Alerta 10--           
        ------------------
    
        ---------------            
        -- Alerta 25 --           
        ---------------            
        --Alert Conditions:
        IF i_dpp_flg_status IN ('R', 'D')
           AND i_dpd_flg_status IN ('R', 'E', 'D')
           AND i_dr_flg_status IS NULL
           AND i_drd_flg_status IS NULL
          --IV Fluids
           AND i_med_type = 'F'
        THEN
            g_error := 'ALERT 25 - BEGIN:';
            --
            --get_clinical_service
            BEGIN
                SELECT e.id_clinical_service
                  INTO l_id_clinical_service
                  FROM episode e
                 WHERE e.id_episode = i_id_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_medication_core.print_medication_logs('Clinical Service not found for episode ' || i_id_episode,
                                                             pk_medication_core.c_log_error);
                    l_id_clinical_service := NULL;
            END;
        
            l_alert_event_row.id_sys_alert := 25;
        
            --
            l_alert_event_row.id_professional     := i_prof.id;
            l_alert_event_row.id_room             := NULL;
            l_alert_event_row.id_clinical_service := l_id_clinical_service;
            --
            l_alert_event_row.replace2 := pk_sysconfig.get_config('ALERT_TAKE_TIMEOUT1', i_prof);
            --Insere evento na tabela de alertas
            g_error := 'INSERT INTO SYS_ALERT_EVENT ALERT 25';
            pk_alertlog.log_warn('Parameters for Alert id :' || 25 || '.' || ' i_id_episode: ' || i_id_episode ||
                                 ' i_id_record: ' || i_id_record || ' i_dt_record: ' || i_dt_record);
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    --i_flg_type_dest   => i_flg_type,
                                                    o_error => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
        ------------------            
        -- End Alerta 25--           
        ------------------
    
        --COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_ex_dt_visit_gt_dt_alert THEN
            raise_application_error(-20002,
                                    pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                    'PK_MEDICATION_CORE.SET_MEDICATION_ALERTS / ' || g_error || ' / ' || SQLERRM);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_MEDICATION_ALERTS',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_medication_alerts;
    --

    /*******************************************************************************************************************************************
    * Removes alert events for Medication area from the sys_alert_event table.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_id_episode          Episode ID
    * 
    * @param i_id_record           ID of record that creates de new Alert (e.g. drug_presc_plan.id_drug_presc_plan)
    *
    * @ param i_dpd_flg_status     Drug_presc_det flg_status field
    * @ param i_drd_flg_status     Drug_req_det flg_status field
    * @ param i_dpp_flg_status     Drug_presc_plan flg_status field
    * @ param i_dr_flg_status      Drug_req flg_status field
    * @ param i_drs_flg_status     Drug_req_supply flg_status field
    * @ param i_med_type           Medication type: M -drugs, S - IV Fluids
    *   
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Orlando Antunes
    * @since                       2009/01/08
    * @version                     1.0
    *
    *****************************************************************************************************************************************************/
    FUNCTION delete_medication_alerts
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        --new alert identification
        i_id_record IN sys_alert_event.id_record%TYPE,
        --conditions to delete alerts
        i_dpd_flg_status IN VARCHAR2 DEFAULT NULL,
        i_drd_flg_status IN VARCHAR2 DEFAULT NULL,
        i_dpp_flg_status IN VARCHAR2 DEFAULT NULL,
        i_dr_flg_status  IN VARCHAR2 DEFAULT NULL,
        i_drs_flg_status IN VARCHAR2 DEFAULT NULL,
        i_med_type       IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        --sys_alert_event row
        l_alert_event_row sys_alert_event%ROWTYPE;
    
        --clinical_service
        l_id_clinical_service episode.id_clinical_service%TYPE;
    
    BEGIN
        --new alert event - generic attributes:
    
        l_alert_event_row.id_episode := i_id_episode;
        --
        l_alert_event_row.id_record := i_id_record;
    
        ---------------            
        -- Alerta 10 --           
        ---------------            
        --Alert Conditions:
        IF i_dpp_flg_status IS NOT NULL
           AND i_dpd_flg_status IS NOT NULL
           AND i_dr_flg_status IS NULL
           AND i_drd_flg_status IS NULL
          --drugs
           AND i_med_type = 'M'
        THEN
            g_error := 'ALERT 10 - BEGIN:';
            --
            l_alert_event_row.id_sys_alert := 10;
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
        ------------------            
        -- End Alerta 10--           
        ------------------
    
        ---------------            
        -- Alerta 25 --           
        ---------------            
        --Alert Conditions:
        IF i_dpp_flg_status IS NOT NULL
           AND i_dpd_flg_status IS NOT NULL
           AND i_dr_flg_status IS NULL
           AND i_drd_flg_status IS NULL
          --IV Fluids
           AND i_med_type = 'F'
        THEN
            g_error := 'ALERT 25 - BEGIN:';
            --
            l_alert_event_row.id_sys_alert := 25;
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
        END IF;
        ------------------            
        -- End Alerta 25--           
        ------------------
    
        ---------------            
        -- Alerta 14 --           
        ---------------            
        --Alert Conditions:
        IF i_dr_flg_status IS NOT NULL
           AND i_drd_flg_status IS NOT NULL
           AND i_dpp_flg_status IS NULL
           AND i_dpd_flg_status IS NULL
        
        THEN
            g_error := 'ALERT 14 - BEGIN:';
            --
            l_alert_event_row.id_sys_alert := 14;
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
        END IF;
        ------------------            
        -- End Alerta 14--           
        ------------------
    
        ---------------            
        -- Alerta 13 --           
        ---------------            
        --Alert Conditions:
        IF i_drs_flg_status IS NOT NULL
           AND i_dpd_flg_status IS NULL
           AND i_drd_flg_status IS NULL
           AND i_dpp_flg_status IS NULL
           AND i_dr_flg_status IS NULL
        THEN
            g_error := 'ALERT 13 - BEGIN:';
        
            l_alert_event_row.id_sys_alert := 13;
            --
            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_alert_event_row,
                                                    o_error           => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        END IF;
        ------------------            
        -- End Alerta 13--           
        ------------------
    
        --COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'DELETE_MEDICATION_ALERTS',
                                              i_function => 'PK_MEDICATION_CORE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END delete_medication_alerts;
    --
    

    /*******************************************************************************************************************************************
      * Get visit from specific episode
      *
      * @param i_lang                Language Id
      * @param i_prof                Professional, institution, software
      * @param i_id_episode         episode
    * @param o_id_visit         id visita
    * @param o_id_epis_type        tipo de episodio
    * @param o_error         erro
      *
      * @return                      BOOLEAN (True if success, False if error)
      *
      * @author                      Pedro Albuquerque
      * @since                       2009/03/17
      * @version                     1.0
      *
      *****************************************************************************************************************************************************/

    FUNCTION get_visit_from_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN drug_prescription.id_episode%TYPE,
        o_id_visit     OUT visit.id_visit%TYPE,
        o_id_epis_type OUT episode.id_epis_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_found BOOLEAN;
    
        CURSOR c_ti IS
            SELECT e.id_visit, e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        --
    
    BEGIN
    
        g_error := 'OPEN c_inst';
        OPEN c_ti;
        FETCH c_ti
            INTO o_id_visit, o_id_epis_type;
        l_found := c_ti%FOUND;
        CLOSE c_ti;
    
        IF NOT l_found
        THEN
            g_error := 'EPISODE INVALID(' || i_id_episode || '), VISIT NOT FOUND!';
            pk_alertlog.log_debug(g_error);
            raise_application_error(-20001, g_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_MEDICATION_CORE',
                                              i_function => 'GET_VISIT_FROM_EPIS',
                                              o_error    => o_error);
        
            IF c_ti%ISOPEN
            THEN
                CLOSE c_ti;
            END IF;
            RETURN FALSE;
        
    END get_visit_from_epis;

    /*******************************************************************************************************************************************
    *  Create new drugs -Inserts                                                                                                               *
    *                                                                                                                                          *
    * @param I_LANG                   LANGUAGE                                                                                                 *
    * @param I_PROF                   PROFESSIONAL ARRAY                                                                                       *
    * @param I_DRUG_DESCR             MEDICATION DESCR                                                                                         *
    * @param I_CHNM                   CHNM ID                                                                                                  *
    * @param I_FLG_TYPE               'M' FOR MEDICATION, 'F' FOR IV-FLUIDS                                                                    *
    * @param I_FLG_MIX_FLUID          Y, FOR DRUGS TO BE ADDED TO IV-FLUIDS                                                                    *
    * @param I_FLG_JUSTIFY            FLAG MED JUSTIFICATION: 'Y' IF IT NEED JUSTIFICATION WHEN PRESCRIBED, 'N' OTHERWISE                      *
    * @param I_DCI_ID                 ACTIVE INGREDIENT(S) ID                                                                                  *
    * @param I_DCI_DESCR              ACTIVE INGREDIENT(S) DESCRIPTIVE                                                                         *
    * @param I_DOSAGE                 MEDICATION DOSAGE                                                                                        *
    * @param I_FORM_FARM_ID           FORM ID                                                                                                  *
    * @param I_FORM_FARM_DESCR        FORM DESCR                                                                                               *
    * @param I_FORM_FARM_ABRV         FORM ABBREVIATION                                                                                        *
    * @param I_ROUTE_ID               ROUTE ID                                                                                                 *
    * @param I_ROUTE_DESCR            ROUTE DESCRIPTIVE                                                                                        *
    * @param I_ROUTE_ABRV             ROUTE ABBREVIATION                                                                                       *
    * @param I_QT_DOS_COMP            BASIS QUANTITY FOR PT AND PACKAGE SIZE FOR USA                                                           *
    * @param I_ID_UNIT_DOS_COMP       MEDICATION UNIT MEASURE ID                                                                               *
    * @param I_COMMIT                 Y, FOR COMMIT, N, OTHERWI SE                                                                             *
    *                                                                                                                                          *
    * @param  o_max_group_id          PHARMACOLOGICAL GROUP CREATED                                                                            *
    * @return                         BOOLEAN                                                                                                  *
    *                                                                                                                                          *
    * @raises                                                                                                                                  *
    *                                                                                                                                          *
    * @author                         Pedro Morais                                                                                             *
    * @version                         1.0                                                                                                     *
    * @since                          2010/17/16                                                                                               *
    *                                                                                                                                          *
    *                                                                                                                                          *
    * Nuno Antunes 2010/11/11 (mi_med_route association)                                                                                       *    
    *                                                                                                                                          *    
    *******************************************************************************************************************************************/
    FUNCTION create_medication_ins
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_drug_descr        IN mi_med.med_descr%TYPE,
        i_chnm              IN mi_med.chnm_id%TYPE,
        i_flg_type          IN mi_med.flg_type%TYPE,
        i_flg_mix_fluid     IN mi_med.flg_mix_fluid%TYPE,
        i_flg_justify       IN mi_med.flg_justify%TYPE,
        i_dci_id            IN mi_med.dci_id%TYPE,
        i_dci_descr         IN mi_med.dci_descr%TYPE,
        i_dosage            IN mi_med.dosagem%TYPE,
        i_form_farm_id      IN mi_med.form_farm_id%TYPE,
        i_form_farm_descr   IN mi_med.form_farm_descr%TYPE,
        i_form_farm_abrv    IN mi_med.form_farm_abrv%TYPE,
        i_route_id          IN mi_med.route_id%TYPE,
        i_route_descr       IN mi_med.route_descr%TYPE,
        i_route_abrv        IN mi_med.route_abrv%TYPE,
        i_qt_dos_comp       IN mi_med.qt_dos_comp%TYPE,
        i_id_unit_dos_comp  IN unit_measure.id_unit_measure%TYPE,
        i_commit            IN VARCHAR2 DEFAULT NULL,
        i_id_drug_replicat  IN mi_med.id_drug%TYPE DEFAULT NULL,
        i_med_flg_available IN mi_med.flg_available%TYPE DEFAULT NULL,
        o_id_medication     OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_max_drug_id VARCHAR2(255);
        l_version     mi_med.vers%TYPE := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_drug_unit   drug_unit.id_drug_unit%TYPE;
        l_chnm_id     mi_med.chnm_id%TYPE;
    
    BEGIN
    
        g_error := 'Get new id_drug';
        pk_alertlog.log_error(g_error);
        SELECT i_prof.institution || lpad(seq_medication.nextval, 12, '0')
          INTO l_max_drug_id
          FROM dual;
    
        g_error := 'Insert into mi_med';
        pk_alertlog.log_error(g_error);
        INSERT INTO mi_med
            (id_drug,
             med_descr_formated,
             med_descr,
             short_med_descr,
             flg_type,
             flg_available,
             flg_justify,
             id_drug_brand,
             dci_id,
             dci_descr,
             form_farm_id,
             form_farm_descr,
             route_id,
             route_descr,
             qt_dos_comp,
             unit_dos_comp,
             dosagem,
             chnm_id,
             flg_mix_fluid,
             id_unit_measure,
             vers,
             form_farm_abrv,
             route_abrv)
        VALUES
            (l_max_drug_id,
             i_drug_descr,
             i_drug_descr,
             i_drug_descr,
             nvl(i_flg_type, 'M'),
             nvl(i_med_flg_available, 'Y'),
             nvl(i_flg_justify, 'N'),
             1,
             i_dci_id,
             i_dci_descr,
             i_form_farm_id,
             i_form_farm_descr,
             i_route_id,
             i_route_descr,
             i_qt_dos_comp,
             to_char(i_id_unit_dos_comp),
             i_dosage,
             i_chnm,
             i_flg_mix_fluid,
             to_char(i_id_unit_dos_comp),
             l_version,
             i_form_farm_abrv,
             i_route_abrv);
    
        --insert new route association
        g_error := 'insert into mi_med_route for id_drug:' || l_max_drug_id;
        pk_alertlog.log_error(g_error);
        INSERT INTO mi_med_route
            (id_drug, route_id, vers)
        VALUES
            (l_max_drug_id, i_route_id, l_version);
    
        --check if chnm is null. if so, puts an identifier in that record as '-id_drug'.
        l_chnm_id := nvl(i_chnm, '-' || l_max_drug_id);
    
        SELECT MAX(id_drug_unit)
          INTO l_drug_unit
          FROM drug_unit;
    
        IF i_id_drug_replicat IS NULL
        THEN
            g_error := 'insert into drug_unit for id_drug:' || l_max_drug_id || ' and id_unit_measure: ' ||
                       i_id_unit_dos_comp;
            pk_alertlog.log_error(g_error);
            INSERT INTO drug_unit
                (id_drug,
                 chnm_id,
                 drug_flg_type,
                 flg_type,
                 flg_available,
                 vers,
                 id_unit_measure,
                 flg_default,
                 id_drug_unit)
            VALUES
                (l_max_drug_id,
                 l_chnm_id,
                 nvl(i_flg_type, 'M'),
                 'I',
                 'Y',
                 l_version,
                 i_id_unit_dos_comp,
                 'Y',
                 nvl(l_drug_unit, 0) + 1);
        ELSE
            g_error := 'insert replicate into drug_unit for id_drug:' || l_max_drug_id || ' and id_unit_measure: ' ||
                       i_id_unit_dos_comp;
            pk_alertlog.log_error(g_error);
            INSERT INTO drug_unit
                (id_drug,
                 chnm_id,
                 drug_flg_type,
                 flg_type,
                 flg_available,
                 vers,
                 id_unit_measure,
                 flg_default,
                 id_drug_unit)
                (SELECT l_max_drug_id,
                        nvl(i_chnm, '-' || l_max_drug_id),
                        nvl(du.drug_flg_type, 'M'),
                        nvl(du.flg_type, 'I'),
                        nvl(du.flg_available, 'Y'),
                        l_version,
                        du.id_unit_measure,
                        nvl(du.flg_default, 'Y'),
                        nvl(l_drug_unit, 0) + rownum --Several IDs. We get the max, and this way add 1 for each record.
                   FROM drug_unit du
                  WHERE id_drug = i_id_drug_replicat
                    AND vers = l_version
                    AND du.id_unit_measure IS NOT NULL);
        
            --insert new route association
            g_error := 'insert replicate into mi_med_route for id_drug:' || l_max_drug_id;
            pk_alertlog.log_error(g_error);
            INSERT INTO mi_med_route
                (id_drug, route_id, vers)
                (SELECT l_max_drug_id, mmr.route_id, l_version
                   FROM mi_med_route mmr
                  WHERE mmr.id_drug = i_id_drug_replicat
                    AND mmr.vers = l_version
                    AND mmr.route_id <> i_route_id);
        
        END IF;
    
        IF i_commit IS NULL
           OR i_commit = g_yes
        THEN
            g_error := 'Commit transaction';
            pk_alertlog.log_error(g_error);
            COMMIT;
        END IF;
    
        o_id_medication := l_max_drug_id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'create_medication',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_medication_ins;


    /********************************************************************************************
     * Update table GRID_TASK.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_prof_cat_type          Professional's category type
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2006/01/20
    **********************************************************************************************/
    FUNCTION update_drug_presc_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error        VARCHAR2(4000);
        l_mess1        VARCHAR2(100);
        l_mess1_old    VARCHAR2(100);
        l_type_old     VARCHAR2(1);
        l_mess2        VARCHAR2(100);
        l_epis         episode.id_episode%TYPE;
        l_short_presc  sys_shortcut.id_sys_shortcut%TYPE;
        l_short_fluids sys_shortcut.id_sys_shortcut%TYPE;
        l_exist        VARCHAR2(1);
        l_id_visit     visit.id_visit%TYPE;
        l_id_epis_type episode.id_epis_type%TYPE;
        l_version      VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
        l_grid_task    grid_task%ROWTYPE;
    
        -- Obter ID do atalho dos IV fluídos
        CURSOR c_short_fluids IS
            SELECT id_sys_shortcut
              FROM sys_shortcut a
             WHERE a.intern_name = 'IVFLUIDS_LIST'
               AND a.id_software = i_prof.software
               AND a.id_institution = (SELECT MAX(b.id_institution)
                                         FROM sys_shortcut b
                                        WHERE b.id_software = a.id_software
                                          AND b.id_institution IN (0, i_prof.institution)
                                          AND b.intern_name = a.intern_name
                                          AND b.id_parent IS NULL)
               AND a.id_parent IS NULL
             ORDER BY a.id_institution DESC;
    
        -- Obter ID do atalho dos medicamentos
        CURSOR c_short_presc IS
            SELECT id_sys_shortcut
              FROM sys_shortcut a
             WHERE a.intern_name = 'GRID_DRUG_ADMIN'
               AND a.id_software = i_prof.software
               AND a.id_institution = (SELECT MAX(b.id_institution)
                                         FROM sys_shortcut b
                                        WHERE b.id_software = a.id_software
                                          AND b.id_institution IN (0, i_prof.institution)
                                          AND b.intern_name = a.intern_name
                                          AND b.id_parent IS NULL)
               AND a.id_parent IS NULL
             ORDER BY a.id_institution DESC;
    
        --
        CURSOR c_drug(l_id_v visit.id_visit%TYPE) IS
            SELECT e.flg_status epis_status,
                   dp.flg_time,
                   decode(nvl(dp.id_episode_origin, 0), 0, dpp.dt_plan_tstz, dp.dt_begin_tstz) dt_begin,
                   dpp.flg_status,
                   dp.dt_drug_prescription_tstz dt_req,
                   e.dt_begin_tstz epis_dt_begin,
                   NULL img_name,
                   m.flg_type
              FROM visit v
              JOIN episode e
                ON v.id_visit = e.id_visit
              JOIN drug_prescription dp
                ON dp.id_episode = e.id_episode
              JOIN drug_presc_det dpd
                ON dp.id_drug_prescription = dpd.id_drug_prescription
              JOIN drug_presc_plan dpp
                ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
              JOIN mi_med m
                ON (m.id_drug = dpd.id_drug AND m.vers = dpd.vers)
             WHERE v.id_visit = l_id_v
               AND dpd.flg_take_type <> g_presc_det_take_type_sos
               AND dpp.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend)
               AND dpd.flg_status NOT IN (SELECT /*+opt_estimate(table v rows=1) */
                                           column_value
                                            FROM TABLE(g_presc_det_inactive) v)
               AND l_version = m.vers
            UNION ALL
            SELECT e.flg_status epis_status,
                   dp.flg_time,
                   decode(nvl(dp.id_episode_origin, 0), 0, dpp.dt_plan_tstz, dp.dt_begin_tstz) dt_begin,
                   dpp.flg_status,
                   dp.dt_drug_prescription_tstz dt_req,
                   e.dt_begin_tstz epis_dt_begin,
                   NULL img_name,
                   'M' --tipo medicamento
              FROM visit v
              JOIN episode e
                ON v.id_visit = e.id_visit
              JOIN drug_prescription dp
                ON dp.id_episode = e.id_episode
              JOIN drug_presc_det dpd
                ON dp.id_drug_prescription = dpd.id_drug_prescription
              JOIN drug_presc_plan dpp
                ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
              JOIN other_product op
                ON (op.id_other_product = dpd.id_other_product AND op.vers = dpd.vers)
             WHERE v.id_visit = l_id_v
               AND dpd.flg_take_type <> g_presc_det_take_type_sos
               AND dpp.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend)
               AND dpd.flg_status NOT IN (SELECT /*+opt_estimate(table v rows=1) */
                                           column_value
                                            FROM TABLE(g_presc_det_inactive) v)
               AND l_version = op.vers
            UNION ALL
            --compounds
            SELECT e.flg_status epis_status,
                   dp.flg_time,
                   decode(nvl(dp.id_episode_origin, 0), 0, dpp.dt_plan_tstz, dp.dt_begin_tstz) dt_begin,
                   dpp.flg_status,
                   dp.dt_drug_prescription_tstz dt_req,
                   e.dt_begin_tstz epis_dt_begin,
                   NULL img_name,
                   'M' --tipo medicamento
              FROM visit v
              JOIN episode e
                ON v.id_visit = e.id_visit
              JOIN drug_prescription dp
                ON dp.id_episode = e.id_episode
              JOIN drug_presc_det dpd
                ON dp.id_drug_prescription = dpd.id_drug_prescription
              JOIN drug_presc_plan dpp
                ON dpp.id_drug_presc_det = dpd.id_drug_presc_det
              JOIN combination_compound cc
                ON (cc.id_combination_compound = dpd.id_combination_compound AND cc.vers = dpd.vers)
             WHERE v.id_visit = l_id_v
               AND dpd.flg_take_type <> g_presc_det_take_type_sos
               AND dpp.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend)
               AND dpd.flg_status NOT IN (SELECT /*+opt_estimate(table v rows=1) */
                                           column_value
                                            FROM TABLE(g_presc_det_inactive) v)
               AND l_version = cc.vers
             ORDER BY flg_time, dt_req; --2, 5;
    
    BEGIN
        --logging
        pk_medication_core.print_medication_logs('UPDATE_DRUG_PRESC_TASK:(i_episode = ' || i_episode || ')',
                                                 pk_medication_core.c_log_debug);
        --get the visit id
        IF NOT pk_medication_core.get_visit_from_epis(i_lang, i_prof, i_episode, l_id_visit, l_id_epis_type, o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
        g_error := 'OPEN C_SHORT_FLUIDS';
        OPEN c_short_fluids;
        FETCH c_short_fluids
            INTO l_short_fluids;
        CLOSE c_short_fluids;
    
        g_error := 'OPEN C_SHORT_PRESC';
        OPEN c_short_presc;
        FETCH c_short_presc
            INTO l_short_presc;
        CLOSE c_short_presc;
    
        -- Corre todas as prescrições encontradas.
        -- Para cada, obtem a cadeia de caracteres. Nas instâncias consecutivas do loop
        -- compara-se cada string com a anterior e determina-se a prioridade
        g_error := 'LOOP C_DRUG';
        FOR cur IN c_drug(l_id_visit)
        LOOP
            g_error := 'GET L_MESS2';
            l_mess2 := pk_grid.get_string_task(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_epis_status => cur.epis_status,
                                               i_flg_time    => cur.flg_time,
                                               i_flg_status  => cur.flg_status,
                                               i_dt_begin    => cur.dt_begin,
                                               i_dt_req      => cur.dt_req,
                                               i_icon_name   => cur.img_name,
                                               i_rank        => NULL,
                                               o_error       => o_error);
            IF o_error IS NOT NULL
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            g_error := 'GET L_MESS1';
            IF l_mess1 IS NOT NULL
            THEN
                l_mess1_old := l_mess1;
                l_mess1     := pk_grid.get_prioritary_task(i_lang,
                                                           l_mess1,
                                                           l_mess2,
                                                           'DRUG_PRESCRIPTION.FLG_STATUS',
                                                           g_flg_doctor);
            END IF;
        
            IF l_mess1_old IS NOT NULL
            THEN
                IF l_mess1 = l_mess1_old
                THEN
                    l_type_old := l_type_old;
                ELSE
                    l_type_old := cur.flg_type;
                END IF;
            ELSE
                l_type_old := cur.flg_type;
            END IF;
        
            l_mess1 := nvl(l_mess1, l_mess2);
        
            IF cur.flg_time = 'B'
            THEN
                l_exist := 'Y';
            END IF;
        
        END LOOP;
    
        g_error := 'GET SHORTCUT';
        IF l_mess1 IS NOT NULL
        THEN
            IF l_type_old = g_drug
            THEN
                l_mess1 := l_short_presc || '|' || l_mess1;
            ELSE
                l_mess1 := l_short_fluids || '|' || l_mess1;
            END IF;
        END IF;
    
        l_grid_task.drug_presc := nvl(l_mess1, ' ');
    
        FOR cur IN (SELECT e.id_episode
                      FROM episode e
                     WHERE e.id_visit = l_id_visit)
        LOOP
            l_grid_task.id_episode := cur.id_episode;
        
            --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
            IF NOT pk_grid.update_grid_task(i_lang => i_lang, i_grid_task => l_grid_task, o_error => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        END LOOP;
    
        --Actualiza GRID_TASK_BETWEEN para o episódio em causa
        g_error := 'UPDATE GRID_TASK_BETWEEN';
        UPDATE grid_task_between
           SET flg_drug = l_exist
         WHERE id_episode IN (SELECT e.id_episode
                                FROM episode e
                               WHERE e.id_visit = l_id_visit);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PRESCRIPTION_INT',
                                              i_function => 'UPDATE_DRUG_PRESC_TASK',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

/* ======================
      --Global definitions--
*  ====================== */

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_medication_core;
/
