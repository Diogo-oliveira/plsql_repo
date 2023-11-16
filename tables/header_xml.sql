create global temporary table header_xml(
                    O_ACUITY clob,
                    O_COLOR_TEXT clob,
                    O_DESC_ACUITY clob,
                    O_CAT clob,
                    O_FLG_TYPE clob,
                    O_PROF_NAME clob,
                    O_COMPL_DIAG clob,
                    O_INFO_ADIC clob,
                    O_COMPL_PAIN clob,
                    O_LOCATION_T clob,
                    O_LOCATION_V clob,
                    O_TIME_ROOM_T clob,
                    O_TIME_ROOM_V clob,
                    O_ADMIT_T clob,
                    O_ADMIT_V clob,
                    O_TOTAL_TIME_T clob,
                    O_TOTAL_TIME_V clob,
                    O_NKDA clob,
                    O_HABIT clob,
                    O_ALLERGY clob,
                    O_RELEV_DISEASE clob,
                    O_RELEV_NOTE clob,
                    O_APPLICATION clob,
                    O_PREV_EPIS clob,
                    O_NAME clob,
                    O_GENDER clob,
                    O_BLOOD_TYPE clob,
                    O_HEALTH_PLAN clob,
                    O_AGE clob,
                    O_CLIN_REC_T clob,
                    O_CLIN_REC_V clob,
                    O_DISCH_T clob,
                    O_DISCH_V clob,
                    O_EPISODE_T clob,
                    O_EPISODE_V clob,
                    O_EFECTIV_T clob,
                    O_EFECTIV_V clob,
                    O_ATEND_T clob,
                    O_ATEND_V clob,
                    O_WAIT_T clob,
                    O_WAIT_V clob,
                    ID_EPISODE clob,
                    O_PATIENT clob,
                    O_SERVICO clob,
                    O_SCHED_T clob,
                    O_SCHED_V clob,
                    file_name varchar2(4000)) on commit delete rows;