CREATE OR REPLACE TYPE t_rec_translation AS OBJECT
(
    code_translation VARCHAR2(200 CHAR),
    module           VARCHAR2(200 CHAR),
    desc_lang_1      VARCHAR2(4000),
    desc_lang_2      VARCHAR2(4000),
    desc_lang_3      VARCHAR2(4000),
    desc_lang_4      VARCHAR2(4000),
    desc_lang_5      VARCHAR2(4000),
    desc_lang_6      VARCHAR2(4000),
    desc_lang_7      VARCHAR2(4000),
    desc_lang_8      VARCHAR2(4000),
    desc_lang_9      VARCHAR2(4000),
    desc_lang_10     VARCHAR2(4000),
    desc_lang_11     VARCHAR2(4000),
    desc_lang_12     VARCHAR2(4000),
    desc_lang_13     VARCHAR2(4000),
    desc_lang_14     VARCHAR2(4000),
    desc_lang_15     VARCHAR2(4000),
    desc_lang_16     VARCHAR2(4000),
    desc_lang_17     VARCHAR2(4000),
    desc_lang_18     VARCHAR2(4000),
    desc_lang_19     VARCHAR2(4000),
    desc_lang_20     VARCHAR2(4000)
)
/

-- cmf 18-12-2012
drop type t_rec_translation;