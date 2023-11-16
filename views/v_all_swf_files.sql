CREATE OR REPLACE VIEW V_ALL_SWF_FILES AS
SELECT 01 MY_ORDER, HOST_SCREEN            FILE_NAME, 'HOST_SCREEN'            FIELD_NAME, 'VIEWER_SYNCHRONIZE'    TABLE_NAME, TO_CHAR(ID_VIEWER_SYNCHRONIZE)    ID_PK	FROM VIEWER_SYNCHRONIZE    WHERE HOST_SCREEN IS NOT NULL
UNION ALL                                                                                                                             
SELECT 02 MY_ORDER, VIEWER_SCREEN          FILE_NAME, 'VIEWER_SCREEN'          FIELD_NAME, 'VIEWER_SYNCHRONIZE'    TABLE_NAME, TO_CHAR(ID_VIEWER_SYNCHRONIZE)    ID_PK FROM VIEWER_SYNCHRONIZE    WHERE VIEWER_SCREEN IS NOT NULL
UNION ALL                                                                                                                             
SELECT 03 MY_ORDER, SCREEN_NAME            FILE_NAME, 'SCREEN_NAME'            FIELD_NAME, 'SYS_BUTTON_PROP'       TABLE_NAME, TO_CHAR(ID_SYS_BUTTON_PROP)       ID_PK FROM SYS_BUTTON_PROP       WHERE SCREEN_NAME IS NOT NULL
UNION ALL                                                                                                                                   
SELECT 04 MY_ORDER, FILE_TO_EXECUTE        FILE_NAME, 'FILE_TO_EXECUTE'        FIELD_NAME, 'DISCHARGE_REASON'      TABLE_NAME, TO_CHAR(ID_DISCHARGE_REASON)      ID_PK FROM DISCHARGE_REASON      WHERE FILE_TO_EXECUTE IS NOT NULL
UNION ALL                                                                                                         
SELECT 05 MY_ORDER, FILE_NAME              FILE_NAME, 'FILE_NAME'              FIELD_NAME, 'DISCHARGE_FLASH_FILES' TABLE_NAME, TO_CHAR(ID_DISCHARGE_FLASH_FILES) ID_PK FROM DISCHARGE_FLASH_FILES WHERE FILE_NAME IS NOT NULL
UNION ALL                                                                                                               
SELECT 06 MY_ORDER, VALUE                  FILE_NAME, 'VALUE'                  FIELD_NAME, 'SYS_CONFIG'            TABLE_NAME, ID_SYS_CONFIG                     ID_PK FROM SYS_CONFIG            WHERE VALUE IS NOT NULL   AND UPPER(VALUE) LIKE '%.SWF%'
UNION ALL                                                                                                                                      
SELECT 07 MY_ORDER, VALUE                  FILE_NAME, 'VALUE'                  FIELD_NAME, 'FINGER_DB.SYS_CONFIG'  TABLE_NAME, ID_SYS_CONFIG                     ID_PK FROM FINGER_DB.SYS_CONFIG  WHERE VALUE IS NOT NULL   AND UPPER(VALUE) LIKE '%.SWF%'
UNION ALL                                                                                                                             
SELECT 08 MY_ORDER, VIEWER_SCREEN          FILE_NAME, 'VIEWER_SCREEN'          FIELD_NAME, 'VIEWER_REFRESH'        TABLE_NAME, TO_CHAR(ID_VIEWER_REFRESH)        ID_PK	FROM VIEWER_REFRESH        WHERE VIEWER_SCREEN IS NOT NULL
UNION ALL                                                                                                                                                                            
SELECT 09 MY_ORDER, DESC_VAL               FILE_NAME, 'DESC_VAL'               FIELD_NAME, 'SYS_DOMAIN'            TABLE_NAME, CODE_DOMAIN                       ID_PK	FROM SYS_DOMAIN            WHERE DESC_VAL IS NOT NULL   AND UPPER(DESC_VAL) LIKE '%.SWF%'
UNION ALL                                                                                                                                                                            
SELECT 10 MY_ORDER, FIRST_SCREEN           FILE_NAME, 'FIRST_SCREEN'           FIELD_NAME, 'PROF_PREFERENCES'      TABLE_NAME, TO_CHAR(ID_PROF_PREFERENCES)      ID_PK	FROM PROF_PREFERENCES      WHERE FIRST_SCREEN IS NOT NULL
UNION ALL                                                                                                                                                                            
SELECT 11 MY_ORDER, SCREEN_NAME            FILE_NAME, 'SCREEN_NAME'            FIELD_NAME, 'EXAM_TYPE_TEMPLATE'    TABLE_NAME, TO_CHAR(ID_EXAM_TYPE_TEMPLATE)    ID_PK	FROM EXAM_TYPE_TEMPLATE    WHERE SCREEN_NAME IS NOT NULL
UNION ALL                                                                                                                             
SELECT 12 MY_ORDER, SCREEN_NAME            FILE_NAME, 'SCREEN_NAME'            FIELD_NAME, 'REP_SCREEN'            TABLE_NAME, TO_CHAR(ID_REP_SCREEN)            ID_PK FROM REP_SCREEN            WHERE SCREEN_NAME IS NOT NULL
UNION ALL                                                         
SELECT 13 MY_ORDER, SCREEN_NAME            FILE_NAME, 'SCREEN_NAME'            FIELD_NAME, 'SUMMARY_PAGE_SECTION'  TABLE_NAME, TO_CHAR(ID_SUMMARY_PAGE_SECTION)  ID_PK FROM SUMMARY_PAGE_SECTION  WHERE SCREEN_NAME IS NOT NULL
UNION ALL
SELECT 14 MY_ORDER, SCREEN_NAME_FREE_TEXT  FILE_NAME, 'SCREEN_NAME_FREE_TEXT'  FIELD_NAME, 'SUMMARY_PAGE_SECTION'  TABLE_NAME, TO_CHAR(ID_SUMMARY_PAGE_SECTION)  ID_PK FROM SUMMARY_PAGE_SECTION  WHERE SCREEN_NAME_FREE_TEXT IS NOT NULL
UNION ALL
SELECT 15 MY_ORDER, SCREEN_NAME_AFTER_SAVE FILE_NAME, 'SCREEN_NAME_AFTER_SAVE' FIELD_NAME, 'SUMMARY_PAGE_SECTION'  TABLE_NAME, TO_CHAR(ID_SUMMARY_PAGE_SECTION)  ID_PK FROM SUMMARY_PAGE_SECTION  WHERE SCREEN_NAME_AFTER_SAVE IS NOT NULL
UNION ALL
SELECT 16 MY_ORDER, SCREEN_NAME            FILE_NAME, 'SCREEN_NAME'            FIELD_NAME, 'BEYE_VIEW_SCREEN'      TABLE_NAME, TO_CHAR(ID_BEYE_VIEW_SCREEN)      ID_PK FROM BEYE_VIEW_SCREEN      WHERE SCREEN_NAME IS NOT NULL
UNION ALL
SELECT 17 MY_ORDER, DET_SCREEN_NAME        FILE_NAME, 'DET_SCREEN_NAME'				 FIELD_NAME, 'REPORTS'							 TABLE_NAME, TO_CHAR(ID_REPORTS)               ID_PK FROM REPORTS               WHERE DET_SCREEN_NAME IS NOT NULL
UNION ALL
SELECT 18 MY_ORDER, CODE_MESSAGE					 FILE_NAME, 'CODE_MESSAGE'					 FIELD_NAME, 'SYS_MESSAGE'					 TABLE_NAME, CODE_MESSAGE											ID_PK FROM SYS_MESSAGE           WHERE CODE_MESSAGE IS NOT NULL AND UPPER(FLG_TYPE) = 'H'
UNION ALL                                                                                                                                                                            
SELECT 19 MY_ORDER, SCREEN_NAME            FILE_NAME, 'SCREEN_NAME'            FIELD_NAME, 'SR_EVAL_SUMM'					 TABLE_NAME, TO_CHAR(ID_SR_EVAL_SUMM)          ID_PK FROM SR_EVAL_SUMM          WHERE SCREEN_NAME IS NOT NULL
;