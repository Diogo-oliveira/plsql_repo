CREATE OR REPLACE TYPE t_rec_sections force AS OBJECT
(
    translated_code              VARCHAR2(4000),
    doc_area                     NUMBER,
    screen_name                  VARCHAR2(200),
    id_sys_shortcut              NUMBER,
    flg_write                    VARCHAR2(1),
    flg_search                   VARCHAR2(1),
    flg_no_changes               VARCHAR2(1),
    flg_template                 VARCHAR2(1),
    height                       NUMBER,
    flg_type                     VARCHAR(2),
    screen_name_after_save       VARCHAR(200),
    subtitle                     VARCHAR2(4000),
    intern_name_sample_text_type VARCHAR(200),
    flg_score                    VARCHAR(1),
    screen_name_free_text        VARCHAR(200),
    flg_scope_type               VARCHAR(1),
    flg_data_paging_enabled      VARCHAR(1),
    page_size                    NUMBER,
    rank                         NUMBER,
    flg_create                   VARCHAR2(1)
)
;