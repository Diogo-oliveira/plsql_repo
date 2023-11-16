CREATE OR REPLACE
TRIGGER b_iu_prfl_tmpl_ac_chk_sh_sft
    BEFORE INSERT OR UPDATE ON profile_templ_access
    FOR EACH ROW
DECLARE
    l_count PLS_INTEGER;
BEGIN

    IF inserting
       AND :NEW.id_profile_templ_access IS NULL
    THEN
       NULL;
        --facilitar a vida para quem cria as entradas usando o UI do PLSQL developer
        --SELECT seq_profile_templ_access.NEXTVAL
        --  INTO :NEW.id_profile_templ_access
        --  FROM dual;
    END IF;

    IF nvl(:OLD.id_shortcut_pk, 0) != nvl(:NEW.id_shortcut_pk, 0)
       OR nvl(:OLD.id_sys_shortcut, 0) != nvl(:NEW.id_sys_shortcut, 0)
    THEN
        --mudança de valor de shortcut -> fazer verificação
        SELECT (SELECT COUNT(0)
                  FROM sys_shortcut s, sys_shortcut c
                 WHERE s.id_sys_shortcut = :NEW.id_sys_shortcut
                   AND s.id_sys_button_prop IS NULL
                   AND c.id_parent = :NEW.id_sys_shortcut
                   AND c.id_shortcut_pk = :NEW.id_shortcut_pk) +
               (SELECT COUNT(0)
                  FROM sys_shortcut s
                 WHERE s.id_sys_shortcut = :NEW.id_sys_shortcut
                   AND s.id_sys_button_prop IS NOT NULL
                   AND s.id_shortcut_pk = :NEW.id_shortcut_pk)
          INTO l_count
          FROM dual;

        IF :NEW.id_shortcut_pk IS NOT NULL
           AND l_count = 0
        THEN
            raise_application_error(-20001, 'Integrity restriction: id_sys_shortcut and id_shortcut_pk don''t match');

        END IF;
    END IF;

    IF nvl(:OLD.id_shortcut_pk, 0) != nvl(:NEW.id_shortcut_pk, 0)
       OR nvl(:OLD.id_sys_button_prop, 0) != nvl(:NEW.id_sys_button_prop, 0)
    THEN
        SELECT COUNT(0)
          INTO l_count
          FROM sys_shortcut s
         WHERE s.id_sys_button_prop != :NEW.id_sys_button_prop
           AND s.id_sys_button_prop IS NOT NULL
           AND s.id_shortcut_pk = :NEW.id_shortcut_pk;
        IF l_count > 0
        THEN
            raise_application_error(-20002,
                                    'Integrity restriction: id_sys_button_prop and id_shortcut_pk don''t match');
        END IF;
    END IF;

    IF nvl(:OLD.id_profile_template, 0) != nvl(:NEW.id_profile_template, 0)
       OR nvl(:OLD.id_software, 0) != nvl(:NEW.id_software, 0)
    THEN

        SELECT COUNT(0)
          INTO l_count
          FROM profile_template p
         WHERE p.id_profile_template = :NEW.id_profile_template
           AND p.id_software != :NEW.id_software;
        IF l_count > 0
        THEN
            raise_application_error(-20004, 'Integrity restriction: id_software and id_profile_template don''t match');
        END IF;
    END IF;

END;
/
