
DECLARE
    g_inst_pk institution.id_institution%TYPE;
    g_prof_pk professional.id_professional%TYPE;
    g_error   VARCHAR2(1000 CHAR);
    g_str     VARCHAR2(1000 CHAR);
    x_error   t_error_out;

    l_market market.id_market%TYPE;
    l_active VARCHAR2(1 CHAR) := 'A';
    l_name   VARCHAR2(500 CHAR);
    l_exception EXCEPTION;
    l_lang  language.id_language%TYPE;
    l_pi_pk inst_attributes.id_inst_attributes%TYPE;

    CURSOR c_inst_ext IS
        SELECT ie.*
          FROM institution_ext ie;

    CURSOR c_prof_ext IS
        SELECT pe.*
          FROM professional_ext pe;
    PROCEDURE log_error(i_text IN VARCHAR2) IS
    BEGIN
        pk_alertlog.log_error(text => i_text, object_name => 'MIGRATION');
    END log_error;

    -- set fields P (professional) or I (institution) 
    FUNCTION set_new_fields
    (
        i_lang  language.id_language%TYPE,
        i_str   IN VARCHAR2,
        i_id    IN NUMBER,
        f_type  IN VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error         VARCHAR2(1000 CHAR);
        l_account_array table_number := table_number();
        l_values_array  table_varchar := table_varchar();
    
        l_inst_array table_number := table_number();
    BEGIN
        IF f_type = 'I'
        THEN
            l_error := ' get accounts related with ' || i_id;
            EXECUTE IMMEDIATE i_str BULK COLLECT
                INTO l_account_array, l_values_array;
            l_error := 'insert fields with forall';
            FORALL i IN 1 .. l_account_array.count
                INSERT INTO institution_field_data
                    (id_institution, id_field_market, VALUE)
                VALUES
                    (i_id, l_account_array(i), l_values_array(i));
        
        ELSIF f_type = 'P'
        THEN
            l_error := ' get accounts related with ' || i_id;
            EXECUTE IMMEDIATE i_str BULK COLLECT
                INTO l_account_array, l_values_array, l_inst_array;
            l_error := 'insert fields with forall';
            FORALL i IN 1 .. l_account_array.count
                INSERT INTO professional_field_data
                    (id_professional, id_field_market, VALUE, id_institution)
                VALUES
                    (i_id, l_account_array(i), l_values_array(i), l_inst_array(i));
        
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'set_inst_fields ->' || l_error || ' - ' || SQLERRM;
            log_error(g_error);
            RETURN FALSE;
    END;
    FUNCTION set_inst_specs
    (
        i_lang     IN language.id_language%TYPE,
        i_old_inst IN institution_ext.id_institution_ext%TYPE,
        i_new_inst IN institution.id_institution%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error    VARCHAR2(1000 CHAR);
        l_cs_array table_number := table_number();
        l_idx      NUMBER := 0;
        l_str_f    VARCHAR2(1000 CHAR) := '';
    BEGIN
        l_error := 'get cs array';
        SELECT iecs.id_clinical_service BULK COLLECT
          INTO l_cs_array
          FROM instit_ext_clin_serv iecs
         WHERE iecs.id_institution_ext = i_old_inst;
    
        FOR rec IN 1 .. l_cs_array.count
        LOOP
            l_idx := l_idx + 1;
            IF l_idx = 1
            THEN
                l_str_f := l_cs_array(rec);
            ELSE
                l_str_f := l_str_f || '|' || l_cs_array(rec);
            END IF;
        
        END LOOP;
        l_error := 'insert new field data';
        BEGIN
            INSERT INTO institution_field_data
                (id_institution, id_field_market, VALUE)
            VALUES
                (i_new_inst, 24, l_str_f);
        EXCEPTION
            WHEN dup_val_on_index THEN
                UPDATE institution_field_data ifd
                   SET ifd.value = l_str_f
                 WHERE ifd.id_institution = i_new_inst
                   AND ifd.id_field_market = 24;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'set_inst_specs ->' || l_error || ' - ' || SQLERRM;
            log_error(g_error);
            RETURN FALSE;
    END;
BEGIN
    dbms_output.enable(NULL);
    g_error := 'inst_PK';
    SELECT seq_institution.nextval
      INTO g_inst_pk
      FROM dual;

    g_error := ' get prof_institution seq - check prof_institution sequence';
    SELECT seq_inst_attributes.nextval
      INTO l_pi_pk
      FROM dual;

    g_error := 'inst_ext';
    FOR inst_ext IN c_inst_ext
    LOOP
        SELECT nvl(id_market, 0)
          INTO l_market
          FROM institution i
         WHERE i.id_institution = inst_ext.id_institution;
        g_inst_pk := g_inst_pk + 1;
        -- insert into institution       
        g_error := 'set_institution';
        INSERT INTO institution
            (id_institution,
             code_institution,
             flg_type,
             flg_available,
             rank,
             abbreviation,
             location,
             id_parent,
             phone_number,
             ext_code,
             address,
             zip_code,
             fax_number,
             district,
             ine_location,
             id_timezone_region,
             id_market,
             flg_external,
             dn_flg_status)
        VALUES
            (g_inst_pk,
             concat('INSTITUTION.CODE_INSTITUTION.', g_inst_pk),
             decode(inst_ext.flg_type, 'O', 'P', inst_ext.flg_type),
             inst_ext.flg_available,
             10,
             NULL,
             inst_ext.location,
             NULL,
             inst_ext.work_phone,
             NULL,
             inst_ext.address,
             inst_ext.zip_code,
             inst_ext.fax,
             NULL,
             'N/A',
             NULL,
             l_market,
             'Y',
             'I');
    
        IF (inst_ext.id_language IS NULL OR inst_ext.id_language = '')
        THEN
            SELECT nvl((SELECT id_language
                         FROM institution_language il
                        WHERE il.id_institution = inst_ext.id_institution
                          AND il.flg_available = 'Y'
                          AND rownum = 1),
                       1)
              INTO l_lang
              FROM dual;
        ELSE
            l_lang := inst_ext.id_language;
        END IF;
        insert_into_translation(l_lang, concat('INSTITUTION.CODE_INSTITUTION.', g_inst_pk), inst_ext.institution_name);
    
        -- set inst_attributes
        g_error := 'set_inst_atributes';
        l_pi_pk := l_pi_pk + 1;
        INSERT INTO inst_attributes
            (id_country, id_institution, id_inst_attributes, email, flg_available)
        VALUES
            (inst_ext.id_country, g_inst_pk, l_pi_pk, inst_ext.email, 'Y');
    
        -- get institution accounts 
        g_str := 'SELECT iea.id_account, iea.value FROM institution_ext_accounts iea WHERE iea.id_institution_ext = ' ||
                 inst_ext.id_institution_ext;
    
        -- set institution fields
        g_error := 'set_new_fields';
        IF NOT set_new_fields(inst_ext.id_language, g_str, g_inst_pk, 'I', x_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF NOT set_inst_specs(inst_ext.id_language, inst_ext.id_institution_ext, g_inst_pk, x_error)
        THEN
            RAISE l_exception;
        END IF;
    
    END LOOP;

    g_error := ' get l_prof_pk - check professional sequence';
    SELECT seq_professional.nextval
      INTO g_prof_pk
      FROM dual;

    FOR prof_ext IN c_prof_ext
    LOOP
        IF (prof_ext.id_language IS NULL OR prof_ext.id_language = '')
        THEN
            SELECT nvl((SELECT id_language
                         FROM institution_language il
                        WHERE il.id_institution = prof_ext.id_institution
                          AND il.flg_available = 'Y'
                          AND rownum = 1),
                       1)
              INTO l_lang
              FROM dual;
        ELSE
            l_lang := prof_ext.id_language;
        END IF;
        g_prof_pk := g_prof_pk + 1;
        l_name    := prof_ext.first_name || ' ' || prof_ext.middle_name || ' ' || prof_ext.last_name;
        -- insert into professionals
        g_error := 'set_new_professional';
        INSERT INTO professional
            (id_professional,
             name,
             nick_name,
             dt_birth,
             address,
             district,
             city,
             zip_code,
             num_contact,
             marital_status,
             gender,
             flg_state,
             num_order,
             id_speciality,
             id_country,
             initials,
             title,
             short_name,
             work_phone,
             cell_phone,
             fax,
             email,
             first_name,
             middle_name,
             last_name)
        VALUES
            (g_prof_pk,
             l_name,
             prof_ext.first_name,
             prof_ext.dt_birth,
             prof_ext.address,
             prof_ext.district,
             prof_ext.city,
             prof_ext.zip_code,
             prof_ext.num_contact,
             prof_ext.marital_status,
             nvl(prof_ext.gender, 'I'),
             'A',
             NULL,
             prof_ext.id_speciality,
             prof_ext.id_country,
             prof_ext.initials,
             prof_ext.title,
             prof_ext.first_name,
             prof_ext.work_phone,
             prof_ext.cell_phone,
             prof_ext.fax,
             prof_ext.email,
             prof_ext.first_name,
             prof_ext.middle_name,
             prof_ext.last_name);
    
        -- insert into professional institution
        g_error := ' set_prof_inst ';
    
        INSERT INTO prof_institution
            (id_prof_institution,
             id_professional,
             id_institution,
             flg_state,
             num_mecan,
             dt_begin_tstz,
             flg_external,
             dn_flg_status)
        VALUES
            (seq_prof_institution.nextval, g_prof_pk, prof_ext.id_institution, 'A', NULL, SYSDATE, 'Y', 'I');
    
        -- get professional accounts
        g_str := '
            SELECT fm.id_field_market, pea.value, pea.id_institution
              FROM prof_ext_accounts pea
              JOIN field_market fm
                ON (fm.id_field = pea.id_account)
             WHERE pea.id_professional_ext = ' || prof_ext.id_professional_ext;
        --set professional fields
        g_error := ' set_new_fields ';
        IF NOT set_new_fields(prof_ext.id_language, g_str, g_prof_pk, 'P', x_error)
        THEN
            RAISE l_exception;
        END IF;
    END LOOP;
EXCEPTION
    WHEN l_exception THEN
        dbms_output.put_line(g_error || ' ' || x_error.log_id);
        log_error(g_error);
        ROLLBACK;
    WHEN OTHERS THEN
        dbms_output.put_line('.. . ' || SQLERRM);
        log_error(g_error);
        ROLLBACK;
END;
/




