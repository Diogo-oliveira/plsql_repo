CREATE OR REPLACE TRIGGER b_iu_cdr_inst_param
    BEFORE INSERT OR UPDATE ON cdr_inst_param
    FOR EACH ROW
DECLARE
    l_def_par  cdr_definition.id_cdr_definition%TYPE;
    l_def_inst cdr_definition.id_cdr_definition%TYPE;

    CURSOR c_def_par(i_parameter IN cdr_parameter.id_cdr_parameter%TYPE) IS
        SELECT cdrdc.id_cdr_definition
          FROM cdr_parameter cdrp
          JOIN cdr_def_cond cdrdc
            ON cdrp.id_cdr_def_cond = cdrdc.id_cdr_def_cond
         WHERE cdrp.id_cdr_parameter = i_parameter;

    CURSOR c_def_inst(i_instance IN cdr_instance.id_cdr_instance%TYPE) IS
        SELECT cdri.id_cdr_definition
          FROM cdr_instance cdri
         WHERE cdri.id_cdr_instance = i_instance;
BEGIN
    -- id_cdr_instance and id_cdr_parameter are not nullable
    -- so the insert will fail, but do not worry about that here
    IF :new.id_cdr_instance IS NULL
    THEN
        NULL;
    ELSIF :new.id_cdr_parameter IS NULL
    THEN
        NULL;
    ELSE
        -- get definition on the parameter side
        OPEN c_def_par(i_parameter => :new.id_cdr_parameter);
        FETCH c_def_par
            INTO l_def_par;
        CLOSE c_def_par;
    
        -- get definition on the instance side
        OPEN c_def_inst(i_instance => :new.id_cdr_instance);
        FETCH c_def_inst
            INTO l_def_inst;
        CLOSE c_def_inst;
    
        -- compare definitions
        IF l_def_par != l_def_inst
        THEN
            raise_application_error(-20001,
                                    'Integrity restriction: the definitions associated with the parameter and the instance do not match!');
        END IF;
    END IF;
END b_iu_cdr_inst_param;
/
