CREATE OR REPLACE PROCEDURE insert_into_translation
(
    i_lang       IN language.id_language%TYPE,
    i_code_trans IN translation.code_translation%TYPE,
    i_desc_trans IN pk_translation.t_desc_translation,
    i_module     IN PK_translation.t_module DEFAULT NULL
) IS
BEGIN

    pk_translation.insert_into_translation(i_lang, i_code_trans, i_desc_trans );
    
END;
/


-- cmf 18-12-2012
drop procedure insert_into_translation;