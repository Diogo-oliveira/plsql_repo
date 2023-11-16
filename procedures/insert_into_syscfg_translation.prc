CREATE OR REPLACE PROCEDURE insert_into_syscfg_translation
(
    i_lang        IN LANGUAGE.id_language%TYPE,
    i_sys_config  IN sys_config_translation.id_sys_config%TYPE,
    i_desc_config IN sys_config_translation.desc_config %TYPE,
    i_desc_func   IN sys_config_translation.desc_functionality%TYPE,
    i_impact_msg  IN sys_config_translation.IMPACT_MSG%TYPE,
    i_impact_screen_msg IN sys_config_translation.IMPACT_SCREEN_MSG%TYPE
) IS
    --l_max translation.id_translation%TYPE;
BEGIN

    MERGE INTO sys_config_translation t
    USING (SELECT i_sys_config  id_sys_config,
                  i_desc_config desc_config,
                  i_desc_func   desc_functionality,
                  i_lang        id_language,
                  i_impact_msg  impact_msg,
                  i_impact_screen_msg impact_screen_msg
             FROM dual) args
    ON (t.id_language = args.id_language AND t.id_sys_config = args.id_sys_config)
    WHEN MATCHED THEN
        UPDATE
           SET desc_config        = args.desc_config,
               desc_functionality = args.desc_functionality,
               adw_last_update    = SYSDATE,
               impact_msg         = args.impact_msg,
               impact_screen_msg  = args.impact_screen_msg
    WHEN NOT MATCHED THEN
        INSERT
            (id_sys_config,
             id_language,
             desc_config,
             desc_functionality,
             adw_last_update,
             impact_msg,
             impact_screen_msg)
        VALUES
            (args.id_sys_config,
             args.id_language,
             args.desc_config,
             args.desc_functionality,
             SYSDATE,
             args.impact_msg,
             args.impact_screen_msg);
END;
