CREATE OR REPLACE PROCEDURE insert_tbl_temp
(
    i_num_1 table_number DEFAULT NULL,
    i_num_2 table_number DEFAULT NULL,
    i_num_3 table_number DEFAULT NULL,
    i_num_4 table_number DEFAULT NULL,
    i_num_5 table_number DEFAULT NULL,
    i_num_6 table_number DEFAULT NULL,
    i_vc_1  table_varchar DEFAULT NULL,
    i_vc_2  table_varchar DEFAULT NULL,
    i_vc_3  table_varchar DEFAULT NULL,
    i_vc_4  table_varchar DEFAULT NULL,
    i_vc_5  table_varchar DEFAULT NULL,
    i_vc_6  table_varchar DEFAULT NULL,
    
    i_dt_1 table_date DEFAULT NULL,
    i_dt_2 table_date DEFAULT NULL,
    i_dt_3 table_date DEFAULT NULL,
    i_dt_4 table_date DEFAULT NULL,
    
    i_tstz_1 table_timestamp_tz DEFAULT NULL,
    i_tstz_2 table_timestamp_tz DEFAULT NULL,
    i_tstz_3 table_timestamp_tz DEFAULT NULL,
    i_tstz_4 table_timestamp_tz DEFAULT NULL
) IS
    l_n1 table_number;
    l_n2 table_number;
    l_n3 table_number;
    l_n4 table_number;
    l_n5 table_number;
    l_n6 table_number;
    --
    l_v1 table_varchar;
    l_v2 table_varchar;
    l_v3 table_varchar;
    l_v4 table_varchar;
    l_v5 table_varchar;
    l_v6 table_varchar;
    --
    l_d1 table_date;
    l_d2 table_date;
    l_d3 table_date;
    l_d4 table_date;
    --    
    l_t1 table_timestamp_tz;
    l_t2 table_timestamp_tz;
    l_t3 table_timestamp_tz;
    l_t4 table_timestamp_tz;
    --
    l_max PLS_INTEGER;

BEGIN
    l_n1 := nvl(i_num_1, table_number());
    l_n2 := nvl(i_num_2, table_number());
    l_n3 := nvl(i_num_3, table_number());
    l_n4 := nvl(i_num_4, table_number());
    l_n5 := nvl(i_num_5, table_number());
    l_n6 := nvl(i_num_6, table_number());
    --
    l_v1 := nvl(i_vc_1, table_varchar());
    l_v2 := nvl(i_vc_2, table_varchar());
    l_v3 := nvl(i_vc_3, table_varchar());
    l_v4 := nvl(i_vc_4, table_varchar());
    l_v5 := nvl(i_vc_5, table_varchar());
    l_v6 := nvl(i_vc_6, table_varchar());
    --
    l_d1 := nvl(i_dt_1, table_date());
    l_d2 := nvl(i_dt_2, table_date());
    l_d3 := nvl(i_dt_3, table_date());
    l_d4 := nvl(i_dt_4, table_date());
    --
    l_t1 := nvl(i_tstz_1, table_timestamp_tz());
    l_t2 := nvl(i_tstz_2, table_timestamp_tz());
    l_t3 := nvl(i_tstz_3, table_timestamp_tz());
    l_t4 := nvl(i_tstz_4, table_timestamp_tz());

    EXECUTE IMMEDIATE --
     'SELECT MAX(column_value) ' || --
     '  FROM TABLE(table_number(:l_n1_COUNT, ' || --
     '                          :l_n2_COUNT, ' || --
     '                          :l_n3_COUNT, ' || --
     '                          :l_n4_COUNT, ' || --
     '                          :l_n5_COUNT, ' || --
     '                          :l_n6_COUNT, ' || --
     '                          :l_v1_COUNT, ' || --
     '                          :l_v2_COUNT, ' || --
     '                          :l_v3_COUNT, ' || --
     '                          :l_v4_COUNT, ' || --
     '                          :l_v5_COUNT, ' || --
     '                          :l_v6_COUNT, ' || --
     '                          :l_d1_COUNT, ' || --
     '                          :l_d2_COUNT, ' || --
     '                          :l_d3_COUNT, ' || --
     '                          :l_d4_COUNT, ' || --
     '                          :l_t1_COUNT, ' || --
     '                          :l_t2_COUNT, ' || --
     '                          :l_t3_COUNT, ' || --
     '                          :l_t4_COUNT))'
        INTO l_max
        USING --
    l_n1.COUNT, l_n2.COUNT, l_n3.COUNT, l_n4.COUNT, l_n5.COUNT, l_n6.COUNT, --
    l_v1.COUNT, l_v2.COUNT, l_v3.COUNT, l_v4.COUNT, l_v5.COUNT, l_v6.COUNT, --
    l_d1.COUNT, l_d2.COUNT, l_d3.COUNT, l_d4.COUNT, --
    l_t1.COUNT, l_t2.COUNT, l_t3.COUNT, l_t4.COUNT;
    --
    IF l_n1.COUNT < l_max
    THEN
        l_n1.EXTEND(l_max - l_n1.COUNT);
    END IF;
    IF l_n2.COUNT < l_max
    THEN
        l_n2.EXTEND(l_max - l_n2.COUNT);
    END IF;
    IF l_n3.COUNT < l_max
    THEN
        l_n3.EXTEND(l_max - l_n3.COUNT);
    END IF;
    IF l_n4.COUNT < l_max
    THEN
        l_n4.EXTEND(l_max - l_n4.COUNT);
    END IF;
    IF l_n5.COUNT < l_max
    THEN
        l_n5.EXTEND(l_max - l_n5.COUNT);
    END IF;
    IF l_n6.COUNT < l_max
    THEN
        l_n6.EXTEND(l_max - l_n6.COUNT);
    END IF;
    --
    IF l_v1.COUNT < l_max
    THEN
        l_v1.EXTEND(l_max - l_v1.COUNT);
    END IF;
    IF l_v2.COUNT < l_max
    THEN
        l_v2.EXTEND(l_max - l_v2.COUNT);
    END IF;
    IF l_v3.COUNT < l_max
    THEN
        l_v3.EXTEND(l_max - l_v3.COUNT);
    END IF;
    IF l_v4.COUNT < l_max
    THEN
        l_v4.EXTEND(l_max - l_v4.COUNT);
    END IF;
    IF l_v5.COUNT < l_max
    THEN
        l_v5.EXTEND(l_max - l_v5.COUNT);
    END IF;
    IF l_v6.COUNT < l_max
    THEN
        l_v6.EXTEND(l_max - l_v6.COUNT);
    END IF;
    --    
    IF l_d1.COUNT < l_max
    THEN
        l_d1.EXTEND(l_max - l_d1.COUNT);
    END IF;
    IF l_d2.COUNT < l_max
    THEN
        l_d2.EXTEND(l_max - l_d2.COUNT);
    END IF;
    IF l_d3.COUNT < l_max
    THEN
        l_d3.EXTEND(l_max - l_d3.COUNT);
    END IF;
    IF l_d4.COUNT < l_max
    THEN
        l_d4.EXTEND(l_max - l_d4.COUNT);
    END IF;
    --
    IF l_t1.COUNT < l_max
    THEN
        l_t1.EXTEND(l_max - l_t1.COUNT);
    END IF;
    IF l_t2.COUNT < l_max
    THEN
        l_t2.EXTEND(l_max - l_t2.COUNT);
    END IF;
    IF l_t3.COUNT < l_max
    THEN
        l_t3.EXTEND(l_max - l_t3.COUNT);
    END IF;
    IF l_t4.COUNT < l_max
    THEN
        l_t4.EXTEND(l_max - l_t4.COUNT);
    END IF;
    --

    --dbms_output.put_line('MAX: ' || l_max);
    FORALL idx IN 1 .. l_max
        INSERT INTO tbl_temp
            (num_1,
             num_2,
             num_3,
             num_4,
             num_5,
             num_6,
             vc_1,
             vc_2,
             vc_3,
             vc_4,
             vc_5,
             vc_6,
             dt_1,
             dt_2,
             dt_3,
             dt_4,
             tstz_1,
             tstz_2,
             tstz_3,
             tstz_4)
        VALUES
            (l_n1(idx),
             l_n2(idx),
             l_n3(idx),
             l_n4(idx),
             l_n5(idx),
             l_n6(idx),
             l_v1(idx),
             l_v2(idx),
             l_v3(idx),
             l_v4(idx),
             l_v5(idx),
             l_v6(idx),
             l_d1(idx),
             l_d2(idx),
             l_d3(idx),
             l_d4(idx),
             l_t1(idx),
             l_t2(idx),
             l_t3(idx),
             l_t4(idx));

END insert_tbl_temp;
/
